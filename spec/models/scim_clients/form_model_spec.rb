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

RSpec.describe ScimClients::FormModel do
  describe ".from_client" do
    subject { described_class.from_client(client) }

    let(:client) do
      create(
        :scim_client, service_account: create(:service_account, authentication_provider: auth_provider, external_id: "abc-def"),
                      authentication_method: :sso,
                      auth_provider:
      )
    end
    let(:auth_provider) { create(:oidc_provider) }

    it "builds a proper FormModel", :aggregate_failures do
      expect(subject.name).to eq(client.name)
      expect(subject.auth_provider_id).to eq(auth_provider.id)
      expect(subject.authentication_method).to eq("sso")
      expect(subject.jwt_sub).to eq("abc-def")
    end

    context "when the auth provider link is missing" do
      let(:client) do
        create :scim_client, service_account: create(:service_account),
                             authentication_method: :sso,
                             auth_provider:
      end

      it "fills the auth_provider_id correctly" do
        expect(subject.auth_provider_id).to eq(auth_provider.id)
      end

      it "leaves the jwt_sub blank" do
        expect(subject.jwt_sub).to be_nil
      end
    end
  end

  describe ".from_params" do
    subject { described_class.from_params(params) }

    let(:params) { { name: "The Client", auth_provider_id: 42, authentication_method: :banana, jwt_sub: "a-sub" } }

    it "builds a proper FormModel", :aggregate_failures do
      expect(subject.name).to eq("The Client")
      expect(subject.auth_provider_id).to eq(42)
      expect(subject.authentication_method).to eq("banana")
      expect(subject.jwt_sub).to eq("a-sub")
    end
  end
end
