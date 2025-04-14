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
    class SubHeaderComponent < ApplicationComponent
      options :date, :mode, :view_mode

      def title # rubocop:disable Metrics/AbcSize
        case mode
        when :day
          I18n.l(date, format: :long)
        when :week
          bow = date.beginning_of_week
          eow = date.end_of_week

          if bow.year == eow.year && bow.month == eow.month
            [I18n.l(bow, format: "%d."), I18n.l(eow, format: "%d. %B %Y")].join(" - ")
          elsif bow.year == eow.year
            [I18n.l(bow, format: "%d. %B"), I18n.l(eow, format: "%d. %B %Y")].join(" - ")
          else
            [I18n.l(bow, format: "%d. %B %Y"), I18n.l(eow, format: "%d. %B %Y")].join(" - ")
          end
        when :month
          I18n.l(date, format: "%B %Y")
        end
      end

      def today_href
        case mode
        when :day
          my_time_tracking_day_path(date: Date.current, view_mode: params[:view_mode])
        when :week
          my_time_tracking_week_path(date: Date.current, view_mode: params[:view_mode])
        when :month
          my_time_tracking_month_path(date: Date.current, view_mode: params[:view_mode])
        end
      end

      def previous_attrs # rubocop:disable Metrics/AbcSize
        case mode
        when :day
          { href: my_time_tracking_day_path(date: date - 1.day, view_mode: params[:view_mode]),
            aria: { label: I18n.t(:label_previous_day) } }
        when :week
          { href: my_time_tracking_week_path(date: date - 1.week, view_mode: params[:view_mode]),
            aria: { label: I18n.t(:label_previous_week) } }
        when :month
          { href: my_time_tracking_month_path(date: date - 1.month, view_mode: params[:view_mode]),
            aria: { label: I18n.t(:label_previous_month) } }
        end
      end

      def next_attrs # rubocop:disable Metrics/AbcSize
        case mode
        when :day
          { href: my_time_tracking_day_path(date: date + 1.day, view_mode: params[:view_mode]),
            aria: { label: I18n.t(:label_next_day) } }
        when :week
          { href: my_time_tracking_week_path(date: date + 1.week, view_mode: params[:view_mode]),
            aria: { label: I18n.t(:label_next_week) } }
        when :month
          { href: my_time_tracking_month_path(date: date + 1.month, view_mode: params[:view_mode]),
            aria: { label: I18n.t(:label_next_month) } }
        end
      end
    end
  end
end
