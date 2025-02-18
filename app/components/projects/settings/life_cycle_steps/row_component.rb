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
      class RowComponent < ::RowComponent
        delegate :definition, :active?, to: :model

        def subject
          render(Primer::Beta::Text.new(color: :muted, classes: "filter-target-visible-text")) do
            model.name
          end
        end

        def type = render(Projects::LifeCycleTypeComponent.new(definition))

        def active
          render(
            Primer::Alpha::ToggleSwitch.new(
              src: toggle_project_settings_life_cycle_step_path(id: definition.id),
              csrf_token: form_authenticity_token,
              data: { test_selector: "toggle-project-life-cycle-#{definition.id}" },
              aria: { label: toggle_aria_label },
              checked: active?,
              size: :small,
              status_label_position: :start,
              classes: "op-primer-adjustments__toggle-switch--hidden-loading-indicator"
            )
          )
        end

        def duration
          case model
          when Project::Stage
            model.working_days_count
          end
        end

        def dates
          case model
          when Project::Gate
            helpers.format_date(model.date)
          when Project::Stage
            format_date_range(model.start_date..model.end_date)
          end
        end

        def toggle_aria_label
          I18n.t("projects.settings.life_cycle.step.use_in_project", step: definition.name)
        end

        def row_attributes
          {
            data: {
              "projects--settings--border-box-filter-target": "searchItem",
              test_selector: "project-life-cycle-step-#{definition.id}"
            }
          }
        end

        private

        def format_date_range(date_range)
          return unless date_range.begin || date_range.end

          "#{helpers.format_date(date_range.begin) || '…'} - #{helpers.format_date(date_range.end) || '…'}"
        end
      end
    end
  end
end
