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

module OpenProject
  module Authentication
    module Strategies
      module Warden
        class JwtOidc < ::Warden::Strategies::Base
          include FailWithHeader

          SUPPORTED_ALG = %w[
            RS256
            RS384
            RS512
          ].freeze

          # The strategy is supposed to only handle JWT.
          # These tokens are supposed to be issued by configured OIDC.
          def valid?
            @access_token = ::Doorkeeper::OAuth::Token.from_bearer_authorization(
              ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
            )
            return false if @access_token.blank?

            @unverified_payload, @unverified_header = JWT.decode(@access_token, nil, false)
            @unverified_header.present? && @unverified_payload.present?
          rescue JWT::DecodeError
            false
          end

          def authenticate!
            issuer = @unverified_payload["iss"]
            provider = OpenProject::OpenIDConnect.providers.find { |p| p.configuration[:issuer] == issuer } if issuer.present?
            if provider.blank?
              return fail_with_header!(error: "invalid_token", error_description: "The access token issuer is unknown")
            end

            client_id = provider.configuration.fetch(:identifier)
            alg = @unverified_header.fetch("alg")
            if SUPPORTED_ALG.exclude?(alg)
              return fail_with_header!(error: "invalid_token", error_description: "Token signature algorithm is not supported")
            end

            kid = @unverified_header.fetch("kid")
            jwks_uri = provider.configuration[:jwks_uri]
            begin
              key = JSON::JWK::Set::Fetcher.fetch(jwks_uri, kid:).to_key
            rescue JSON::JWK::Set::KidNotFound
              return fail_with_header!(error: "invalid_token", error_description: "The access token signature kid is unknown")
            end

            begin
              verified_payload, = JWT.decode(
                @access_token,
                key,
                true,
                {
                  algorithm: alg,
                  verify_iss: true,
                  verify_aud: true,
                  iss: issuer,
                  aud: client_id,
                  required_claims: ["sub", "iss", "aud"]
                }
              )
            rescue JWT::ExpiredSignature
              return fail_with_header!(error: "invalid_token", error_description: "The access token expired")
            rescue JWT::ImmatureSignature
              # happens when nbf time is less than current
              return fail_with_header!(error: "invalid_token", error_description: "The access token is used too early")
            rescue JWT::InvalidIssuerError
              return fail_with_header!(error: "invalid_token", error_description: "The access token issuer is wrong")
            rescue JWT::InvalidAudError
              return fail_with_header!(error: "invalid_token", error_description: "The access token audience claim is wrong")
            end

            user = User.find_by(identity_url: "#{provider.name}:#{verified_payload['sub']}")
            success!(user) if user
          end
        end
      end
    end
  end
end
