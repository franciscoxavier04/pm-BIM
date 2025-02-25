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
require "support/edit_fields/edit_field"

RSpec.describe "Automatic scheduling logic test cases (WP #61054)", :js, with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:user) { create(:admin) }

  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_milestone) { create(:type_milestone) }
  shared_let(:project) { create(:project, types: [type_bug, type_milestone]) }

  shared_let(:bug_wp) { create(:work_package, project:, type: type_bug) }
  shared_let(:milestone_wp) { create(:work_package, project:, type: type_milestone) }

  # assume sat+sun are non working days
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:date_attribute) { :combinedDate }
  let(:date_field) { work_packages_page.edit_field(date_attribute) }
  let(:datepicker) { date_field.datepicker }

  let(:current_user) { user }
  let(:work_package) { bug_wp }

  def apply_and_expect_saved(attributes)
    date_field.save!

    work_packages_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    work_package.reload

    attributes.each do |attr, value|
      expect(work_package.send(attr)).to eq value
    end
  end

  before do
    Setting.available_languages << current_user.language
    I18n.locale = current_user.language
    work_package.update_columns(current_attributes)
    login_as(current_user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
    date_field.activate!
    date_field.expect_active!
    # Wait for the datepicker to be initialized
    datepicker.expect_visible
  end

  describe "Scenario 25: Manual to automatic with no predecessors or children" do
    context "when there are no predecessors or children" do
      let(:current_attributes) do
        {
          start_date: Date.parse("2025-01-08"),
          due_date: Date.parse("2025-01-10"),
          duration: 3,
          schedule_manually: true
        }
      end

      it "cannot change scheduling mode to automatic" do
        datepicker.expect_manual_scheduling_mode

        datepicker.toggle_scheduling_mode
        datepicker.expect_automatic_scheduling_mode

        datepicker.expect_save_button_disabled
      end
    end
  end
end
