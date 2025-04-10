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
    class HeaderComponent < ApplicationComponent
      options :date, :mode, :view_mode

      def title
        case mode
        when :week then week_title
        when :month then month_title
        when :day then day_title
        end
      end

      def day_title
        if Date.current == date
          I18n.t(:label_today)
        else
          I18n.t(:label_specific_day, day: I18n.l(date, format: :short))
        end
      end

      def week_title
        if Date.current.all_week.include?(date)
          I18n.t(:label_this_week)
        else
          I18n.t(:label_specific_week, week: I18n.l(date, format: "%W %Y"))
        end
      end

      def month_title
        if Date.current.all_month.include?(date)
          I18n.t(:label_this_month)
        else
          I18n.t(:label_specific_month, month: I18n.l(date, format: "%B %Y"))
        end
      end

      def view_mode_block
        if view_mode == :list
          lambda do |button|
            button.with_leading_visual_icon(icon: "list-unordered")
            button.with_trailing_action_icon(icon: "triangle-down")
            t(:label_list)
          end
        else
          lambda do |button|
            button.with_leading_visual_icon(icon: :calendar)
            button.with_trailing_action_icon(icon: "triangle-down")
            t(:label_calendar)
          end
        end
      end
    end
  end
end
