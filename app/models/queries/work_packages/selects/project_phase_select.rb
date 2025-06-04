# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::WorkPackages::Selects::ProjectPhaseSelect < Queries::WorkPackages::Selects::WorkPackageSelect
  def initialize
    super(:project_phase,
          association: :project_phase_definition,
          group_by_column_name: :project_phase_definition,
          sortable: sortable_statement,
          groupable: group_by_statement,
          groupable_join: group_by_join_statement,
          groupable_select: groupable_select
    )
  end

  def groupable_select
    "pd.id as project_phase_definition_id"
  end

  def group_by_statement
    "pd.id"
  end

  def order_for_count
    Arel.sql(
      <<~SQL.squish
        CASE WHEN COALESCE(pd.id, 0) = 0 THEN 1 ELSE 0 END
      SQL
    )
  end

  # Is called when the query is grouped by project phase definition. We ensure that only active project phases are considered.
  # Note that one project might have an active phase while another project has set the phase with the same definition to inactive.
  # Additionally, the permissions to view project phases are considered on a project level, too.
  def group_by_join_statement
    # FIXME: the last line (join on projects) is only necessary because the specs break otherwise (invalid statement).
    # I have no idea why yet. Remove this hacky fix and investigate.
    Arel.sql(
      <<~SQL.squish
        LEFT JOIN (
          SELECT
            wp.id AS wp_id,
            MAX(CASE WHEN ph.active THEN ph.definition_id ELSE NULL END) AS active_phase_definition_id
          FROM work_packages wp
          LEFT JOIN project_phases ph ON ph.project_id = wp.project_id AND ph.definition_id = wp.project_phase_definition_id
          WHERE wp.project_id IN (#{project_with_view_phases_permissions.to_sql})
          GROUP BY wp.id
        ) AS active_phases ON active_phases.wp_id = work_packages.id
        LEFT JOIN project_phase_definitions pd ON pd.id = active_phases.active_phase_definition_id
        JOIN projects on projects.id = work_packages.project_id
      SQL
    )
  end

  def sortable_join_statement(_query)
    # Replicate the group by join to ensure the same conditions are applied (and the same alias for the join is used)
    group_by_join_statement
  end

  def sortable_statement
    # We use the join alias from the group by join statement to ensure that work packages with an *inactive* project
    # phase are treated like work packages *without* a project phase. In the result list, they will belong to the
    # same group: without an active project phase.
    "COALESCE(pd.position, -1)"
  end

  def self.instances(context = nil)
    allowed = if context
                OpenProject::FeatureDecisions.stages_and_gates_active? &&
                  User.current.allowed_in_project?(:view_project_phases, context)
              else
                OpenProject::FeatureDecisions.stages_and_gates_active? &&
                  User.current.allowed_in_any_project?(:view_project_phases)
              end

    if allowed
      [new]
    else
      []
    end
  end

  private

  def project_with_view_phases_permissions
    Project.allowed_to(User.current, :view_project_phases).select(:id)
  end
end
