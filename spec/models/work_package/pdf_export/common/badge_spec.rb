require "spec_helper"

RSpec.describe WorkPackage::PDFExport::Common::Badge do
  let(:badge) { Class.new { extend WorkPackage::PDFExport::Common::Badge } }

  describe "#readable_color" do
    it "returns white for dark colors: black" do
      expect(badge.readable_color("000000")).to eq("FFFFFF")
    end

    it "returns white for dark colors: dark blue" do
      expect(badge.readable_color("1864AB")).to eq("FFFFFF")
    end

    it "returns white for light colors: blue-6" do
      expect(badge.readable_color("228BE6")).to eq("000000")
    end

    it "returns black for light colors: orange-2" do
      expect(badge.readable_color("FFD8A8")).to eq("000000")
    end

    it "returns black for light colors: cyan-0" do
      expect(badge.readable_color("E3FAFC")).to eq("000000")
    end

    it "returns black for light colors: white" do
      expect(badge.readable_color("FFFFFF")).to eq("000000")
    end
  end
end
