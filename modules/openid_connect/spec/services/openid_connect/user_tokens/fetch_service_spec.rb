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

RSpec.describe OpenIDConnect::UserTokens::FetchService, :webmock do
  let(:service) { described_class.new(user:, jwt_parser:) }
  let(:user) { create(:user, identity_url: "#{provider.slug}:1337") }
  let(:provider) { create(:oidc_provider) }
  let(:jwt_parser) { instance_double(OpenIDConnect::JwtParser, parse: Success([parsed_jwt, nil])) }
  let(:parsed_jwt) { { "exp" => Time.now.to_i + 60 } }

  let(:access_token) { "the-access-token" }
  let(:refresh_token) { "the-refresh-token" }

  let(:existing_audience) { "existing-audience" }
  let(:queried_audience) { existing_audience }

  let(:refresh_response) do
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
      body: { access_token: "#{access_token}-refreshed", refresh_token: "#{refresh_token}-refreshed" }.to_json
    }
  end

  before do
    user.oidc_user_tokens.create!(access_token:, refresh_token:, audiences: [existing_audience])
    stub_request(:post, provider.token_endpoint).to_return(**refresh_response)
  end

  shared_examples_for "returns a refreshed access token" do
    it { is_expected.to be_success }

    it "returns a refreshed access token" do
      expect(result.value!).to eq("the-access-token-refreshed")
    end

    it "updates the stored access token" do
      expect { subject }.to change { user.oidc_user_tokens.first.access_token }.to("the-access-token-refreshed")
    end

    it "updates the stored refresh token" do
      expect { subject }.to change { user.oidc_user_tokens.first.refresh_token }.to("the-refresh-token-refreshed")
    end

    context "when the refresh response is unexpected JSON" do
      let(:refresh_response) do
        {
          status: 200, # misbehaving server responds with wrong JSON for success status
          headers: { "Content-Type": "application/json" },
          body: { error: "I can't let you do that Dave!" }.to_json
        }
      end

      it { is_expected.to be_failure }
    end

    context "when the refresh response has unexpected status" do
      let(:refresh_response) do
        {
          status: 502,
          headers: { "Content-Type": "text/html" },
          body: "<html><body>502 Bad Gateway</body></html>"
        }
      end

      it { is_expected.to be_failure }
    end
  end

  describe "#access_token_for" do
    subject(:result) { service.access_token_for(audience: queried_audience) }

    it { is_expected.to be_success }

    it "returns the stored access token" do
      expect(result.value!).to eq(access_token)
    end

    context "when the token can't be parsed as JWT" do
      let(:jwt_parser) { instance_double(OpenIDConnect::JwtParser, parse: Failure("Not a valid JWT")) }

      it { is_expected.to be_success }

      it "returns the stored access token" do
        expect(result.value!).to eq(access_token)
      end
    end

    context "when the token is expired" do
      let(:parsed_jwt) { { "exp" => Time.now.to_i } }

      it_behaves_like "returns a refreshed access token"

      context "and there is no refresh token" do
        let(:refresh_token) { nil }

        it { is_expected.to be_failure }

        it "does not try to perform a token refresh" do
          subject
          expect(WebMock).not_to have_requested(:post, provider.token_endpoint)
        end
      end
    end

    context "when audience can't be found" do
      let(:queried_audience) { "wrong-audience" }

      it { is_expected.to be_failure }
    end
  end

  describe "#refreshed_access_token_for" do
    subject(:result) { service.refreshed_access_token_for(audience: queried_audience) }

    it_behaves_like "returns a refreshed access token"

    context "when audience can't be found" do
      let(:queried_audience) { "wrong-audience" }

      it { is_expected.to be_failure }
    end

    context "and there is no refresh token" do
      let(:refresh_token) { nil }

      it { is_expected.to be_failure }

      it "does not try to perform a token refresh" do
        subject
        expect(WebMock).not_to have_requested(:post, provider.token_endpoint)
      end
    end
  end
end
