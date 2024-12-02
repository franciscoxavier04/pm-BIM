require "spec_helper"
require_module_spec_helper

RSpec.describe RecurringMeeting,
               with_settings: {
                 date_format: "%Y-%m-%d"
               } do
  describe "end_date" do
    subject { build(:recurring_meeting, start_date: (Date.current + 2.days).iso8601, end_date:) }

    context "with end_date before start_date" do
      let(:end_date) { Date.current + 1.day }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:end_date]).to include("must be after #{subject.start_date}.")
      end
    end

    context "with end_date in the past" do
      let(:end_date) { Date.yesterday }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:end_date]).to include("must be in the future.")
      end
    end
  end

  describe "daily schedule" do
    subject do
      build(:recurring_meeting,
            start_time: Time.zone.tomorrow + 10.hours,
            frequency: "daily",
            end_after: "specific_date",
            end_date: Time.zone.tomorrow + 1.week)
    end

    it "schedules daily", :aggregate_failures do
      expect(subject.first_occurrence).to eq Time.zone.tomorrow + 10.hours
      expect(subject.last_occurrence).to eq Time.zone.tomorrow + 1.week + 10.hours

      occurrence_in_two_days = Time.zone.today + 2.days + 10.hours
      Timecop.freeze(Time.zone.tomorrow + 11.hours) do
        expect(subject.next_occurrence).to eq occurrence_in_two_days
      end

      next_occurrences = subject.scheduled_occurrences(limit: 5).map(&:to_time)
      expect(next_occurrences).to eq [
        Time.zone.tomorrow + 10.hours,
        Time.zone.today + 2.days + 10.hours,
        Time.zone.today + 3.days + 10.hours,
        Time.zone.today + 4.days + 10.hours,
        Time.zone.today + 5.days + 10.hours
      ]

      Timecop.freeze(Time.zone.tomorrow + 2.weeks) do
        expect(subject.next_occurrence).to be_nil
      end
    end
  end

  describe "working_days schedule" do
    subject do
      build(:recurring_meeting,
            start_time: DateTime.parse("2024-12-02T10:00Z"),
            frequency: "working_days",
            end_after: "specific_date",
            end_date: DateTime.parse("2024-12-29T10:00Z"))
    end

    context "with working days set to four-week", with_settings: { working_days: [1, 2, 3, 4] } do
      it "schedules working days", :aggregate_failures do
        # Monday, 9AM
        Timecop.freeze(DateTime.parse("2024-12-02T09:00Z")) do
          expect(subject.first_occurrence).to eq Time.zone.today + 10.hours
          # Last thursday of the year
          expect(subject.last_occurrence).to eq DateTime.parse("2024-12-26T10:00Z")

          next_occurrences = subject.scheduled_occurrences(limit: 5).map(&:to_time)
          expect(next_occurrences).to eq [
            DateTime.parse("2024-12-02T10:00Z"),
            DateTime.parse("2024-12-03T10:00Z"),
            DateTime.parse("2024-12-04T10:00Z"),
            DateTime.parse("2024-12-05T10:00Z"),
            DateTime.parse("2024-12-09T10:00Z")
          ]
        end

        # Go to Saturday, expect next on Monday
        Timecop.freeze(DateTime.parse("2024-12-07T09:00Z")) do
          expect(subject.next_occurrence).to eq DateTime.parse("2024-12-09T10:00Z")
        end
      end
    end
  end

  describe "weekly schedule" do
    subject do
      build(:recurring_meeting,
            start_time: Time.zone.tomorrow + 10.hours,
            frequency: "weekly",
            end_after: "specific_date",
            end_date: Time.zone.tomorrow + 4.weeks)
    end

    it "schedules weekly", :aggregate_failures do
      expect(subject.first_occurrence).to eq Time.zone.tomorrow + 10.hours
      expect(subject.last_occurrence).to eq Time.zone.tomorrow + 4.weeks + 10.hours

      following_occurrence = Time.zone.tomorrow + 7.days + 10.hours
      Timecop.freeze(Time.zone.tomorrow + 11.hours) do
        expect(subject.next_occurrence).to eq following_occurrence
      end

      next_occurrences = subject.scheduled_occurrences(limit: 5).map(&:to_time)
      expect(next_occurrences).to eq [
        Time.zone.tomorrow + 10.hours,
        Time.zone.tomorrow + 7.days + 10.hours,
        Time.zone.tomorrow + 14.days + 10.hours,
        Time.zone.tomorrow + 21.days + 10.hours,
        Time.zone.tomorrow + 28.days + 10.hours
      ]

      Timecop.freeze(Time.zone.tomorrow + 5.weeks) do
        expect(subject.next_occurrence).to be_nil
      end
    end
  end
end
