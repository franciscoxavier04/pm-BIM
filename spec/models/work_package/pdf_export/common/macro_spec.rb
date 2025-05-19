require "spec_helper"

RSpec.describe WorkPackage::PDFExport::Common::Macro do
  let(:work_package) do
    create(:work_package, id: 185, subject: "Work package 1")
  end
  let(:markdown) { "" }
  let(:formatter) { Class.new { extend WorkPackage::PDFExport::Common::Macro } }

  subject(:formatted) do
    formatter.apply_markdown_field_macros(markdown, { work_package: work_package })
  end

  describe "empty text" do
    it "contains correct data" do
      expect(formatted).to eq ""
    end
  end

  describe "wp mention tag" do
    let(:markdown) { '<mention class="mention" data-id="185" data-type="work_package" data-text="#185">#185</mention>' }

    it "ignores the tag" do
      expect(formatted).to eq "<mention class=\"mention\" data-id=\"185\" data-type=\"work_package\" data-text=\"#185\">\\#185</mention>\n"
    end
  end

  describe "wp mention plain" do
    let(:markdown) { '#185' }

    it "contains correct data" do
      expect(formatted).to eq "<mention class=\"mention\" data-id=\"185\" data-type=\"work_package\" data-text=\"#185\">#185</mention>\n"
    end
  end

  describe "wp mention with markdown formating bold" do
    let(:markdown) { "\n**#185**\n" }

    it "contains correct data" do
      expect(formatted).to eq "**<mention class=\"mention\" data-id=\"185\" data-type=\"work_package\" data-text=\"#185\">#185</mention>**\n"
    end
  end

  describe "wp mention with markdown formating strikethrough" do
    let(:markdown) { '~~#185~~' }

    it "contains correct data" do
      expect(formatted).to eq "~~<mention class=\"mention\" data-id=\"185\" data-type=\"work_package\" data-text=\"#185\">#185</mention>~~\n"
    end
  end
end
