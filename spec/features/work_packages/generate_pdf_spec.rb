#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "features/work_packages/work_packages_page"

RSpec::Matchers.define :has_mandatory_params do |expected|
  match do |actual|
    expected.count do |key, value|
      actual[key.to_sym] == value
    end == expected.size
  end
end

RSpec.describe "work package generate PDF dialog", :js do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:default_footer_text) { project.name }
  shared_let(:download_list) { DownloadList.new }
  let(:work_package) do
    build(:work_package,
          project:,
          id: 666,
          assigned_to: user,
          responsible: user)
  end
  let(:document_generator) { instance_double(WorkPackage::PDFExport::DocumentGenerator) }
  let(:wp_exporter) { instance_double(WorkPackage::PDFExport::WorkPackageToPdf) }
  let(:expected_params) { {} }

  def visit_work_package_page!
    Pages::FullWorkPackage.new(work_package).visit!
  end

  def mock_generating_pdf
    allow(WorkPackage::PDFExport::DocumentGenerator)
      .to receive(:new)
            .with(work_package, has_mandatory_params(expected_params))
            .and_return(document_generator)
    allow(WorkPackage::PDFExport::WorkPackageToPdf)
      .to receive(:new)
            .with(work_package, has_mandatory_params(expected_params))
            .and_return(wp_exporter)

    [document_generator, wp_exporter].each do |generator|
      allow(generator)
        .to receive(:export!)
              .and_return(
                Exports::Result.new(
                  format: :pdf, title: "filename.pdf", content: "PDF Content", mime_type: "application/pdf"
                )
              )
    end
  end

  def open_generate_pdf_dialog!
    click_link_or_button "More"
    click_link_or_button "Generate PDF"
  end

  def generate!
    click_link_or_button "Download"
    expect(subject).to have_text("filename.pdf")
  end

  before do
    mock_generating_pdf
    login_as(user)
    work_package.save!
    visit_work_package_page!
    open_generate_pdf_dialog!
  end

  after do
    DownloadList.clear
  end

  subject { download_list.refresh_from(page).latest_download.to_s }

  context "with default parameters" do
    let(:expected_params) do
      {
        hyphenation: "false",
        hyphenation_language: "en",
        template: "attributes",
        footer_text_right: project.name
      }
    end

    it "downloads with options" do
      generate!
    end
  end

  context "with contract template" do
    let(:expected_params) do
      {
        hyphenation: "false",
        hyphenation_language: "en",
        template: "contract",
        footer_text_center: work_package.subject
      }
    end

    it "downloads with options" do
      select "Contract", from: "template"
      expect(page).to have_field("footer_text_center")
      generate!
    end
  end

  context "with custom parameters" do
    let(:expected_params) do
      {
        footer_text_right: "Custom Footer Text",
        template: "attributes",
        hyphenation: "true",
        hyphenation_language: "de"
      }
    end

    it "downloads with options" do
      check("Hyphenation")
      select "Deutsch", from: "hyphenation_language"
      fill_in "footer_text_right", with: "Custom Footer Text"
      generate!
    end
  end
end
