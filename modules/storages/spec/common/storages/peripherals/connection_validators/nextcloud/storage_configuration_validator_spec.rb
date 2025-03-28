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
  module Peripherals
    module ConnectionValidators
      module Nextcloud
        RSpec.describe StorageConfigurationValidator, :webmock do
          let(:storage) { create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed) }

          subject(:validator) { described_class.new(storage) }

          it "returns a GroupValidationResult", vcr: "nextcloud/capabilities_success" do
            results = validator.call

            expect(results).to be_a(ValidationGroupResult)
            expect(results).to be_success
          end

          describe "possible error scenarios" do
            context "when the storage is not configured" do
              let(:storage) { create(:nextcloud_storage) }

              it "the check fails" do
                results = validator.call
                expect(results[:storage_configured]).to be_a_failure
                expect(results[:storage_configured].message).to eq(I18n.t(i18n_key(:not_configured)))
              end
            end

            it "base url could not be reached" do
              stub_request(:get, UrlBuilder.url(storage.uri, "/ocs/v2.php/cloud/capabilities"))
                .to_return(status: 404, body: "Not Found")

              results = validator.call
              expect(results[:host_url_accessible]).to be_a_failure
              expect(results[:host_url_accessible].message).to eq(I18n.t(i18n_key(:host_not_found)))
            end

            it "integration app version mismatch", vcr: "nextcloud/capabilities_success" do
              absurd_version = { dependencies: { integration_app: { min_version: "2099.10.138" } } }.deep_stringify_keys
              allow(subject).to receive(:nextcloud_dependencies).and_return(absurd_version)

              results = validator.call
              expect(results[:dependencies_versions]).to be_a_failure
              expect(results[:dependencies_versions].message).to eq(I18n.t(i18n_key(:app_version_mismatch)))
            end

            it "integration app disabled / missing", vcr: "nextcloud/capabilities_success_app_disabled" do
              results = validator.call

              expect(results[:dependencies_check]).to be_a_failure
              expect(results[:dependencies_check].message)
                .to eq(I18n.t(i18n_key(:missing_dependencies), dependency: "Integration OpenProject"))
            end
          end

          private

          def i18n_key(key) = "storages.health.connection_validation.#{key}"
        end
      end
    end
  end
end
