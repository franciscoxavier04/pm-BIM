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

require_relative "../spec_helper"

RSpec.describe "my time tracking", :js do
  let(:time_zone) { "Etc/UTC" }
  let(:user) do
    create(:user,
           preferences: { time_zone: },
           member_with_permissions: {
             project1 => %i[view_project view_time_entries log_own_time edit_own_time_entries],
             project2 => %i[view_project view_time_entries log_own_time]
           })
  end

  let(:project1) { create(:project_with_types) }
  let(:project2) { create(:project_with_types) }
  let(:work_package1) { create(:work_package, project: project1) }
  let(:work_package2) { create(:work_package, project: project2) }
  let!(:time_entry1) { create(:time_entry, user:, work_package: work_package1, spent_on: "2025-04-07", hours: 6.5) }
  let!(:time_entry2) do
    create(:time_entry, work_package: work_package1, user:, spent_on: "2025-04-09", hours: 1.0, start_time: (9 * 60) + 30,
                        time_zone:)
  end
  let!(:time_entry3) { create(:time_entry, user:, work_package: work_package1, spent_on: "2025-04-14", hours: 3.0) }
  let!(:time_entry4) { create(:time_entry, user:, work_package: work_package2, spent_on: "2025-04-09", hours: 2.0) }
  let!(:time_entry5) do
    create(:time_entry, user:, work_package: work_package2, spent_on: "2025-04-09", hours: 1.0, start_time: (13 * 60) + 30,
                        time_zone:)
  end
  let!(:time_entry6) { create(:time_entry, user:, work_package: work_package2, spent_on: "2025-04-14", hours: 2.0) }

  let(:allow_exact_time_tracking) { true }
  let(:force_exact_time_tracking) { false }

  let(:calendar_page) { Pages::MyTimeTracking::CalendarPage.new }
  let(:list_page) { Pages::MyTimeTracking::ListPage.new }

  before do
    allow(TimeEntry).to receive_messages(
      can_track_start_and_end_time?: allow_exact_time_tracking,
      must_track_start_and_end_time?: force_exact_time_tracking
    )

    login_as user
  end

  around do |example|
    travel_to "2025-04-09T12:00:00Z" do # rubocop:disable RSpecRails/TravelAround
      example.run
    end
  end

  context "when requesting list view" do
    context "for a defined work week", with_settings: { working_days: [1, 3, 4, 5] } do
      before do
        visit my_time_tracking_path(date: "2025-04-09", view_mode: "list", mode: "workweek")
      end

      it "shows all dates of the current work week" do
        list_page.expect_displays_day_section("2025-04-07", collapsed: true)
        list_page.expect_no_display_day_section("2025-04-08")
        list_page.expect_displays_day_section("2025-04-09", collapsed: false)
        list_page.expect_displays_day_section("2025-04-10", collapsed: false)
        list_page.expect_displays_day_section("2025-04-11", collapsed: false)
        list_page.expect_no_display_day_section("2025-04-12")
        list_page.expect_no_display_day_section("2025-04-13")
      end
    end

    context "for a full week" do
      before do
        visit my_time_tracking_path(date: "2025-04-09", view_mode: "list", mode: "week")
      end

      it "shows all dates of the current week" do
        list_page.expect_displays_day_section("2025-04-07", collapsed: true)
        list_page.expect_displays_day_section("2025-04-08", collapsed: true)
        list_page.expect_displays_day_section("2025-04-09", collapsed: false)
        list_page.expect_displays_day_section("2025-04-10", collapsed: false)
        list_page.expect_displays_day_section("2025-04-11", collapsed: false)
        list_page.expect_displays_day_section("2025-04-12", collapsed: false)
        list_page.expect_displays_day_section("2025-04-13", collapsed: false)
      end
    end
  end

  context "when requesting calendar view" do # rubocop:disable RSpec/EmptyExampleGroup
    before do
      visit my_time_tracking_path(date: "2025-04-09", view_mode: "calendar", mode: "workweek")
    end
  end
end
