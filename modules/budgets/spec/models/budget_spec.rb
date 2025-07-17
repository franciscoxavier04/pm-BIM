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

require_relative "../spec_helper"

RSpec.describe Budget do
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project_with_types) }

  before_all do
    set_factory_default(:user, user)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
  end

  let(:budget) { build(:budget) }

  describe "destroy" do
    let(:work_package) { create(:work_package) }

    before do
      budget.author = user
      budget.work_packages = [work_package]
      budget.save!

      budget.destroy
    end

    it "deletes the budget" do
      expect(described_class.find_by(id: budget.id)).to be_nil
      expect(work_package.reload.budget).to be_nil
    end

    it "does not delete the associated work packages" do
      expect(WorkPackage.find_by(id: work_package.id)).to eq(work_package)
    end
  end

  describe "#existing_material_budget_item_attributes=" do
    let!(:existing_material_budget_item) do
      create(:material_budget_item, budget:, units: 10.0)

      budget.material_budget_items.reload.first
    end

    context "when allowed to edit budgets" do
      before do
        mock_permissions_for(User.current) do |mock|
          mock.allow_in_project :edit_budgets, project:
        end
      end

      context "with a non integer value" do
        it "updates the item" do
          budget.existing_material_budget_item_attributes = { existing_material_budget_item.id.to_s.to_sym => { units: "0.5" } }

          expect(existing_material_budget_item.units)
            .to be 0.5
        end
      end

      context "with no value" do
        it "deletes the item" do
          budget.existing_material_budget_item_attributes = { existing_material_budget_item.id.to_s.to_sym => {} }

          expect(existing_material_budget_item)
            .to be_destroyed
        end
      end
    end
  end

  describe "#children_budgets_count" do
    context "without any budget relations" do
      it { expect(budget.children_budgets_count).to eq(0) }
    end

    context "with one child budget relation" do
      let!(:child_budget) { create(:budget) }
      let!(:budget_relation) { create(:budget_relation, parent_budget: budget, child_budget:) }

      it { expect(budget.children_budgets_count).to eq(1) }

      context "with also a grandchild budget relation" do
        let!(:grandchild_budget) { create(:budget) }
        let!(:grandchild_budget_relation) do
          create(:budget_relation, parent_budget: child_budget, child_budget: grandchild_budget)
        end

        it { expect(budget.children_budgets_count).to eq(2) }
      end
    end
  end
end
