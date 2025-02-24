# frozen_string_literal: true

FactoryBot.define do
  factory :oidc_user_token, class: "OpenIDConnect::UserToken" do
    transient do
      extra_audiences { nil }
    end

    user
    access_token { "INVALID_TOKEN" }
    refresh_token { "REFRESH_TOKEN" }
    expires_at { 1.hour.from_now }
    audiences { [OpenIDConnect::UserToken::IDP_AUDIENCE] + Array(extra_audiences) }
  end
end
