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

module My
  class TimeTrackingController < ApplicationController
    before_action :require_login

    no_authorization_required!(:calendar, :day, :week, :month)

    current_menu_item do |ctrl|
      if ctrl.params[:action] == "day" && ctrl.today?
        :my_time_tracking_today
      elsif ctrl.params[:action] == "week" && ctrl.this_week?
        :my_time_tracking_this_week
      elsif ctrl.params[:action] == "month" && ctrl.this_month?
        :my_time_tracking_this_month
      else
        :my_time_tracking
      end
    end

    layout "global"

    helper_method :current_day, :today?, :this_week?, :this_month?, :list_view_component

    def calendar
      if mobile?
        redirect_to action: :day, view_mode: default_view_mode
      else
        redirect_to action: :week, view_mode: default_view_mode
      end
    end

    def day
      load_time_entries(current_day)
    end

    def week
      load_time_entries(current_day.all_week)
    end

    def month
      load_time_entries(current_day.all_month)
    end

    def today?
      current_day == Time.zone.today
    end

    def this_week?
      current_day == Time.zone.today.beginning_of_week
    end

    def this_month?
      current_day == Time.zone.today.beginning_of_month
    end

    private

    def current_day
      return @current_day if defined?(@current_day)

      parsed_date = if params[:date].present?
                      begin
                        Date.iso8601(params[:date])
                      rescue StandardError
                        nil
                      end
                    end

      @current_day = parsed_date || current_date
    end

    def default_view_mode
      if TimeEntry.can_track_start_and_end_time?
        "calendar"
      else
        "list"
      end
    end

    def view_mode
      ActiveSupport::StringInquirer.new(params[:view_mode] || default_view_mode)
    end

    def current_date
      case params[:action].to_sym
      when :day then Time.zone.today
      when :week then Time.zone.today.beginning_of_week
      when :month then Time.zone.today.beginning_of_month
      end
    end

    def load_time_entries(time_scope)
      @time_entries = TimeEntry
        .includes(:project, :activity, { work_package: :status })
        .where(user: User.current, spent_on: time_scope)
        .order(:spent_on, :start_time, :hours)
    end

    def list_view_component
      if view_mode.list?
        My::TimeTracking::ListComponent.new(time_entries: @time_entries, mode: params[:action].to_sym, date: current_day)
      else
        My::TimeTracking::CalendarComponent.new(time_entries: @time_entries, mode: params[:action].to_sym, date: current_day)
      end
    end

    def mobile?
      browser.device.mobile?
    end

    def default_breadcrumb; end

    def show_local_breadcrumb
      false
    end
  end
end
