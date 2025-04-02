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

module RemoteIdentities
  class AutoCreate
    IntegrationConfig = Data.define(:name, :integration_fetcher, :token_fetcher)

    class << self
      def register(name, integration_fetcher:, token_fetcher:)
        configs << IntegrationConfig.new(name:, integration_fetcher:, token_fetcher:)
      end

      def handle_login(user)
        configs.each do |config|
          config.integration_fetcher.call(user).each do |integration|
            token = config.token_fetcher.call(user, integration)
            create_remote_identity(user:, integration:, token:)
          end
        rescue StandardError => e
          error("Unhandled exception while creating #{config.name} RemoteIdentity for user #{user.id}: #{e.message}")
        end
      end

      private

      def configs
        @configs ||= []
      end

      def create_remote_identity(user:, integration:, token:)
        RemoteIdentities::CreateService
          .new(user:, integration:, auth_source: user.authentication_provider)
          .call(token:)
          .on_failure do |e|
            error("RemoteIdentity creation for user #{user.id} failed: #{e.message}")
          end
      end

      def error(message)
        Rails.logger.error(message)
      end
    end
  end
end
