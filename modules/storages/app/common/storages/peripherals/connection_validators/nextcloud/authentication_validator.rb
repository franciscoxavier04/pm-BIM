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

module Storages
  module Peripherals
    module ConnectionValidators
      module Nextcloud
        class AuthenticationValidator < BaseValidatorGroup
          def initialize(storage)
            super
            @user = User.current
          end

          private

          def validate
            @storage.authenticate_via_idp? ? validate_sso : validate_oauth
          end

          def validate_oauth
            register_checks(:existing_token, :user_bound_request)

            oauth_token
            user_bound_request
          end

          def oauth_token
            if OAuthClientToken.where(user: @user, oauth_client: @storage.oauth_client).any?
              pass_check(:existing_token)
            else
              warn_check(:existing_token, message(:oauth_token_missing), halt_validation: true)
            end
          end

          def user_bound_request
            Registry["nextcloud.queries.user"].call(storage: @storage, auth_strategy:).on_failure do
              fail_check(:user_bound_request, message("oauth_request_#{it.result}"))
            end

            pass_check(:user_bound_request)
          end

          def auth_strategy = Registry["nextcloud.authentication.user_bound"].call(storage: @storage, user: @user)

          def validate_sso
            register_checks(:non_provisioned_user, :provisioned_user_provider, :token_negotiable, :user_bound_request)

            non_provisioned_user
            non_oidc_provisioned_user
            token_negotiable
            user_bound_request
          end

          def non_provisioned_user
            if @user.identity_url.present?
              pass_check(:non_provisioned_user)
            else
              warn_check(:non_provisioned_user, message(:oidc_non_provisioned_user), halt_validation: true)
            end
          end

          def non_oidc_provisioned_user
            if @user.authentication_provider.is_a?(OpenIDConnect::Provider)
              pass_check(:provisioned_user_provider)
            else
              warn_check(:provisioned_user_provider, message(:oidc_non_oidc_user), halt_validation: true)
            end
          end

          def token_negotiable
            service = OpenIDConnect::UserTokens::FetchService.new(user: @user)

            result = service.access_token_for(audience: @storage.audience)
            return pass_check(:token_negotiable) if result.success?

            error_code = case result.failure
                         in { code: /token_exchange/ | :unable_to_exchange_token }
                           :oidc_cant_exchange_token
                         in { code: /token_refresh/ }
                           :oidc_cant_refresh_token
                         in { code: :no_token_for_audience }
                           :oidc_cant_acquire_token
                         else
                           :unknown_error
                         end

            fail_check(:token_negotiable, message(error_code))
          end
        end
      end
    end
  end
end
