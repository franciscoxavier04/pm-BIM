# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module OpenIDConnect
  module UserTokens
    ##
    # Provides APIs to obtain access tokens of a given user for use at a third-party
    # application for which we know the audience name, which is typically the application's
    # client_id at an identity provider that OpenProject and the application have in common.
    class FetchService
      include Dry::Monads[:result]

      def initialize(user:, jwt_parser: JwtParser.new(verify_audience: false, verify_expiration: false))
        @user = user
        @provider = user.authentication_provider
        @jwt_parser = jwt_parser
      end

      ##
      # Obtains an access token that can be used to make requests in the user's name at the
      # remote service identified by the +audience+ parameter.
      #
      # The access token will be refreshed before being returned by this method, if it can be
      # identified as being expired. There is no guarantee that all access tokens will be properly
      # recognized as expired, so client's still need to make sure to handle rejected access tokens
      # properly. Also see #refreshed_access_token_for.
      def access_token_for(audience:)
        token = token_with_audience(audience)
        token = token.bind do |t|
          if expired?(t.access_token)
            refresh(t)
          else
            Success(t)
          end
        end

        token.fmap(&:access_token)
      end

      ##
      # Obtains an access token that can be used to make requests in the user's name at the
      # remote service identified by the +audience+ parameter.
      #
      # The access token will always be refreshed before being returned by this method.
      # It is advised to use this method, after learning that a remote service rejected
      # an access token, because it was expired.
      def refreshed_access_token_for(audience:)
        token_with_audience(audience)
          .bind { |t| refresh(t) }
          .fmap(&:access_token)
      end

      private

      def token_with_audience(aud)
        token = @user.oidc_user_tokens.where("audiences ? :aud", aud:).first
        token ? Success(token) : Failure("No token for given audience")
      end

      def refresh(token)
        return Failure("Can't refresh the access token") if token.refresh_token.blank?

        refresh_token_request(token.refresh_token).bind do |json|
          access_token = json["access_token"]
          refresh_token = json["refresh_token"]
          break Failure("Refresh token response invalid") if access_token.blank?

          token.update!(access_token:, refresh_token:)

          Success(token)
        end
      end

      def refresh_token_request(refresh_token)
        response = OpenProject.httpx
                              .basic_auth(@provider.client_id, @provider.client_secret)
                              .post(@provider.token_endpoint, form: {
                                      grant_type: :refresh_token,
                                      refresh_token:
                                    })
        response.raise_for_status

        Success(response.json)
      rescue HTTPX::Error => e
        Failure(e)
      end

      def expired?(token_string)
        exp = @jwt_parser.parse(token_string).fmap { |decoded, _| decoded["exp"] }.value_or(nil)
        return false if exp.nil?

        exp <= Time.now.to_i
      end
    end
  end
end
