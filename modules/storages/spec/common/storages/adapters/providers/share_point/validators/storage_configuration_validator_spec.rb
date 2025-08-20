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
require_module_spec_helper

module Storages
  module Adapters
    module Providers
      module SharePoint
        module Validators
          RSpec.describe StorageConfigurationValidator, :webmock do
            let(:storage) { create(:share_point_storage, :sandbox, :as_automatically_managed) }
            let(:error) { Results::Error.new(code: error_code, source: self) }

            subject(:validator) { described_class.new(storage) }

            describe "success", vcr: "share_point/files_query_userless" do
              it "returns a GroupValidationResult" do
                results = validator.call

                expect(results).to be_a(ConnectionValidators::ValidationGroupResult)
                expect(results).to be_success
              end
            end

            describe "failure" do
              let(:files_double) { class_double(Queries::FilesQuery) }
              let(:auth_strategy) { Registry["share_point.authentication.userless"].call }
              let(:input_data) { Input::Files.build(folder: "/").value! }
              let(:result) { Success() }

              before do
                allow(files_double).to receive(:call).with(storage:, auth_strategy:, input_data:).and_return(result)
              end

              context "when the storage isn't configured" do
                let(:storage) { create(:share_point_storage) }

                it "the check fails" do
                  results = validator.call
                  expect(results[:storage_configured]).to be_a_failure
                  expect(results[:storage_configured].code).to eq(:not_configured)
                end
              end

              context "when the tenant id is wrong" do
                it "but looks like an actual valid value", vcr: "share_point/validation_wrong_tenant_id" do
                  storage.tenant_id = "itdoesnotexists9000.sharepoint.com"
                  results = described_class.new(storage).call

                  expect(results[:tenant_id]).to be_a_failure
                  expect(results[:tenant_id].code).to eq(:sp_tenant_id_invalid)
                end

                it "but is blatantly wrong", vcr: "share_point/validation_absurd_tenant_id" do
                  storage.tenant_id = "wrong"
                  results = described_class.new(storage).call

                  expect(results[:tenant_id]).to be_a_failure
                  expect(results[:tenant_id].code).to eq(:sp_tenant_id_invalid)
                end
              end

              context "when the client secret is wrong" do
                it "fails the check", vcr: "share_point/validation_wrong_client_secret" do
                  storage.oauth_client.client_secret = "wrong"
                  results = described_class.new(storage).call

                  expect(results[:client_secret]).to be_a_failure
                  expect(results[:client_secret].code).to eq(:client_secret_invalid)
                end
              end

              context "when the client id is wrong" do
                it "fails the check", vcr: "share_point/validation_wrong_client_id" do
                  storage.oauth_client.client_id = "wrong"
                  results = described_class.new(storage).call

                  expect(results[:client_id]).to be_a_failure
                  expect(results[:client_id].code).to eq(:client_id_invalid)
                end
              end
            end
          end
        end
      end
    end
  end
end
