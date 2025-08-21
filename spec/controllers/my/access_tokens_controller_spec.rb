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

RSpec.describe My::AccessTokensController do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "rss" do
    it "creates a key" do
      expect(user.rss_token).to be_nil

      post :generate_rss_key
      expect(user.reload.rss_token).to be_present
      expect(flash[:info]).to be_present
      expect(flash[:error]).not_to be_present

      expect(response).to redirect_to action: :index
    end

    context "with existing key" do
      let!(:key) { Token::RSS.create user: }

      it "replaces the key" do
        expect(user.rss_token).to eq(key)

        post :generate_rss_key
        new_token = user.reload.rss_token
        expect(new_token).not_to eq(key)
        expect(new_token.value).not_to eq(key.value)
        expect(new_token.value).to eq(user.rss_key)

        expect(flash[:info]).to be_present
        expect(flash[:error]).not_to be_present
        expect(response).to redirect_to action: :index
      end
    end
  end

  describe "api" do
    context "with no existing key" do
      it "creates a key" do
        expect(user.api_tokens).to be_empty

        post :generate_api_key, params: { token_api: { token_name: "One heck of a token" } }, format: :turbo_stream
        new_token = user.reload.api_tokens.last
        expect(new_token).to be_present

        expect(response).to be_successful
        expect(response.body).to include(new_token.token_name)
      end
    end

    context "with existing key" do
      let!(:key) { Token::API.create(user:, data: { name: "One heck of a token" }) }

      it "must add the new key" do
        expect(user.reload.api_tokens.last).to eq(key)

        post :generate_api_key, params: { token_api: { token_name: "Two heck of a token" } }, format: :turbo_stream

        new_token = user.reload.api_tokens.last
        expect(new_token).not_to eq(key)
        expect(new_token.value).not_to eq(key.value)

        expect(response).to be_successful
        expect(response.body).to include("Two heck of a token")
      end
    end
  end

  describe "ical" do
    # unlike with the other tokens, creating new ical tokens is not done in this context
    # ical tokens are generated whenever the user requests a new ical url
    # a user can have N ical tokens
    #
    # in this context a specific ical token of a user should be reverted
    # this invalidates the previously generated ical url
    context "with existing keys" do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:query) { create(:query, project:) }
      let(:another_query) { create(:query, project:) }
      let!(:ical_token_for_query) { create(:ical_token, user:, query:, name: "Some Token Name") }
      let!(:another_ical_token_for_query) { create(:ical_token, user:, query:, name: "Some Other Token Name") }
      let!(:ical_token_for_another_query) { create(:ical_token, user:, query: another_query, name: "Some Token Name") }

      it "revoke specific ical tokens" do
        expect(user.ical_tokens).to contain_exactly(
          ical_token_for_query, another_ical_token_for_query, ical_token_for_another_query
        )

        delete :revoke_ical_token, params: { access_token_id: another_ical_token_for_query.id }

        expect(user.ical_tokens.reload).to contain_exactly(
          ical_token_for_query, ical_token_for_another_query
        )

        expect(user.ical_tokens.reload).not_to contain_exactly(
          ical_token_for_another_query
        )

        expect(flash[:info]).to be_present
        expect(flash[:error]).not_to be_present

        expect(response).to redirect_to action: :index
      end
    end
  end

  describe "file storage" do
    let(:client) { create(:oauth_client, integration: create(:nextcloud_storage)) }
    let(:token) { create(:oauth_client_token, oauth_client: client, scope: nil, user:, expires_in: 3_600) }

    render_views

    before { token }

    it "list the tokens" do
      get :index
      expect(response.body).to have_css("#storage-oauth-token-#{token.id}")
    end

    it "can remove the token" do
      expect do
        delete :revoke_storage_token, params: { access_token_id: token.id }
      end.to change(OAuthClientToken, :count).by(-1)

      expect(flash[:info]).to be_present
      expect(flash[:error]).not_to be_present
      expect(response).to redirect_to(action: :index)
    end
  end
end
