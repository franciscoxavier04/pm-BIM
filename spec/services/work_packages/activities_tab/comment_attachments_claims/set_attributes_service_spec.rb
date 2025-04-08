# frozen_string_literal: true

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

RSpec.describe WorkPackages::ActivitiesTab::CommentAttachmentsClaims::SetAttributesService do
  let(:user) { build_stubbed(:user) }

  let(:journal) { build_stubbed(:work_package_journal, notes:) }

  subject(:set_attributes_service) do
    described_class.new(
      user:,
      model: journal,
      contract_class: EmptyContract
    ).call
  end

  describe "#call" do
    context "when the journal notes have attachments" do
      let(:attachment1) { build_stubbed(:attachment) }
      let(:attachment2) { build_stubbed(:attachment) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment1.id}/content">
          Lorem ipsum dolor sit amet
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment2.id}/content">
          consectetur adipiscing elit
        HTML
      end

      before do
        allow(Attachment).to receive(:where)
          .with(id: [attachment1.id.to_s, attachment2.id.to_s])
          .and_return([attachment1, attachment2])
      end

      it "sets the attachments replacements" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to contain_exactly(attachment1, attachment2)
      end
    end

    context "when the journal notes have no attachments" do
      let(:notes) { "Lorem ipsum dolor sit amet" }

      it "does not set the attachments" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to be_nil
      end
    end

    context "when the journal notes are nil" do
      let(:notes) { nil }

      it "does not set the attachments" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to be_nil
      end
    end
  end
end
