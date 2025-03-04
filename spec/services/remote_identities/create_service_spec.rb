# frozen_string_literal: true

require "spec_helper"

require "services/base_services/behaves_like_create_service"

RSpec.describe RemoteIdentities::CreateService, :storage_server_helpers, :webmock, type: :model do
  let(:user) { create(:user) }
  let(:integration) { create(:nextcloud_storage_configured) }
  let(:oauth_config) { integration.oauth_configuration }
  let(:auth_source) { oauth_config.oauth_client }
  let(:oauth_client_token) do
    create(:oauth_client_token,
           user:,
           oauth_client: oauth_config.oauth_client)
  end

  subject(:service) { described_class.new(user:, token: oauth_client_token, integration:) }

  before { stub_nextcloud_user_query(integration.host) }

  describe ".call" do
    it "requires certain parameters" do
      method = described_class.method :call

      expect(method.parameters).to contain_exactly(%i[keyreq user], %i[keyreq token], %i[keyreq integration])
    end

    it "succeeds", :webmock do
      expect(described_class.call(user:, token: oauth_client_token, integration:)).to be_success
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

    it "sets origin_user_id" do
      expect { service.call.result }.to change {
        RemoteIdentity.pluck(:origin_user_id)
      }.from([]).to(["admin"])
    end

    it "emits only one event for a number of subsequent calls if model has not changed" do
      allow(OpenProject::Notifications)
        .to receive(:send).with(OpenProject::Events::REMOTE_IDENTITY_CREATED, integration:).once
      3.times { service.call.result }
    end

    it "emits two events for 2 subsequent calls if model has changed between them" do
      allow(OpenProject::Notifications)
        .to receive(:send).with(OpenProject::Events::REMOTE_IDENTITY_CREATED, integration:).twice

      model = service.call.result
      model.origin_user_id = "123123"
      model.save
      service.call.result
    end
  end
end
