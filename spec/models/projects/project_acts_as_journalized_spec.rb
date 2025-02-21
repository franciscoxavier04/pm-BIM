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

RSpec.describe Project, "acts_as_journalized" do
  shared_let(:user) { create(:user) }

  let!(:project) do
    User.execute_as user do
      create(:project,
             description: "project description")
    end
  end

  context "on project creation" do
    it "has one journal entry" do
      expect(Journal.all.count).to eq(1)
      expect(Journal.first.journable).to eq(project)
    end

    it "notes the changes to name" do
      expect(Journal.first.details[:name])
        .to eql([nil, project.name])
    end

    it "notes the changes to description" do
      expect(Journal.first.details[:description])
        .to eql([nil, project.description])
    end

    it "notes the changes to public flag" do
      expect(Journal.first.details[:public])
        .to eql([nil, project.public])
    end

    it "notes the changes to identifier" do
      expect(Journal.first.details[:identifier])
        .to eql([nil, project.identifier])
    end

    it "notes the changes to active flag" do
      expect(Journal.first.details[:active])
        .to eql([nil, project.active])
    end

    it "notes the changes to template flag" do
      expect(Journal.first.details[:templated])
        .to eql([nil, project.templated])
    end

    it "has the timestamp of the project update time for created_at" do
      expect(Journal.first.created_at)
        .to eql(project.reload.updated_at)
    end
  end

  context "when nothing is changed" do
    it { expect { project.save! }.not_to change(Journal, :count) }
  end

  describe "on project update", with_settings: { journal_aggregation_time_minutes: 0 } do
    shared_let(:parent_project) { create(:project) }

    before do
      project.name = "changed project name"
      project.description = "changed project description"
      project.public = !project.public
      project.parent = parent_project
      project.identifier = "changed-identifier"
      project.active = !project.active
      project.templated = !project.templated

      project.save!
    end

    context "for last created journal" do
      it "has the timestamp of the project update time for created_at" do
        expect(project.last_journal.created_at)
          .to eql(project.reload.updated_at)
      end

      it "contains last changes" do
        %i[name description public parent_id identifier active templated].each do |prop|
          expect(project.last_journal.details).to have_key(prop.to_s), "Missing change for #{prop}"
        end
      end
    end
  end

  describe "custom values", with_settings: { journal_aggregation_time_minutes: 0 } do
    shared_let(:custom_field) { create(:string_project_custom_field) }
    let(:custom_value) do
      build(:custom_value,
            value: "some string value for project custom field",
            custom_field:)
    end
    let(:custom_field_key) { "custom_fields_#{custom_field.id}" }

    shared_context "for project with new custom value" do
      before do
        project.update(custom_values: [custom_value])
      end
    end

    shared_examples "contains no change for disabled custom field" do
      before do
        project.project_custom_field_project_mappings.where(custom_field_id: custom_field.id).delete_all
      end

      it "contains no change for the disabled custom field" do
        expect(project.last_journal.details).not_to have_key(custom_field_key)
      end
    end

    context "for new custom value" do
      include_context "for project with new custom value"

      it "contains the new custom value change" do
        expect(project.last_journal.details)
          .to include(custom_field_key => [nil, custom_value.value])
      end

      it_behaves_like "contains no change for disabled custom field"
    end

    context "for updated custom value" do
      include_context "for project with new custom value"

      let(:modified_custom_value) do
        build(:custom_value,
              value: "some modified value for project custom field",
              custom_field:)
      end

      before do
        project.update(custom_values: [modified_custom_value])
      end

      it "contains the change from previous value to updated value" do
        expect(project.last_journal.details)
          .to include(custom_field_key => [custom_value.value, modified_custom_value.value])
      end

      it_behaves_like "contains no change for disabled custom field"
    end

    context "when project saved without any changes" do
      include_context "for project with new custom value"

      let(:unmodified_custom_value) do
        build(:custom_value,
              value: custom_value.value,
              custom_field:)
      end

      before do
        project.custom_values = [unmodified_custom_value]
      end

      it { expect { project.save! }.not_to change(Journal, :count) }
    end

    context "when custom value removed" do
      include_context "for project with new custom value"

      before do
        project.update(custom_values: [])
      end

      it "contains the change from previous value to nil" do
        expect(project.last_journal.details)
          .to include(custom_field_key => [custom_value.value, nil])
      end

      it_behaves_like "contains no change for disabled custom field"
    end
  end

  describe "life cycle steps", with_settings: { journal_aggregation_time_minutes: 0 } do
    describe "activation/deactivation" do
      let!(:stage) { build(:project_stage, project:, active: true, start_date: nil, end_date: nil) }
      let!(:gate) { build(:project_gate, project:, active: true, date: nil) }

      context "when adding activated" do
        it "contains the change" do
          project.update!(life_cycle_steps: [stage, gate])

          expect(project.last_journal.details).to eq(
            {
              "project_life_cycle_step_#{stage.id}_active" => [nil, true],
              "project_life_cycle_step_#{gate.id}_active" => [nil, true]
            }
          )
        end
      end

      context "when deactivating" do
        before do
          project.update!(life_cycle_steps: [stage, gate])
        end

        it "contains the change" do
          stage.update(active: false)
          gate.update(active: false)
          project.save!

          expect(project.last_journal.details).to eq(
            {
              "project_life_cycle_step_#{stage.id}_active" => [true, false],
              "project_life_cycle_step_#{gate.id}_active" => [true, false]
            }
          )
        end
      end
    end

    describe "modifying dates" do
      let!(:stage) { create(:project_stage, project:, start_date: original_stage_start, end_date: original_stage_end) }
      let!(:gate) { create(:project_gate, project:, date: original_gate_date) }

      before do
        project.save!
      end

      context "when setting dates" do
        let(:original_stage_start) { nil }
        let(:original_stage_end) { nil }
        let(:original_gate_date) { nil }

        it "contains the change" do
          stage.update(start_date: Date.new(2025, 1, 30), end_date: Date.new(2025, 1, 31))
          gate.update(date: Date.new(2025, 2, 1))
          project.save!

          expect(project.last_journal.details).to match(
            {
              "project_life_cycle_step_#{stage.id}_date_range" => [
                nil,
                Date.new(2025, 1, 30)..Date.new(2025, 1, 31)
              ],
              "project_life_cycle_step_#{gate.id}_date_range" => [
                nil,
                Date.new(2025, 2, 1)..
              ]
            }
          )
        end
      end

      context "when changing dates" do
        let(:original_stage_start) { Date.new(2025, 1, 30) }
        let(:original_stage_end) { Date.new(2025, 1, 31) }
        let(:original_gate_date) { Date.new(2025, 2, 1) }

        it "contains the change" do
          stage.update(start_date: Date.new(2025, 1, 30), end_date: Date.new(2025, 2, 1))
          gate.update(date: Date.new(2025, 2, 3))
          project.save!

          expect(project.last_journal.details).to match(
            {
              "project_life_cycle_step_#{stage.id}_date_range" => [
                Date.new(2025, 1, 30)..Date.new(2025, 1, 31),
                Date.new(2025, 1, 30)..Date.new(2025, 2, 1)
              ],
              "project_life_cycle_step_#{gate.id}_date_range" => [
                Date.new(2025, 2, 1)..,
                Date.new(2025, 2, 3)..
              ]
            }
          )
        end
      end

      context "when removing dates" do
        let(:original_stage_start) { Date.new(2025, 1, 30) }
        let(:original_stage_end) { Date.new(2025, 1, 31) }
        let(:original_gate_date) { Date.new(2025, 2, 1) }

        it "contains the change" do
          stage.update(start_date: nil, end_date: nil)
          gate.update(date: nil)
          project.save!

          expect(project.last_journal.details).to match(
            {
              "project_life_cycle_step_#{stage.id}_date_range" => [
                Date.new(2025, 1, 30)..Date.new(2025, 1, 31),
                nil
              ],
              "project_life_cycle_step_#{gate.id}_date_range" => [
                Date.new(2025, 2, 1)..,
                nil
              ]
            }
          )
        end
      end
    end

    describe "combined" do
      let!(:stage) do
        build(:project_stage, project:, active: true, start_date: Date.new(2025, 1, 30), end_date: Date.new(2025, 1, 31))
      end
      let!(:gate) { build(:project_gate, project:, active: true, date: Date.new(2025, 2, 1)) }

      it "contains both changes" do
        project.update!(life_cycle_steps: [stage, gate])

        expect(project.last_journal.details).to match(
          {
            "project_life_cycle_step_#{stage.id}_active" => [nil, true],
            "project_life_cycle_step_#{stage.id}_date_range" => [
              nil,
              Date.new(2025, 1, 30)..Date.new(2025, 1, 31)
            ],
            "project_life_cycle_step_#{gate.id}_active" => [nil, true],
            "project_life_cycle_step_#{gate.id}_date_range" => [
              nil,
              Date.new(2025, 2, 1)..
            ]
          }
        )
      end
    end

    describe "when creating without touching project" do
      let!(:project) do
        Timecop.freeze(1.year.ago) do
          create(:project)
        end
      end

      before do
        create(:project_gate, project_id: project.id)
      end

      it "fails when using save_journals" do
        expect do
          project.save_journals
        end.to raise_error(ActiveRecord::StatementInvalid)
      end

      it "succeeds when using touch_and_save_journals" do
        expect do
          project.touch_and_save_journals
        end.to change { project.journals.count }.from(1).to(2)
      end
    end
  end

  describe "on project deletion" do
    shared_let(:custom_field) { create(:string_project_custom_field) }
    let(:custom_value) do
      build(:custom_value,
            value: "some string value for project custom field",
            custom_field:)
    end
    let!(:project) do
      User.execute_as user do
        create(:project, custom_values: [custom_value])
      end
    end
    let!(:journal) { project.last_journal }
    let!(:customizable_journals) { journal.customizable_journals }

    before do
      project.destroy
    end

    it "removes the journal" do
      expect(Journal.find_by(id: journal.id))
        .to be_nil
    end

    it "removes the journal data" do
      expect(Journal::ProjectJournal.find_by(id: journal.data_id))
        .to be_nil
    end

    it "removes the customizable journals" do
      expect(Journal::CustomizableJournal.find_by(id: customizable_journals.map(&:id)))
        .to be_nil
    end
  end
end
