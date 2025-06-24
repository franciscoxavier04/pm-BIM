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

RSpec.describe "SCIM API ServiceProviderConfig" do
  let(:external_user_id) { "idp_user_id_123asdqwe12345" }
  let(:external_group_id) { "idp_group_id_123asdqwe12345" }
  let(:admin) { create(:admin) }
  let(:oidc_provider) { create(:oidc_provider, slug: "keycloak", creator: admin) }
  let(:user) { create(:user, identity_url: "#{oidc_provider.slug}:#{external_user_id}") }
  let(:group) { create(:group, identity_url: "#{oidc_provider.slug}:#{external_group_id}", members: [user]) }
  let(:headers) { { "CONTENT_TYPE" => "application/scim+json", "HTTP_AUTHORIZATION" => "Bearer access_token" } }

  describe "GET /scim_v2/ServiceProviderConfig" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      before { group }

      it do
        get "/scim_v2/Schemas", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body["totalResults"]).to eq(2)
        expect(response_body["schemas"]).to eq(["urn:ietf:params:scim:api:messages:2.0:ListResponse"])
        expect(response_body["schemas"]).to eq(["urn:ietf:params:scim:api:messages:2.0:ListResponse"])
        group_schema = response_body["Resources"].find { |r| r["name"] == "Group" }
        user_schema = response_body["Resources"].find { |r| r["name"] == "User" }
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
