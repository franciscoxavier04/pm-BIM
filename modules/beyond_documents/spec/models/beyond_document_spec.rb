# frozen_string_literal: true

require "spec_helper"
require_module_spec_helper

RSpec.describe BeyondDocument do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:type) }
    it { is_expected.to belong_to(:status) }
    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to belong_to(:assigned_to).class_name("Principal").optional }
  end
end
