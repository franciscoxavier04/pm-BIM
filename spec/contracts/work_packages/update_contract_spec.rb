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

require "spec_helper"
require "contracts/work_packages/shared_base_contract"

RSpec.describe WorkPackages::UpdateContract do
  include_context "work package contract"

  shared_let(:type) { create(:type) }
  shared_let(:persisted_work_package) do
    create(:work_package,
           project: persisted_project,
           type: persisted_type,
           status: persisted_status)
  end
  shared_let(:persisted_parent_work_package) do
    create(:work_package,
           project: persisted_project,
           type: persisted_type,
           status: persisted_status) do |parent|
      create(:work_package,
             parent:,
             project: persisted_project,
             type: persisted_type,
             status: persisted_status)
    end
  end

  let(:work_package) do
    persisted_work_package
  end
  let(:user) { persisted_user }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }

  describe "validations" do
    describe "general authorization" do
      context "without read access" do
        let(:permissions) { [:edit_work_packages] }

        it_behaves_like "contract is invalid", base: :error_not_found
      end

      context "without write access" do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like "contract user is unauthorized"
      end
    end

    describe "lock_version" do
      context "without a lock_version present" do
        before do
          work_package.lock_version = nil
        end

        it_behaves_like "contract is invalid", base: :error_conflict
      end

      context "with the lock_version changed" do
        before do
          work_package.lock_version += 1
        end

        it_behaves_like "contract is invalid", base: :error_conflict
      end

      context "with lock_version present and unchanged" do
        it_behaves_like "contract is valid"
      end
    end

    describe "project_id" do
      let(:target_project) { persisted_other_project }
      let(:target_permissions) { [:move_work_packages] }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project *permissions, project: persisted_project
          mock.allow_in_project *target_permissions, project: target_project
        end

        work_package.project = target_project
      end

      it_behaves_like "contract is valid"

      context "if the user lacks the permissions" do
        let(:target_permissions) { [] }

        it_behaves_like "contract is invalid", project_id: :error_readonly
      end
    end

    describe "remaining_hours" do
      # not parent case covered by shared base contract
      context "when is a parent" do
        let(:work_package) { persisted_parent_work_package }

        context "when has not changed" do
          it_behaves_like "contract is valid"
        end

        context "when has changed" do
          before do
            work_package.remaining_hours = 10
          end

          it_behaves_like "contract is valid"
        end
      end
    end

    describe "ignore_non_working_days" do
      context "when having children and not being scheduled manually" do
        before do
          allow(work_package)
            .to receive(:leaf?)
                  .and_return(false)

          work_package.ignore_non_working_days = !work_package.ignore_non_working_days
          work_package.schedule_manually = false
        end

        it_behaves_like "contract is invalid", ignore_non_working_days: :error_readonly
      end

      context "when having children and being scheduled manually" do
        before do
          allow(work_package)
            .to receive(:leaf?)
                  .and_return(false)

          work_package.ignore_non_working_days = !work_package.ignore_non_working_days
          work_package.schedule_manually = true
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "type" do
      let!(:milestone_type) do
        create(:type, is_milestone: true, projects: [work_package.project])
      end

      context "when changing to a milestone type and having a child work package" do
        let!(:child_work_package) do
          create(:work_package,
                 project: work_package.project,
                 parent: work_package)
        end

        before do
          work_package.type = milestone_type
        end

        it_behaves_like "contract is invalid", type: :cannot_be_milestone_due_to_children
      end
    end

    describe "journal_notes" do
      context "when only adding a comment and having only the comment permission permission" do
        let(:permissions) { %i[view_work_packages add_work_package_comments] }

        before do
          work_package.attributes = { journal_notes: "some notes" }
        end

        it_behaves_like "contract is valid"
      end

      context "when changing more than a comment and having only the comment permission permission" do
        let(:permissions) { %i[view_work_packages add_work_package_comments] }

        before do
          work_package.attributes = { journal_notes: "some notes", subject: "blubs" }
        end

        it_behaves_like "contract user is unauthorized"
      end

      context "when only adding a comment and having edit permissions" do
        before do
          work_package.attributes = { journal_notes: "some notes" }
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "readonly status" do
      context "with the status being readonly", with_ee: %i[readonly_work_packages] do
        shared_let(:readonly_status) { create(:status, is_readonly: true) }

        before do
          work_package.status = readonly_status
          work_package.save
        end

        describe "updating the priority (representative for default attributes)" do
          let(:new_priority) { build_stubbed(:priority) }

          before do
            work_package.priority = new_priority

            contract.validate
          end

          it_behaves_like "contract is invalid",
                          priority_id: :error_readonly,
                          base: :readonly_status
        end

        describe "updating the custom field values" do
          let(:cf1) { create(:string_wp_custom_field) }

          before do
            persisted_project.work_package_custom_fields << cf1
            persisted_type.custom_fields << cf1
            work_package.custom_field_values = { cf1.id => "test" }
            contract.validate
          end

          shared_examples_for "custom_field readonly errors" do
            it "adds an error to the written custom field attribute" do
              expect(contract.errors.symbols_for(cf1.attribute_name.to_sym))
                .to include(:error_readonly)
            end

            it "adds an error to base to better explain" do
              expect(contract.errors.symbols_for(:base))
                .to include(:readonly_status)
            end
          end

          context "when the subject does not extends OpenProject::ChangedBySystem" do
            include_examples "custom_field readonly errors"
          end

          context "when the subject extends OpenProject::ChangedBySystem" do
            before do
              work_package.extend(OpenProject::ChangedBySystem)
            end

            include_examples "custom_field readonly errors"
          end
        end
      end
    end

    describe "parent_id" do
      shared_let(:parent) { create(:work_package) }

      let(:parent_visible) { true }

      before do
        work_package.parent = parent

        allow(parent)
          .to receive(:visible?)
                .and_return(parent_visible)
      end

      context "if the user has only edit permissions" do
        it_behaves_like "contract is invalid", parent_id: :error_readonly
      end

      context "if the user has edit and subtasks permissions" do
        let(:permissions) { %i[edit_work_packages view_work_packages manage_subtasks] }

        it_behaves_like "contract is valid"
      end

      context "if the user lacks all edit and subtask permissions" do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like "contract is invalid", parent_id: :error_readonly
      end

      context "with manage_subtasks permission" do
        let(:permissions) { %i[view_work_packages manage_subtasks] }

        it_behaves_like "contract is valid"

        describe "changing more than the parent_id" do
          before do
            work_package.subject = "Foobar!"
          end

          it_behaves_like "contract is invalid", subject: :error_readonly
        end
      end

      context "when the user has the necessary permission on the work package but does not have access to the parent" do
        let(:permissions) { %i[view_work_packages manage_subtasks] }

        let(:parent_visible) { false }

        it_behaves_like "contract is invalid", parent_id: %i[error_unauthorized]
      end
    end

    describe "project_phase_definition", with_flag: { stages_and_gates: true } do
      let(:permissions) { super() + %i[view_project_phases move_work_packages] }

      context "when not changing the value but assigning a project in which the phase is not active" do
        before do
          # This leads to the project already having had the phase_definition assigned
          work_package.project_phase_definition = persisted_project_phase_definition
          work_package.save
          work_package.reload

          work_package.project = persisted_other_project
        end

        it_behaves_like "contract is valid"
      end

      context "when changing the value and assigning a project in which the phase is not active" do
        before do
          work_package.project_phase_definition = persisted_project_phase_definition
          work_package.project = persisted_other_project
        end

        it_behaves_like "contract is invalid", project_phase_id: :inclusion
      end
    end
  end

  describe "#writable_attributes" do
    subject { contract.writable_attributes }

    context "for a user having only the edit_work_packages permission" do
      let(:permissions) { %i[edit_work_packages] }

      it "includes all attributes except version_id" do
        expect(subject)
          .to include("subject", "start_date", "description")

        expect(subject)
          .not_to include("version_id", "version")
      end
    end

    context "for a user having only the assign_versions permission" do
      let(:permissions) { %i[assign_versions] }

      it "includes all attributes except version_id" do
        expect(subject)
          .to include("version_id", "version")

        expect(subject)
          .not_to include("subject", "start_date", "description")
      end
    end
  end

  describe "#assignable_assignees" do
    it "returns the users assignable" do
      expect(subject.assignable_assignees)
        .to contain_exactly(persisted_possible_assignee)
    end
  end

  describe "#assignable_responsibles" do
    it "returns the users assignable" do
      expect(subject.assignable_responsibles)
        .to contain_exactly(persisted_possible_assignee)
    end
  end
end
