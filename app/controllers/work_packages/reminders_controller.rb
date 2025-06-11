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

class WorkPackages::RemindersController < ApplicationController
  include OpTurbo::ComponentStream
  layout false
  before_action :find_work_package
  before_action :build_or_find_reminder, only: %i[modal_body create]
  before_action :find_reminder, only: %i[update destroy]

  before_action :authorize

  def modal_body
    render modal_component_class.new(
      remindable: @work_package,
      reminder: @reminder,
      preset: params[:preset]
    )
  end

  def create
    service_result = Reminders::CreateService.new(user: current_user)
                                             .call(reminder_params)

    if service_result.success?
      render_success_flash_message_via_turbo_stream(message: I18n.t("work_package.reminders.success_creation_message"))
      respond_with_turbo_streams
    else
      replace_via_turbo_stream(
        component: modal_component_class.new(
          remindable: @work_package,
          reminder: service_result.result,
          errors: service_result.errors,
          remind_at_date:,
          remind_at_time:
        )
      )

      respond_with_turbo_streams(status: :unprocessable_entity)
    end
  end

  def update
    service_result = Reminders::UpdateService.new(user: current_user,
                                                  model: @reminder)
                                             .call(reminder_params)

    if service_result.success?
      render_success_flash_message_via_turbo_stream(message: I18n.t("work_package.reminders.success_update_message"))
      respond_with_turbo_streams
    else
      replace_via_turbo_stream(
        component: modal_component_class.new(
          remindable: @work_package,
          reminder: service_result.result,
          errors: service_result.errors,
          remind_at_date:,
          remind_at_time:
        )
      )

      respond_with_turbo_streams(status: :unprocessable_entity)
    end
  end

  def destroy
    service_result = Reminders::DeleteService.new(user: current_user,
                                                  model: @reminder)
                                             .call

    if service_result.success?
      render_success_flash_message_via_turbo_stream(message: I18n.t("work_package.reminders.success_deletion_message"))
      respond_with_turbo_streams
    else
      render_error_flash_message_via_turbo_stream(message: service_result.errors.full_messages)
      respond_with_turbo_streams(status: :unprocessable_entity)
    end
  end

  private

  def modal_component_class
    WorkPackages::Reminder::ModalBodyComponent
  end

  def find_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
  end

  # We assume for now that there is only one reminder per work package
  def build_or_find_reminder
    @reminder = @work_package.reminders
                             .upcoming_and_visible_to(User.current)
                             .last || @work_package.reminders.build
  end

  def find_reminder
    @reminder = @work_package.reminders
                             .upcoming_and_visible_to(User.current)
                             .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error_flash_message_via_turbo_stream(message: I18n.t(:error_reminder_not_found))
    respond_with_turbo_streams(status: :not_found)
    false
  end

  def reminder_params
    params.expect(reminder: %i[remind_at_date remind_at_time note])
          .merge(remindable: @work_package, creator: User.current)
  end

  def remind_at_date
    params[:reminder][:remind_at_date]
  end

  def remind_at_time
    params[:reminder][:remind_at_time]
  end
end
