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
require "support/pages/custom_fields/index_page"

RSpec.describe "custom fields", :js, :with_cuprite do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::IndexPage.new }

  before do
    login_as user
  end

  describe "available fields" do
    before do
      cf_page.visit!
      click_on "Create a new custom field"
    end

    it "shows all form elements" do
      expect(cf_page).to have_form_element("Name")
      expect(cf_page).to have_form_element("Required")
      expect(cf_page).to have_form_element("For all projects")
      expect(cf_page).to have_form_element("Used as a filter")
      expect(cf_page).to have_form_element("Searchable")
    end
  end

  describe "creating a new bool custom field" do
    before do
      cf_page.visit!
      click_on "Create a new custom field"
      wait_for_reload
    end

    it "creates a new bool custom field" do
      cf_page.set_name "New Field"
      cf_page.select_format "Date"
      click_on "Save"

      expect(page).to have_text("Successful creation")
      expect(page).to have_text("New Field")
    end
  end
end
