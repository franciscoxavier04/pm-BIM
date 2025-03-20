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

RSpec.describe OpenProject::JournalFormatter::ProjectLifeCycleStepDates do
  describe "#render" do
    let(:key) { "project_life_cycle_step_#{id}_date_range" }
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

      context "when date added" do
        let(:values) { [nil, date(28)..] }
        let(:plain_result) { "The Gate set to 01/28/2025" }
        let(:html_result) { "<strong>The Gate</strong> set to 01/28/2025" }

        include_examples "test result"
      end

      context "when date changed" do
        let(:values) { [date(28).., date(29)..] }
        let(:plain_result) { "The Gate changed from 01/28/2025 to 01/29/2025" }
        let(:html_result) { "<strong>The Gate</strong> changed from 01/28/2025 to 01/29/2025" }

        include_examples "test result"
      end

      context "when date removed" do
        let(:values) { [date(28).., nil] }
        let(:plain_result) { "The Gate date deleted 01/28/2025" }
        let(:html_result) { "<strong>The Gate</strong> date deleted <del>01/28/2025</del>" }

        include_examples "test result"
      end

      context "when both dates absent" do
        let(:values) { [nil, nil] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end

      context "when gate was deleted" do
        let(:step) { nil }
        let(:id) { "42" }
        let(:values) { [date(28).., date(29)..] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end

    describe "for stage changes" do
      let(:step) { build_stubbed(:project_stage, definition:) }
      let(:definition) { build_stubbed(:project_stage_definition, name: "The Stage") }

      context "when date range added" do
        let(:values) { [nil, date(28)..date(29)] }
        let(:plain_result) { "The Stage set to 01/28/2025 - 01/29/2025" }
        let(:html_result) { "<strong>The Stage</strong> set to 01/28/2025 - 01/29/2025" }

        include_examples "test result"
      end

      context "when date range changed" do
        let(:values) { [date(28)..date(29), date(28)..date(30)] }
        let(:plain_result) { "The Stage changed from 01/28/2025 - 01/29/2025 to 01/28/2025 - 01/30/2025" }
        let(:html_result) { "<strong>The Stage</strong> changed from 01/28/2025 - 01/29/2025 to 01/28/2025 - 01/30/2025" }

        include_examples "test result"
      end

      context "when date range removed" do
        let(:values) { [date(28)..date(29), nil] }
        let(:plain_result) { "The Stage date deleted 01/28/2025 - 01/29/2025" }
        let(:html_result) { "<strong>The Stage</strong> date deleted <del>01/28/2025 - 01/29/2025</del>" }

        include_examples "test result"
      end

      context "when both date ranges absent" do
        let(:values) { [nil, nil] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end

      context "when stage was deleted" do
        let(:step) { nil }
        let(:id) { "42" }
        let(:values) { [date(28)..date(29), date(28)..date(30)] }
        let(:plain_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end
  end
end
