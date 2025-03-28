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

require_relative "../../../support/pages/structured_meeting/show"

RSpec.describe "Meeting Outcomes CRUD", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create :user,
           lastname: "First",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings manage_agendas close_meeting_agendas create_meeting_minutes] }
  end
  shared_let(:other_user) do
    create :user,
           lastname: "Second",
           member_with_permissions: { project => %i[view_meetings manage_agendas close_meeting_agendas] }
  end
  shared_let(:meeting) do
    create :structured_meeting,
           project:,
           start_time: "2024-12-31T13:30:00Z",
           duration: 1.5,
           author: user
  end

  shared_let(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:wp_agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:) }

  let(:current_user) { user }
  let(:state) { :in_progress }
  let(:show_page) { Pages::StructuredMeeting::Show.new(meeting) }
  let(:field) do
    TextEditorField.new(page, "Outcome", selector: test_selector("meeting-outcome-input"))
  end

  context "when a user has the necessary 'create_meeting_minutes' permission" do
    before do
      meeting.update(state: state)
      login_as current_user
    end

    context "when the meeting is 'in progress'" do
      it "can view outcomes and do all actions" do
        item = MeetingAgendaItem.find(meeting_agenda_item.id)

        show_page.visit!

        show_page.add_outcome_from_menu(item) do
          field.expect_active!
          field.set_value "Hakuna Matata"
          click_link_or_button "Save"
        end

        show_page.in_outcome_component(item) do
          show_page.expect_outcome "Hakuna Matata"

          show_page.select_outcome_action "Remove outcome"

          show_page.expect_no_outcome "Hakuna Matata"
          expect(page).to have_css(".op-meeting-outcome--button")
        end

        wp_item = MeetingAgendaItem.find(wp_agenda_item.id)

        show_page.add_outcome(wp_item) do
          field.expect_active!
          field.set_value "It means no worries"
          click_link_or_button "Save"
        end

        show_page.in_outcome_component(wp_item) do
          show_page.expect_outcome "It means no worries"

          show_page.select_outcome_action "Edit outcome"
          field.expect_active!
          field.set_value "Updated outcome"
          click_link_or_button "Save"

          show_page.expect_outcome "Updated outcome"
        end

        show_page.expect_no_outcome_action(wp_item)
      end
    end

    context "when the meeting is 'open'" do
      let!(:state) { :open }
      let(:outcome) { create(:meeting_outcome, meeting_agenda_item:, notes: "Existing outcome") }

      before do
        outcome
        show_page.visit!
      end

      it "can only view existing outcomes" do
        show_page.expect_outcome "Existing outcome"
        show_page.expect_no_outcome_actions
        show_page.expect_no_outcome_button

        item = MeetingAgendaItem.find(meeting_agenda_item.id)
        wp_item = MeetingAgendaItem.find(wp_agenda_item.id)

        show_page.expect_no_outcome_action(item)
        show_page.expect_no_outcome_action(wp_item)
      end
    end

    context "when the meeting is 'closed'" do
      let!(:state) { :closed }
      let(:outcome) { create(:meeting_outcome, meeting_agenda_item:, notes: "Existing outcome") }

      before do
        outcome
        show_page.visit!
      end

      it "can only view existing outcomes" do
        show_page.expect_outcome "Existing outcome"
        show_page.expect_no_outcome_actions
        show_page.expect_no_outcome_button
      end
    end
  end

  context "when a user doesn't have the necessary permission" do
    let(:outcome) { create(:meeting_outcome, meeting_agenda_item:, notes: "Existing outcome") }

    before do
      outcome
      meeting.update(state: state)
      login_as other_user
      show_page.visit!
    end

    it "can only view existing outcomes" do
      show_page.expect_outcome "Existing outcome"
      show_page.expect_no_outcome_actions
      show_page.expect_no_outcome_button
    end
  end
end
