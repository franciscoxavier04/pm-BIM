# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "spec_helper"

RSpec.describe ProjectQuery, "results of 'Any stage or gate' filter" do
  let(:instance) { described_class.new }

  shared_let(:view_role) { create(:project_role, permissions: %i[view_project_stages_and_gates]) }

  shared_let(:stage_start_date) { Date.parse("2025-02-07") }
  shared_let(:stage_end_date) { Date.parse("2025-02-17") }
  shared_let(:project_with_stage) do
    create(:project, name: "Project with stage") do |project|
      create(:project_stage, project:, start_date: stage_start_date, end_date: stage_end_date)
    end
  end

  shared_let(:gate_date) { Date.parse("2025-02-22") }
  shared_let(:project_with_gate) do
    create(:project, name: "Project with gate") do |project|
      create(:project_gate, project:, date: gate_date)
    end
  end
  shared_let(:project_without_step) { create(:project, name: "Project without step") }

  shared_let(:user) do
    create(:user, member_with_permissions: {
             project_with_stage => %i[view_project_stages_and_gates],
             project_with_gate => %i[view_project_stages_and_gates],
             project_without_step => %i[view_project_stages_and_gates]
           })
  end

  current_user { user }

  # rubocop:disable RSpec/ScatteredSetup
  def self.remove_gate
    before do
      Project::LifeCycleStep.where(type: Project::Gate.name).destroy_all
    end
  end

  def self.remove_stage
    before do
      Project::LifeCycleStep.where(type: Project::Stage.name).destroy_all
    end
  end

  def self.disable_stage
    before do
      Project::LifeCycleStep.where(type: Project::Stage.name).update_all(active: false)
    end
  end

  def self.disable_gate
    before do
      Project::LifeCycleStep.where(type: Project::Gate.name).update_all(active: false)
    end
  end

  def self.remove_permissions
    before do
      # We keep the permission within the project without steps so that the filter itself is available
      # but we check that the filter does not return values.
      RolePermission
        .where(role_id: Role.joins(:member_roles)
                            .where(member_roles: { member_id: Member.where(project: [project_with_stage,
                                                                                     project_with_gate]) }))
        .where(permission: :view_project_stages_and_gates)
        .destroy_all
    end
  end
  # rubocop:enable RSpec/ScatteredSetup

  context "with a =d (on) operator" do
    before do
      instance.where("any_stage_or_gate", "=d", values)
    end

    context "when filtering in the middle of the stage" do
      let(:values) { [(stage_start_date + ((stage_end_date - stage_start_date) / 2)).to_s] }

      it "returns the project whose stage is covering an interval including the date" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when filtering on the first day of the stage" do
      let(:values) { [stage_start_date.to_s] }

      it "returns the project whose stage begins on that date" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when filtering on the last day of the stage" do
      let(:values) { [stage_end_date.to_s] }

      it "returns the project whose stage ends on that date" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when filtering before the stage" do
      let(:values) { [(stage_start_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering after the stage" do
      let(:values) { [(stage_end_date + 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering on the day of the gate" do
      let(:values) { [gate_date.to_s] }

      it "returns the project whose gate is on the date of the value" do
        expect(instance.results).to contain_exactly(project_with_gate)
      end
    end

    context "when filtering before the gate" do
      let(:values) { [(gate_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering after the gate" do
      let(:values) { [(gate_date + 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering in the middle of the stage but with the stage being inactive" do
      let(:values) { [(stage_start_date + ((stage_end_date - stage_start_date) / 2)).to_s] }

      disable_stage

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering on the day of the gate but with the gate being inactive" do
      let(:values) { [gate_date.to_s] }

      disable_gate

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering in the middle of the stage but without permissions" do
      let(:values) { [(stage_start_date + ((stage_end_date - stage_start_date) / 2)).to_s] }

      remove_permissions

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering on the day of the gate but without permissions" do
      let(:values) { [gate_date.to_s] }

      remove_permissions

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end
  end

  context "with a t (today) operator" do
    before do
      instance.where("any_stage_or_gate", "t", [])
    end

    context "when being in the middle of the stage" do
      it "returns the project whose stage is currently running" do
        Timecop.travel((stage_start_date + (stage_end_date - stage_start_date)).noon) do
          expect(instance.results).to contain_exactly(project_with_stage)
        end
      end
    end

    context "when being on the first day of the stage" do
      it "returns the project whose stage begins on that date" do
        Timecop.travel(stage_start_date.noon) do
          expect(instance.results).to contain_exactly(project_with_stage)
        end
      end
    end

    context "when being on the last day of the stage" do
      it "returns the project whose stage begins on that date" do
        Timecop.travel(stage_end_date.noon) do
          expect(instance.results).to contain_exactly(project_with_stage)
        end
      end
    end

    context "when being before the stage" do
      it "returns no project" do
        Timecop.travel(stage_start_date.noon - 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being after the stage" do
      it "returns no project" do
        Timecop.travel(stage_end_date.noon + 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on the day of the gate" do
      it "returns the project whose gate is on the date of the value" do
        Timecop.travel(gate_date.noon) do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end
    end

    context "when being before the day of the gate" do
      it "returns no project" do
        Timecop.travel(gate_date.noon - 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being after the day of the gate" do
      it "returns no project" do
        Timecop.travel(gate_date.noon + 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the stage but with the stage being disabled" do
      disable_stage

      it "returns no project" do
        Timecop.travel((stage_start_date + (stage_end_date - stage_start_date)).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on the day of the gate but with the stage being disabled" do
      disable_gate

      it "returns no project" do
        Timecop.travel(gate_date.noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the stage but without permissions" do
      remove_permissions

      it "returns no project" do
        Timecop.travel((stage_start_date + (stage_end_date - stage_start_date)).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on the day of the gate but without permissions" do
      remove_permissions

      it "returns no project" do
        Timecop.travel(gate_date.noon) do
          expect(instance.results).to be_empty
        end
      end
    end
  end

  # TODO: get the start of week setting in

  context "with a w (this week) operator" do
    before do
      instance.where("any_stage_or_gate", "w", [])
    end

    context "when being in the middle of the stage" do
      it "returns the project whose stage is currently running" do
        Timecop.travel((stage_start_date + 3.days).noon) do
          expect(instance.results).to contain_exactly(project_with_stage)
        end
      end
    end

    context "when the current week overlaps the beginning of the stage" do
      it "returns the project whose stage begins within the week" do
        Timecop.travel((stage_start_date - 1.day).noon) do
          expect(instance.results).to contain_exactly(project_with_stage)
        end
      end
    end

    context "when the current week overlaps the end of the stage" do
      # Would otherwise interfere with the spec
      remove_gate

      it "returns the project whose stage begins within the week" do
        Timecop.travel(stage_end_date.noon) do
          expect(instance.results).to contain_exactly(project_with_stage)
        end
      end
    end

    context "when being before the stage" do
      it "returns no project" do
        Timecop.travel(stage_start_date.noon - 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being after the stage" do
      it "returns no project" do
        Timecop.travel(stage_end_date.noon + 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being a day before the gate" do
      # Would otherwise interfere with the spec
      remove_stage

      it "returns the project whose gate is within the current week" do
        Timecop.travel(gate_date.noon - 1.day) do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end
    end

    context "when being a day after the gate" do
      # Would otherwise interfere with the spec
      remove_stage

      it "returns the project whose gate is within the current week" do
        Timecop.travel(gate_date.noon + 1.day) do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end
    end

    context "when being in the week before the day of the gate" do
      # Would otherwise interfere with the spec
      remove_stage

      it "returns no project" do
        Timecop.travel(gate_date.noon - 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the week after the day of the gate" do
      it "returns no project" do
        Timecop.travel(gate_date.noon + 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the stage but with the stage disabled" do
      disable_stage

      it "returns no project" do
        Timecop.travel((stage_start_date + 3.days).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being a day before the gate but with the gate disabled" do
      # Would otherwise interfere with the spec
      remove_stage
      disable_gate

      it "returns no project" do
        Timecop.travel(gate_date.noon - 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the stage but without permissions" do
      remove_permissions

      it "returns no project" do
        Timecop.travel((stage_start_date + 3.days).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being a day before the gate but without permissions" do
      # Would otherwise interfere with the spec
      remove_stage
      remove_permissions

      it "returns no project" do
        Timecop.travel(gate_date.noon - 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end
  end

  context "with a <>d (between) operator" do
    before do
      instance.where("any_stage_or_gate", "<>d", values)
    end

    context "when encompassing the stage completely" do
      let(:values) { [(stage_start_date - 1.day).to_s, (stage_end_date + 1.day).to_s] }

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when encompassing the stage precisely" do
      let(:values) { [stage_start_date.to_s, stage_end_date.to_s] }

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when the values overlap the stage's start date but not the end date" do
      let(:values) { [(stage_start_date - 1.day).to_s, (stage_end_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the values overlap the stage's end date but not the start date" do
      let(:values) { [(stage_start_date + 1.day).to_s, stage_end_date.to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the values are between the start and the end date of the stage" do
      let(:values) { [(stage_start_date + 1.day).to_s, (stage_end_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when only the lower value is provided and that one is before the stage's start date" do
      let(:values) { [(stage_start_date - 1.day).to_s, ""] }

      # Interferes at it would otherwise be found as well
      remove_gate

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when only the lower value is provided and that one is on the stage's start date" do
      let(:values) { [stage_start_date.to_s, ""] }

      # Interferes at it would otherwise be found as well
      remove_gate

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when only the lower value is provided and that one after the stage's start date" do
      let(:values) { [(stage_start_date + 1.day).to_s, ""] }

      # Interferes at it would otherwise be found as well
      remove_gate

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when only the upper value is provided and that one is after the stage's end date" do
      let(:values) { ["", (stage_end_date + 1.day).to_s] }

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when encompassing the gate completely" do
      let(:values) { [(gate_date - 1.day).to_s, (gate_date + 1.day).to_s] }

      it "returns the project with the gate" do
        expect(instance.results).to contain_exactly(project_with_gate)
      end
    end

    context "when encompassing the gate precisely" do
      let(:values) { [gate_date.to_s, gate_date.to_s] }

      it "returns the project with the gate" do
        expect(instance.results).to contain_exactly(project_with_gate)
      end
    end

    context "when only the lower value is provided and that one is before the gate's date" do
      let(:values) { [(gate_date - 1.day).to_s, ""] }

      it "returns the project with the gate" do
        expect(instance.results).to contain_exactly(project_with_gate)
      end
    end

    context "when only the upper value is provided and that one is after the gate's date" do
      let(:values) { ["", (gate_date + 1.day).to_s] }

      # Interferes at it would otherwise be found as well
      remove_stage

      it "returns the project with the gate" do
        expect(instance.results).to contain_exactly(project_with_gate)
      end
    end

    context "when only the upper value is provided and that one is on the gate's date" do
      let(:values) { ["", gate_date.to_s] }

      # Interferes at it would otherwise be found as well
      remove_stage

      it "returns the project with the gate" do
        expect(instance.results).to contain_exactly(project_with_gate)
      end
    end

    context "when only the upper value is provided and that one is before the gate's date" do
      let(:values) { ["", (gate_date - 1.day).to_s] }

      # Interferes at it would otherwise be found as well
      remove_stage

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when encompassing the stage completely but with the stage disabled" do
      let(:values) { [(stage_start_date - 1.day).to_s, (stage_end_date + 1.day).to_s] }

      disable_stage

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when encompassing the gate precisely but with the gate disabled" do
      let(:values) { [gate_date.to_s, gate_date.to_s] }

      disable_gate

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when encompassing the stage completely but without permissions" do
      let(:values) { [(stage_start_date - 1.day).to_s, (stage_end_date + 1.day).to_s] }

      remove_permissions

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when encompassing the gate precisely but without permissions" do
      let(:values) { [gate_date.to_s, gate_date.to_s] }

      remove_permissions

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end
  end
end
