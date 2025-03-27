# frozen_string_literal: true

module OpenProject
  module Authentication
    module Strategies
      module Warden
        class JwtOidc < ::Warden::Strategies::Base
          include FailWithHeader

          # The strategy is supposed to only handle JWT.
          # These tokens are supposed to be issued by configured OIDC.
          def valid?
            @access_token = ::Doorkeeper::OAuth::Token.from_bearer_authorization(
              ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
            )
            return false if @access_token.blank?

            unverified_payload, unverified_header = JWT.decode(@access_token, nil, false)
            unverified_payload.present? && unverified_header.present?
          rescue JWT::DecodeError
            false
          end

          def authenticate!
            ::OpenIDConnect::JwtParser.new(required_claims: ["sub"]).parse(@access_token).either(
              ->(payload_and_provider) do
                payload, provider = payload_and_provider
                user = User.find_by(identity_url: "#{provider.slug}:#{payload['sub']}")
                authentication_result(user)
              end,
              ->(error) { fail_with_header!(error: "invalid_token", error_description: error) }
            )
          end

          private

          def authentication_result(user)
            if user.nil?
              return fail_with_header!(
                error: "invalid_token",
                error_description: "The user identified by the token is not known"
              )
            end

            if user.active?
              success!(user)
            else
              fail_with_header!(
                error: "invalid_token",
                error_description: "The user account is locked"
              )
            end
          end
        end
      end
    end
  end
end
