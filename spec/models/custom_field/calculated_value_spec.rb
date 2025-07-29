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

      it "excludes the current custom field from the results" do
        expect(subject.usable_custom_field_references_for_formula).not_to include(subject)
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

    context "when there are circular references" do
      let!(:field_a) { create(:calculated_value_project_custom_field, formula: "1 + 1", is_for_all: true) }
      let!(:field_b) { create(:calculated_value_project_custom_field, formula: "2 + 2", is_for_all: true) }
      let!(:field_c) { create(:calculated_value_project_custom_field, formula: "3 + 3", is_for_all: true) }

      before do
        # Set up circular reference: field_a -> field_b -> field_c -> field_a
        field_a.formula = "{{cf_#{field_b.id}}} + 1"
        field_b.formula = "{{cf_#{field_c.id}}} + 2"
        field_c.formula = "{{cf_#{field_a.id}}} + 3"

        field_a.save(validate: false)
        field_b.save(validate: false)
        field_c.save(validate: false)
      end

      it "excludes fields that would create circular references" do
        # field_a should not be able to reference field_b, field_b should not be able to reference field_c, etc.
        expect(field_a.usable_custom_field_references_for_formula).not_to include(field_b)
        expect(field_b.usable_custom_field_references_for_formula).not_to include(field_c)
        expect(field_c.usable_custom_field_references_for_formula).not_to include(field_a)
      end

      it "still includes fields that don't create circular references" do
        expect(field_a.usable_custom_field_references_for_formula).to include(int, float)
        expect(field_b.usable_custom_field_references_for_formula).to include(int, float)
        expect(field_c.usable_custom_field_references_for_formula).to include(int, float)
      end
    end

    context "when there are self-referencing fields" do
      let!(:self_referencing_field) { create(:calculated_value_project_custom_field, formula: "1 + 1", is_for_all: true) }

      before do
        self_referencing_field.formula = "{{cf_#{self_referencing_field.id}}} + 1"
        self_referencing_field.save(validate: false)
      end

      it "excludes self-referencing fields from other fields' usable references" do
        expect(subject.usable_custom_field_references_for_formula).not_to include(self_referencing_field)
      end

      it "still includes non-self-referencing fields" do
        expect(subject.usable_custom_field_references_for_formula).to include(int, float)
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

  describe "#formula_referenced_custom_field_ids" do
    it "returns an empty array if no formula is set" do
      subject.formula = nil

      expect(subject.formula_referenced_custom_field_ids).to eq([])
    end

    it "returns an empty array if formula doesn't reference custom fields" do
      subject.formula = "2 + 2"

      expect(subject.formula_referenced_custom_field_ids).to eq([])
    end

    it "returns ids if formula references custom fields" do
      subject.formula = "1 * {{cf_7}} + {{cf_42}}"

      expect(subject.formula_referenced_custom_field_ids).to eq([7, 42])
    end
  end

  describe "#formula_contains_reference_to_id?" do
    let!(:int_field) { create(:project_custom_field, :integer, default_value: 10, is_for_all: true) }
    let!(:float_field) { create(:project_custom_field, :float, default_value: 5.5, is_for_all: true) }
    let!(:text_field) { create(:project_custom_field, :text, default_value: "text", is_for_all: true) }

    current_user { create(:admin) }

    context "when checking a non-calculated value custom field" do
      it "returns false for integer custom field" do
        expect(subject.send(:formula_references_id?, int_field, subject.id)).to be false
      end

      it "returns false for float custom field" do
        expect(subject.send(:formula_references_id?, float_field, subject.id)).to be false
      end

      it "returns false for text custom field" do
        expect(subject.send(:formula_references_id?, text_field, subject.id)).to be false
      end
    end

    context "when checking a calculated value custom field with formula but no references" do
      let!(:simple_calculated_field) do
        create(:calculated_value_project_custom_field, formula: "1 + 2", is_for_all: true)
      end

      it "returns false" do
        expect(subject.send(:formula_references_id?, simple_calculated_field, subject.id)).to be false
      end
    end

    context "when checking for direct circular reference" do
      let!(:self_referencing_field) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{int_field.id}}} + 1",
               is_for_all: true)
      end

      before do
        # Manually set the formula to reference itself
        self_referencing_field.formula = "{{cf_#{self_referencing_field.id}}} + 1"
        self_referencing_field.save(validate: false)
      end

      it "returns true when field references itself" do
        circular = self_referencing_field.send(:formula_references_id?, self_referencing_field, self_referencing_field.id)
        expect(circular).to be true
      end
    end

    context "when checking for indirect circular reference" do
      let!(:field_a) do
        create(:calculated_value_project_custom_field,
               formula: "1 + 1",
               is_for_all: true)
      end

      let!(:field_b) do
        create(:calculated_value_project_custom_field,
               formula: "1 + 1",
               is_for_all: true)
      end

      let!(:field_c) do
        create(:calculated_value_project_custom_field,
               formula: "1 + 1",
               is_for_all: true)
      end

      before do
        # Set up the circular reference: field_a -> field_b -> field_c -> field_a
        field_a.formula = "{{cf_#{field_b.id}}} + 1"
        field_b.formula = "{{cf_#{field_c.id}}} + 2"
        field_c.formula = "{{cf_#{field_a.id}}} + 3"

        field_a.save(validate: false)
        field_b.save(validate: false)
        field_c.save(validate: false)
      end

      it "returns true when there is an indirect circular reference" do
        expect(field_a.send(:formula_references_id?, field_a, field_a.id)).to be true
      end

      it "returns true when checking from any field in the circular chain" do
        expect(field_b.send(:formula_references_id?, field_b, field_b.id)).to be true
        expect(field_c.send(:formula_references_id?, field_c, field_c.id)).to be true
      end
    end

    context "when checking for no circular reference" do
      # Set up a linear chain: field_x -> field_y -> field_z (no circular reference)
      let!(:field_x) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{int_field.id}}} + 1",
               is_for_all: true)
      end

      let!(:field_y) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{field_x.id}}} + 2",
               is_for_all: true)
      end

      let!(:field_z) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{field_y.id}}} + 3",
               is_for_all: true)
      end

      it "returns false when there is no circular reference" do
        expect(field_x.send(:formula_references_id?, field_x, field_x.id)).to be false
        expect(field_y.send(:formula_references_id?, field_y, field_y.id)).to be false
        expect(field_z.send(:formula_references_id?, field_z, field_z.id)).to be false
      end
    end

    context "when checking with visited nodes tracking" do
      let!(:field1) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{int_field.id}}} + 1",
               is_for_all: true)
      end

      let!(:field2) do
        create(:calculated_value_project_custom_field,
               formula: "{{cf_#{field1.id}}} + 2",
               is_for_all: true)
      end

      it "returns true when a node has already been visited" do
        visited = Set.new([field1.id])
        expect(field2.send(:formula_references_id?, field1, field2.id, visited)).to be true
      end

      it "returns false when checking a new node with empty visited set" do
        visited = Set.new
        expect(field2.send(:formula_references_id?, field1, field2.id, visited)).to be false
      end
    end

    context "when checking with non-existent referenced custom field" do
      let!(:field_with_invalid_ref) do
        create(:calculated_value_project_custom_field,
               formula: "1 + 1",
               is_for_all: true)
      end

      before do
        field_with_invalid_ref.formula = "{{cf_99999}} + 1"
        field_with_invalid_ref.save(validate: false)
      end

      it "returns false when referenced custom field does not exist" do
        circular = field_with_invalid_ref.send(:formula_references_id?, field_with_invalid_ref, field_with_invalid_ref.id)
        expect(circular).to be false
      end
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

    context "with a formula using the modulo operator" do
      let(:formula) { "10 % 3" }

      it_behaves_like "valid formula"
    end

    context "with a formula calculating percentages" do
      let(:formula) { "10% * 3" }

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
