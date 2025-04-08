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
    class ListComponent < ApplicationComponent
      include OpTurbo::Streamable
      include SharedComponent

      options time_entries: [],
              mode: :week,
              date: Date.current

      private

      def wrapper_data
        {
          "controller" => "generic-dialog-close",
          "application-target" => "dynamic"
        }
      end

      def range
        case mode
        when :day then [date]
        when :week then date.all_week
        when :month then date.all_month
        end
      end

      def time_entries_by_day
        @time_entries_by_day ||= time_entries.group_by(&:spent_on).tap do |hash|
          hash.default_proc = ->(h, k) { h[k] = [] }
        end
      end

      def total_hours_per_day(date)
        total_hours = time_entries_by_day[date].sum(&:hours).round(2)
        DurationConverter.output(total_hours, format: :hours_and_minutes)
      end

      def date_title(date) # rubocop:disable Metrics/AbcSize
        result = [
          render(Primer::Beta::Text.new) { date.strftime("%A %d") }
        ]

        if date.today?
          result << render(Primer::Beta::Text.new(color: :muted)) { t("label_today") }
        elsif date.yesterday?
          result << render(Primer::Beta::Text.new(color: :muted)) { t("label_yesterday") }
        end

        result << render(Primer::Beta::Text.new(color: :muted)) do
          count = time_entries_by_day[date].count
          "#{count} #{TimeEntry.model_name.human(count: count)}"
        end

        result << render(Primer::Beta::Text.new) { total_hours_per_day(date) }

        safe_join(result, " ")
      end
    end
  end
end
