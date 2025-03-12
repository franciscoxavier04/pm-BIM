# frozen_string_literal: true

#-- copyright
# OpenProject is a project management system.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# +

require "spec_helper"

RSpec.describe OpenProject::OpenIDConnect::Hooks::Hook do
  describe "#omniauth_user_authorized" do
    subject(:call_hook) { described_class.instance.omniauth_user_authorized(context) }

    let(:context) { { controller:, auth_hash: } }
    let(:controller) { instance_double(ActionController::Base, session:) }
    let(:session) { {} }

    let(:existing_provider) { create(:oidc_provider, slug: "oidc-foo") }

    let(:auth_hash) { { provider: "oidc-foo", credentials: { token:, refresh_token:, expires_in: } } }
    let(:token) { "an-access-token" }
    let(:refresh_token) { "a-refresh-token" }
    let(:expires_in) { 3600 }

    before do
      existing_provider.save!
    end

    it "populates the session with token information", :aggregate_failures do
      call_hook

      expect(session["omniauth.oidc_access_token"]).to eq(token)
      expect(session["omniauth.oidc_refresh_token"]).to eq(refresh_token)
      expect(session["omniauth.oidc_expires_in"]).to eq(expires_in)
    end

    context "when the provider indicated in the auth hash can't be found" do
      let(:existing_provider) { create(:oidc_provider, slug: "oidc-bar") }

      it "does not change the session at all" do
        call_hook

        expect(session).to be_empty
      end
    end
  end
end
