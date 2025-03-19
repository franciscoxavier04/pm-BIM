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

module OpenProject::OpenIDConnect
  module Hooks
    class Hook < OpenProject::Hook::Listener
      ##
      # Once the user has signed in and has an oidc session
      # we want to map that to the internal session
      def user_logged_in(context)
        session = context.fetch(:session)
        ::OpenProject::OpenIDConnect::SessionMapper.handle_login(session)

        user = context.fetch(:user)

        access_token = session["omniauth.oidc_access_token"]

        if access_token
          OpenIDConnect::UserTokens::CreateService.new(user).call(
            access_token:,
            refresh_token: session["omniauth.oidc_refresh_token"],
            expires_in: session["omniauth.oidc_expires_in"],
            known_audiences: [OpenIDConnect::UserToken::IDP_AUDIENCE],
            # We clear previous tokens while adding this one to avoid keeping
            # stale tokens around (and to avoid piling up duplicate IDP tokens)
            # -> Fresh login causes fresh set of tokens
            clear_previous: true
          )
        end
      end

      ##
      # Called once omniauth has returned with an auth hash
      def omniauth_user_authorized(context)
        controller = context.fetch(:controller)
        session = controller.session

        if OpenIDConnect::Provider.exists?(slug: context.dig(:auth_hash, :provider))
          session["omniauth.oidc_access_token"] = context.dig(:auth_hash, :credentials, :token)
          session["omniauth.oidc_refresh_token"] = context.dig(:auth_hash, :credentials, :refresh_token)
          session["omniauth.oidc_expires_in"] = parse_expires_in(context.dig(:auth_hash, :credentials, :expires_in))
        end

        nil
      end

      private

      def parse_expires_in(expires_in)
        expires_in = expires_in.to_i
        return nil if expires_in.zero?

        expires_in
      end
    end
  end
end
