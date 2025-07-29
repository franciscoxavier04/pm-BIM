# frozen_string_literal: true

FactoryBot.define do
  factory :risk, class: "Risk" do
    project
    type
    status
    author
    subject { "Risk #{SecureRandom.hex(4)}" }
    risk_impact { rand(1..5) }
    risk_likelihood { rand(1..5) }
    work_package_type { "Risk" }
  end
end
