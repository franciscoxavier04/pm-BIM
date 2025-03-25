# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require Rails.root.join("db/migrate/20250324161229_merge_lifecycle_steps.rb")

RSpec.describe MergeLifecycleSteps, type: :model do
  shared_let(:colors) { create_list(:color, 3) }
  shared_let(:project) { create(:project) }
  shared_let(:project_journal) { project.journals.first }

  before do
    ActiveRecord::Migration.suppress_messages do
      described_class.new.migrate(:down)
    end

    ActiveRecord::Base.connection.execute(
      <<-SQL.squish
      INSERT INTO project_life_cycle_step_definitions (id, type, name, position, color_id, created_at, updated_at)
      VALUES
        (1, 'Project::StageDefinition', 'Initiating', 1, #{colors.first.id}, NOW(), NOW()),
        (2, 'Project::GateDefinition', 'Ready for Executing', 2, #{colors.second.id}, NOW(), NOW()),
        (3, 'Project::StageDefinition', 'Executing', 3, #{colors.third.id}, NOW(), NOW())
    SQL
    )

    ActiveRecord::Base.connection.execute(
      <<-SQL.squish
        INSERT INTO project_life_cycle_steps (id, type, start_date, end_date, active, project_id, definition_id, created_at, updated_at)
        VALUES
          (1, 'Project::Stage', '#{Time.zone.today}', '#{Time.zone.today + 5.days}', true, #{project.id}, 1, NOW(), NOW()),
          (2, 'Project::Gate', '#{Time.zone.today + 5.days}', '#{Time.zone.today + 5.days}', true, #{project.id}, 2, NOW(), NOW()),
          (3, 'Project::Stage', '#{Time.zone.today + 6.days}', '#{Time.zone.today + 15.days}', false, #{project.id}, 3, NOW(), NOW())
      SQL
    )

    ActiveRecord::Base.connection.execute(
      <<-SQL.squish
        INSERT INTO project_life_cycle_step_journals (journal_id, life_cycle_step_id, start_date, end_date, active)
        VALUES
          (#{project_journal.id}, 1, '#{Time.zone.today}', '#{Time.zone.today + 5.days}', true),
          (#{project_journal.id}, 2, '#{Time.zone.today + 5.days}', '#{Time.zone.today + 5.days}', true),
          (#{project_journal.id}, 3, '#{Time.zone.today + 6.days}', '#{Time.zone.today + 15.days}', false)
      SQL
    )

    # Need to be after the life cycle steps are created
    query_without_lifecycle
    query_with_lifecycle_any_filter
    query_with_lifecycle_order
    query_with_lifecycle_select
    query_with_lifecycle_gate_filter
    query_with_lifecycle_stage_filter
  end

  let(:query_without_lifecycle) { create(:project_query) }
  let(:query_with_lifecycle_select) { create(:project_query, select: %w[name lcsd_2 project_status]) }
  let(:query_with_lifecycle_order) do
    create(:project_query).tap do |q|
      q.order("lcsd_3" => "desc")
      q.save(validate: false)
    end
  end
  let(:query_with_lifecycle_any_filter) do
    create(:project_query).tap do |q|
      q.where("lcsd_any", "t", [])
      q.save
    end
  end
  let(:query_with_lifecycle_gate_filter) do
    create(:project_query).tap do |q|
      q.where("lcsd_gate_2", "t", [])
      q.save
    end
  end
  let(:query_with_lifecycle_stage_filter) do
    create(:project_query).tap do |q|
      q.where("lcsd_stage_1", "t", [])
      q.save
    end
  end

  subject { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  it "removes all project life cycle steps and renames the table" do
    expect(ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM project_life_cycle_steps")["count"])
      .to eq 3

    subject

    expect(ActiveRecord::Base.connection.table_exists?("project_life_cycle_steps"))
      .to be false
    expect(ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM project_phases")["count"])
      .to eq 0
  end

  it "removes all project life cycle step definitions and renames the table" do
    expect(ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM project_life_cycle_step_definitions")["count"])
      .to eq 3

    subject

    expect(ActiveRecord::Base.connection.table_exists?("project_life_cycle_step_definitions"))
      .to be false
    expect(ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM project_phase_definitions")["count"])
      .to eq 0
  end

  it "removes all project life cycle step journal entries but leaves the journal - the step journal table is removed" do
    expect(ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM project_life_cycle_step_journals")["count"])
      .to eq 3

    subject

    expect(ActiveRecord::Base.connection.table_exists?("project_life_cycle_step_journals"))
      .to be false
    expect(ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM project_phase_journals")["count"])
      .to eq 0
    expect(Journal)
      .to exist(id: project_journal.id)
  end

  it "removes all queries with life cycle references in order, select or filters" do
    expect { subject }
      .to(change(ProjectQuery, :count).from(6).to(1))

    expect(ProjectQuery)
      .to exist(id: query_without_lifecycle.id)
  end
end
