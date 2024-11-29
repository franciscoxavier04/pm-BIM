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
  class UpdateService < ::BaseServices::Update
    include WithTemplate

    protected

    def after_perform(call)
      return call unless call.success?

      cleanup_cancelled_schedules(call.result)
      update_template(call)
    end

    def update_template(call)
      recurring_meeting = call.result
      template = recurring_meeting.template

      unless template.update(@template_params)
        call.merge! ServiceResult.failure(result: template, errors: template.errors)
      end

      call
    end

    def cleanup_cancelled_schedules(recurring_meeting)
      ScheduledMeeting
        .where(recurring_meeting:)
        .cancelled
        .find_each do |scheduled|
        occurring = recurring_meeting.schedule.occurs_at?(scheduled.start_time)
        scheduled.delete unless occurring
      end
    end
  end
end
