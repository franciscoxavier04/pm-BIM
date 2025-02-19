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

module Admin
  class TimeEntryActivitiesController < ApplicationController
    include OpTurbo::ComponentStream

    # Allow only admins here
    before_action :require_admin
    before_action :find_time_entry_activity, only: %i[edit update destroy move reassign]
    layout "admin"

    menu_item :time_entry_activities

    def index
      @time_entry_activities = TimeEntryActivity.all
    end

    def new
      @time_entry_activity = TimeEntryActivity.new
    end

    def edit; end

    def create
      @time_entry_activity = TimeEntryActivity.new(permitted_params.time_entry_activities)

      if @time_entry_activity.save
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to(action: :index)
      else
        render action: :new, status: :unprocessable_entity
      end
    end

    def update
      if @time_entry_activity.update(permitted_params.time_entry_activities)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to(action: :index)
      else
        render action: :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @time_entry_activity.in_use?
        handle_reassignment_on_deletion
      elsif @time_entry_activity.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
        redirect_to(action: :index)
      else
        flash.now[:error] = I18n.t(:error_can_not_delete_entry)
        redirect_to(action: :index)
      end
    end

    def move
      if @time_entry_activity.update(move_params)
        render_success_flash_message_via_turbo_stream(
          message: I18n.t(:caption_activity_order_changed)
        )
      else
        render_error_flash_message_via_turbo_stream(
          message: I18n.t(:error_activity_could_not_be_moved)
        )
      end

      replace_via_turbo_stream(
        component: Admin::TimeEntryActivities::IndexComponent.new(time_entry_activities: TimeEntryActivity.all)
      )

      respond_with_turbo_streams
    end

    def reassign
      @other_activities = TimeEntryActivity.all - [@time_entry_activity]
    end

    private

    def move_params
      move_to = params[:move_to]
      position = Integer(params[:position], exception: false)

      if move_to.in? %w(highest higher lower lowest)
        { move_to: move_to }
      elsif position
        { position: position }
      else
        {}
      end
    end

    def handle_reassignment_on_deletion
      reassign_to_id = params.dig(:time_entry_activity, :reassign_to_id)

      if reassign_to_id.present?
        reassign_to = TimeEntryActivity.find_by(id: reassign_to_id)
        @time_entry_activity.destroy(reassign_to)
        flash[:notice] = I18n.t(:notice_successful_delete)
        redirect_to(action: :index)
      else
        redirect_to(action: :reassign, id: @time_entry_activity.id)
      end
    end

    def find_time_entry_activity
      @time_entry_activity = TimeEntryActivity.find(params[:id])
    end
  end
end
