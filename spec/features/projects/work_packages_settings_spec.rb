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

RSpec.describe "Projects", "work packages settings menu", :js do
  let!(:project) { create(:project) }
  let(:work_packages_settings_page) { Pages::Projects::Settings::WorkPackages.new(project) }

  describe "view settings page" do
    context "when the user has access to types tab" do
      let(:permissions) { %i(edit_project view_work_packages manage_types) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "displays the types tab" do
        work_packages_settings_page.visit!
        expect(page).to have_css(".tabnav-tab", text: I18n.t("settings.work_packages.types_tab"))
        expect(page).to have_css("#types-form")
      end
    end

    context "when the user has access to the categories tab" do
      let(:permissions) { %i(edit_project view_work_packages manage_categories) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "displays the categories tab" do
        work_packages_settings_page.visit!
        expect(page).to have_css(".tabnav-tab", text: I18n.t("settings.work_packages.categories_tab"))
        expect(page).to have_css("span", text: I18n.t("projects.settings.categories.no_results_title_text"))
      end
    end

    context "when the user has access to the custom fields tab" do
      let(:permissions) { %i(edit_project view_work_packages select_custom_fields) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "displays the custom fields tab" do
        work_packages_settings_page.visit!
        expect(page).to have_css(".tabnav-tab", text: I18n.t("settings.work_packages.custom_fields_tab"))
        expect(page).to have_css("span", text: I18n.t("projects.settings.custom_fields.no_results_title_text"))
      end
    end

    context "when the user does not have access to any tabs" do
      let(:permissions) { %i(edit_project view_work_packages) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "does not display any tabs" do
        work_packages_settings_page.visit!
        expect(page).to have_no_css(".tabnav-tab")
        expect(page).to have_css("span", text: I18n.t("settings.work_packages.not_allowed_text"))
      end
    end
  end
end
