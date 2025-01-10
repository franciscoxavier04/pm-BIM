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

RSpec.describe "Work package single context menu", :js do
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }

  let(:wp_view) { Pages::FullWorkPackage.new(work_package, work_package.project) }

  before do
    login_as(user)
    wp_view.visit!
    find("#action-show-more-dropdown-menu .button").click
  end

  it "sets the correct copy project link" do
    find(".menu-item", text: "Duplicate in another project", exact_text: true).click
    expect(page).to have_css("h2", text: I18n.t(:button_copy))
    expect(page).to have_css("a.work_package", text: "##{work_package.id}")
    expect(page).to have_current_path /work_packages\/move\/new\?copy=true&ids\[\]=#{work_package.id}/
  end

  it "successfully copies the short url of the work package" do
    find(".menu-item", text: "Copy link to clipboard", exact_text: true).click

    # We cannot access the navigator.clipboard from a headless browser.
    # This test makes sure the copy to clipboard logic is working,
    # regardless of the browser permissions.
    expect(page).to have_content("/wp/#{work_package.id}")
  end
end
