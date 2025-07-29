# frozen_string_literal: true

require "spec_helper"

RSpec.describe Risk do
  let(:project) { create(:project) }
  let(:type) { create(:type) }
  let(:status) { create(:status) }
  let(:author) { create(:user) }

  describe "validations" do
    let(:risk) { build(:risk, project:, type:, status:, author:) }

    it "is valid with valid attributes" do
      risk.risk_impact = 3
      risk.risk_likelihood = 4
      expect(risk).to be_valid
    end

    it "requires risk_impact" do
      risk.risk_impact = nil
      expect(risk).not_to be_valid
      expect(risk.errors[:risk_impact]).to include("can't be blank")
    end

    it "requires risk_likelihood" do
      risk.risk_likelihood = nil
      expect(risk).not_to be_valid
      expect(risk.errors[:risk_likelihood]).to include("can't be blank")
    end

    it "validates risk_impact range" do
      risk.risk_impact = 0
      expect(risk).not_to be_valid
      expect(risk.errors[:risk_impact]).to include("must be between 1 and 5.")

      risk.risk_impact = 6
      expect(risk).not_to be_valid
      expect(risk.errors[:risk_impact]).to include("must be between 1 and 5.")
    end

    it "validates risk_likelihood range" do
      risk.risk_likelihood = 0
      expect(risk).not_to be_valid
      expect(risk.errors[:risk_likelihood]).to include("must be between 1 and 5.")

      risk.risk_likelihood = 6
      expect(risk).not_to be_valid
      expect(risk.errors[:risk_likelihood]).to include("must be between 1 and 5.")
    end
  end

  describe "risk level calculation" do
    let(:risk) { build(:risk, project:, type:, status:, author:) }

    it "calculates risk_level as impact * likelihood" do
      risk.risk_impact = 3
      risk.risk_likelihood = 4
      risk.save!
      expect(risk.risk_level).to eq(12)
    end

    it "updates risk_level when impact changes" do
      risk.risk_impact = 2
      risk.risk_likelihood = 3
      risk.save!
      expect(risk.risk_level).to eq(6)

      risk.risk_impact = 5
      risk.save!
      expect(risk.risk_level).to eq(15)
    end
  end

  describe "sti" do
    it "has correct sti_name" do
      expect(Risk.sti_name).to eq("Risk")
    end

    it "is a risk" do
      risk = create(:risk, project:, type:, status:, author:)
      expect(risk.risk?).to be true
    end
  end

  describe "risk_level_category" do
    let(:risk) { build(:risk, project:, type:, status:, author:) }

    it "returns the correct category for risk levels" do
      risk.risk_impact = 1
      risk.risk_likelihood = 1
      risk.save!
      expect(risk.risk_level_category).to eq("low")

      risk.risk_impact = 3
      risk.risk_likelihood = 4
      risk.save!
      expect(risk.risk_level_category).to eq("medium")

      risk.risk_impact = 5
      risk.risk_likelihood = 5
      risk.save!
      expect(risk.risk_level_category).to eq("high")
    end

    it "returns nil when risk_level is nil" do
      risk.risk_level = nil
      expect(risk.risk_level_category).to be_nil
    end
  end
end
