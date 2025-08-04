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
require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples_for "project contract" do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*project_permissions, project:)
      mock.allow_globally(*global_permissions)
    end
  end

  let(:project_permissions) { [] }
  let(:global_permissions) { [] }
  let(:project_name) { "Project name" }
  let(:project_identifier) { "project_identifier" }
  let(:project_description) { "Project description" }
  let(:project_active) { true }
  let(:project_public) { true }
  let(:project_status_code) { "on_track" }
  let(:project_status_explanation) { "some explanation" }
  let(:project_parent) do
    build_stubbed(:project)
  end
  let(:parent_assignable) { true }
  let!(:assignable_parents) do
    assignable_parents_scope = double("assignable parents scope")
    assignable_parents = double("assignable parents")

    allow(Project)
      .to receive(:allowed_to)
      .and_call_original

    allow(Project)
      .to receive(:allowed_to)
      .with(current_user, :add_subprojects)
      .and_return assignable_parents_scope

    allow(assignable_parents_scope)
      .to receive(:where)
      .and_return(assignable_parents_scope)

    allow(assignable_parents_scope)
      .to receive(:not)
      .with(id: project.self_and_descendants)
      .and_return(assignable_parents)

    if project_parent
      allow(assignable_parents)
        .to receive(:where)
        .with(id: project_parent.id)
        .and_return(assignable_parents_scope)

      allow(assignable_parents_scope)
        .to receive(:exists?)
        .and_return(parent_assignable)
    end

    assignable_parents
  end

  it_behaves_like "contract is valid"

  context "if the name is nil" do
    let(:project_name) { nil }

    it_behaves_like "contract is invalid", name: %i(blank)
  end

  context "if the description is nil" do
    let(:project_description) { nil }

    it_behaves_like "contract is valid"
  end

  context "if the parent is nil" do
    let(:project_parent) { nil }

    it_behaves_like "contract is valid"
  end

  context "if the parent is not in the set of assignable_parents" do
    let(:parent_assignable) { false }

    it_behaves_like "contract is invalid", parent: %i(does_not_exist)
  end

  context "if active is nil" do
    let(:project_active) { nil }

    it_behaves_like "contract is invalid", active: %i(blank)
  end

  context "if status code is nil" do
    let(:project_status_code) { nil }

    it_behaves_like "contract is valid"
  end

  context "if status explanation is nil" do
    let(:project_status_explanation) { nil }

    it_behaves_like "contract is valid"
  end

  context "if status code is invalid" do
    before do
      # Hack in order to handle setting an Enum value without raising an
      # ArgumentError and letting the Contract perform the validation.
      #
      # This is the behavior that would be expected to be performed by
      # the SetAttributesService at that layer of the flow.
      bogus_project_status_code = "bogus"
      code_attributes = project.instance_variable_get(:@attributes)["status_code"]
      code_attributes.instance_variable_set(:@value_before_type_cast, bogus_project_status_code)
      code_attributes.instance_variable_set(:@value, bogus_project_status_code)
    end

    it_behaves_like "contract is invalid", status: %i(inclusion)
  end

  context "when the identifier consists of only letters" do
    let(:project_identifier) { "abc" }

    it_behaves_like "contract is valid"
  end

  context "when the identifier consists of letters followed by numbers" do
    let(:project_identifier) { "abc12" }

    it_behaves_like "contract is valid"
  end

  context "when the identifier consists of letters followed by numbers with a hyphen in between" do
    let(:project_identifier) { "abc-12" }

    it_behaves_like "contract is valid"
  end

  context "when the identifier consists of letters followed by numbers with an underscore in between" do
    let(:project_identifier) { "abc_12" }

    it_behaves_like "contract is valid"
  end

  context "when the identifier consists of numbers followed by letters with a hyphen in between" do
    let(:project_identifier) { "12-abc" }

    it_behaves_like "contract is valid"
  end

  context "when the identifier consists of numbers followed by letters with an underscore in between" do
    let(:project_identifier) { "12_abc" }

    it_behaves_like "contract is valid"
  end

  context "when the identifier consists of only numbers" do
    let(:project_identifier) { "12" }

    it_behaves_like "contract is invalid", identifier: %i(invalid)
  end

  context "when the identifier consists of a reserved word" do
    let(:project_identifier) { "new" }

    it_behaves_like "contract is invalid", identifier: %i(exclusion)
  end

  context "if the user lacks permission" do
    let(:global_permissions) { [] }
    let(:project_permissions) { [] }

    it_behaves_like "contract is invalid", base: %i(error_unauthorized)
  end

  describe "assignable_values" do
    context "for project" do
      before do
        assignable_parents
      end

      it "returns all projects the user has the add_subprojects permissions for" do
        expect(contract.assignable_parents)
          .to eql assignable_parents
      end
    end

    context "for a list custom field" do
      let(:custom_field) { build_stubbed(:list_project_custom_field) }

      it "is the list of custom field values" do
        expect(subject.assignable_custom_field_values(custom_field))
          .to eql custom_field.possible_values
      end
    end

    context "for a version custom field" do
      let(:custom_field) { build_stubbed(:version_project_custom_field) }
      let(:versions) { double("versions") }

      before do
        allow(project)
          .to receive(:assignable_versions)
          .and_return(versions)
      end

      it "is the list of versions for the project" do
        expect(subject.assignable_custom_field_values(custom_field))
          .to eql versions
      end
    end
  end

  describe "available_custom_fields" do
    let(:visible_custom_field) { build_stubbed(:integer_project_custom_field, admin_only: false) }
    let(:invisible_custom_field) { build_stubbed(:integer_project_custom_field, admin_only: true) }

    before do
      allow(project)
        .to receive(:available_custom_fields)
        .and_return([visible_custom_field, invisible_custom_field])
    end

    context "if the user is admin" do
      before do
        allow(current_user)
          .to receive(:admin?)
          .and_return(true)
      end

      it "returns all available_custom_fields of the project" do
        expect(subject.available_custom_fields)
          .to contain_exactly(visible_custom_field, invisible_custom_field)
      end
    end

    context "if the user is no admin" do
      it "returns all visible and available_custom_fields of the project" do
        expect(subject.available_custom_fields)
          .to contain_exactly(visible_custom_field)
      end
    end
  end
end
