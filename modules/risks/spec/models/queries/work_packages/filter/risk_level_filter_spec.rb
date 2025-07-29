# frozen_string_literal: true

require "spec_helper"

RSpec.describe Risks::Queries::WorkPackages::Filter::RiskLevelFilter do
  let(:project) { create(:project) }
  let(:type) { create(:type) }
  let(:status) { create(:status) }
  let(:author) { create(:user) }

  before do
    create(:risk, project:, type:, status:, author:, risk_impact: 1, risk_likelihood: 2) # risk_level = 2 (low)
    create(:risk, project:, type:, status:, author:, risk_impact: 3, risk_likelihood: 4) # risk_level = 12 (medium)
    create(:risk, project:, type:, status:, author:, risk_impact: 5, risk_likelihood: 5) # risk_level = 25 (high)
    create(:work_package, project:, type:, status:, author:) # non-risk
  end

  describe "#allowed_values" do
    it "returns the expected values" do
      filter = described_class.new
      expected_values = [
        ["Low", "low"],
        ["Medium", "medium"],
        ["High", "high"]
      ]
      expect(filter.allowed_values).to eq(expected_values)
    end
  end

  describe "#human_name" do
    it "returns the translated name" do
      filter = described_class.new
      expect(filter.human_name).to eq("Risk Level")
    end
  end

  describe "#where" do
    it "filters by low risk level" do
      filter = described_class.new
      filter.values = ["low"]

      query = Queries::WorkPackages::WorkPackageQuery.new
      query.filters = [filter]

      result = query.results.work_packages
      expect(result.count).to eq(1)
      expect(result.first.risk_level).to eq(2)
    end

    it "filters by medium risk level" do
      filter = described_class.new
      filter.values = ["medium"]

      query = Queries::WorkPackages::WorkPackageQuery.new
      query.filters = [filter]

      result = query.results.work_packages
      expect(result.count).to eq(1)
      expect(result.first.risk_level).to eq(12)
    end

    it "filters by high risk level" do
      filter = described_class.new
      filter.values = ["high"]

      query = Queries::WorkPackages::WorkPackageQuery.new
      query.filters = [filter]

      result = query.results.work_packages
      expect(result.count).to eq(1)
      expect(result.first.risk_level).to eq(25)
    end

    it "filters by multiple risk levels" do
      filter = described_class.new
      filter.values = ["low", "high"]

      query = Queries::WorkPackages::WorkPackageQuery.new
      query.filters = [filter]

      result = query.results.work_packages
      expect(result.count).to eq(2)
      risk_levels = result.pluck(:risk_level).sort
      expect(risk_levels).to eq([2, 25])
    end
  end
end
