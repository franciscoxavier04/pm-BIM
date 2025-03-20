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

RSpec.describe OpenProject::JournalFormatter::ProjectLifeCycleStepActive do
  describe "#render" do
    let(:key) { "project_life_cycle_step_#{id}_active" }
    let(:id) { step.id.to_s }

    subject(:result) { described_class.new(nil).render(key, values, html:) }

    before do
      allow(Project::LifeCycleStep).to receive(:find_by).with(id:).and_return(step)
    end

    def date(day) = Date.new(2025, 1, day)

    shared_examples "test result" do
      context "with html output" do
        let(:html) { true }

        it { is_expected.to eq html_result }
      end

      context "with plain output" do
        let(:html) { false }

        it { is_expected.to eq plain_result }
      end
    end

    describe "for gate changes" do
      let(:step) { build_stubbed(:project_gate, definition:) }
      let(:definition) { build_stubbed(:project_gate_definition, name: "The Gate") }

      context "when activated" do
        let(:values) { [false, true] }
        let(:plain_result) { "The Gate activated" }
        let(:html_result) { "<strong>The Gate</strong> activated" }

        include_examples "test result"
      end

      context "when deactivated" do
        let(:values) { [true, false] }
        let(:plain_result) { "The Gate deactivated" }
        let(:html_result) { "<strong>The Gate</strong> deactivated" }

        include_examples "test result"
      end

      context "when no change between truthy values" do
        let(:values) { [true, true] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end

      context "when no change between falsey values" do
        let(:values) { [nil, false] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end

      context "when gate was deleted" do
        let(:step) { nil }
        let(:id) { "42" }
        let(:values) { [true, false] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end

    describe "for stage changes" do
      let(:step) { build_stubbed(:project_stage, definition:) }
      let(:definition) { build_stubbed(:project_stage_definition, name: "The Stage") }

      context "when activated" do
        let(:values) { [false, true] }
        let(:plain_result) { "The Stage activated" }
        let(:html_result) { "<strong>The Stage</strong> activated" }

        include_examples "test result"
      end

      context "when deactivated" do
        let(:values) { [true, false] }
        let(:plain_result) { "The Stage deactivated" }
        let(:html_result) { "<strong>The Stage</strong> deactivated" }

        include_examples "test result"
      end

      context "when no change between truthy values" do
        let(:values) { [true, true] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end

      context "when no change between falsey values" do
        let(:values) { [nil, false] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end

      context "when stage was deleted" do
        let(:step) { nil }
        let(:id) { "42" }
        let(:values) { [true, false] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end
  end
end
