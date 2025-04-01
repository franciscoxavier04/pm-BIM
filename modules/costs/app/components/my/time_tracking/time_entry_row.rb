# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module TimeTracking
    class TimeEntryRow < OpPrimer::BorderBoxRowComponent
      def button_links
        [
          action_menu
        ]
      end

      def action_menu
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": t("label_more"), scheme: :invisible)
          menu.with_item(
            content_arguments: {
              data: {
                "turbo-stream" => true
              }
            },
            tag: :a,
            label: t("label_edit"),
            href: dialog_time_entry_path(time_entry, onlyMe: true)
          ) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end
        end
      end

      def time
        time_entry.start_timestamp || ""
      end

      def hours
        DurationConverter.output(time_entry.hours, format: :hours_and_minutes)
      end

      def subject
        "##{time_entry.work_package.id} - #{time_entry.work_package.subject}"
      end

      def project
        time_entry.project.name
      end

      def activity
        time_entry.activity&.name
      end

      delegate :comments, to: :time_entry

      private

      def time_entry
        model
      end
    end
  end
end
