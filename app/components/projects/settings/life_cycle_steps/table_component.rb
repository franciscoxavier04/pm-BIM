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

        def headers
          columns.map do |name|
            # TODO: a lot of attributes are not really life cycle step attributes (subject, dates)
            [name, { caption: Project::LifeCycleStep.human_attribute_name(name) }]
          end
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
          render(ProjectDateRowComponent.new(row: project, table: self, date_method: :end_date))
        end
      end
    end
  end
end
