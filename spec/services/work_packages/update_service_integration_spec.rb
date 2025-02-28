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

RSpec.describe WorkPackages::UpdateService, "integration", type: :model do
  shared_let(:type) { create(:type_standard) }
  shared_let(:project_types) { [type] }
  shared_let(:project) do
    create(:project, types: project_types)
  end
  shared_let(:default_status) { create(:default_status, name: "default_status") }
  shared_let(:non_default_status) { create(:status, name: "non_default_status") }

  shared_let(:role) do
    create(:project_role,
           permissions: %i[
             view_work_packages
             edit_work_packages
             add_work_packages
             move_work_packages
             manage_subtasks
           ])
  end
  shared_let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  shared_let(:status) { default_status }
  shared_let(:priority) { create(:priority) }

  before_all do
    set_factory_default(:priority, priority)
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, status)
    set_factory_default(:type, type)
    set_factory_default(:user, user)
  end

  shared_let(:work_package, refind: true, reload: false) do
    create(:work_package,
           subject: "work_package")
  end
  let(:parent_work_package) do
    create(:work_package,
           subject: "parent",
           schedule_manually: false).tap do |w|
      w.children << work_package
      work_package.reload
    end
  end
  let(:grandparent_work_package) do
    create(:work_package,
           subject: "grandparent",
           schedule_manually: false).tap do |w|
      w.children << parent_work_package
    end
  end
  let(:sibling1_attributes) { {} }
  let(:sibling2_attributes) { {} }
  let(:sibling1_work_package) do
    create(:work_package,
           subject: "sibling1",
           parent: parent_work_package,
           **sibling1_attributes)
  end
  let(:sibling2_work_package) do
    create(:work_package,
           subject: "sibling2",
           parent: parent_work_package,
           **sibling2_attributes)
  end
  let(:child_attributes) { {} }
  let(:child_work_package) do
    parent = work_package
    parent.update_column(:schedule_manually, false)
    create(:work_package,
           subject: "child",
           parent:,
           **child_attributes)
  end
  let(:instance) do
    described_class.new(user:,
                        model: work_package)
  end

  subject do
    instance.call(**attributes.merge(send_notifications: false).symbolize_keys)
  end

  describe "updating subject" do
    let(:attributes) { { subject: "New subject" } }

    it "updates the subject" do
      expect(subject)
        .to be_success

      expect(work_package.subject)
        .to eql(attributes[:subject])
    end
  end

  context "when updating the project" do
    shared_let(:target_project) do
      create(:project,
             types: project_types,
             parent: nil)
    end
    let(:target_permissions) { [:move_work_packages] }

    let(:attributes) { { project_id: target_project.id } }

    before do
      create(:member,
             user:,
             project: target_project,
             roles: [create(:project_role, permissions: target_permissions)])
    end

    it "is success and updates the project" do
      expect(subject).to be_success
      expect(work_package.reload.project).to eql target_project
    end

    context "with missing :move_work_packages permission" do
      let(:target_permissions) { [] }

      it "is failure" do
        expect(subject).to be_failure
      end
    end

    describe "time_entries" do
      let!(:time_entries) do
        create_list(:time_entry, 2, project:, work_package:)
      end

      it "moves the time entries along" do
        expect(subject)
          .to be_success

        expect(TimeEntry.where(id: time_entries.map(&:id)).pluck(:project_id).uniq)
          .to contain_exactly(target_project.id)
      end
    end

    describe "memberships" do
      let(:wp_role) { create(:work_package_role, permissions: [:view_work_packages]) }
      let(:other_user) { create(:user) }
      let!(:membership) do
        create(:member, project:, entity: work_package, principal: other_user, roles: [wp_role])
      end

      it "moves memberships for the entity to the new project" do
        expect do
          subject
          membership.reload
        end.to change(membership, :project).from(project).to(target_project)
      end

      describe "when the work package has descendents" do
        let!(:child_membership) do
          create(:member, project:, entity: child_work_package, principal: other_user, roles: [wp_role])
        end

        it "moves memberships for the entity and its descendents to the new project" do
          expect do
            subject
            membership.reload
            child_membership.reload
          end.to change(membership, :project).from(project).to(target_project).and \
            change(child_membership, :project).from(project).to(target_project)
        end
      end
    end

    describe "categories" do
      let(:category) do
        create(:category,
               project:)
      end

      before do
        work_package.category = category
        work_package.save!
      end

      context "with equally named category" do
        let!(:target_category) do
          create(:category,
                 name: category.name,
                 project: target_project)
        end

        it "replaces the current category by the equally named one" do
          expect(subject)
            .to be_success

          expect(subject.result.category)
            .to eql target_category
        end
      end

      context "without a target category" do
        let!(:other_category) do
          create(:category,
                 project: target_project)
        end

        it "removes the category" do
          expect(subject)
            .to be_success

          expect(subject.result.category)
            .to be_nil
        end
      end
    end

    describe "version" do
      let(:sharing) { "none" }
      let(:version) do
        create(:version,
               status: "open",
               project:,
               sharing:)
      end

      before do
        work_package.update(version:)
      end

      context "with an unshared version" do
        it "removes the version" do
          expect(subject)
            .to be_success

          expect(subject.result.version)
            .to be_nil
        end
      end

      context "with a system wide shared version" do
        let(:sharing) { "system" }

        it "keeps the version" do
          expect(subject)
            .to be_success

          expect(subject.result.version)
            .to eql version
        end
      end

      context "when moving the work package in project hierarchy" do
        before do
          target_project.update(parent: project)
        end

        context "with an unshared version" do
          it "removes the version" do
            expect(subject)
              .to be_success

            expect(subject.result.version)
              .to be_nil
          end
        end

        context "with a hierarchy shared version" do
          let(:sharing) { "tree" }

          it "keeps the version" do
            expect(subject)
              .to be_success

            expect(subject.result.version)
              .to eql version
          end
        end
      end
    end

    describe "type" do
      shared_let(:other_type) { create(:type) }
      shared_let(:default_type) { type }
      shared_let(:workflow_type) do
        create(:workflow, type: default_type, role:, old_status_id: status.id)
      end
      shared_let(:workflow_other_type) do
        create(:workflow, type: other_type, role:, old_status_id: status.id)
      end

      before do
        project.types << other_type

        # reset types of target project
        # types will be added in each context depending on the test.
        target_project.types.delete_all
      end

      context "with the type existing in the target project" do
        before do
          target_project.types << type
        end

        it "keeps the type" do
          expect(subject)
            .to be_success

          expect(subject.result.type)
            .to eql type
        end
      end

      context "with a default type existing in the target project" do
        before do
          target_project.types << default_type
        end

        it "uses the default type" do
          expect(subject)
            .to be_success

          expect(subject.result.type)
            .to eql default_type
        end
      end

      context "with only non default types" do
        before do
          target_project.types << other_type
        end

        it "is unsuccessful" do
          expect(subject)
            .to be_failure
        end
      end

      context "with an invalid type being provided" do
        before do
          target_project.types << type
        end

        let(:attributes) do
          { project: target_project,
            type: other_type }
        end

        it "is unsuccessful" do
          expect(subject)
            .to be_failure
        end
      end
    end

    describe "relations" do
      let!(:relation) do
        create(:follows_relation,
               from: work_package,
               to: create(:work_package,
                          project:))
      end

      context "with cross project relations allowed", with_settings: { cross_project_work_package_relations: true } do
        it "keeps the relation" do
          expect(subject)
            .to be_success

          expect(Relation.find_by(id: relation.id))
            .to eql(relation)
        end
      end

      context "with cross project relations disabled", with_settings: { cross_project_work_package_relations: false } do
        it "deletes the relation" do
          expect(subject)
            .to be_success

          expect(Relation.find_by(id: relation.id))
            .to be_nil
        end
      end
    end
  end

  describe "inheriting dates" do
    let(:attributes) do
      {
        start_date: Time.zone.today - 8.days,
        due_date: Time.zone.today + 12.days
      }
    end
    let(:sibling1_attributes) do
      {
        start_date: Time.zone.today - 5.days,
        due_date: Time.zone.today + 10.days
      }
    end
    let(:sibling2_attributes) do
      {
        due_date: Time.zone.today + 16.days
      }
    end

    before do
      parent_work_package
      grandparent_work_package
      sibling1_work_package
      sibling2_work_package
    end

    it "works and inherits" do
      expect(subject)
        .to be_success

      # receives the provided start/finish date
      expect(work_package)
        .to have_attributes(start_date: attributes[:start_date],
                            due_date: attributes[:due_date])

      # receives the min/max of the children's start/finish date
      [parent_work_package,
       grandparent_work_package].each do |wp|
        wp.reload
        expect(wp)
          .to have_attributes(start_date: attributes[:start_date],
                              due_date: sibling2_work_package.due_date)
      end

      # sibling dates are unchanged
      sibling1_work_package.reload
      expect(sibling1_work_package)
        .to have_attributes(start_date: sibling1_attributes[:start_date],
                            due_date: sibling1_attributes[:due_date])

      sibling2_work_package.reload
      expect(sibling2_work_package)
        .to have_attributes(start_date: sibling2_attributes[:start_date],
                            due_date: sibling2_attributes[:due_date])

      expect(subject.all_results)
        .to contain_exactly(work_package, parent_work_package, grandparent_work_package)
    end
  end

  describe "inheriting done_ratio" do
    let(:attributes) do
      {
        estimated_hours: 10.0,
        remaining_hours: 5.0
      }
    end
    let(:sibling1_attributes) do
      # no estimated or remaining hours
      {}
    end
    let(:sibling2_attributes) do
      {
        estimated_hours: 100.0,
        remaining_hours: 25.0,
        parent: parent_work_package
      }
    end

    before do
      parent_work_package
      grandparent_work_package
      sibling1_work_package
      sibling2_work_package
    end

    it "works and inherits average done ratio of leaves weighted by work values" do
      expect(subject)
        .to be_success

      # sets it to the computation between estimated_hours and remaining_hours
      expect(work_package.done_ratio)
        .to eq(50)

      [parent_work_package,
       grandparent_work_package].each do |wp|
        wp.reload

        # sibling1 not factored in as its estimated and remaining hours are nil
        #
        # Total factored in estimated_hours (work_package + sibling2) = 110
        # Total factored in remaining_hours (work_package + sibling2) = 30
        # Work done = 80
        # Calculated done ratio rounded up = (80 / 110) * 100
        expect(wp.derived_done_ratio)
          .to eq(73)
      end

      # unchanged
      sibling1_work_package.reload
      expect(sibling1_work_package.done_ratio)
        .to be_nil

      sibling2_work_package.reload
      expect(sibling2_work_package.done_ratio)
        .to eq(75) # Was not changed as

      # Returns changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package, parent_work_package, grandparent_work_package)
    end
  end

  describe "inheriting estimated_hours" do
    let(:attributes) { { estimated_hours: 7 } }
    let(:sibling1_attributes) do
      # no estimated hours
      {}
    end
    let(:sibling2_attributes) do
      {
        estimated_hours: 5
      }
    end
    let(:child_attributes) do
      {
        estimated_hours: 10
      }
    end

    before do
      parent_work_package
      grandparent_work_package
      sibling1_work_package
      sibling2_work_package
      child_work_package
    end

    it "works and inherits" do
      expect(subject)
        .to be_success

      # receives the provided value
      expect(work_package.estimated_hours)
        .to eql(attributes[:estimated_hours].to_f)

      # receive the sum of the children's estimated hours
      [parent_work_package,
       grandparent_work_package].each do |wp|
        sum = sibling1_attributes[:estimated_hours].to_f +
              sibling2_attributes[:estimated_hours].to_f +
              attributes[:estimated_hours].to_f +
              child_attributes[:estimated_hours].to_f

        wp.reload

        expect(wp.estimated_hours).to be_nil
        expect(wp.derived_estimated_hours).to eql(sum)
      end

      # sibling hours are unchanged
      sibling1_work_package.reload
      expect(sibling1_work_package.estimated_hours)
        .to be_nil

      sibling2_work_package.reload
      expect(sibling2_work_package.estimated_hours)
        .to eql(sibling2_attributes[:estimated_hours].to_f)

      # child hours are unchanged
      child_work_package.reload
      expect(child_work_package.estimated_hours)
        .to eql(child_attributes[:estimated_hours].to_f)

      # Returns changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package, parent_work_package, grandparent_work_package)
    end
  end

  describe "inheriting ignore_non_working_days" do
    let(:attributes) { { ignore_non_working_days: true } }

    before do
      parent_work_package
      grandparent_work_package
      sibling1_work_package
    end

    it "propagates the value up the ancestor chain" do
      expect(subject)
        .to be_success

      # receives the provided value
      expect(work_package.reload.ignore_non_working_days)
        .to be_truthy

      # parent and grandparent receive the value
      expect(parent_work_package.reload.ignore_non_working_days)
        .to be_truthy
      expect(grandparent_work_package.reload.ignore_non_working_days)
        .to be_truthy

      # Returns changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package, parent_work_package, grandparent_work_package)
    end
  end

  describe "closing duplicates on closing status" do
    let(:status_closed) do
      create(:status,
             is_closed: true) do |status_closed|
        create(:workflow,
               old_status: status,
               new_status: status_closed,
               type:,
               role:)
      end
    end
    let!(:duplicate_work_package) do
      create(:work_package, subject: "duplicate") do |wp|
        create(:relation, relation_type: Relation::TYPE_DUPLICATES, from: wp, to: work_package)
      end
    end

    let(:attributes) { { status: status_closed } }

    it "works and closes duplicates" do
      expect(subject)
        .to be_success

      duplicate_work_package.reload

      expect(work_package.status)
        .to eql(attributes[:status])
      expect(duplicate_work_package.status)
        .to eql(attributes[:status])
    end
  end

  describe "rescheduling work packages along follows/hierarchy relations" do
    # layout
    #                   following_parent_work_package +-follows- following2_parent_work_package   following3_parent_work_package
    #                                    |                                 |                          /                  |
    #                                hierarchy                          hierarchy                 hierarchy            hierarchy
    #                                    |                                 |                        /                    |
    #                                    +                                 +                       +                     |
    # work_package +-follows- following_work_package     following2_work_package +-follows- following3_work_package      +
    #                                                                                            following3_sibling_work_package
    let_work_packages(<<~TABLE)
      hierarchy                         | MTWTFSS                               | scheduling mode | predecessors
      work_package                      | XXXXXX                                | manual          |
      following_parent_work_package     |       XXXXXXXXXXXXXXX                 | automatic       |
        following_work_package          |       XXXXXXXXXXXXXXX                 | automatic       | work_package
      following2_parent_work_package    |                      XXXXX            | automatic       | following_parent_work_package
        following2_work_package         |                      XXXXX            | automatic       |
      following3_parent_work_package    |                           XXXXXXXXXXX | automatic       |
        following3_work_package         |                           XXXXX       | automatic       | following2_work_package
        following3_sibling_work_package |                                 XXXXX | manual          |
    TABLE
    let(:attributes) do
      {
        start_date: work_package.start_date + 5.days,
        due_date: work_package.due_date + 5.days
      }
    end

    let(:monday) { Date.current.next_occurring(:monday) }

    it "propagates the changes to start/finish date along" do
      expect(subject)
        .to be_success

      # Returns changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package,
                            following_parent_work_package, following_work_package,
                            following2_parent_work_package, following2_work_package,
                            following3_parent_work_package, following3_work_package)

      expect_work_packages(subject.all_results + [following3_sibling_work_package], <<~TABLE)
        subject                           | MTWTFSS                               |
        work_package                      |      XXXXXX                           |
        following_parent_work_package     |            XXXXXXXXXXXXXXX            |
          following_work_package          |            XXXXXXXXXXXXXXX            |
        following2_parent_work_package    |                           XXXXX       |
          following2_work_package         |                           XXXXX       |
        following3_parent_work_package    |                                XXXXXX |
          following3_work_package         |                                XXXXX  |
          following3_sibling_work_package |                                 XXXXX |
      TABLE
    end
  end

  describe "rescheduling work packages with a parent having a follows relation (Regression #43220)" do
    let(:predecessor_attributes) do
      {
        start_date: Time.zone.today + 1.day,
        due_date: Time.zone.today + 3.days
      }
    end

    let!(:predecessor_work_package) do
      create(:work_package,
             subject: "predecessor",
             **predecessor_attributes) do |wp|
        create(:follows_relation, from: parent_work_package, to: wp)
      end
    end

    let(:parent_work_package) do
      create(:work_package, subject: "parent", schedule_manually: false)
    end

    let(:expected_parent_dates) do
      {
        start_date: Time.zone.today + 4.days,
        due_date: Time.zone.today + 4.days
      }
    end

    let(:expected_child_dates) do
      {
        start_date: Time.zone.today + 4.days,
        due_date: nil
      }
    end

    # `schedule_manually: true` is the default value. Adding it here anyway for explicitness.
    let(:attributes) { { parent: parent_work_package, schedule_manually: true } }

    it "sets the parent and child dates correctly" do
      expect(subject)
        .to be_success

      expect(parent_work_package.reload.slice(:start_date, :due_date).symbolize_keys)
        .to eq(expected_parent_dates)

      expect(work_package.reload.slice(:start_date, :due_date).symbolize_keys)
        .to eq(expected_child_dates)

      expect(subject.all_results.uniq)
        .to contain_exactly(work_package, parent_work_package)
    end
  end

  describe "changing the parent" do
    let_work_packages(<<~TABLE)
      hierarchy                     | MTWTFSS    | scheduling mode
      former_parent_work_package    | XXXXXXX    | automatic
        work_package                |     XXX    | manual
        former_sibling_work_package | XXXX       | manual
      new_parent_work_package       |        XXX | automatic
        new_sibling_work_package    |        XXX | manual
    TABLE

    let(:attributes) { { parent: new_parent_work_package } }

    it "changes the parent reference and reschedules former and new parent" do
      expect(subject)
        .to be_success

      expect(subject.all_results.uniq)
        .to contain_exactly(work_package, former_parent_work_package, new_parent_work_package)

      expect(work_package.reload.parent).to eq(new_parent_work_package)

      expect_work_packages(subject.all_results + [former_sibling_work_package, new_sibling_work_package], <<~TABLE)
        subject                       | MTWTFSS     |
        # updates the former parent's dates based on the only remaining child (former sibling)
        former_parent_work_package    | XXXX        |
          former_sibling_work_package | XXXX        |
        # updates the new parent's dates based on the moved work package and its now sibling
        new_parent_work_package       |     XXXXXX  |
          work_package                |     XXX     |
          new_sibling_work_package    |        XXX  |
      TABLE
    end
  end

  context "when being manually scheduled and setting the parent" do
    let(:attributes) { { parent: new_parent } }

    before do
      set_non_working_week_days("saturday", "sunday")
    end

    context "without dates and with the parent being restricted in its ability to be moved" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS | scheduling mode | predecessors
        work_package           |         | manual          |
        new_parent_predecessor |   X     | manual          |
        new_parent             |         | automatic       | follows new_parent_predecessor with lag 3
      TABLE

      it "schedules parent to start and end at soonest working start date and the child to start at the parent start" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSS   |
          new_parent   |         X |
          work_package |         [ |
        TABLE
      end
    end

    context "without dates, with a duration and with the parent being restricted in its ability to be moved" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS | duration | scheduling mode | predecessors
        work_package           |         |        4 | manual          |
        new_parent_predecessor |   X     |          | manual          |
        new_parent             |         |          | automatic       | follows new_parent_predecessor with lag 3
      TABLE

      it "schedules the moved work package to start at the parent soonest date and sets due date to keep the same duration " \
         "and schedules the parent dates to match the child dates" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSS      |
          new_parent   |         XXXX |
          work_package |         XXXX |
        TABLE
      end
    end

    context "with the parent being restricted in its ability to be moved and with a due date before parent constraint" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS   | scheduling mode | predecessors
        work_package           | ]         | manual          |
        new_parent_predecessor | X         | manual          |
        new_parent             |           | automatic       | follows new_parent_predecessor with lag 3
      TABLE

      it "schedules the moved work package to start and end at the parent soonest working start date" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSS |
          new_parent   |     X   |
          work_package |     X   |
        TABLE
      end
    end

    context "with the parent being restricted in its ability to be moved and with a due date after parent constraint" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS   | scheduling mode | predecessors
        work_package           |         ] | manual          |
        new_parent_predecessor | X         | manual          |
        new_parent             |           | automatic       | follows new_parent_predecessor with lag 3
      TABLE

      it "schedules the moved work package to start at the parent soonest working start date and keep the due date" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSS   |
          new_parent   |     X..XX |
          work_package |     X..XX |
        TABLE
      end
    end

    context "with the parent being restricted but work package already has both dates set" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS   | scheduling mode | predecessors
        work_package           |        XX | manual          |
        new_parent_predecessor | X         | manual          |
        new_parent             |           | automatic       | follows new_parent_predecessor with lag 3
      TABLE

      it "does not reschedule the moved work package, and sets new parent dates to child dates" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSS   | scheduling mode
          new_parent   |        XX | automatic
          work_package |        XX | manual
        TABLE
      end
    end
  end

  describe "setting an automatically scheduled parent having a predecessor restricting it moving to an earlier date" do
    context "when the work package is automatically scheduled with both dates set " \
            "and start date is before predecessor's due date" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS        | scheduling mode | predecessors
        new_parent_predecessor | XX             | manual          |
        new_parent             |         XXXXXX | automatic       | new_parent_predecessor
        work_package           |  XXX           | automatic       |
      TABLE
      let(:attributes) { { parent: new_parent } }

      it "reschedules the work package and the parent to start ASAP while being limited by the predecessor" do
        expect(subject).to be_success
        expect(work_package.reload.parent).to eq new_parent
        expect(subject.all_results.map(&:subject)).to contain_exactly("work_package", "new_parent")

        # The work_package dates are moved to the parent's soonest start date.
        # The parent dates are the same as its child.
        expect_work_packages(subject.all_results + [new_parent_predecessor], <<~TABLE)
          subject                | MTWTFSS | scheduling mode
          new_parent_predecessor | XX      | manual
          new_parent             |   XXX   | automatic
          work_package           |   XXX   | automatic
        TABLE
      end
    end

    context "when the work package is automatically scheduled with both dates set after predecessor's due date" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS        | scheduling mode | predecessors
        new_parent_predecessor | XX             | manual          |
        new_parent             |         XXXXXX | automatic       | new_parent_predecessor
        work_package           |     XXX        | automatic       |
      TABLE
      let(:attributes) { { parent: new_parent } }

      it "reschedules the work package to start ASAP and keeps the duration; " \
         "the parent is rescheduled like its child" do
        expect(subject).to be_success
        expect(work_package.reload.parent).to eq new_parent
        expect(subject.all_results.map(&:subject)).to contain_exactly("work_package", "new_parent")

        # The work_package dates are moved to the parent's soonest start date.
        # The parent dates are the same as its child.
        expect_work_packages(subject.all_results + [new_parent_predecessor], <<~TABLE)
          subject                | MTWTFSS | scheduling mode
          new_parent_predecessor | XX      | manual
          new_parent             |   XXX   | automatic
          work_package           |   XXX   | automatic
        TABLE
      end
    end

    context "when the work package is automatically scheduled without any dates set" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS        | scheduling mode | predecessors
        new_parent_predecessor | XX             | manual          |
        new_parent             |         XXXXXX | automatic       | new_parent_predecessor
        work_package           |                | automatic       |
      TABLE
      let(:attributes) { { parent: new_parent } }

      it "reschedules the work package to start ASAP and leaves its due date unset; " \
         "the parent is rescheduled to start ASAP too and end on the same day (use child start date as due date)" do
        expect(subject).to be_success
        expect(work_package.reload.parent).to eq new_parent
        expect(subject.all_results.map(&:subject)).to contain_exactly("work_package", "new_parent")

        # The work_package start date is set to the parent's soonest start date.
        # Both parent dates are the same as its child start date.
        expect_work_packages(subject.all_results + [new_parent_predecessor], <<~TABLE)
          subject                | MTWTFSS | scheduling mode
          new_parent_predecessor | XX      | manual
          new_parent             |   X     | automatic
          work_package           |   [     | automatic
        TABLE
      end
    end

    context "when the work package is automatically scheduled with only a due date being set before predecessor's due date" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS        | scheduling mode | predecessors
        new_parent_predecessor | XX             | manual          |
        new_parent             |         XXXXXX | automatic       | new_parent_predecessor
        work_package           | ]              | automatic       |
      TABLE
      let(:attributes) { { parent: new_parent } }

      it "reschedules the work package to start ASAP and changes the due date to be the same as start date; " \
         "the parent is rescheduled like its child" do
        expect(subject).to be_success
        expect(work_package.reload.parent).to eq new_parent
        expect(subject.all_results.map(&:subject)).to contain_exactly("work_package", "new_parent")

        # The work_package start date is set to the parent's soonest start date.
        # The work_package due date is moved to the same as start date (can't start earlier).
        # The parent dates are the same as its child.
        expect_work_packages(subject.all_results + [new_parent_predecessor], <<~TABLE)
          subject                | MTWTFSS | scheduling mode
          new_parent_predecessor | XX      | manual
          new_parent             |   X     | automatic
          work_package           |   X     | automatic
        TABLE
      end
    end

    context "when the work package is automatically scheduled with only a due date being set after predecessor's due date" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS        | scheduling mode | predecessors
        new_parent_predecessor | XX             | manual          |
        new_parent             |         XXXXXX | automatic       | new_parent_predecessor
        work_package           |       ]        | automatic       |
      TABLE
      let(:attributes) { { parent: new_parent } }

      it "reschedules the work package to start ASAP and keeps the due date; " \
         "the parent is rescheduled like its child" do
        expect(subject).to be_success
        expect(work_package.reload.parent).to eq new_parent
        expect(subject.all_results.map(&:subject)).to contain_exactly("work_package", "new_parent")

        # The work_package start date is set to the parent's soonest start date.
        # The work_package due date is kept.
        # The parent dates are the same as its child.
        expect_work_packages(subject.all_results + [new_parent_predecessor], <<~TABLE)
          subject                | MTWTFSS | scheduling mode
          new_parent_predecessor | XX      | manual
          new_parent             |   XXXXX | automatic
          work_package           |   XXXXX | automatic
        TABLE
      end
    end

    context "when the work package is manually scheduled with dates set" do
      let_work_packages(<<~TABLE)
        subject                | MTWTFSS        | scheduling mode | predecessors
        new_parent_predecessor | XX             | manual          |
        new_parent             |         XXXXXX | automatic       | new_parent_predecessor
        work_package           |  XXX           | manual          |
      TABLE
      let(:attributes) { { parent: new_parent } }

      it "sets parent's dates to be the same as the work package despite the predecessor constraints" do
        expect(subject).to be_success
        expect(work_package.reload.parent).to eq new_parent
        expect(subject.all_results.map(&:subject)).to contain_exactly("work_package", "new_parent")

        # The work_package dates are not changed as it's manually scheduled.
        # The parent dates are the same as its child. The follows relation is
        # ignored as children dates always take precedence over relations.
        expect_work_packages(subject.all_results + [new_parent_predecessor], <<~TABLE)
          subject                | MTWTFSS | scheduling mode
          new_parent_predecessor | XX      | manual
          new_parent             |  XXX    | automatic
          work_package           |  XXX    | manual
        TABLE
      end
    end

    context "when the work package is automatically scheduled, has a child and no dates" do
      let_work_packages(<<~TABLE)
        hierarchy              | MTWTFSS        | scheduling mode | predecessors
        new_parent_predecessor | XX             | manual          |
        new_parent             |   XXXXXX       | automatic       | new_parent_predecessor
        work_package           |                | automatic       |
          child                |                | automatic       |
      TABLE
      let(:attributes) { { parent: new_parent } }

      it "sets child start date to be soonest start, " \
         "and parent and work package start and due dates to be child start date" do
        expect(subject).to be_success
        expect(work_package.reload.parent).to eq new_parent
        expect(subject.all_results.map(&:subject)).to contain_exactly("child", "work_package", "new_parent")

        expect_work_packages(subject.all_results + [new_parent_predecessor], <<~TABLE)
          subject                | MTWTFSS | scheduling mode
          new_parent_predecessor | XX      | manual
          new_parent             |   X     | automatic
          work_package           |   X     | automatic
          child                  |   [     | automatic
        TABLE
      end
    end
  end

  context "when updating child dates" do
    context "with a hierarchy of ancestors" do
      let_work_packages(<<~TABLE)
        | hierarchy          | MTWTFSS | scheduling mode
        | grandparent        | XXX     | automatic
        |   parent           | XXX     | automatic
        |     child          | XXX     | automatic
        |       work_package | XXX     | manual
      TABLE

      let(:attributes) { { start_date: _table.tuesday, due_date: _table.friday } }

      it "updates the dates of the whole ancestors hierarchy" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject)).to contain_exactly("work_package", "child", "parent", "grandparent")

        expect_work_packages_after_reload([work_package, child, parent, grandparent], <<~TABLE)
          | subject            | MTWTFSS | scheduling mode
          | grandparent        |  XXXX   | automatic
          |   parent           |  XXXX   | automatic
          |     child          |  XXXX   | automatic
          |       work_package |  XXXX   | manual
        TABLE
      end
    end
  end

  context "when switching scheduling mode to automatic" do
    let(:attributes) { { schedule_manually: false } }

    before do
      set_non_working_week_days("saturday", "sunday")
    end

    context "when the work package has a manually scheduled child " \
            "and a predecessor restricting it moving to an earlier date" do
      let_work_packages(<<~TABLE)
        | hierarchy    | MTWTFSS | scheduling mode | predecessors
        | predecessor  |   XX    | manual          |
        | work_package | XXX     | manual          | predecessor
        |   child      |  X      | manual          |
      TABLE

      it "sets the dates to the child dates, despite the predecessor" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject)).to contain_exactly("work_package")

        expect_work_packages_after_reload([work_package, predecessor, child], <<~TABLE)
          | subject      | MTWTFSS | scheduling mode
          | predecessor  |   XX    | manual
          | work_package |  X      | automatic
          | child        |  X      | manual
        TABLE
      end
    end

    context "when the work package has an automatically scheduled child " \
            "and a predecessor restricting it moving to an earlier date" do
      let_work_packages(<<~TABLE)
        | hierarchy         | MTWTFSS | scheduling mode | predecessors
        | predecessor       |   XX    | manual          |
        | child_predecessor | X       | manual          |
        | work_package      |  XXXX   | manual          | predecessor
        |   child           |  XXX    | automatic       | child_predecessor
      TABLE

      it "sets the dates to start after the predecessor" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject)).to contain_exactly("work_package", "child")

        expect_work_packages_after_reload([predecessor, child_predecessor, work_package, child], <<~TABLE)
          | subject           | MTWTFSS   | scheduling mode
          | predecessor       |   XX      | manual
          | child_predecessor | X         | manual
          | work_package      |     X..XX | automatic
          | child             |     X..XX | automatic
        TABLE
      end
    end

    context "when the work package has an automatically scheduled child, " \
            "a second manually scheduled child and a predecessor restricting it moving to an earlier date" do
      let_work_packages(<<~TABLE)
        | hierarchy    | MTWTFSS | scheduling mode | predecessors
        | predecessor  |   XX    | manual          |
        | work_package |  XXXX   | manual          | predecessor
        |   child1     | X       | manual          |
        |   child2     |  XX     | automatic       | child1
      TABLE

      it "reschedule the automatic child to start after the predecessor and parent dates span over both children dates" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject)).to contain_exactly("work_package", "child2")

        expect_work_packages_after_reload([predecessor, work_package, child1, child2], <<~TABLE)
          | subject           | MTWTFSS  | scheduling mode
          | predecessor       |   XX     | manual
          | work_package      | XXXXX..X | automatic
          | child1            | X        | manual
          | child2            |     X..X | automatic
        TABLE
      end
    end

    context "when the work package has two children with dates" do
      let_work_packages(<<~TABLE)
        | hierarchy    | MTWTFSS | scheduling mode
        | work_package | XXX     | manual
        |   child1     |  X      | manual
        |   child2     |         | manual
        |   child3     |    XX   | manual
      TABLE

      it "sets the parent start and due dates to the children earliest and latest dates" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject)).to contain_exactly("work_package")

        expect_work_packages_after_reload([work_package, child1, child2, child3], <<~TABLE)
          | subject      | MTWTFSS | scheduling mode
          | work_package |  XXXX   | automatic
          | child1       |  X      | manual
          | child2       |         | manual
          | child3       |    XX   | manual
        TABLE
      end
    end

    context "when the work package has two children with start dates only (no due dates)" do
      let_work_packages(<<~TABLE)
        | hierarchy    | MTWTFSS | scheduling mode
        | work_package | XXX     | manual
        |   child1     |  [      | manual
        |   child2     |    [    | manual
      TABLE

      it "sets the parent start and due dates to the children earliest and latest start dates" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject)).to contain_exactly("work_package")

        expect_work_packages_after_reload([work_package, child1, child2], <<~TABLE)
          | subject      | MTWTFSS | scheduling mode
          | work_package |  XXX    | automatic
          | child1       |  [      | manual
          | child2       |    [    | manual
        TABLE
      end
    end

    context "when the work package has two children with due dates only (no start dates)" do
      let_work_packages(<<~TABLE)
        | hierarchy    | MTWTFSS | scheduling mode
        | work_package | XXX     | manual
        |   child1     |  ]      | manual
        |   child2     |     ]   | manual
      TABLE

      it "sets the parent start and due dates to the children earliest and latest due dates" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject)).to contain_exactly("work_package")

        expect_work_packages_after_reload([work_package, child1, child2], <<~TABLE)
          | subject      | MTWTFSS | scheduling mode
          | work_package |  XXXX   | automatic
          | child1       |  ]      | manual
          | child2       |     ]   | manual
        TABLE
      end
    end

    context "when the work package has one child without dates" do
      let_work_packages(<<~TABLE)
        | hierarchy    | MTWTFSS | scheduling mode
        | work_package | XXX     | manual
        |   child      |         | manual
      TABLE

      it "clears the parent dates" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject)).to contain_exactly("work_package")

        expect_work_packages_after_reload([work_package, child], <<~TABLE)
          | subject      | MTWTFSS | scheduling mode
          | work_package |         | automatic
          | child        |         | manual
        TABLE
      end
    end
  end

  context "when setting dates" do
    before do
      set_non_working_week_days("saturday", "sunday")
    end

    context "on a manually scheduled parent having a predecessor" do
      let_work_packages(<<~TABLE)
        | hierarchy    | MTWTFSS | scheduling mode | predecessors
        | predecessor  |   XX    | manual          |
        | work_package | XXX     | manual          | predecessor
        |   child      |  X      | manual          |
      TABLE

      # change due date of work package from Wednesday to Friday
      let(:attributes) { { due_date: work_package.due_date + 2.days } }

      it "sets the dates to the given dates" do
        expect(subject).to be_success

        expect_work_packages_after_reload([work_package, predecessor, child], <<~TABLE)
          | subject      | MTWTFSS | scheduling mode
          | predecessor  |   XX    | manual
          | work_package | XXXXX   | manual
          | child        |  X      | manual
        TABLE
      end
    end
  end

  describe "removing the parent on a work package which precedes its sibling" do
    let_work_packages(<<~TABLE)
      hierarchy              | MTWTFSS     | scheduling mode | predecessors
      parent_work_package    | XXXXXXXXXXX | automatic       |
        work_package         | XXXX        | manual          |
        sibling_work_package |     XXXXXXX | automatic       | work_package
    TABLE

    let(:attributes) { { parent: nil } }

    it "removes the parent and reschedules it" do
      expect(subject)
        .to be_success
      expect(subject.all_results.uniq)
        .to contain_exactly(work_package, parent_work_package)
      expect(work_package.reload.parent).to be_nil

      expect_work_packages(subject.all_results + [sibling_work_package], <<~TABLE)
        subject                | MTWTFSS     | scheduling mode
        # work package itself is unchanged (except for the parent)
        work_package           | XXXX        | manual
        # parent is rescheduled to the sibling's dates
        parent_work_package    |     XXXXXXX | automatic
          sibling_work_package |     XXXXXXX | automatic
      TABLE
    end
  end

  context "when removing the last child of an automatically scheduled parent" do
    let(:attributes) { { parent: nil } }

    describe "when the parent has predecessors and successors" do
      let_work_packages(<<~TABLE)
        hierarchy      | MTWTFSS | scheduling mode | predecessors
        predecessor    | X       | manual          |
        parent         |    XXX  | automatic       | predecessor
          work_package |    XXX  | manual          |
        successor      |       X | automatic       | parent
      TABLE

      it "keeps former parent duration and moves it to its soonest start date, and successors are rescheduled" do
        expect(subject)
          .to be_success
        expect(subject.all_results.pluck(:subject))
          .to contain_exactly("work_package", "parent", "successor")
        expect(work_package.reload.parent).to be_nil

        expect_work_packages(subject.all_results + [predecessor], <<~TABLE)
          subject        | MTWTFSS | scheduling mode |
          predecessor    | X       | manual          |
          parent         |  XXX    | automatic       |
          successor      |     X   | automatic       |

          work_package   |    XXX  | manual          |
        TABLE
      end
    end

    describe "when the parent has no predecessors" do
      let_work_packages(<<~TABLE)
        hierarchy      | MTWTFSS | scheduling mode
        # the child will be removed
        parent         |    XXX  | automatic
          work_package |    XXX  | manual
      TABLE

      it "keeps former parent dates and switch to manual scheduling mode" do
        expect(subject).to be_success
        expect(subject.all_results.pluck(:subject))
          .to contain_exactly("work_package", "parent")
        expect(work_package.reload.parent).to be_nil

        expect_work_packages(subject.all_results, <<~TABLE)
          subject        | MTWTFSS | scheduling mode
          parent         |    XXX  | manual
          work_package   |    XXX  | manual
        TABLE
      end
    end
  end

  describe "replacing the attachments" do
    let!(:old_attachment) do
      create(:attachment, container: work_package)
    end
    let!(:other_users_attachment) do
      create(:attachment, container: nil, author: create(:user))
    end
    let!(:new_attachment) do
      create(:attachment, container: nil, author: user)
    end

    # rubocop:disable RSpec/ExampleLength
    it "reports on invalid attachments and replaces the existent with the new if everything is valid" do
      work_package.attachments.reload

      result = instance.call(attachment_ids: [other_users_attachment.id])

      expect(result)
        .to be_failure

      expect(result.errors.symbols_for(:attachments))
        .to contain_exactly(:does_not_exist)

      expect(work_package.attachments.reload)
        .to contain_exactly(old_attachment)

      expect(other_users_attachment.reload.container)
        .to be_nil

      result = instance.call(attachment_ids: [new_attachment.id])

      expect(result)
        .to be_success

      expect(work_package.attachments.reload)
        .to contain_exactly(new_attachment)

      expect(new_attachment.reload.container)
        .to eql work_package

      expect(Attachment.find_by(id: old_attachment.id))
        .to be_nil

      result = instance.call(attachment_ids: [])

      expect(result)
        .to be_success

      expect(work_package.attachments.reload)
        .to be_empty

      expect(Attachment.all)
        .to contain_exactly(other_users_attachment)
    end
    # rubocop:enable RSpec/ExampleLength
  end

  ##
  # Regression test for #27746
  # - Parent: A
  # - Child1: B
  # - Child2: C
  #
  # Trying to set parent of C to B failed because parent relation is requested before change is saved.
  describe "Changing parent to a new one that has the same parent as the current element (Regression #27746)" do
    shared_let(:admin) { create(:admin) }
    let(:user) { admin }

    let(:project) { create(:project) }
    let!(:wp_a) { create(:work_package) }
    let!(:wp_b) { create(:work_package, parent: wp_a) }
    let!(:wp_c) { create(:work_package, parent: wp_a) }

    let(:work_package) { wp_c }

    let(:attributes) { { parent: wp_b } }

    it "allows changing the parent" do
      expect(subject).to be_success
    end
  end

  describe "Changing type to one that does not have the current status (Regression #27780)" do
    shared_let(:new_type) { create(:type) }

    let(:attributes) { { type: new_type } }

    before do
      project.types << new_type
    end

    context "when the work package does NOT have default status" do
      before do
        work_package.update(status: non_default_status)
      end

      it "assigns the default status" do
        expect(subject).to be_success

        expect(work_package.status).to eq(Status.default)
      end
    end

    context "when the work package does have default status" do
      before do
        create(:workflow, type: new_type, role:, old_status_id: default_status.id)
        work_package.update(status: default_status)
      end

      it "does not change the status" do
        expect(subject).to be_success

        expect(new_type.statuses).to include(default_status)

        expect(work_package)
          .not_to be_saved_change_to_status_id
      end
    end
  end

  describe "removing an invalid parent" do
    # The parent does not have a required custom field set but will need to be touched since
    # the dates, inherited from its children (and then the only remaining child), will have to be updated.
    let!(:parent) do
      create(:work_package,
             type: project.types.first,
             schedule_manually: false,
             start_date: Time.zone.today - 1.day,
             due_date: Time.zone.today + 5.days)
    end
    let!(:custom_field) do
      create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil) do |cf|
        project.types.first.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end
    let!(:sibling) do
      create(:work_package,
             type: project.types.first,
             parent:,
             start_date: Time.zone.today + 1.day,
             due_date: Time.zone.today + 5.days,
             custom_field.attribute_name => 5)
    end
    let!(:attributes) { { parent: nil } }

    before do
      # must use `update` as we are using `shared_let`
      work_package.update(
        start_date: Time.zone.today - 1.day,
        due_date: Time.zone.today + 1.day,
        type: project.types.first,
        parent:,
        custom_field.attribute_name => 8
      )
    end

    it "removes the parent successfully and reschedules the parent" do
      expect(parent.valid?).to be(false)
      expect(subject).to be_success

      expect(work_package.reload.parent).to be_nil

      parent.reload
      expect(parent.valid?).to be(false)
      expect(parent.start_date)
        .to eql(sibling.start_date)
      expect(parent.due_date)
        .to eql(sibling.due_date)
    end
  end

  describe "updating an invalid work package" do
    # The work package does not have a required custom field set.
    let(:mandatory_custom_field) do
      create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil) do |cf|
        project.types.first.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end
    let(:attributes) { { subject: "A new subject" } }

    before do
      work_package.update(
        subject: "The old subject",
        type: project.types.first
      )
      # Creating the mandatory custom field after the work package is already saved.
      # That turns the work package invalid as the mandatory custom field is not set.
      mandatory_custom_field
    end

    it "is a failure and does not save the change" do
      expect(subject).to be_failure

      expect(work_package.reload.subject)
        .to eq "The old subject"
    end
  end

  describe "updating the type (custom field resetting)" do
    let(:new_type) { create(:type) }
    let!(:custom_field_of_current_type) do
      create(:integer_wp_custom_field, default_value: nil) do |cf|
        type.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end
    let!(:custom_field_of_new_type) do
      create(:integer_wp_custom_field, default_value: 8) do |cf|
        new_type.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end
    let(:attributes) do
      { type: new_type }
    end

    before do
      project.types << new_type
      work_package.update(
        type: type,
        custom_field_of_current_type.attribute_name => 5
      )
    end

    it "is success, removes the existing custom field value and sets the default for the new one" do
      expect(subject).to be_success

      expect(work_package.reload.custom_values.pluck(:custom_field_id, :value))
        .to eq [[custom_field_of_new_type.id, "8"]]
    end
  end
end
