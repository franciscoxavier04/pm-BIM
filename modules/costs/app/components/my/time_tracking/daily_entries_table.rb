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
    class DailyEntriesTable < OpPrimer::BorderBoxTableComponent
      columns :time, :hours, :subject, :project, :activity, :comments
      main_column :time, :subject, :project

      def row_class
        TimeEntryRow
      end

      def mobile_title
        TimeEntry.model_name.human(count: 2)
      end

      def has_actions? = true

      def action_row_header_content
        render(Primer::Beta::IconButton.new(
                 icon: "plus",
                 scheme: :invisible,
                 size: :small,
                 tag: :a,
                 tooltip_direction: :e,
                 href: dialog_time_entries_path(onlyMe: true, date: options[:date]),
                 data: { "turbo-stream" => true },
                 label: t("label_log_time"),
                 aria: { label: t("label_log_time") }
               ))
      end

      def headers
        [
          TimeEntry.can_track_start_and_end_time? ? [:time, { caption: "Time" }] : nil,
          [:hours, { caption: "Hours" }],
          [:subject, { caption: "Subject" }],
          [:project, { caption: "Project" }],
          [:activity, { caption: "Activity" }],
          [:comments, { caption: "Comments" }]
        ].compact
      end

      def skip_column?(column)
        if column == :time
          !TimeEntry.can_track_start_and_end_time?
        else
          false
        end
      end
    end
  end
end
