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

require "rails_helper"

RSpec.describe Project::Phase do
  it "can be instantiated" do
    expect { described_class.new }.not_to raise_error(NotImplementedError)
  end

  it { is_expected.to have_readonly_attribute(:definition_id) }

  describe "associations" do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:definition).required }
    it { is_expected.to have_many(:work_packages) }
  end

  describe ".visible" do
    let(:project) { create(:project) }
    let(:development_project) { create(:project) }
    let(:user) do
      create(:user,
             member_with_permissions:
             { project => %i(view_project view_project_phases),
               development_project => %i(view_project) })
    end

    let!(:phase) { create(:project_phase, project:) }
    let!(:phase_dev) { create(:project_phase, project: development_project) }
    let!(:inactive_phase) { create(:project_phase, project: development_project, active: false) }

    it "returns active phases where the user has a view_project_phases permission" do
      expect(described_class.visible(user)).to contain_exactly(phase)
    end
  end

  describe "#not_set?" do
    it "returns true if start_date or finish_date is blank" do
      expect(subject.not_set?).to be(true)
    end

    it "returns false if both start_date and finish_date are present" do
      subject.start_date = Time.zone.today
      subject.finish_date = Date.tomorrow
      expect(subject.not_set?).to be(false)
    end
  end

  describe "#date_range=" do
    it "splits a valid date range string into start_date and finish_date" do
      subject.date_range = "2024-11-26 - 2024-11-27"
      expect(subject.start_date).to eq(Date.parse("2024-11-26"))
      expect(subject.finish_date).to eq(Date.parse("2024-11-27"))
    end

    it "sets finish_date to start_date if a single date is provided" do
      subject.date_range = "2024-11-26"
      expect(subject.start_date).to eq(Date.parse("2024-11-26"))
      expect(subject.finish_date).to eq(Date.parse("2024-11-26"))
    end
  end

  describe "#validate_date_range" do
    it "is valid when both dates are blank" do
      stage = build(:project_phase, start_date: nil, finish_date: nil)
      expect(stage).to be_valid
    end

    it "adds error if start_date is after finish_date" do
      subject.start_date = Date.tomorrow
      subject.finish_date = Time.zone.today
      expect(subject).not_to be_valid
      expect(subject.errors.symbols_for(:date_range)).to include(:start_date_must_be_before_finish_date)
    end

    it "does not add errors if start_date is before or equal to finish_date" do
      subject.start_date = Time.zone.today
      subject.finish_date = Time.zone.today
      expect(subject).not_to be_valid
      expect(subject.errors[:date_range]).to be_empty
    end
  end

  describe "#working_days_count" do
    it "returns nil if not_set? is true" do
      allow(Day).to receive(:working)

      subject.start_date = nil
      subject.finish_date = nil

      expect(subject.working_days_count).to be_nil
      expect(Day).not_to have_received(:working)
    end

    it "returns the correct number of days if start_date and finish_date are the same" do
      subject.start_date = Time.zone.today
      subject.finish_date = Time.zone.today
      expect(subject.working_days_count).to eq(1)
    end

    it "returns the correct number of days for a valid date range" do
      subject.start_date = Date.parse("2024-11-25")
      subject.finish_date = Date.parse("2024-11-27")
      expect(subject.working_days_count).to eq(3)
    end

    it "calls the Day.working.from_range method with the right arguments" do
      subject.start_date = Date.parse("2024-11-25")
      subject.finish_date = Date.parse("2024-11-27")

      allow(Day).to receive(:working).and_return(Day)
      allow(Day).to receive(:from_range)
                      .with(from: subject.start_date, to: subject.finish_date)
                      .and_return([])

      expect(subject.working_days_count).to eq(0)

      expect(Day).to have_received(:working).with(no_args)
      expect(Day).to have_received(:from_range).with(from: subject.start_date, to: subject.finish_date)
    end
  end
end
