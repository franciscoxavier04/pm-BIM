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
  module Adapters
    class Authentication
      # @param strategy [Input::Strategy]
      # @return [AuthenticationStrategy]
      def self.[](strategy)
        auth = strategy.value_or { |it| raise ArgumentError, "Invalid authentication strategy '#{it.inspect}'" }

        case auth.key
        when :noop
          AuthenticationStrategies::Noop.new
        when :basic_auth
          AuthenticationStrategies::BasicAuth.new
        when :oauth_user_token
          AuthenticationStrategies::OAuthUserToken.new(auth.user)
        when :oauth_client_credentials
          AuthenticationStrategies::OAuthClientCredentials.new(auth.use_cache)
        when :sso_user_token
          AuthenticationStrategies::SsoUserToken.new(auth.user)
        else
          raise Errors::UnknownAuthenticationStrategy, "Unknown #{auth.key} authentication scheme"
        end
      end

      # TODO: Needs update for OIDC. Add tests for this.
      #   Used only on the API. Should it become a service? - 2025-01-15 @mereghost
      def self.authorization_state(storage:, user:)
        return :not_connected if RemoteIdentity.where(integration: storage, user:).none?

        auth_strategy = Registry["#{storage}.authentication.user_bound"].call(user, storage)

        Registry.resolve("#{storage}.queries.user")
                .call(storage:, auth_strategy:)
                .either(
                  ->(*) { :connected },
                  ->(error) { error.code == :unauthorized ? :failed_authorization : :error }
                )
      end
    end
  end
end
