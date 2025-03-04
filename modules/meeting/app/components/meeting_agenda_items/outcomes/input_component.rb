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

module MeetingAgendaItems::Outcomes
  class InputComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, meeting_agenda_item:, meeting_outcome: nil)
      super
      @meeting = meeting
      @meeting_agenda_item = meeting_agenda_item
      @meeting_outcome = meeting_outcome || build_meeting_outcome
    end

    private

    def wrapper_uniq_by
      @meeting_agenda_item.id
    end

    def build_meeting_outcome
      MeetingOutcome.new(
        meeting_agenda_item: @meeting_agenda_item,
        kind: 0
      )
    end

    def method
      if @meeting_outcome.id.present?
        :put
      else
        :post
      end
    end

    def submit_path
      if @meeting_outcome.id.present?
        meeting_outcome_path(@meeting, @meeting_outcome.id, format: :turbo_stream)
      else
        meeting_outcomes_path(@meeting, meeting_agenda_item_id: @meeting_agenda_item.id, format: :turbo_stream)
      end
    end

    def cancel_path
      if @meeting_outcome.id.present?
        cancel_edit_meeting_outcome_path(@meeting, @meeting_outcome)
      else
        cancel_new_meeting_outcomes_path(@meeting, meeting_agenda_item_id: @meeting_agenda_item.id)
      end
    end
  end
end
