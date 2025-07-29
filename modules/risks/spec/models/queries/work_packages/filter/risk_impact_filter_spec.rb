# frozen_string_literal: true

require "spec_helper"

RSpec.describe Risks::Queries::WorkPackages::Filter::RiskImpactFilter do
  let(:project) { create(:project) }
  let(:type) { create(:type) }
  let(:status) { create(:status) }
  let(:author) { create(:user) }

  before do
    create(:risk, project:, type:, status:, author:, risk_impact: 3)
    create(:risk, project:, type:, status:, author:, risk_impact: 5)
    create(:work_package, project:, type:, status:, author:) # non-risk
  end

  describe "#allowed_values" do
    it "returns the expected values" do
      filter = described_class.new
      expected_values = [
        ["Very Low", 1],
        ["Low", 2],
        ["Medium", 3],
        ["High", 4],
        ["Very High", 5]
      ]
      expect(filter.allowed_values).to eq(expected_values)
    end
  end

  describe "#human_name" do
    it "returns the translated name" do
      filter = described_class.new
      expect(filter.human_name).to eq("Risk Impact")
    end
  end

  describe "#where" do
    it "filters by risk_impact" do
      filter = described_class.new
      filter.values = ["3"]

      query = Queries::WorkPackages::WorkPackageQuery.new
      query.filters = [filter]

      result = query.results.work_packages
      expect(result.count).to eq(1)
      expect(result.first.risk_impact).to eq(3)
    end
  end
end
