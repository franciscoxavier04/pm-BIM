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

require "spec_helper"

RSpec.describe Queries::Meetings::Filters::AttendedUserFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list_optional }
    let(:class_key) { :attended_user_id }
    let(:human_name) { I18n.t(:label_attended_user) }

    describe "#available?" do
      it "is true" do
        expect(instance).to be_available
      end
    end

    describe "#allowed_values" do
      it "is nil" do
        expect(instance.allowed_values).to be_nil
      end
    end
  end

  describe "#where clause" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:project) { create(:project) }
    let(:meeting1) { create(:meeting, project:) }
    let(:meeting2) { create(:meeting, project:) }
    let(:meeting3) { create(:meeting, project:) }
    let(:meeting4) { create(:meeting, project:) }
    let!(:empty_meeting) do
      create(:meeting, project:).tap { |meeting| meeting.participants.delete_all }
    end

    let!(:participant1) { create(:meeting_participant, :attendee, meeting: meeting1, user: user1) }
    let!(:participant2) { create(:meeting_participant, :attendee, meeting: meeting2, user: user2) }
    let!(:participant3) { create(:meeting_participant, :invitee, meeting: meeting3, user: user1) }
    let!(:participant4) { create(:meeting_participant, :invitee, meeting: meeting4, user: user2) }

    let(:instance) do
      described_class.create!(name: :attended_user_id, operator:, values:)
    end

    context 'for "="' do
      let(:operator) { "=" }
      let(:values) { [user1.id.to_s] }

      it "finds meetings where the user attended" do
        expect(instance.where).to include("#{MeetingParticipant.table_name}.user_id")

        meetings = Meeting.left_outer_joins(:participants).where(instance.where)

        expect(meetings).to include(meeting1)
        expect(meetings).not_to include(meeting2)
        expect(meetings).not_to include(meeting3)
        expect(meetings).not_to include(meeting4)
      end
    end

    context 'for "!"' do
      let(:operator) { "!" }
      let(:values) { [user1.id.to_s] }

      it "finds meetings where the user did not attend" do
        expect(instance.where).to include("NOT")

        meetings = Meeting.left_outer_joins(:participants).where(instance.where)
        expect(meetings.pluck(:id)).to contain_exactly(meeting2.id, empty_meeting.id, meeting3.id, meeting4.id)
      end
    end

    context 'for "*"' do
      let(:operator) { "*" }
      let(:values) { [] }

      it "finds meetings with any attendee" do
        meetings = Meeting.left_outer_joins(:participants).where(instance.where)

        expect(meetings).to include(meeting1)
        expect(meetings).to include(meeting2)
        expect(meetings).not_to include(meeting3)
        expect(meetings).not_to include(meeting4)
      end
    end

    context 'for "!*"' do
      let(:operator) { "!*" }
      let(:values) { [] }

      it "finds meetings with no attendees" do
        meetings = Meeting.left_outer_joins(:participants).where(instance.where)

        expect(meetings).not_to include(meeting1)
        expect(meetings).not_to include(meeting2)
        expect(meetings).to include(meeting3)
        expect(meetings).to include(meeting4)
      end
    end
  end
end
