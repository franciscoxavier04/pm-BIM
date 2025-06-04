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

class Queries::WorkPackages::Filter::ProjectPhaseFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    @allowed_values ||= project_phase_definitions.map { |s| [s.name, s.id.to_s] }
  end

  def available?
    project_phase_definitions.any?
  end

  def type
    :list
  end

  def self.key
    :project_phase_definition_id
  end

  def ar_object_filter?
    true
  end

  def value_objects
    available_definitions = project_phase_definitions.index_by(&:id)

    values.filter_map { |id| available_definitions[id.to_i] }
  end

  # TODO: copied over from ProjectPhaseSelect, refactor to use the same truth
  def joins
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

  def project_with_view_phases_permissions
    Project.allowed_to(User.current, :view_project_phases).select(:id)
  end

  def where
    if operator_strategy.to_sym == :"="
      Arel.sql(
        <<~SQL.squish
          active_phases.active_phase_definition_id IS NOT NULL AND
            active_phases.active_phase_definition_id IN (#{values.join(',')})
        SQL
      )
    elsif operator_strategy.to_sym == :!
      Arel.sql(
        <<~SQL.squish
          active_phases.active_phase_definition_id IS NULL OR
            active_phases.active_phase_definition_id NOT IN (#{values.join(',')})
        SQL
      )
    else
      ""
    end
  end

  private

  def project_phase_feature_flag_enabled?
    OpenProject::FeatureDecisions.stages_and_gates_active?
  end

  def project_phase_definitions
    return Project::PhaseDefinition.none unless project_phase_feature_flag_enabled?

    Project::PhaseDefinition.order(Arel.sql("position"))
  end
end
