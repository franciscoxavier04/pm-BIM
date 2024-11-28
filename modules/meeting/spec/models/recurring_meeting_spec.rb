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
end
