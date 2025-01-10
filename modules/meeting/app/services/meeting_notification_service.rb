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

class MeetingNotificationService
  attr_reader :meeting, :content_type

  def initialize(meeting)
    @meeting = meeting
  end

  def call(action, include_author: false, **)
    recipients_with_errors = send_notifications!(action, include_author:, **)
    ServiceResult.new(success: recipients_with_errors.empty?, errors: recipients_with_errors)
  end

  private

  def send_notifications!(action, include_author:, **)
    author_mail = meeting.author.mail

    recipients_with_errors = []
    meeting.participants.includes(:user).find_each do |recipient|
      next if recipient.mail == author_mail && !include_author

      MeetingMailer.send(action, meeting, recipient.user, User.current, **).deliver_later
    rescue StandardError => e
      Rails.logger.error do
        "Failed to deliver #{action} notification to #{recipient.mail}: #{e.message}"
      end
      recipients_with_errors << recipient
    end

    recipients_with_errors
  end
end
