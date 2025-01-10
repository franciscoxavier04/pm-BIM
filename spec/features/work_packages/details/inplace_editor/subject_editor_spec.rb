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
require "features/page_objects/notification"
require "features/work_packages/details/inplace_editor/shared_examples"
require "features/work_packages/shared_contexts"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"

RSpec.describe "subject inplace editor", :js, :selenium do
  let(:project) { create(:project_with_types, public: true) }
  let(:property_name) { :subject }
  let(:property_title) { "Subject" }
  let(:work_package) { create(:work_package, project:) }
  let(:user) { create(:admin) }
  let(:work_packages_page) { Pages::SplitWorkPackage.new(work_package, project) }
  let(:field) { work_packages_page.edit_field(property_name) }
  let(:notification) { PageObjects::Notifications.new(page) }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  context "as a read state" do
    it "has correct content" do
      field.expect_state_text(work_package.send(property_name))
    end
  end

  it_behaves_like "as an auth aware field"
  it_behaves_like "a cancellable field"
  it_behaves_like "as a single validation point"
  it_behaves_like "as a required field"

  context "as an edit state" do
    before do
      field.activate_edition
    end

    it "renders a text input" do
      expect(field.input_element).to be_visible
      expect(field.input_element["type"]).to eq "text"
    end

    it "has a correct value for the input" do
      expect(field.input_element[:value]).to eq work_package.subject
    end

    it "displays an error when too long" do
      too_long = "*" * 256
      field.set_value too_long
      field.submit_by_enter

      field.expect_error
      field.expect_active!
      expect(field.input_element.value).to eq(too_long)

      notification.expect_error("Subject is too long (maximum is 255 characters)")
    end

    context "when save" do
      before do
        field.input_element.set "Aloha"
      end

      # safeguard
      include_context "ensure wp details pane update done" do
        let(:update_user) { user }
      end

      it "saves the value on ENTER" do
        field.submit_by_enter
        field.expect_state_text("Aloha")
      end
    end
  end

  context "with conflicting modification" do
    it "shows a conflict when modified elsewhere", with_flag: { primerized_work_package_activities: true } do
      work_package.subject = "Some other subject!"
      work_package.save!

      field.display_element.click

      # try to avoid flakyness with the waiting approach
      wait_for { page }.to have_content(I18n.t("notice_locking_conflict_danger"))

      work_packages_page.expect_conflict_error_banner
    end

    it "shows a conflict when modified elsewhere", with_flag: { primerized_work_package_activities: false } do
      work_package.subject = "Some other subject!"
      work_package.save!

      field.display_element.click

      notification.expect_error(I18n.t("api_v3.errors.code_409"))
    end
  end
end
