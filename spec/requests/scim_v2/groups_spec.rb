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

RSpec.describe "SCIM API Groups" do
  let(:external_user_id) { "idp_user_id_123asdqwe12345" }
  let(:external_group_id) { "idp_group_id_123asdqwe12345" }
  let(:external_admin_id) { "idp_admin_id_123asdqwe12345" }
  let(:oidc_provider_slug) { "keycloak" }
  let(:oidc_provider) { create(:oidc_provider, slug: oidc_provider_slug) }
  let(:admin) { create(:admin, identity_url: "#{oidc_provider_slug}:#{external_admin_id}") }
  let(:user) { create(:user, identity_url: "#{oidc_provider_slug}:#{external_user_id}") }
  let(:user1) { user }
  let(:user2) { create(:user, identity_url: "#{oidc_provider_slug}:#{external_user_id}_user2") }
  let(:group) { create(:group, identity_url: "#{oidc_provider_slug}:#{external_group_id}", members: [user]) }
  let(:group_without_external_id) { create(:group, members: [user]) }
  let(:headers) { { "CONTENT_TYPE" => "application/scim+json", "HTTP_AUTHORIZATION" => "Bearer #{token.plaintext_token}" } }
  let(:token) { create(:oauth_access_token, resource_owner: service_account, scopes: ["scim_v2"]) }
  let(:service_account) { create(:service_account, service: scim_client, admin: true) }
  let(:scim_client) { create(:scim_client, authentication_method: :oauth2_token, auth_provider_id: oidc_provider.id) }

  before do
    oidc_provider
    group_without_external_id
    token
  end

  describe "GET /scim_v2/Groups" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      before { group }

      it "responds with group list" do
        get "/scim_v2/Groups", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to match({ "Resources" => contain_exactly({ "displayName" => group.name,
                                                                          "externalId" => external_group_id,
                                                                          "id" => group.id.to_s,
                                                                          "members" => [{ "value" => user.id.to_s }],
                                                                          "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                                                      "created" => group.created_at.iso8601,
                                                                                      "lastModified" => group.updated_at.iso8601,
                                                                                      "resourceType" => "Group" },
                                                                          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] }, { "displayName" => group_without_external_id.name,
                                                                                                                                            "id" => group_without_external_id.id.to_s,
                                                                                                                                            "members" => [{ "value" => user.id.to_s }],
                                                                                                                                            "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group_without_external_id.id}",
                                                                                                                                                        "created" => group_without_external_id.created_at.iso8601,
                                                                                                                                                        "lastModified" => group_without_external_id.updated_at.iso8601,
                                                                                                                                                        "resourceType" => "Group" },
                                                                                                                                            "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] }),
                                         "itemsPerPage" => 100,
                                         "schemas" => ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
                                         "startIndex" => 1,
                                         "totalResults" => 2 })
      end

      it "filters results" do
        filter = ERB::Util.url_encode("displayName Eq \"#{group.name}\"")
        get "/scim_v2/Groups?filter=#{filter}", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq({ "Resources" => [{ "displayName" => group.name,
                                                        "externalId" => external_group_id,
                                                        "id" => group.id.to_s,
                                                        "members" => [{ "value" => user.id.to_s }],
                                                        "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                                    "created" => group.created_at.iso8601,
                                                                    "lastModified" => group.updated_at.iso8601,
                                                                    "resourceType" => "Group" },
                                                        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] }],
                                      "itemsPerPage" => 100,
                                      "schemas" => ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
                                      "startIndex" => 1,
                                      "totalResults" => 1 })

        filter = ERB::Util.url_encode('displayName Eq "NONEXISTENT GROUP NAME"')
        get "/scim_v2/Groups?filter=#{filter}", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq({ "Resources" => [],
                                      "itemsPerPage" => 100,
                                      "schemas" => ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
                                      "startIndex" => 1,
                                      "totalResults" => 0 })
      end
    end

    context "with the feature flag disabled", with_flag: { scim_api: false } do
      it do
        get "/scim_v2/Groups", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Requires authentication", "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "401" }
        )
        expect(last_response).to have_http_status(401)
      end
    end
  end

  describe "GET /scim_v2/Groups/:id" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      it "responds with specific group data" do
        group
        get "/scim_v2/Groups/#{group.id}", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "members" => [{ "value" => user.id.to_s }],
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end

      it "excludes specified attributes" do
        get "/scim_v2/Groups/#{group.id}?excludedAttributes=members", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
        expect(response_body["members"]).to be_nil
      end
    end

    context "with the feature flag disabled", with_flag: { scim_api: false } do
      it do
        get "/scim_v2/Groups/#{group.id}", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Requires authentication", "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "401" }
        )
        expect(last_response).to have_http_status(401)
      end
    end
  end

  describe "POST /scim_v2/Groups/" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      let(:group_name) { "Group 123" }

      it "creates a group with members" do
        user
        request_body = { "displayName" => group_name,
                         "externalId" => external_group_id,
                         "members" => [{ "value" => user.id.to_s }],
                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] }
        expect do
          post "/scim_v2/Groups/", request_body.to_json, headers
        end.to change(Group, :count).by(1)

        response_body = JSON.parse(last_response.body)
        group = Group.find_by(name: group_name)
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "members" => [{ "value" => user.id.to_s }],
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end

      it "creates group without members specified" do
        user
        request_body = { "displayName" => "Group 123",
                         "externalId" => external_group_id,
                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] }
        expect do
          post "/scim_v2/Groups/", request_body.to_json, headers
        end.to change(Group, :count).by(1)

        response_body = JSON.parse(last_response.body)
        group = Group.find_by(name: group_name)
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "members" => [],
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end
    end

    context "with the feature flag disabled", with_flag: { scim_api: false } do
      it do
        post "/scim_v2/Groups/", "", headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Requires authentication", "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "401" }
        )
        expect(last_response).to have_http_status(401)
      end
    end
  end

  describe "DELETE /scim_v2/Groups/:id" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      it "deletes specific group" do
        group
        delete "/scim_v2/Groups/#{group.id}", "", headers

        expect(last_response.body).to eq("")
        expect(last_response).to have_http_status(204)

        get "/scim_v2/Groups/#{group.id}", "", headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "members" => [{ "value" => user.id.to_s }],
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })

        perform_enqueued_jobs
        assert_performed_jobs 1

        get "/scim_v2/Groups/#{group.id}", "", headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Resource \"#{group.id}\" not found",
            "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "404" }
        )
      end
    end

    context "with the feature flag disabled", with_flag: { scim_api: false } do
      it do
        delete "/scim_v2/Users/123", "", headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Requires authentication", "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "401" }
        )
        expect(last_response).to have_http_status(401)
      end
    end
  end

  describe "PUT /scim_v2/Groups/:id" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      it "updates specific group by replacing it with newly provided data" do
        admin
        group
        new_external_group_id = "new_idp_group_id_123asdqwe12345"
        request_body = {
          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
          "active" => true,
          "externalId" => new_external_group_id,
          "displayName" => group.name,
          "members" => [
            { "value" => user.id.to_s },
            { "value" => admin.id.to_s }
          ]
        }

        put "/scim_v2/Groups/#{group.id}", request_body.to_json, headers

        response_body = JSON.parse(last_response.body)
        group.reload
        expect(response_body).to match({ "displayName" => group.name,
                                         "externalId" => new_external_group_id,
                                         "id" => group.id.to_s,
                                         "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                     "created" => group.created_at.iso8601,
                                                     "lastModified" => group.updated_at.iso8601,
                                                     "resourceType" => "Group" },
                                         "members" => contain_exactly({ "value" => user.id.to_s }, { "value" => admin.id.to_s }),
                                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end
    end

    context "with the feature flag disabled", with_flag: { scim_api: false } do
      it do
        put "/scim_v2/Groups/123", "", headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Requires authentication", "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "401" }
        )
        expect(last_response).to have_http_status(401)
      end
    end
  end

  describe "PATCH /scim_v2/Groups/:id" do
    context "with the feature flag enabled", with_flag: { scim_api: true } do
      it "supports external_id replacing" do
        group
        new_external_group_id = "new_idp_user_id_123asdqwe12345"
        request_body = {
          "schemas" =>
          ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          "Operations" => [{
            "op" => "replace",
            "path" => "externalId",
            "value" => new_external_group_id
          }]
        }
        patch "/scim_v2/Groups/#{group.id}", request_body.to_json, headers

        response_body = JSON.parse(last_response.body)
        group.reload
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => new_external_group_id,
                                      "id" => group.id.to_s,
                                      "members" => [{ "value" => user.id.to_s }],
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end

      it "supports replacing of members" do
        group
        user2

        request_body = {
          "schemas" =>
          ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          "Operations" => [{
            "op" => "replace",
            "path" => "members",
            "value" => [{
              "value" => user2.id.to_s
            }]
          }]
        }
        patch "/scim_v2/Groups/#{group.id}", request_body.to_json, headers

        response_body = JSON.parse(last_response.body)
        group.reload
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "members" => [{ "value" => user2.id.to_s }],
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end

      it "supports adding of a member" do
        group
        user2

        request_body = {
          "schemas" =>
          ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          "Operations" => [{
            "op" => "add",
            "path" => "members",
            "value" => [{ "value" => user2.id.to_s }]
          }]
        }
        patch "/scim_v2/Groups/#{group.id}", request_body.to_json, headers

        response_body = JSON.parse(last_response.body)
        group.reload
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "members" => [{ "value" => user1.id.to_s },
                                                    { "value" => user2.id.to_s }],
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end

      it "supports removal of a member" do
        group

        request_body = {
          "schemas" =>
          ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          "Operations" => [{
            "op" => "remove",
            "path" => "members",
            "value" => [{ "value" => user1.id.to_s }]
          }]
        }
        patch "/scim_v2/Groups/#{group.id}", request_body.to_json, headers

        response_body = JSON.parse(last_response.body)
        group.reload
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "members" => [],
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end

      it "supports removal of a member with exclusion of members list from the response" do
        group

        request_body = {
          "schemas" =>
          ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          "Operations" => [{
            "op" => "remove",
            "path" => "members",
            "value" => [{ "value" => user1.id.to_s }]
          }]
        }
        patch "/scim_v2/Groups/#{group.id}?excludedAttributes=members", request_body.to_json, headers

        response_body = JSON.parse(last_response.body)
        group.reload
        expect(response_body).to eq({ "displayName" => group.name,
                                      "externalId" => external_group_id,
                                      "id" => group.id.to_s,
                                      "meta" => { "location" => "http://test.host/scim_v2/Groups/#{group.id}",
                                                  "created" => group.created_at.iso8601,
                                                  "lastModified" => group.updated_at.iso8601,
                                                  "resourceType" => "Group" },
                                      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"] })
      end
    end

    context "with the feature flag disabled", with_flag: { scim_api: false } do
      it do
        patch "/scim_v2/Groups/123", "", headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "Requires authentication", "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "401" }
        )
      end
    end
  end
end
