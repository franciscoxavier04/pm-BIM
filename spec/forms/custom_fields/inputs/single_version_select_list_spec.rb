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

RSpec.describe CustomFields::Inputs::SingleVersionSelectList, type: :forms do
  include_context "with rendered custom field input form"

  let(:custom_field) { create(:version_project_custom_field, name: "Version field") }
  let(:value) { create(:version, name: "Version 26", project: model) }

  it_behaves_like "rendering label with help text", "Version field"
  it_behaves_like "rendering autocompleter", "Version field" do
    it "sets correct autocompleter inputs" do
      expect(autocompleter["data-items"]).to have_json_size(1)
      expect(autocompleter["data-model"]).to be_json_eql(%{{"name":"Version 26"}}).excluding("group_by")
    end
  end
end
