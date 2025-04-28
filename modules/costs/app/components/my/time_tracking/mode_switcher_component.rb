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
    class ModeSwitcherComponent < ApplicationComponent
      options :current_mode,
              :view_mode,
              :date

      def call
        render(Primer::Alpha::SegmentedControl.new("aria-label": I18n.t(:label_meeting_date_time))) do |control|
          %i[day week month].each do |mode|
            control.with_item(
              tag: :a,
              href: my_time_tracking_path(date:, view_mode:, mode:),
              icon: icon_for_mode(mode),
              label: t("label_#{mode}"),
              title: t("label_#{mode}"),
              selected: (current_mode == mode)
            )
          end
        end
      end

      def icon_for_mode(mode)
        case mode
        when :day
          "op-calendar-day"
        when :week
          "op-calendar-week"
        else
          "calendar"
        end
      end
    end
  end
end
