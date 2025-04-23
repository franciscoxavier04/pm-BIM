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
#
require "spec_helper"

RSpec.describe Projects::CopyOptionsForm, type: :forms do
  include_context "with rendered form"

  let(:model) { Projects::CopyOptions.new }

  shared_examples "rendering dependency checkbox" do |locator|
    it "renders checked checkbox for '#{locator}'" do
      expect(page).to have_checked_field locator, fieldset: "Copy options"
    end
  end

  describe "dependencies" do
    include_examples "rendering dependency checkbox", "Project members"
    include_examples "rendering dependency checkbox", "Versions"
    include_examples "rendering dependency checkbox", "Work packages: categories"
    include_examples "rendering dependency checkbox", "Work packages"
    include_examples "rendering dependency checkbox", "Work packages: attachments"
    include_examples "rendering dependency checkbox", "Work packages: shares"
    include_examples "rendering dependency checkbox", "Wiki pages"
    include_examples "rendering dependency checkbox", "Wiki pages: attachments"
    include_examples "rendering dependency checkbox", "Forums"
    include_examples "rendering dependency checkbox", "Work packages: saved views"
    include_examples "rendering dependency checkbox", "Boards"
    include_examples "rendering dependency checkbox", "Project overview"
    include_examples "rendering dependency checkbox", "File storages"
    include_examples "rendering dependency checkbox", "File storages: Project folders"
    include_examples "rendering dependency checkbox", "Work packages: file links"
  end

  describe "notifications" do
    it "renders unchecked checkbox for email notifications" do
      expect(page).to have_unchecked_field "Send email notifications during the project copy"
    end
  end
end
