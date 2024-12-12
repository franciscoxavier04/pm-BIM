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

RSpec.describe OpenIDConnect::AssociateUserToken do
  subject { described_class.new(session).call(**args) }

  let(:session) do
    instance_double(ActionDispatch::Request::Session,
                    id: instance_double(Rack::Session::SessionId, private_id: 42))
  end

  let(:args) { { access_token:, refresh_token:, assume_idp: true } }

  let(:access_token) { "access-token-foo" }
  let(:refresh_token) { "refresh-token-bar" }

  let!(:user_session) { create(:user_session, session_id: session.id.private_id) }

  before do
    allow(Rails.logger).to receive(:error)
  end

  it "creates a correct user token", :aggregate_failures do
    expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

    token = OpenIDConnect::UserToken.last
    expect(token.access_token).to eq access_token
    expect(token.refresh_token).to eq refresh_token
    expect(token.audiences).to eq ["__op-idp__"]
  end

  it "logs no error" do
    subject
    expect(Rails.logger).not_to have_received(:error)
  end

  context "when there is no refresh token" do
    let(:refresh_token) { nil }

    it "creates a correct user token", :aggregate_failures do
      expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

      token = OpenIDConnect::UserToken.last
      expect(token.access_token).to eq access_token
      expect(token.refresh_token).to be_nil
      expect(token.audiences).to eq ["__op-idp__"]
    end

    it "logs no error" do
      subject
      expect(Rails.logger).not_to have_received(:error)
    end
  end

  context "when there is no access token" do
    let(:access_token) { nil }

    it "does not create a user token" do
      expect { subject }.not_to change(OpenIDConnect::UserToken, :count)
    end

    it "logs an error" do
      subject
      expect(Rails.logger).to have_received(:error)
    end
  end

  context "when the user session can't be found" do
    let!(:user_session) { create(:user_session, session_id: SecureRandom.uuid) }

    it "does not create a user token" do
      expect { subject }.not_to change(OpenIDConnect::UserToken, :count)
    end

    it "logs an error" do
      subject
      expect(Rails.logger).to have_received(:error)
    end
  end

  context "when we are not allowed to assume the token has the IDP audience" do
    let(:args) { { access_token:, refresh_token: } }

    it "does not create a user token" do
      expect { subject }.not_to change(OpenIDConnect::UserToken, :count)
    end

    it "logs no error" do
      subject
      expect(Rails.logger).not_to have_received(:error)
    end
  end
end
