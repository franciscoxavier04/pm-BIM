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

RSpec.describe "SCIM API ServiceProviderConfig", with_ee: [:scim_api] do
  let(:oidc_provider_slug) { "keycloak" }
  let(:oidc_provider) { create(:oidc_provider, slug: oidc_provider_slug) }
  let(:headers) { { "CONTENT_TYPE" => "application/scim+json", "HTTP_AUTHORIZATION" => "Bearer #{token.plaintext_token}" } }
  let(:token) { create(:oauth_access_token, resource_owner: service_account, scopes: ["scim_v2"]) }
  let(:service_account) { create(:service_account, service: scim_client) }
  let(:scim_client) { create(:scim_client, authentication_method: :oauth2_token, auth_provider_id: oidc_provider.id) }

  before { token }

  describe "GET /scim_v2/ServiceProviderConfig" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      it "responds with full ServiceProviderConfig information if authorization is correct" do
        get "/scim_v2/ServiceProviderConfig", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to include("authenticationSchemes" => [{ "description" => "https://www.openproject.org/docs/system-admin-guide/authentication/scim/#a-static-access-token",
                                                                       "name" => "OAuth2",
                                                                       "type" => "oauth2" },
                                                                     { "description" => "https://www.openproject.org/docs/system-admin-guide/authentication/scim/#b-oauth-20-client-credentials",
                                                                       "name" => "OAuth Bearer Token",
                                                                       "type" => "oauthbearertoken" },
                                                                     { "description" => "https://www.openproject.org/docs/system-admin-guide/authentication/scim/#c-jwt-from-identity-provider",
                                                                       "name" => "OpenID Provider JWT",
                                                                       "type" => "oidcjwt" }],
                                         "bulk" => { "supported" => false },
                                         "changePassword" => { "supported" => false },
                                         "etag" => { "supported" => false },
                                         "filter" => { "maxResults" => 100,
                                                       "supported" => true },
                                         "patch" => { "supported" => true },
                                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"],
                                         "sort" => { "supported" => false })
      end

      context "when authorization header contains an invalid token" do
        let(:token) { object_double(Doorkeeper::AccessToken.new, plaintext_token: "123123") }

        it "responds with 401 Unauthorized" do
          get "/scim_v2/ServiceProviderConfig", {}, headers

          expect(last_response).to have_http_status(401)
          expect(last_response.body).to eq("invalid_token")
        end
      end

      context "when there is no authorization header at all" do
        let(:token) { object_double(Doorkeeper::AccessToken.new, plaintext_token: "123123") }

        it "responds with limited ServiceProviderConfig information" do
          get "/scim_v2/ServiceProviderConfig", {}, { "CONTENT_TYPE" => "application/scim+json" }

          expect(last_response).to have_http_status(200)
          response_body = JSON.parse(last_response.body)
          expect(response_body.keys).to eq(["meta", "schemas", "authenticationSchemes"])
          expect(response_body).to include("authenticationSchemes" => [{ "description" => "https://www.openproject.org/docs/system-admin-guide/authentication/scim/#a-static-access-token",
                                                                         "name" => "OAuth2",
                                                                         "type" => "oauth2" },
                                                                       { "description" => "https://www.openproject.org/docs/system-admin-guide/authentication/scim/#b-oauth-20-client-credentials",
                                                                         "name" => "OAuth Bearer Token",
                                                                         "type" => "oauthbearertoken" },
                                                                       { "description" => "https://www.openproject.org/docs/system-admin-guide/authentication/scim/#c-jwt-from-identity-provider",
                                                                         "name" => "OpenID Provider JWT",
                                                                         "type" => "oidcjwt" }],
                                           "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"])
        end
      end
    end

    context "with the feature flag disabled", with_flag: { scim_api: false } do
      it do
        get "/scim_v2/ServiceProviderConfig", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Requires authentication", "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "401" }
        )
        expect(last_response).to have_http_status(401)
      end
    end
  end
end
