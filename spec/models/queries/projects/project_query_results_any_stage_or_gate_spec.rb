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

  shared_let(:stage_start_date) { Time.zone.today - 5.days }
  shared_let(:stage_end_date) { Time.zone.today + 5.days }
  shared_let(:project_with_stage) do
    create(:project, name: "Project with stage") do |project|
      create(:project_stage, project:, start_date: stage_start_date, end_date: stage_end_date)
    end
  end

  shared_let(:gate_date) { Time.zone.today + 10.days }
  shared_let(:project_with_gate) do
    create(:project, name: "Project with gate") do |project|
      create(:project_gate, project:, date: gate_date)
    end
  end

  shared_let(:user) do
    create(:user, member_with_permissions: {
             project_with_stage => %i[view_project_stages_and_gates],
             project_with_gate => %i[view_project_stages_and_gates]
           })
  end

  current_user { user }

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
  end

  # TODO: check active state

  context "with a t (today) operator" do
    before do
      instance.where("any_stage_or_gate", "t", [])
    end

    context "when being in the middle of the stage" do
      it "returns the project whose stage is currently running" do
        expect(instance.results).to contain_exactly(project_with_stage)
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
      before do
        Project::LifeCycleStep.where(type: Project::Gate.name).destroy_all
      end

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when only the lower value is provided and that one is on the stage's start date" do
      let(:values) { [stage_start_date.to_s, ""] }

      # Interferes at it would otherwise be found as well
      before do
        Project::LifeCycleStep.where(type: Project::Gate.name).destroy_all
      end

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_stage)
      end
    end

    context "when only the lower value is provided and that one after the stage's start date" do
      let(:values) { [(stage_start_date + 1.day).to_s, ""] }

      # Interferes at it would otherwise be found as well
      before do
        Project::LifeCycleStep.where(type: Project::Gate.name).destroy_all
      end

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
      before do
        Project::LifeCycleStep.where(type: Project::Stage.name).destroy_all
      end

      it "returns the project with the gate" do
        expect(instance.results).to contain_exactly(project_with_gate)
      end
    end

    context "when only the upper value is provided and that one is on the gate's date" do
      let(:values) { ["", gate_date.to_s] }

      # Interferes at it would otherwise be found as well
      before do
        Project::LifeCycleStep.where(type: Project::Stage.name).destroy_all
      end

      it "returns the project with the gate" do
        expect(instance.results).to contain_exactly(project_with_gate)
      end
    end

    context "when only the upper value is provided and that one is before the gate's date" do
      let(:values) { ["", (gate_date - 1.day).to_s] }

      # Interferes at it would otherwise be found as well
      before do
        Project::LifeCycleStep.where(type: Project::Stage.name).destroy_all
      end

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end
  end
end
