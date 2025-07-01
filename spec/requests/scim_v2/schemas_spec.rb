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

RSpec.describe "SCIM API Schemas" do
  let(:oidc_provider_slug) { "keycloak" }
  let(:oidc_provider) { create(:oidc_provider, slug: oidc_provider_slug) }
  let(:headers) { { "CONTENT_TYPE" => "application/scim+json", "HTTP_AUTHORIZATION" => "Bearer #{token.plaintext_token}" } }
  let(:token) { create(:oauth_access_token, resource_owner: service_account, scopes: ["scim_v2"]) }
  let(:service_account) { create(:service_account, service: scim_client) }
  let(:scim_client) { create(:scim_client, authentication_method: :oauth2_token, auth_provider_id: oidc_provider.id) }

  before { token }

  describe "GET /scim_v2/Schemas" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      it do
        get "/scim_v2/Schemas", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body["totalResults"]).to eq(2)
        expect(response_body["schemas"]).to eq(["urn:ietf:params:scim:api:messages:2.0:ListResponse"])
        expect(response_body["schemas"]).to eq(["urn:ietf:params:scim:api:messages:2.0:ListResponse"])
        group_schema = response_body["Resources"].find { |r| r["name"] == "Group" }
        user_schema = response_body["Resources"].find { |r| r["name"] == "User" }
        external_id_schema = { "multiValued" => false,
                               "required" => true,
                               "caseExact" => true,
                               "mutability" => "readWrite",
                               "uniqueness" => "none",
                               "returned" => "default",
                               "name" => "externalId",
                               "type" => "string" }
        expect(group_schema["attributes"]).to include(external_id_schema)
        expect(user_schema["attributes"]).to include(external_id_schema)
      end
    end

    context "with the feature flag disabled", with_flag: { scim_api: false } do
      it do
        get "/scim_v2/Schemas", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Requires authentication", "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "401" }
        )
      end
    end
  end
end
