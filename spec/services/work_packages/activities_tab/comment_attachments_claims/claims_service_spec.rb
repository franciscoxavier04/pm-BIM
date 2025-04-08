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
require "services/base_services/behaves_like_update_service"

RSpec.describe WorkPackages::ActivitiesTab::CommentAttachmentsClaims::ClaimsService do
  shared_let(:user) { create(:user) }
  shared_let(:work_package) { create(:work_package, author: user) }

  it_behaves_like "BaseServices update service" do
    let(:model_instance) { build_stubbed(:work_package_journal, journable: work_package, version: 2, notes: "") }
    let(:set_attributes_class) { WorkPackages::ActivitiesTab::CommentAttachmentsClaims::SetAttributesService }
    let(:contract_class) { WorkPackages::ActivitiesTab::CommentAttachmentsClaimsContract }
  end

  describe "#call" do
    context "when the journal has no notes" do
      let(:journal_without_notes) { create(:work_package_journal, journable: work_package, version: 2, notes: "") }

      subject(:attachment_claims_service) do
        described_class.new(
          user:,
          model: journal_without_notes
        )
      end

      it "does not claim any attachments" do
        claim_result = attachment_claims_service.call
        expect(claim_result).to be_success

        expect(journal_without_notes.reload.attachments).to be_empty
      end
    end

    context "when the journal has notes with attachments" do
      shared_let(:attachment1) { create(:attachment, author: user, container: nil) }
      shared_let(:attachment2) { create(:attachment, author: user, container: nil) }
      shared_let(:attachment3) { create(:attachment, author: user, container: nil) }

      let(:journal_with_attachments) { create(:work_package_journal, journable: work_package, version: 3, notes:) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment1.id}/content">

          First attachment

          <br>

          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment2.id}/content">

          Second attachment

          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment3.id}/content">

          Third attachment
        HTML
      end

      subject(:attachment_claims_service) do
        described_class.new(
          user:,
          model: journal_with_attachments
        )
      end

      it "claims the attachments" do
        claim_result = attachment_claims_service.call
        expect(claim_result).to be_success

        expect(journal_with_attachments.reload.attachments).to contain_exactly(attachment1, attachment2, attachment3)
      end
    end
  end
end
