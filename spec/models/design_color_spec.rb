# frozen_string_literal: true

require "spec_helper"

RSpec.describe DesignColor do
  let(:default_primary) { OpenProject::CustomStyles::Design.variables["primary-button-color"] }
  let(:primary_color) { create(:"design_color_primary-button-color") }

  describe "normalization" do
    it "does not normalize non-hexcodes, except to strip whitespace", :aggregate_failures do
      expect(subject).to normalize(:hexcode).from("").to("")
      expect(subject).to normalize(:hexcode).from(" ").to("")
      expect(subject).to normalize(:hexcode).from("11").to("11")
      expect(subject).to normalize(:hexcode).from("purple").to("purple")
      expect(subject).to normalize(:hexcode).from("green ").to("green")
    end

    it "normalizes short hexcodes", :aggregate_failures do
      expect(subject).to normalize(:hexcode).from(" ccc").to("#CCCCCC")
      expect(subject).to normalize(:hexcode).from("333 ").to("#333333")
      expect(subject).to normalize(:hexcode).from("#ddd").to("#DDDDDD")
    end

    it "normalizes full hexcodes", :aggregate_failures do
      expect(subject).to normalize(:hexcode).from(" 800080").to("#800080")
      expect(subject).to normalize(:hexcode).from("228b22 ").to("#228B22")
      expect(subject).to normalize(:hexcode).from("#00CED1").to("#00CED1")
    end
  end

  describe "#setables" do
    it "returns an Array of instances" do
      expect(described_class.setables).to be_a(Array)
      expect(described_class.setables.first).to be_a(described_class)
    end

    it "not overwritten defaults do not have a color set" do
      expect(described_class.setables.first.hexcode).to be_nil
    end

    it "instances overwrite defaults" do
      primary_color
      expect(described_class.setables.first.hexcode).to eq("#3493B3")
      expect(described_class.setables.second.hexcode).to be_nil
    end
  end

  describe "#get_hexcode" do
    it "returns hexcode if present" do
      primary_color
      expect(primary_color.hexcode).to eq("#3493B3")
    end

    it "returns nil hexcode if hexcode not present" do
      expect(described_class.new(variable: "primary-button-color").hexcode)
        .to be_nil
    end
  end

  describe "validations" do
    context "a color_variable already exists" do
      let(:design_color) do
        described_class.new variable: "foo", hexcode: "#AB1234"
      end

      before do
        design_color.save
      end

      it "fails validation for another design_color with same name" do
        second_color_variable = described_class.new variable: "foo", hexcode: "#888888"
        expect(second_color_variable).not_to be_valid
      end
    end

    context "the hexcode's validation" do
      it "fails validations" do
        expect(described_class.new(variable: "foo", hexcode: "1")).not_to be_valid
        expect(described_class.new(variable: "foo", hexcode: "#1")).not_to be_valid
        expect(described_class.new(variable: "foo", hexcode: "#1111111")).not_to be_valid
        expect(described_class.new(variable: "foo", hexcode: "#HHHHHH")).not_to be_valid
      end

      it "passes validations" do
        expect(described_class.new(variable: "foo", hexcode: "111111")).to be_valid
        expect(described_class.new(variable: "foo", hexcode: "#111111")).to be_valid
        expect(described_class.new(variable: "foo", hexcode: "#ABC123")).to be_valid
        expect(described_class.new(variable: "foo", hexcode: "#111")).to be_valid
        expect(described_class.new(variable: "foo", hexcode: "111")).to be_valid
      end
    end
  end

  describe "#create" do
    context "no CustomStyle.current exists yet" do
      subject { described_class.new variable: "foo", hexcode: "#111111" }

      it "creates a CustomStyle.current" do
        expect(CustomStyle.current).to be_nil
        subject.save
        expect(CustomStyle.current).to be_present
      end
    end
  end
end
