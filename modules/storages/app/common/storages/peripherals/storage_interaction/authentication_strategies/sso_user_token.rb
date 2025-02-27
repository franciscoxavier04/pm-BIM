# frozen_string_literal:true

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
    module StorageInteraction
      module AuthenticationStrategies
        class SsoUserToken
          def self.strategy
            Strategy.new(:sso_user_token)
          end

          def initialize(user)
            @user = user
          end

          def call(storage:, http_options: {}, &)
            OpenIDConnect::UserTokens::FetchService
              .new(user: @user)
              .access_token_for(audience: storage.audience)
              .either(
                ->(token) do
                  opts = http_options.deep_merge({ headers: { "Authorization" => "Bearer #{token}" } })
                  yield OpenProject.httpx.with(opts)
                end,
                ->(error) do
                  log_message = "Failed to fetch access token for user #{@user}. Error: #{error.inspect}"
                  Failures::Builder.call(code: :unauthorized, log_message:, data: error)
                end
              )
          end
        end
      end
    end
  end
end
