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
require_relative "shared_avatar_examples"

RSpec.describe "User avatar management", :js do
  include Rails.application.routes.url_helpers

  let(:user) { create(:admin) }
  let(:avatar_management_path) { edit_user_path(target_user, tab: "avatar") }

  before do
    login_as user
  end

  context "when user is admin" do
    let(:target_user) { create(:user) }

    it_behaves_like "avatar management"
  end

  context "when user is self" do
    let(:user) { create(:user) }
    let(:target_user) { user }

    it "forbids the user to access" do
      visit avatar_management_path
      expect(page).to have_text("[Error 403]")
    end
  end

  context "when user is another user" do
    let(:target_user) { create(:user) }
    let(:user) { create(:user) }

    it "forbids the user to access" do
      visit avatar_management_path
      expect(page).to have_text("[Error 403]")
    end
  end

  describe "none enabled" do
    let(:target_user) { create(:user) }

    before do
      allow(Setting)
        .to receive(:plugin_openproject_avatars)
        .and_return({})
    end

    it "does not render the user edit tab" do
      visit edit_user_path(user)
      expect(page).to have_no_css "#tab-avatar"
    end
  end
end
