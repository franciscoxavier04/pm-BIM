# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackages::ScheduleDependency do
  create_shared_association_defaults_for_work_package_factory

  describe "#descendants" do
    shared_let(:work_package) { create(:work_package) }
    let(:schedule_dependency) { described_class.new(work_package) }

    context "with a simple hierarchy" do
      let!(:child1) { create(:work_package, parent: work_package) }
      let!(:child2) { create(:work_package, parent: work_package) }

      it "returns all direct children" do
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child1, child2)
      end
    end

    context "with multiple levels" do
      let!(:child) { create(:work_package, parent: work_package) }
      let!(:grandchild) { create(:work_package, parent: child) }
      let!(:great_grandchild) { create(:work_package, parent: grandchild) }

      it "returns all descendants at all levels" do
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child, grandchild, great_grandchild)
      end
    end

    context "with multiple branches" do
      let!(:child1) { create(:work_package, parent: work_package) }
      let!(:child2) { create(:work_package, parent: work_package) }
      let!(:grandchild1) { create(:work_package, parent: child1) }
      let!(:grandchild2) { create(:work_package, parent: child2) }

      it "returns all descendants from all branches" do
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(
          child1, child2, grandchild1, grandchild2
        )
      end
    end

    context "with caching" do
      let!(:child) { create(:work_package, parent: work_package) }

      it "caches the result" do
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child)

        # Create a new child after the first call
        create(:work_package, parent: work_package)

        # Should still return the cached result
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child)
      end
    end

    context "with a cycle in the hierarchy" do
      let!(:child) { create(:work_package, parent: work_package) }

      before do
        # Create a cycle by making the work package a child of its child
        work_package.update_column(:parent_id, child.id)
      end

      it "handles the cycle gracefully" do
        expect { schedule_dependency.descendants(work_package) }.not_to raise_error
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child)
      end
    end

    context "with no children" do
      it "returns an empty array" do
        expect(schedule_dependency.descendants(work_package)).to be_empty
      end
    end
  end
end
