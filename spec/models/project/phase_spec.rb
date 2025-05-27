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

require "rails_helper"

RSpec.describe Project::Phase do
  it "can be instantiated" do
    expect { described_class.new }.not_to raise_error(NotImplementedError)
  end

  it { is_expected.to have_readonly_attribute(:definition_id) }

  describe "associations" do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:definition).required }
    it { is_expected.to have_many(:work_packages).through(:definition) }
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

  describe "validations" do
    subject { create(:project_phase) }

    it "is valid when both dates are blank" do
      subject.assign_attributes(start_date: nil, finish_date: nil)
      expect(subject).to be_valid
    end

    it "adds error if start_date is after finish_date (start date is changed)" do
      subject.start_date = subject.finish_date + 1.day
      expect(subject).not_to be_valid
      expect(subject.errors.symbols_for(:start_date)).to include(:must_be_before_finish_date)
    end

    it "adds error if finish_date is before start_date (finish date is changed)" do
      subject.finish_date = subject.start_date - 1.day
      expect(subject).not_to be_valid
      expect(subject.errors.symbols_for(:finish_date)).to include(:must_be_after_start_date)
    end

    it "does not add errors if start_date is before or equal to finish_date" do
      subject.start_date = subject.finish_date
      expect(subject).to be_valid
    end

    describe "date format validation" do
      it "is valid with correct YYYY-MM-DD format" do
        subject.start_date = "2025-06-17"
        subject.finish_date = "2025-06-18"
        expect(subject).to be_valid
      end

      it "is invalid with extra characters in date" do
        subject.start_date = "2025-06-170"
        expect(subject).not_to be_valid
        expect(subject.errors.symbols_for(:start_date)).to include(:invalid)
      end

      it "is invalid with non-date string" do
        subject.finish_date = "not-a-date"
        expect(subject).not_to be_valid
        expect(subject.errors.symbols_for(:finish_date)).to include(:invalid)
      end

      it "is invalid with wrong format (missing leading zero)" do
        subject.start_date = "2025-6-17"
        expect(subject).not_to be_valid
        expect(subject.errors.symbols_for(:start_date)).to include(:invalid)
      end

      it "is valid when date is blank" do
        subject.start_date = ""
        subject.finish_date = nil
        expect(subject).to be_valid
      end
    end
  end

  describe "duration calculation" do
    shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

    let(:date) { Time.zone.today }

    it "returns number of working days in complete date range" do
      subject.start_date = date
      subject.finish_date = date + 27

      expect(subject.calculate_duration).to eq(20)
    end

    it "returns nil if date range is incomplete" do
      subject.start_date = nil

      expect(subject.calculate_duration).to be_nil
    end
  end
end
