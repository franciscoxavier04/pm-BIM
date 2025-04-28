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

RSpec.describe Projects::Settings::StatusForm, type: :forms do
  include_context "with rendered form"

  let(:model) { build_stubbed(:project, status_explanation: "example status info") }

  it "renders status field" do
    expect(page).to have_element "opce-autocompleter", "data-input-name": "\"project[status_code]\""
    expect(page).to have_element "opce-autocompleter", "data-qa-field-name": "status" do |elem|
      expect(elem["data-items"]).to have_json_size(7)
      expect(elem["data-items"]).to include_json(%{{"name":"Not set","classes":"project-status--name -not-set"}})
      expect(elem["data-items"]).to include_json(
        %{{"id":"on_track","name":"On track","classes":"project-status--name -on-track"}}
      ).including(:id)
    end
  end

  it "renders status description field" do
    expect(page).to have_field "Project status description", with: "example status info", visible: :hidden
    expect(page).to have_element "opce-ckeditor-augmented-textarea",
                                 "data-textarea-selector": "\"#project_status_explanation\""
    expect(page).to have_element "opce-ckeditor-augmented-textarea", "data-qa-field-name": "statusExplanation"
  end
end
