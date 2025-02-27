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

module Meetings
  class SidePanel::StateComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super

      @meeting = meeting
      @project = meeting.project
    end

    private

    def edit_enabled?
      User.current.allowed_in_project?(:close_meeting_agendas, @project)
    end

    def status_button
      current_status = case @meeting.state
                       when "open"
                         open_status
                       when "in_progress"
                         in_progress_status
                       when "closed"
                         closed_status
                       end

      OpPrimer::StatusButtonComponent.new(current_status: current_status,
                                          items: [open_status, in_progress_status, closed_status],
                                          readonly: !edit_enabled?,
                                          disabled: !edit_enabled?,
                                          button_arguments: { title: "Status", size: :medium })
    end

    def open_status
      OpPrimer::StatusButtonOption.new(name: t("label_meeting_state_open"),
                                       color: Color.new(hexcode: "#1F883D"),
                                       icon: :"issue-opened",
                                       tag: :a,
                                       href: change_state_project_meeting_path(@project, @meeting, state: "open"),
                                       content_arguments: {
                                         data: { "turbo-stream": true, "turbo-method": "put" }
                                       })
    end

    def in_progress_status
      OpPrimer::StatusButtonOption.new(name: t("label_meeting_state_in_progress"),
                                       color: Color.new(hexcode: "#9A6700"),
                                       icon: :play,
                                       tag: :a,
                                       href: change_state_project_meeting_path(@project, @meeting, state: "in_progress"),
                                       content_arguments: {
                                         data: { "turbo-stream": true, "turbo-method": "put" }
                                       })
    end

    def closed_status
      OpPrimer::StatusButtonOption.new(name: t("label_meeting_state_closed"),
                                       color: Color.new(hexcode: "#8250DF"),
                                       icon: :"codescan-checkmark",
                                       tag: :a,
                                       href: change_state_project_meeting_path(@project, @meeting, state: "closed"),
                                       content_arguments: {
                                         data: { "turbo-stream": true, "turbo-method": "put" }
                                       })
    end
  end
end
