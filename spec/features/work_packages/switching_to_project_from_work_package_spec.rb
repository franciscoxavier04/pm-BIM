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

RSpec.describe "Switching to project from work package", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as(user)
    work_package
  end

  it "allows to switch to the project the work package belongs to" do
    wp_table.visit!
    wp_table.expect_work_package_listed work_package

    # Open WP in global selection
    wp_table.open_full_screen_by_link work_package

    # Follow link to project
    expect(page).to have_css(".attributes-group.-project-context")
    link = find(".attributes-group.-project-context .project-context--switch-link")
    expect(link[:href]).to include(project_path(project.id))

    link.click
    # Redirection causes a trailing / on the path
    expect(page).to have_current_path("#{project_path(project.id)}/")
  end
end
