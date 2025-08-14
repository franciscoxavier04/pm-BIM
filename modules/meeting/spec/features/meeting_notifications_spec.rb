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
require_relative "../support/pages/meetings/index"
require_relative "../support/pages/recurring_meeting/show"

RSpec.describe "Meeting notifications", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas] })
  end

  before do
    login_as(user)
  end

  shared_examples "notification checkbox behaviour" do
    it "shows checkbox checked initially" do
      within "#meeting-form" do
        expect(page).to have_field(I18n.t("label_meeting_send_updates"), type: "checkbox", checked: true)
      end
    end

    it "toggles banner on checkbox change" do
      within "#meeting-form" do
        # toggle between checkbox states
        checkbox = find_field(I18n.t("label_meeting_send_updates"))
        expect(page).to have_css(".Banner", text: enabled_text.strip)

        checkbox.click
        expect(page).to have_css(".Banner", text: disabled_text.strip)

        checkbox.click
        expect(page).to have_css(".Banner", text: enabled_text.strip)
      end
    end
  end

  context "for a one-time meeting" do
    let(:current_user) { user }
    let(:meeting) { Meeting.last }
    let(:show_page) { Pages::Meetings::Show.new(meeting) }
    let(:meetings_page) { Pages::Meetings::Index.new(project:) }

    let(:enabled_text) { I18n.t("meeting.notifications.banner.onetime.enabled") }
    let(:disabled_text) { I18n.t("meeting.notifications.banner.onetime.disabled") }

    before do
      meetings_page.visit!
      meetings_page.click_on "add-meeting-button"
      meetings_page.click_on "One-time"
    end

    include_examples "notification checkbox behaviour"

    it "sets and toggle the calendar updates state" do
      meetings_page.set_title "Some title"
      meetings_page.click_create

      # check if notify is set correct
      expect(meeting.notify).to be true

      # do not send initial mail
      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 0

      show_page.visit!

      # check calendar updates sidepanel component
      page.within("[data-test-selector='email-updates-mode-selector']") do
        expect(page).to have_text("Email calendar updates")
        expect(page).to have_text("Enabled.")
        expect(page).to have_text("All participants will receive updated calendar invites via email informing them of changes.")
        expect(page).to have_selector(:link_or_button, "Disable")
      end

      # edit meeting and check that mail is sent
      page.find("[data-test-selector='edit-meeting-details-button']").click
      retry_block do
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        expect(page).to have_test_selector("notifications-banner")
        show_page.set_start_time "12:00"
        click_on "Save"
      end

      wait_for_network_idle

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 1
      ActionMailer::Base.deliveries.clear

      # disable updates from the sidepanel
      page.within("[data-test-selector='email-updates-mode-selector']") do
        click_on "Disable"
      end

      show_page.expect_modal "Disable email calendar updates?"
      show_page.within_modal "Disable email calendar updates?" do
        click_on "Disable email updates"
      end

      wait_for_network_idle

      # check that updates are now disabled
      expect(meeting.reload.notify).to be false

      page.within("[data-test-selector='email-updates-mode-selector']") do
        expect(page).to have_text("Email calendar updates")
        expect(page).to have_text("Disabled.")
        expect(page).to have_text("Participants will not receive an email informing them of changes.")
        expect(page).to have_selector(:link_or_button, "Enable")
      end

      page.find("[data-test-selector='edit-meeting-details-button']").click
      retry_block do
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        expect(page).to have_test_selector("notifications-banner")
        show_page.set_start_time "12:00"
        click_on "Save"
      end

      wait_for_network_idle

      # enable updates and check that an email is sent out immediately
      page.within("[data-test-selector='email-updates-mode-selector']") do
        click_on "Enable"
      end

      show_page.expect_modal "Enable email calendar updates?"
      show_page.within_modal "Enable email calendar updates?" do
        click_on "Enable email updates"
      end

      wait_for_network_idle

      expect_flash(message: "Email calendar update sent to all participants")

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 1
      ActionMailer::Base.deliveries.clear

      # check that no mails are sent on edit/delete when disabled
      page.within("[data-test-selector='email-updates-mode-selector']") do
        click_on "Disable"
      end

      show_page.expect_modal "Disable email calendar updates?"
      show_page.within_modal "Disable email calendar updates?" do
        click_on "Disable email updates"
      end

      wait_for_network_idle

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 0

      show_page.trigger_dropdown_menu_item "Delete meeting"
      show_page.expect_modal "Delete meeting"

      show_page.within_modal "Delete meeting" do
        click_on "Delete"
      end

      wait_for_network_idle

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 0
    end
  end

  context "when creating a recurring meeting" do
    let(:current_user) { user }
    let(:meetings_page) { Pages::Meetings::Index.new(project:) }

    let(:enabled_text) { I18n.t("meeting.notifications.banner.template.enabled") }
    let(:disabled_text) { I18n.t("meeting.notifications.banner.template.disabled") }

    before do
      meetings_page.visit!
      meetings_page.click_on "add-meeting-button"
      page.within(".Overlay") do
        meetings_page.click_on "Recurring"
      end
    end

    include_examples "notification checkbox behaviour"
  end

  context "for a recurring meeting" do
    let(:current_user) { user }
    let(:meeting) do
      create :recurring_meeting,
             :skip_validations,
             project:,
             start_time: 1.day.from_now.to_date,
             duration: 1.5,
             frequency: "weekly",
             end_after: "specific_date",
             end_date: 1.year.from_now.to_date,
             author: current_user
    end
    let(:show_page) { Pages::RecurringMeeting::Show.new(meeting) }
    let(:template_page) { Pages::Meetings::Show.new(meeting.template) }
    let(:occurrence_page) { Pages::Meetings::Show.new(meeting.meetings.where(template: false).first) }

    it "can set and toggle the calendar updates state for the template and occurrences" do
      template_page.visit!

      expect(meeting.template.notify).to be true
      page.within("#meetings-header-component") do
        click_on "Open first meeting"
      end

      wait_for_network_idle

      # check if mail is sent on opening first meeting
      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 1
      ActionMailer::Base.deliveries.clear

      template_page.visit!

      # check sidepanel component
      page.within("[data-test-selector='email-updates-mode-selector']") do
        expect(page).to have_text("Email calendar updates")
        expect(page).to have_text("Enabled.")
        expect(page).to have_text("All participants will receive updated calendar invites via email informing them of changes.")
        expect(page).to have_selector(:link_or_button, "Disable")
      end

      # edit series and check that mail is sent
      page.find("[data-test-selector='edit-meeting-details-button']").click
      retry_block do
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        expect(page).to have_test_selector("notifications-banner")
        expect(page).to have_text(I18n.t("meeting.notifications.banner.template.enabled"))
        template_page.set_start_time "12:00"
        wait_for_network_idle
        click_on "Save"
      end

      wait_for_network_idle

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 1
      ActionMailer::Base.deliveries.clear

      # switch to occurrence and check sidepanel component
      occurrence_page.visit!

      page.within("[data-test-selector='email-updates-mode-selector']") do
        expect(page).to have_text("Email calendar updates")
        expect(page).to have_text("Enabled.")
        expect(page).to have_text("All participants will receive updated calendar invites via email informing them of changes.")
        expect(page).to have_no_selector(:link_or_button, "Disable")
        expect(page).to have_text("To change this, edit the series template.")
      end

      # edit occurrence and check that mail is sent
      page.find("[data-test-selector='edit-meeting-details-button']").click
      retry_block do
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        expect(page).to have_test_selector("notifications-banner")
        expect(page).to have_text(I18n.t("meeting.notifications.banner.occurrence.enabled"))
        occurrence_page.set_start_time "13:00"
        wait_for_network_idle
        click_on "Save"
      end

      wait_for_network_idle

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 1
      ActionMailer::Base.deliveries.clear

      # turn off updates from the template
      template_page.visit!

      page.within("[data-test-selector='email-updates-mode-selector']") do
        click_on "Disable"
      end

      template_page.expect_modal "Disable email calendar updates?"
      template_page.within_modal "Disable email calendar updates?" do
        click_on "Disable email updates"
      end

      wait_for_network_idle

      expect(meeting.template.reload.notify).to be false

      # check that this is reflected for occurrences too
      occurrence_page.visit!

      page.within("[data-test-selector='email-updates-mode-selector']") do
        expect(page).to have_text("Email calendar updates")
        expect(page).to have_text("Disabled.")
        expect(page).to have_text("Participants will not receive an email informing them of changes.")
        expect(page).to have_no_selector(:link_or_button, "Enable")
        expect(page).to have_text("To change this, edit the series template.")
      end

      # check that no mails are sent on deleting the series
      show_page.visit!

      show_page.delete_meeting_series
      retry_block do
        show_page.within_modal "Delete meeting series" do
          check "I understand that this deletion cannot be reversed", allow_label_click: true
          click_on "Delete permanently"
        end
      end

      wait_for_network_idle
      expect_flash(type: :success, message: "Successful deletion.")

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 0
    end
  end

  context "when a meeting is closed" do
    let(:current_user) { user }
    let(:meeting) { create(:meeting, project:, author: current_user, notify: true, state: :closed) }
    let(:show_page) { Pages::Meetings::Show.new(meeting) }

    it "does not show the sidebar component" do
      show_page.visit!

      expect(page).to have_no_css("[data-test-selector='email-updates-mode-selector']")
    end
  end

  context "for a user with no edit permissions" do
    let(:no_permissions_user) do
      create(:user,
             lastname: "Second",
             member_with_permissions: { project => %i[view_meetings manage_agendas] })
    end
    let(:current_user) { no_permissions_user }
    let(:meeting) { create(:meeting, project:, author: current_user, notify: true) }
    let(:show_page) { Pages::Meetings::Show.new(meeting) }

    before do
      login_as no_permissions_user
    end

    it "does not show the sidebar component" do
      show_page.visit!

      expect(page).to have_no_css("[data-test-selector='email-updates-mode-selector']")
    end
  end
end
