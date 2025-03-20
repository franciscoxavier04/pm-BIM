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
        class AuthenticationValidator < BaseValidator
          def initialize(storage)
            super
            @user = User.current
          end

          def call
            catch :interrupted do
              @storage.authenticate_via_idp? ? validate_sso : validate_oauth
            end

            @results
          end

          private

          def validate_oauth
            @results = {
              existing_token: CheckResult.skipped(:existing_token),
              user_bound_request: CheckResult.skipped(:user_bound_request)
            }

            oauth_token
            user_bound_request
          end

          def oauth_token
            if OAuthClientToken.where(user: @user, oauth_client: @storage.oauth_client).any?
              pass_check(:existing_token)
            else
              warn_check(:existing_token, message(:oauth_token_missing))
              throw :interrupted
            end
          end

          def user_bound_request
            Registry["nextcloud.queries.files"]
              .call(storage: @storage, auth_strategy:, folder: ParentFolder.new("/")).on_failure do
              fail_check(__method__, message("oauth_request_#{it.result}"))
            end

            pass_check(__method__)
          end

          def auth_strategy = Registry["nextcloud.authentication.user_bound"].call(storage: @storage, user: @user)

          def validate_sso
            @results = {
              non_provisioned_user: CheckResult.skipped(:non_provisioned_user),
              non_oidc_provisioned_user: CheckResult.skipped(:non_oidc_provisioned_user),
              token_usability: CheckResult.skipped(:token_usability)
            }

            non_provisioned_user
            non_oidc_provisioned_user
            token_usability
          end

          def non_provisioned_user
            if @user.identity_url.present?
              pass_check(__method__)
            else
              warn_check(__method__, message(:oidc_non_provisioned_user))
              throw :interrupted
            end
          end

          def non_oidc_provisioned_user
            if @user.authentication_provider.is_a?(OpenIDConnect::Provider)
              pass_check(__method__)
            else
              warn_check(__method__, message(:oidc_non_oidc_user))
              throw :interrupted
            end
          end

          def token_usability
            service = OpenIDConnect::UserTokens::FetchService.new(user: @user)

            result = service.access_token_for(audience: @storage.audience)
            return pass_check(__method__) if result.success?

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

            fail_check(__method__, message(error_code))
            throw :interrupted
          end
        end
      end
    end
  end
end
