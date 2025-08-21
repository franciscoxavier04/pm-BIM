# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Portfolios",
               "creation",
               :js do
  shared_let(:user_with_permissions) do
    create(:user,
           global_permissions: :add_portfolios)
  end
  # Role granted to creator on portfolio creation to be able to access the portfolio.
  shared_let(:default_project_role) { create(:project_role) }

  current_user { user_with_permissions }

  it "can create a portfolio", with_flag: { portfolio_models: true } do
    # TODO: trigger this from a button
    # e.g. on the project index page
    visit new_portfolio_path

    expect(page).to have_heading "New portfolio"

    fill_in "Name", with: "Foo bar"
    click_on "Create"

    expect_and_dismiss_flash type: :success, message: "Successful creation."

    expect(page).to have_current_path /\/projects\/foo-bar\/?/
    expect(page).to have_content "Foo bar"
  end

  it "cannot create the portfolio without the feature flag being active", with_flag: { portfolio_models: false } do
    visit new_portfolio_path

    expect(page).to have_content "[Error 403] You are not authorized to access this page."
  end
end
