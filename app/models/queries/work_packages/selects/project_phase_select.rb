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
    "#{group_by_statement} as project_phase_definition_id"
  end

  def group_by_statement
    active_phase_null_case(true_case: "NULL", false_case: "project_phase_definitions.id")
  end

  def order_for_count
    active_phase_null_case(true_case: "1", false_case: "0")
  end

  # Is called when the query is grouped by project phase definition. We ensure that only active project phases are considered.
  # Note that one project might have an active phase while another project has set the phase with the same definition to inactive.
  # Additionally, the permissions to view project phases are considered on a project level, too.
  def group_by_join_statement
    # The project is joined here anew which should not be necessary but is.
    # The necessity comes from AR's behaviour of automatically determining the alias for tables LEFT JOINed via includes.
    # To avoid conflicts, AR will search strings for occurrences of the table name and if found, an included table will be aliased
    # (potentially with a numbering). In this case, if the permission checks are part of the query, it will include a reference
    # to the projects table. Therefore, the include for projects, which happens in the query itself, will be considered needing
    # an alias. That assumption is wrong in this case as the reference to projects is in a subquery but AR does not know that.
    <<~SQL.squish
      LEFT OUTER JOIN "projects" ON "projects"."id" = "work_packages"."project_id"
      LEFT OUTER JOIN (
        SELECT
          ph.id,
          ph.project_id,
          ph.definition_id AS active_phase_definition_id
        FROM project_phases ph
        WHERE ph.project_id IN (#{project_with_view_phases_permissions.to_sql})
        AND ph.active = true
      ) AS active_phases
      ON active_phases.active_phase_definition_id = work_packages.project_phase_definition_id
        AND active_phases.project_id = work_packages.project_id
    SQL
  end

  def sortable_join_statement(_query)
    # Replicate the group by join to ensure the same conditions are applied (and the same alias for the join is used)
    group_by_join_statement
  end

  def sortable_statement
    # We use the join alias from the group by join statement to ensure that work packages with an *inactive* project
    # phase are treated like work packages *without* a project phase. In the result list, they will belong to the
    # same group: without an active project phase.
    active_phase_null_case(true_case: "-1", false_case: "project_phase_definitions.position")
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

  def active_phase_null_case(true_case:, false_case:)
    "(CASE WHEN ACTIVE_PHASES.ID IS NULL THEN #{true_case} ELSE #{false_case} END)"
  end
end
