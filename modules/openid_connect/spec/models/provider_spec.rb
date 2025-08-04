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

RSpec.describe OpenIDConnect::Provider do
  let(:provider) do
    create(:oidc_provider, options: {
             "grant_types_supported" => supported_grant_types
           })
  end
  let(:supported_grant_types) { %w[authorization_code implicit] }

  describe "#token_exchange_capable?" do
    subject { provider.token_exchange_capable? }

    it { is_expected.to be_falsey }

    context "when the provider supports the token exchange grant" do
      let(:supported_grant_types) { %w[authorization_code implicit urn:ietf:params:oauth:grant-type:token-exchange] }

      it { is_expected.to be_truthy }
    end

    context "when supported grant types are nil (legacy providers)" do
      let(:supported_grant_types) { nil }

      it { is_expected.to be_falsey }
    end
  end

  describe "#to_h" do
    subject { provider.to_h }

    let(:options) { raise "define me!" }

    before do
      options.stringify_keys.each do |opt, value|
        provider.options[opt] = value
      end
    end

    describe "with claims" do
      let(:options) { { claims: "login" } }

      it "includes the claims" do
        expect(subject[:claims]).to eq "login"
      end
    end

    describe "with acr_values" do
      let(:options) { { acr_values: "phr" } }

      it "includes the acr values" do
        expect(subject[:acr_values]).to eq "phr"
      end
    end

    describe "with mapped attributes" do
      let(:options) do
        {
          mapping_email: :address,
          mapping_login: :logout,
          mapping_first_name: :given_name,
          mapping_last_name: :surname
        }
      end

      let(:expected_value) do
        {
          email: :address,
          login: :logout,
          first_name: :given_name,
          last_name: :surname
        }
      end

      it "contains the resulting attribute map being passed to omniauth-openid-connect" do
        expect(subject[:attribute_map]).to eq expected_value
      end

      it "does not turn them into superfluous attributes" do
        expect(subject).not_to include :email
        expect(subject).not_to include :login
        expect(subject).not_to include :first_name
        expect(subject).not_to include :last_name
      end
    end

    describe "with post_logout_redirect_uri" do
      let(:options) { { post_logout_redirect_uri: "https://www.openproject.org" } }

      it "contains the option" do
        expect(subject[:post_logout_redirect_uri]).to eq options[:post_logout_redirect_uri]
      end
    end
  end
end
