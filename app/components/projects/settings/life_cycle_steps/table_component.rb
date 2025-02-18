# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

module Projects
  module Settings
    module LifeCycleSteps
      class TableComponent < ::TableComponent
        options :project, :life_cycle_steps, :life_cycle_definitions

        columns :subject, :type, :active, :duration, :dates

        def initialize(**)
          super(rows: [], **)
        end

        def sortable? = false

        def button_column? = false

        def header_caption(column)
          Project::LifeCycleStep.human_attribute_name(column)
        end

        def rows
          @rows ||= begin
            steps_by_definition_id = life_cycle_steps.index_by(&:definition_id)

            life_cycle_definitions.map do |definition|
              steps_by_definition_id[definition.id] || definition.build_step(project_id: project.id)
            end
          end
        end

        def render_collection(rows)
          render(ProjectDateRowComponent.new(row: project, table: self, date_method: :start_date)) +
          render(row_class.with_collection(rows, table: self)) +
          filter_no_results_row +
          render(ProjectDateRowComponent.new(row: project, table: self, date_method: :end_date))
        end

        def filter_no_results_row
          render(
            Primer::BaseComponent.new(
              tag: :tr,
              display: :none,
              data: { "projects--settings--border-box-filter-target": "noResultsText" }
            )
          ) do
            content_tag :td, colspan: columns.length do
              render Primer::Beta::Text.new do
                I18n.t("js.autocompleter.notFoundText")
              end
            end
          end
        end
      end
    end
  end
end
