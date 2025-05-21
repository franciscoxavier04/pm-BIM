# frozen_string_literal: true

require "spec_helper"

require "services/base_services/behaves_like_create_service"

RSpec.describe RemoteIdentities::CreateService, :storage_server_helpers, type: :model do
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

  before do
    allow(OpenProject::Notifications).to receive(:send)
    allow(integration).to receive(:extract_origin_user_id).and_return(ServiceResult.success(result: "the-extracted-user-id"))
  end

  describe ".call" do
    it "requires certain parameters" do
      method = described_class.method :call

      expect(method.parameters).to contain_exactly(
        %i[keyreq user],
        %i[keyreq token],
        %i[keyreq integration],
        %i[key force_update]
      )
    end

    it "succeeds" do
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
      }.from([]).to(["the-extracted-user-id"])
    end

    context "when calling multiple times, without the model changing in-between" do
      before do
        2.times { service.call }
      end

      it "emits only one event" do
        expect(OpenProject::Notifications).to have_received(:send).with(
          OpenProject::Events::REMOTE_IDENTITY_CREATED,
          integration:
        ).once
      end

      it "only queries for the origin_user_id once" do
        expect(integration).to have_received(:extract_origin_user_id).once
      end
    end

    context "when calling multiple times, with changes to the model in between" do
      before do
        model = service.call.result
        model.update!(origin_user_id: "the-changed-user-id")
        service.call
      end

      it "emits only one event" do
        expect(OpenProject::Notifications).to have_received(:send).with(
          OpenProject::Events::REMOTE_IDENTITY_CREATED,
          integration:
        ).once
      end

      it "only queries for the origin_user_id once" do
        expect(integration).to have_received(:extract_origin_user_id).once
      end

      it "does not undo changes to the model" do
        expect(RemoteIdentity.last.origin_user_id).to eq("the-changed-user-id")
      end

      context "when the force_update flag is enabled" do
        subject(:service) { described_class.new(user:, token: oauth_client_token, integration:, force_update: true) }

        it "emits multiple events" do
          expect(OpenProject::Notifications).to have_received(:send).with(
            OpenProject::Events::REMOTE_IDENTITY_CREATED,
            integration:
          ).twice
        end

        it "queries for the origin_user_id again" do
          expect(integration).to have_received(:extract_origin_user_id).twice
        end

        it "updates the model" do
          expect(RemoteIdentity.last.origin_user_id).to eq("the-extracted-user-id")
        end
      end
    end
  end
end
