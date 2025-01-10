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

RSpec.describe "Milestones full screen v iew", :js do
  let(:type) { create(:type, is_milestone: true) }
  let(:project) { create(:project, types: [type]) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           subject: "Foobar")
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:button) { find(".add-work-package", wait: 5) }

  before do
    login_as(user)
    wp_page.visit!
  end

  context "user has :add_work_packages permission" do
    let(:user) do
      create(:user, member_with_roles: { project => role })
    end
    let(:role) { create(:project_role, permissions:) }
    let(:permissions) do
      %i[view_work_packages add_work_packages]
    end

    it "shows the button as enabled" do
      expect(button).not_to be_disabled

      button.click
      expect(page).to have_css(".menu-item", text: type.name.upcase)
    end
  end

  context "user has :view_work_packages permission only" do
    let(:user) do
      create(:user, member_with_roles: { project => role })
    end
    let(:role) { create(:project_role, permissions:) }
    let(:permissions) do
      %i[view_work_packages]
    end

    it "shows the button as correctly disabled" do
      expect(button["disabled"]).to be_truthy
    end
  end
end
