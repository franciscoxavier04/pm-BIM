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

class MeetingParticipantsController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include Meetings::AgendaComponentStreams

  before_action :authorize
  before_action :set_meeting
  before_action :set_participant, only: %i[toggle_attendance destroy]

  def create
    user_id = params[:meeting_participant][:user_id]

    if MeetingParticipant.exists?(user_id: user_id, meeting_id: @meeting.id) || user_id.blank?
      update_add_user_form_component_via_turbo_stream
      update_list_component_via_turbo_stream

      respond_with_turbo_streams
      return
    end

    create_new_participant(user_id)

    update_list_component_via_turbo_stream
    respond_with_turbo_streams
  end

  def mark_all_attended
    @meeting.participants.each do |participant|
      participant.update!(attended: true)
    end

    update_add_user_form_component_via_turbo_stream
    update_list_component_via_turbo_stream
    update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)

    respond_with_turbo_streams
  end

  def toggle_attendance
    @participant.toggle!(:attended)

    update_add_user_form_component_via_turbo_stream
    update_list_component_via_turbo_stream
    update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)

    respond_with_turbo_streams
  end

  def destroy
    if @participant.destroy!
      update_add_user_form_component_via_turbo_stream
      update_list_component_via_turbo_stream
      update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)

      respond_with_turbo_streams
    end
  end

  def manage_participants_dialog
    respond_with_dialog Meetings::Participants::ManageParticipantsDialog.new(meeting: @meeting)
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:meeting_id])
  end

  def set_participant
    @participant = MeetingParticipant.find(params[:id])
  end

  def send_notification(user)
    if Journal::NotificationConfiguration.active? && !@meeting.templated? && @meeting.notify?
      MeetingMailer.invited(@meeting, user, User.current).deliver_later
    end
  end

  def create_new_participant(user_id)
    participant = MeetingParticipant.create(
      meeting: @meeting,
      user_id:,
      invited: true,
      attended: false
    )

    if participant.persisted?
      send_notification(User.find(user_id))

      update_add_user_form_component_via_turbo_stream
      update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)
    else
      participant.errors.full_messages.each do |msg|
        @meeting.errors.add(:base, msg)
      end
    end
  end
end
