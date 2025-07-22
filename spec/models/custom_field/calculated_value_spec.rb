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

RSpec.describe CustomField::CalculatedValue, with_flag: { calculated_value_project_attribute: true } do
  subject(:custom_field) { create(:calculated_value_project_custom_field, formula: "1 + 1") }

  describe "#usable_custom_field_references_for_formula" do
    let!(:int) { create(:project_custom_field, :integer, default_value: 4, is_for_all: true) }
    let!(:float) { create(:project_custom_field, :float, default_value: 5.5, is_for_all: true) }
    let!(:other_calculated_value) { create(:calculated_value_project_custom_field, formula: "2 + 2", is_for_all: true) }

    current_user { create(:admin) }

    context "with permission to see all custom fields" do
      it "returns custom fields with formats that can be used in formulas" do
        expect(subject.usable_custom_field_references_for_formula).to contain_exactly(int, float, other_calculated_value)
      end

      it "excludes custom field formats that are not usable in formulas" do
        text = create(:project_custom_field, :text, default_value: "txt", is_for_all: true)
        expect(subject.usable_custom_field_references_for_formula).not_to include(text)
      end
    end

    context "with insufficient permission to see some custom fields" do
      let(:project_with_permission) { create(:project) }
      let(:project_without_permission) { create(:project) }
      let(:user) { create(:user, member_with_permissions: { project_with_permission => [:view_project_attributes] }) }

      let!(:int) { create(:project_custom_field, :integer, default_value: 4, projects: [project_with_permission]) }
      let!(:float) { create(:project_custom_field, :float, default_value: 5.5, projects: [project_with_permission]) }
      let!(:other_calculated_value) do
        create(:calculated_value_project_custom_field, formula: "2 + 2", projects: [project_without_permission])
      end

      current_user { user }

      it "returns only custom fields that the user has permission to see" do
        expect(subject.usable_custom_field_references_for_formula).to contain_exactly(int, float)
      end
    end
  end

  describe "#formula=" do
    let!(:int) { create(:project_custom_field, :integer, default_value: 2, is_for_all: true) }
    let!(:float) { create(:project_custom_field, :float, default_value: 3.5, is_for_all: true) }

    current_user { create(:admin) }

    it "splits formula and referenced custom fields on persist if given a string" do
      formula = "1 * {{cf_#{int.id}}} + {{cf_#{float.id}}}"
      subject.formula = formula

      expect(subject.formula).to eq({ "formula" => formula, "referenced_custom_fields" => [int.id, float.id] })
    end

    it "omits referenced custom fields if none are given" do
      formula = "2 + 3 * (8 / 7)"
      subject.formula = formula

      expect(subject.formula).to eq({ "formula" => formula, "referenced_custom_fields" => [] })
    end
  end

  describe "#formula_string" do
    it "returns an empty string if no formula is set" do
      subject.formula = nil
      expect(subject.formula_string).to eq("")
    end

    it "returns the formula as a string" do
      formula = "1 * {{cf_7}} + {{cf_42}}"
      subject.formula = formula

      expect(subject.formula_string).to eq(formula)
    end
  end

  describe "#validate_formula" do
    shared_examples_for "valid formula" do
      it "is valid", :aggregate_failures do
        subject.formula = formula
        subject.validate_formula

        expect(subject).to be_valid
      end
    end

    shared_examples_for "invalid formula" do |error_message|
      it "is invalid", :aggregate_failures do
        subject.formula = formula
        subject.validate_formula

        expect(subject).not_to be_valid
        expect(subject.errors[:formula]).to include(error_message)
      end
    end

    let(:formula) { "" }

    context "with an empty formula" do
      it_behaves_like "invalid formula", "can't be blank."
    end

    context "with a formula containing only allowed characters" do
      let(:formula) { "1 / 2 + (3 * 4.5) - 0.0" }

      it_behaves_like "valid formula"
    end

    context "when omitting leading decimals before a decimal point" do
      let(:formula) { "1.5 + .0 - 3.25" }

      it_behaves_like "valid formula"
    end

    context "when omitting trailing decimals after a decimal point" do
      let(:formula) { "1.5 + 1. - 3.25" }

      it_behaves_like "invalid formula", "is invalid."
    end

    context "with a formula containing forbidden characters" do
      let(:formula) { "abc + 2" }

      it_behaves_like "invalid formula", "contains invalid characters."
    end

    context "with a formula containing references to custom fields without pattern-mustaches" do
      let(:formula) { "100 * cf_3" }

      it_behaves_like "invalid formula", "contains invalid characters."
    end

    context "with a formula that is not a valid equation" do
      let(:formula) { "1 / + - 3" }

      it_behaves_like "invalid formula", "is invalid."
    end

    context "with a formula that contains custom fields that are not visible to the user" do
      let(:project_with_permission) { create(:project) }
      let(:project_without_permission) { create(:project) }
      let(:user) { create(:user, member_with_permissions: { project_with_permission => [:view_project_attributes] }) }

      let!(:int) do
        create(:project_custom_field, :integer, name: "int", default_value: 4, projects: [project_without_permission])
      end
      let!(:float) do
        create(:project_custom_field, :float, name: "float", default_value: 5.5, projects: [project_without_permission])
      end
      let!(:other_calculated_value) do
        create(:calculated_value_project_custom_field, formula: "2 + 2", projects: [project_with_permission])
      end

      let(:formula) { "1 + {{cf_#{int.id}}} + {{cf_#{float.id}}} + {{cf_#{other_calculated_value.id}}}" }

      current_user { user }

      it_behaves_like "invalid formula", "contains custom fields that are not allowed: int, float."
    end
  end
end
