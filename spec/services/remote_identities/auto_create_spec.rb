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

RSpec.describe RemoteIdentities::AutoCreate do
  subject { described_class.handle_login(user) }

  let(:user) { create(:user, authentication_provider:) }
  let(:authentication_provider) { create(:oidc_provider) }

  let(:integrations_a) { instance_double(Proc, call: integrations.take(2)) }
  let(:integrations_b) { instance_double(Proc, call: [integrations.last]) }
  let(:integrations) { ["Integration A1", "Integration A2", "Integration B"] }
  let(:token_fetcher_a) { instance_double(Proc, call: "token-a") }
  let(:token_fetcher_b) { instance_double(Proc, call: "token-b") }
  let(:create_remote_identity) { instance_double(RemoteIdentities::CreateService, call: create_result) }
  let(:create_result) { ServiceResult.success(result: "mh?") }

  around do |example|
    # Making sure the test does not have lasting consequences outside its scope
    original_configs = described_class.instance_variable_get(:@configs)
    described_class.instance_variable_set(:@configs, [])
    example.run
  ensure
    described_class.instance_variable_set(:@configs, original_configs)
  end

  before do
    described_class.register(:alice, integration_fetcher: integrations_a, token_fetcher: token_fetcher_a)
    described_class.register(:bob, integration_fetcher: integrations_b, token_fetcher: token_fetcher_b)

    allow(RemoteIdentities::CreateService).to receive(:new).and_return(create_remote_identity)
    allow(Rails.logger).to receive(:error)
  end

  it "calls the create service once per integration", :aggregate_failures do
    subject

    expect(create_remote_identity).to have_received(:call).exactly(3).times
    expect(create_remote_identity).to have_received(:call).with(token: "token-a").twice
    expect(create_remote_identity).to have_received(:call).with(token: "token-b").once
  end

  it "instanciates the create service once per integration" do
    subject

    integrations.each do |integration|
      expect(RemoteIdentities::CreateService).to have_received(:new).with(
        user:,
        integration:,
        auth_source: authentication_provider
      ).once
    end
  end

  it "passes the user into the integrations callback" do
    subject

    expect(integrations_a).to have_received(:call).with(user)
    expect(integrations_b).to have_received(:call).with(user)
  end

  it "passes user and integration into the token fetcher" do
    subject

    expect(token_fetcher_a).to have_received(:call).with(user, integrations.first).once
    expect(token_fetcher_a).to have_received(:call).with(user, integrations.second).once
    expect(token_fetcher_b).to have_received(:call).with(user, integrations.last).once
  end

  it "logs no error" do
    subject

    expect(Rails.logger).not_to have_received(:error)
  end

  context "when creating a remote identity fails" do
    let(:create_result) { ServiceResult.failure(errors: "oh no!") }

    it "logs an error" do
      subject

      expect(Rails.logger).to have_received(:error).at_least(:once)
    end

    it "continues processing for other integrations" do
      subject

      expect(create_remote_identity).to have_received(:call).at_least(:once)
    end
  end

  context "when an exception occurs" do
    before do
      allow(token_fetcher_a).to receive(:call).and_raise("Oh no!")
    end

    it "logs an error" do
      subject

      expect(Rails.logger).to have_received(:error).at_least(:once)
    end

    it "continues processing for other integrations" do
      subject

      expect(create_remote_identity).to have_received(:call).at_least(:once)
    end
  end
end
