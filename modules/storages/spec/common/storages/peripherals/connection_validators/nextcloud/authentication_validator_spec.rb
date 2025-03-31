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
        RSpec.describe AuthenticationValidator, :webmock do
          subject(:validator) { described_class.new(storage) }

          context "when using OAuth2" do
            let(:user) { create(:user) }
            let(:storage) do
              create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed,
                     oauth_client_token_user: user, origin_user_id: "m.jade@death.star")
            end

            before { User.current = user }

            it "passes when the user has a token and the request works", vcr: "nextcloud/user_query_success" do
              expect(validator.call).to be_success
            end

            it "returns a warning when there's no token for the current user" do
              User.current = create(:user)
              result = validator.call

              expect(result[:existing_token]).to be_a_warning
              expect(result[:existing_token].message).to eq(I18n.t(i18n_key(:oauth_token_missing)))
              expect(result[:user_bound_request]).to be_skipped
            end

            it "returns a failure if the remote call failed" do
              Registry.stub("nextcloud.queries.user", ->(_) { ServiceResult.failure(result: :unauthorized) })

              result = validator.call
              expect(result[:user_bound_request]).to be_a_failure
              expect(result[:user_bound_request].message).to eq(I18n.t(i18n_key(:oauth_request_unauthorized)))
            end
          end

          context "when using OpenID Connect" do
            let(:storage) { create(:nextcloud_storage_configured, :oidc_sso_enabled) }

            let(:user) { create(:user, identity_url: "#{oidc_provider.slug}:UNIVERSALLY-DUPLICATED-IDENTIFIER") }
            let!(:oidc_provider) { create(:oidc_provider) }

            before do
              User.current = user

              xml_response = Rails.root.join("modules/storages/spec/support/payloads/nextcloud_user_query_success.xml")
              stub_request(:get, "#{storage.uri}ocs/v1.php/cloud/user")
                .and_return(status: 200, body: File.read(xml_response), headers: { content_type: "text/xml" })
            end

            it "succeeds give the user is provisioned and tokens can be acquired" do
              create(:oidc_user_token, user:, extra_audiences: storage.audience)
              expect(validator.call).to be_success
            end

            describe "error and warning handling" do
              it "returns a warning if the current user isn't provisioned" do
                user.update!(identity_url: nil)
                result = validator.call

                expect(result[:non_provisioned_user]).to be_warning
                expect(result[:non_provisioned_user].message).to eq(I18n.t(i18n_key(:oidc_non_provisioned_user)))

                state_count = result.tally
                expect(state_count).to eq({ skipped: 3, warning: 1 })
              end

              it "returns a warning if the user is not provisioned by an oidc provider" do
                user.update!(identity_url: "ldap-provider:this-will-trigger-a-warning")
                result = validator.call

                expect(result[:provisioned_user_provider]).to be_warning
                expect(result[:provisioned_user_provider].message).to eq(I18n.t(i18n_key(:oidc_non_oidc_user)))

                state_count = result.tally
                expect(state_count).to eq({ success: 1, skipped: 2, warning: 1 })
              end
            end

            describe "checks related to the token" do
              context "when the token doesn't have the necessary audiences" do
                it "returns a validation failure in case the server does not support token exchange" do
                  create(:oidc_user_token, user:)
                  result = validator.call

                  expect(result[:token_negotiable]).to be_failure
                  expect(result[:token_negotiable].message).to eq(I18n.t(i18n_key(:oidc_cant_acquire_token)))
                end
              end

              context "when the existing token requires a refresh" do
                let(:expired_storage_token) do
                  create(:oidc_user_token, user:, extra_audiences: storage.audience, expires_at: 10.hours.ago)
                end

                it "tries to refresh the token if it is expired" do
                  refresh_request = stub_request(:post, oidc_provider.token_endpoint)
                                      .with(body: { grant_type: "refresh_token",
                                                    refresh_token: expired_storage_token.refresh_token })
                                      .and_return_json(status: 200, body: { access_token: "NEW_TOKEN" })

                  expect(validator.call).to be_success
                  expect(refresh_request).to have_been_requested.once
                end

                it "fails when the refresh response is invalid" do
                  stub_request(:post, oidc_provider.token_endpoint)
                    .with(body: { grant_type: "refresh_token", refresh_token: expired_storage_token.refresh_token })
                    .and_return_json(status: 200, body: { error: "this is a broken endpoint" })

                  result = validator.call

                  expect(result[:token_negotiable]).to be_failure
                  expect(result[:token_negotiable].message).to eq(I18n.t(i18n_key(:oidc_cant_refresh_token)))
                end

                it "fails when refresh fails" do
                  stub_request(:post, oidc_provider.token_endpoint)
                    .with(body: { grant_type: "refresh_token", refresh_token: expired_storage_token.refresh_token })
                    .and_return(status: 401)

                  result = validator.call

                  expect(result[:token_negotiable]).to be_failure
                  expect(result[:token_negotiable].message).to eq(I18n.t(i18n_key(:oidc_cant_refresh_token)))
                end

                context "when the server supports token exchange" do
                  let(:oidc_provider) { create(:oidc_provider, :token_exchange_capable) }
                  let(:exchangeable_token) { create(:oidc_user_token, user:, refresh_token: nil) }

                  it "favors token exchange when refreshing" do
                    exchange_request = stub_request(:post, oidc_provider.token_endpoint)
                                         .with(body: { audience: storage.audience, subject_token: exchangeable_token.access_token,
                                                       grant_type: OpenIDConnect::Provider::TOKEN_EXCHANGE_GRANT_TYPE })
                                         .and_return_json(status: 200, body: { access_token: "NEW_TOKEN" })

                    expect(validator.call).to be_success
                    expect(exchange_request).to have_been_requested.once
                  end

                  it "fails if the exchange is met with an unexpected body" do
                    exchange_request = stub_request(:post, oidc_provider.token_endpoint)
                                         .with(body: { audience: storage.audience, subject_token: exchangeable_token.access_token,
                                                       grant_type: OpenIDConnect::Provider::TOKEN_EXCHANGE_GRANT_TYPE })
                                         .and_return_json(status: 200, body: { error: "failed " })

                    result = validator.call

                    expect(result[:token_negotiable]).to be_failure
                    expect(result[:token_negotiable].message).to eq(I18n.t(i18n_key(:oidc_cant_exchange_token)))
                    expect(exchange_request).to have_been_requested.once
                  end

                  it "fails if the exchange fails" do
                    exchange_request = stub_request(:post, oidc_provider.token_endpoint)
                                         .with(body: { audience: storage.audience, subject_token: exchangeable_token.access_token,
                                                       grant_type: OpenIDConnect::Provider::TOKEN_EXCHANGE_GRANT_TYPE })
                                         .and_return(status: 401)

                    result = validator.call

                    expect(result[:token_negotiable]).to be_failure
                    expect(result[:token_negotiable].message).to eq(I18n.t(i18n_key(:oidc_cant_exchange_token)))
                    expect(exchange_request).to have_been_requested.once
                  end
                end
              end
            end
          end

          private

          def i18n_key(key) = "storages.health.connection_validation.#{key}"
        end
      end
    end
  end
end
