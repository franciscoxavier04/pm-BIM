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

require_relative "../support/pages/meetings/show"

RSpec.describe "Meeting Backlogs", :js, with_flag: { meeting_backlogs: true } do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create :user,
           lastname: "First",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings manage_agendas close_meeting_agendas create_meeting_minutes] }
  end
  shared_let(:meeting) do
    create :meeting,
           project:,
           start_time: "2024-12-31T13:30:00Z",
           duration: 1.5,
           author: user
  end
  shared_let(:backlog) do
    create :meeting_section,
           backlog: true
  end

  let(:current_user) { user }
  let(:state) { :open }
  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  before do
    login_as current_user
  end

  describe "backlog visibility" do
    context "when the meeting is 'open'" do
      it "is expanded" do
        show_page.visit!
        show_page.expect_backlog collapsed: false
      end
    end

    context "when the meeting is 'in progress'" do
      before do
        meeting.update(state: :in_progress)
      end

      it "is collapsed" do
        show_page.visit!
        show_page.expect_backlog collapsed: true
      end
    end

    context "when the meeting is 'closed'" do
      before do
        meeting.update(state: :closed)
      end

      it "is not visible" do
        show_page.visit!
        show_page.expect_no_backlog
      end
    end

    context "when meeting state is changed" do
      it "collapses and expands the backlog" do
        show_page.visit!
        show_page.expect_backlog collapsed: false
        show_page.start_meeting
        show_page.expect_backlog collapsed: true
        show_page.close_meeting_from_in_progress
        show_page.reopen_meeting
        show_page.expect_backlog collapsed: false
      end
    end
  end

  describe "backlog actions" do
    let!(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }
    let!(:work_package) { create(:work_package, project:) }
    let!(:wp_agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:) }

    before do
      meeting.update(state: :in_progress)
    end

    it "work correctly and keep collapsed state" do
      show_page.visit!

      # check initial state
      show_page.expect_backlog collapsed: true
      show_page.expect_backlog_count(0)

      # add first item and autoexpand backlog
      show_page.add_agenda_item_to_backlog do
        fill_in "Title", with: "Backlog agenda item"
      end
      show_page.expect_backlog_count(1)
      show_page.expect_backlog collapsed: false
      show_page.within_backlog do
        show_page.expect_agenda_item(title: "Backlog agenda item")
      end

      # add more items
      show_page.add_agenda_item_to_backlog do
        fill_in "Title", with: "Second backlog agenda item"
      end
      show_page.expect_backlog_count(2)
      show_page.expect_backlog collapsed: false
      show_page.within_backlog do
        show_page.expect_agenda_item(title: "Second backlog agenda item")
      end

      # check for correct agenda item actions outside of backlog
      agenda_item = MeetingAgendaItem.find(meeting_agenda_item.id)
      show_page.expect_non_backlog_actions(agenda_item)

      # move item to backlog
      wp_item = MeetingAgendaItem.find(wp_agenda_item.id)
      show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_backlog))

      show_page.expect_backlog_count(3)
      show_page.expect_backlog collapsed: false

      # check for correct agenda item actions within backlog
      item = MeetingAgendaItem.find_by(title: "Backlog agenda item")
      show_page.expect_backlog_actions(item)

      # reorder items within backlog
      show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_top))
      show_page.expect_backlog collapsed: false

      # move item to current meeting
      show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_current_meeting))
      show_page.expect_backlog_count(2)
      show_page.expect_backlog collapsed: false

      # edit item
      show_page.edit_agenda_item(item) do
        fill_in "Title", with: "Updated title"
        click_on "Save"
      end
      show_page.expect_backlog collapsed: false

      # delete item
      show_page.remove_agenda_item(item)
      show_page.expect_backlog_count(1)
      show_page.expect_backlog collapsed: false

      # empty backlog
      last_item = MeetingAgendaItem.find_by(title: "Second backlog agenda item")
      show_page.remove_agenda_item(last_item)
      show_page.expect_backlog_count(0)
      show_page.expect_backlog collapsed: false
      show_page.expect_empty_backlog

      # clear and autocollapse backlog
      show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_backlog))
      show_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_backlog))
      show_page.clear_backlog
      show_page.expect_backlog collapsed: true
    end
  end

  describe "blankslate" do
    before do
      meeting.update(state: :in_progress)
    end

    it "shows when the backlog is empty" do
      show_page.visit!
      show_page.expect_backlog collapsed: true
      show_page.expect_backlog_count(0)
      show_page.expect_blankslate
    end

    it "shows when the backlog has agenda items" do
      show_page.visit!
      show_page.add_agenda_item_to_backlog do
        fill_in "Title", with: "Backlog agenda item"
      end
      show_page.within_backlog do
        show_page.expect_agenda_item(title: "Backlog agenda item")
      end
      show_page.expect_blankslate
    end
  end

  describe "outcomes" do
    let!(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }
    let(:field) do
      TextEditorField.new(page, "Outcome", selector: test_selector("meeting-outcome-input"))
    end

    before do
      meeting.update(state: :in_progress)
    end

    it "cannot be added for items in backlogs" do
      show_page.visit!
      show_page.click_on_backlog
      item = MeetingAgendaItem.find(meeting_agenda_item.id)
      show_page.select_action(item, I18n.t(:label_agenda_item_move_to_backlog))
      retry_block do
        show_page.expect_no_outcome_action(item)
      end
    end

    it "show for items that had outcomes before being moved to the backlog" do
      show_page.visit!
      show_page.click_on_backlog
      item = MeetingAgendaItem.find(meeting_agenda_item.id)
      show_page.add_outcome(item) do
        field.expect_active!
        field.set_value "Backlog outcome"
        click_link_or_button "Save"
      end
      show_page.expect_outcome "Backlog outcome"
      show_page.select_action(item, I18n.t(:label_agenda_item_move_to_backlog))
      retry_block do
        show_page.expect_no_outcome_actions
        show_page.expect_no_outcome_button
        show_page.expect_no_outcome_action(item)
      end
    end
  end
end
