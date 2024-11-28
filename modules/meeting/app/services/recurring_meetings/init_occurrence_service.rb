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

module RecurringMeetings
  class InitOccurrenceService < ::BaseServices::BaseCallable
    include ::Shared::ServiceContext

    attr_reader :user, :recurring_meeting

    def initialize(user:, recurring_meeting:)
      super()
      @user = user
      @recurring_meeting = recurring_meeting
    end

    protected

    def perform(date:)
      in_context(recurring_meeting, send_notifications: false) do
        call = instantiate(date)
        create_schedule(call) if call.success?

        call
      end
    end

    def instantiate(date)
      ::Meetings::CopyService
        .new(user:, model: recurring_meeting.template)
        .call(attributes: instantiate_params(date),
              copy_agenda: true,
              copy_attachments: true,
              send_notifications: false)
    end

    def instantiate_params(start_date)
      {
        start_date:,
        recurring_meeting:
      }
    end

    def create_schedule(call)
      meeting = call.result

      schedule = ScheduledMeeting.new(
        meeting: meeting,
        recurring_meeting: recurring_meeting,
        date: meeting.parsed_start_date
      )

      unless schedule.save
        call.merge!(ServiceResult.failure(errors: schedule.errors))
      end
    end
  end
end
