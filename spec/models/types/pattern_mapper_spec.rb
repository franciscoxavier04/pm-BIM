# frozen_string_literal: true

#-- copyright
#++

require "spec_helper"

RSpec.describe Types::PatternMapper do
  let(:type) { build(:type, patterns: { subject: subject_pattern }) }
  let(:subject_pattern) { "ID Please: {{id}}" }
  let(:work_package) { create(:work_package) }

  subject(:resolver) { described_class.new(subject_pattern) }

  it "resolves a pattern" do
    expect(subject.resolve(work_package)).to eq("ID Please: #{work_package.id}")
  end

  context "when the pattern has WorkPackage properties" do
    let(:subject_pattern) { "{{id}} | {{done_ratio}} | {{created}}" }

    it "resolves the pattern" do
      expect(subject.resolve(work_package))
        .to eq("#{work_package.id} | #{work_package.done_ratio} | #{work_package.created_at.to_date.iso8601}")
    end
  end

  context "when the pattern has WorkPackage association attributes" do
    let(:subject_pattern) { "{{id}} | {{author}} | {{type}}" }

    it "resolves the pattern" do
      expect(subject.resolve(work_package))
        .to eq("#{work_package.id} | #{work_package.author.name} | #{work_package.type.name}")
    end
  end
end
