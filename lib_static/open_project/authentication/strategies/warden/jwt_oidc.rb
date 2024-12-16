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
            verified_payload, provider = ::OpenIDConnect::JwtParser.new(required_claims: ["sub"]).parse(@access_token)

            user = User.find_by(identity_url: "#{provider.slug}:#{verified_payload['sub']}")
            success!(user) if user
          rescue JWT::ExpiredSignature
            fail_with_header!(error: "invalid_token", error_description: "The access token expired")
          rescue JWT::ImmatureSignature
            # happens when nbf time is less than current
            fail_with_header!(error: "invalid_token", error_description: "The access token is used too early")
          rescue JWT::InvalidAudError
            fail_with_header!(error: "invalid_token", error_description: "The access token audience claim is wrong")
          rescue JSON::JWK::Set::KidNotFound
            fail_with_header!(error: "invalid_token", error_description: "The access token signature kid is unknown")
          rescue ::OpenIDConnect::JwtParser::Error => e
            fail_with_header!(error: "invalid_token", error_description: e.message)
          end
        end
      end
    end
  end
end
