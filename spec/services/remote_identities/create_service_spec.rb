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

require "services/base_services/behaves_like_create_service"

RSpec.describe RemoteIdentities::CreateService, type: :model do
  let(:user) { create(:user) }
  let(:storage) { create(:nextcloud_storage_configured) }
  let(:oauth_config) { storage.oauth_configuration }
  let(:oauth_token) { Rack::OAuth2::AccessToken.new(access_token: "sudo-access-token", user_id: "bob-from-accounting") }

  subject(:service) { described_class.new(user:, oauth_config:, oauth_token:) }

  describe ".call" do
    it "requires a user, a oauth configuration and a rack token" do
      method = described_class.method :call

      expect(method.parameters).to contain_exactly(%i[keyreq user], %i[keyreq oauth_config], %i[keyreq oauth_token])
    end

    it "succeeds" do
      expect(described_class.call(user:, oauth_config:, oauth_token:)).to be_success
    end
  end

  describe "#user" do
    it "exposes a user which is available as a getter" do
      expect(service.user).to eq(user)
    end
  end

  describe "#call" do
    it "succeeds" do
      expect(service.call).to be_success
    end

    it "returns the model as a result" do
      result = service.call.result
      expect(result).to be_a RemoteIdentity
    end

    context "if creation fails" do
      let(:oauth_token) { Rack::OAuth2::AccessToken.new(access_token: "sudo-access-token") }

      it "is unsuccessful" do
        expect(service.call).to be_failure
      end

      it "exposes the errors" do
        result = service.call
        expect(result.errors.size).to eq(1)
        expect(result.errors[:origin_user_id]).to eq(["can't be blank."])
      end
    end
  end
end
