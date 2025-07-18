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

RSpec.describe "Link custom fields edit", :js do
  shared_let(:admin) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::IndexPage.new }

  current_user { admin }

  before do
    cf_page.visit!
  end

  it "can create and edit link custom fields" do
    # Create CF
    cf_page.click_to_create_new_custom_field("Link (URL)")

    fill_in "custom_field_name", with: "My Link CF"

    expect(page).to have_no_field("custom_field_custom_options_attributes_0_value")

    click_on "Save"

    cf_page.expect_and_dismiss_flash(message: "Successful creation.")

    # Expect field to be created
    cf = CustomField.last
    expect(cf.name).to eq("My Link CF")
    expect(cf.field_format).to eq "link"

    # Edit again
    find("a", text: "My Link CF").click

    expect(page).to have_no_field("custom_field_custom_options_attributes_0_value")
    fill_in "custom_field_name", with: "My Link CF (edited)"

    click_on "Save"

    cf_page.expect_and_dismiss_flash(message: "Successful update.")

    # Expect field to be saved
    cf = CustomField.last
    expect(cf.name).to eq("My Link CF (edited)")
  end
end
