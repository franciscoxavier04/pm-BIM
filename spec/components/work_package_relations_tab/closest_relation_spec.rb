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

RSpec.describe WorkPackageRelationsTab::ClosestRelation do
  let(:work_package) { build_stubbed(:work_package) }
  let(:today) { Time.zone.today }

  def closest_relation(lag: 0, **wp_attributes)
    predecessor = build_stubbed(:work_package, **wp_attributes)
    relation = build_stubbed(:follows_relation, from: work_package, to: predecessor, lag:)
    described_class.new(relation)
  end

  describe "#<=>" do
    context "without a lag" do
      context "when comparing two instances with different due dates" do
        it "compares with the respective due dates" do
          expect(closest_relation(due_date: 1.day.from_now)).to be < closest_relation(due_date: 2.days.from_now)
          expect(closest_relation(due_date: today)).to be > closest_relation(due_date: 2.days.ago)
          expect(closest_relation(due_date: today)).to be > closest_relation(due_date: nil)
          expect(closest_relation(due_date: nil)).to be < closest_relation(due_date: 1.day.ago)
        end
      end

      context "when comparing two instances with different start dates" do
        it "compares with the respective start dates" do
          expect(closest_relation(start_date: 1.day.from_now)).to be < closest_relation(start_date: 2.days.from_now)
          expect(closest_relation(start_date: today)).to be > closest_relation(start_date: 2.days.ago)
          expect(closest_relation(start_date: today)).to be > closest_relation(start_date: nil)
          expect(closest_relation(start_date: nil)).to be < closest_relation(start_date: 1.day.ago)
        end
      end

      context "when comparing two instances with same due dates" do
        it "compares with the respective created at dates, oldest > newest" do
          expect(closest_relation(due_date: 1.day.from_now)).to be > closest_relation(due_date: 1.day.from_now)
          expect(closest_relation(due_date: 2.days.ago)).to be > closest_relation(due_date: 2.days.ago)
          expect(closest_relation(due_date: nil)).to be > closest_relation(due_date: nil)
        end
      end

      context "when comparing two instances with same start dates" do
        it "compares with the respective created at dates, oldest > newest" do
          expect(closest_relation(start_date: 1.day.from_now)).to be > closest_relation(start_date: 1.day.from_now)
          expect(closest_relation(start_date: 2.days.ago)).to be > closest_relation(start_date: 2.days.ago)
          expect(closest_relation(start_date: nil)).to be > closest_relation(start_date: nil)
        end
      end

      context "when comparing two instances with both due and start dates set" do
        it "compares with the respective due dates, ignoring start dates" do
          expect(closest_relation(due_date: 10.days.from_now, start_date: today))
            .to be < closest_relation(due_date: 12.days.from_now, start_date: 2.days.ago)
          expect(closest_relation(due_date: 14.days.from_now, start_date: today))
            .to be > closest_relation(due_date: 12.days.from_now, start_date: 2.days.ago)
        end
      end
    end

    context "with a lag" do
      context "when comparing two instances with same soonest starts (due date and lag)" do
        it "compares with the respective created at dates, oldest > newest" do
          expect(closest_relation(lag: 3, due_date: 3.days.from_now))
            .to be > closest_relation(lag: 4, due_date: 2.days.from_now)
          expect(closest_relation(lag: 2, due_date: 3.days.ago))
            .to be > closest_relation(lag: 1, due_date: 4.days.ago)
          expect(closest_relation(lag: 2, due_date: nil))
            .to be > closest_relation(lag: 2, due_date: nil)
        end
      end

      context "when comparing two instances with same soonest starts (start date and lag)" do
        it "compares with the respective created at dates, oldest > newest" do
          expect(closest_relation(lag: 3, start_date: 3.days.from_now))
            .to be > closest_relation(lag: 4, start_date: 2.days.from_now)
          expect(closest_relation(lag: 2, start_date: 3.days.ago))
            .to be > closest_relation(lag: 1, start_date: 4.days.ago)
          expect(closest_relation(lag: 2, start_date: nil))
            .to be > closest_relation(lag: 2, start_date: nil)
        end
      end

      context "when comparing two instances with different soonest starts (due date and lag)" do
        it "compares with the combined due dates and lag" do
          expect(closest_relation(lag: 4, due_date: 3.days.from_now))
            .to be > closest_relation(lag: 4, due_date: 2.days.from_now)
          expect(closest_relation(lag: 1, due_date: 3.days.ago))
            .to be < closest_relation(lag: 4, due_date: 3.days.ago)
          expect(closest_relation(lag: 4, due_date: nil))
            .to be < closest_relation(lag: 4, due_date: 2.days.from_now)
          expect(closest_relation(lag: 1, due_date: 3.days.ago))
            .to be > closest_relation(lag: 4, due_date: nil)
        end
      end

      context "when comparing two instances with different soonest starts (start date and lag)" do
        it "compares with the combined start dates and lag" do
          expect(closest_relation(lag: 4, start_date: 3.days.from_now))
            .to be > closest_relation(lag: 4, start_date: 2.days.from_now)
          expect(closest_relation(lag: 1, start_date: 3.days.ago))
            .to be < closest_relation(lag: 4, start_date: 3.days.ago)
          expect(closest_relation(lag: 4, start_date: nil))
            .to be < closest_relation(lag: 4, start_date: 2.days.from_now)
          expect(closest_relation(lag: 1, start_date: 3.days.ago))
            .to be > closest_relation(lag: 4, start_date: nil)
        end
      end
    end
  end

  describe "#soonest_start" do
    context "with a nil due and start date" do
      it "returns nil" do
        expect(closest_relation(due_date: nil, start_date: nil).soonest_start).to be_nil
        expect(closest_relation(lag: 1, due_date: nil, start_date: nil).soonest_start).to be_nil
      end
    end

    context "with a due date set" do
      let(:due_date) { Date.new(2020, 7, 14) }

      context "without a lag" do
        it "returns the due date" do
          expect(closest_relation(due_date:).soonest_start).to eq(Date.new(2020, 7, 14))
        end
      end

      context "with a positive lag" do
        it "returns the combined due date and lag" do
          expect(closest_relation(lag: 11, due_date:).soonest_start).to eq(Date.new(2020, 7, 25))
        end
      end

      context "with a negative lag" do
        it "returns the combined due date and lag" do
          pending "negative lags are not yet implemented"
          expect(closest_relation(lag: -2, due_date:).soonest_start).to eq(Date.new(2020, 7, 12))
        end
      end
    end

    context "with a start date set" do
      let(:start_date) { Date.new(2020, 7, 14) }

      context "with a zero lag" do
        it "returns the start date" do
          expect(closest_relation(start_date:).soonest_start).to eq(Date.new(2020, 7, 14))
        end
      end

      context "with a positive lag" do
        it "returns the combined start date and lag" do
          expect(closest_relation(lag: 11, start_date:).soonest_start).to eq(Date.new(2020, 7, 25))
        end
      end

      context "with a negative lag" do
        it "returns the combined start date and lag" do
          pending "negative lags are not yet implemented (Feature OP#38606)"
          expect(closest_relation(lag: -2, start_date:).soonest_start).to eq(Date.new(2020, 7, 12))
        end
      end
    end
  end

  describe "#inspect" do
    subject { closest_relation(lag: 3, due_date: Date.new(2022, 7, 4)) }

    it "outputs object for debugging" do
      expect(subject.inspect)
        .to start_with("#<WorkPackageRelationsTab::ClosestRelation soonest_start: 2022-07-07")
        .and include(subject.relation.inspect)
    end
  end
end
