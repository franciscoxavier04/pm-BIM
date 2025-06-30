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
    module Providers
      module Nextcloud
        module Queries
          class CapabilitiesQuery < Base
            def self.call(storage:, auth_strategy:)
              new(storage).call(auth_strategy:)
            end

            def call(auth_strategy:)
              http_options = { headers: { accepts: "application/json" } }.deep_merge(ocs_api_request_headers)
              Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
                handle_response(http.get(url))
              end
            end

            private

            def url = UrlBuilder.url(@storage.uri, "/ocs/v2.php/cloud/capabilities")

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                json = response.json(symbolize_keys: true)
                parse_capabilities(json)
              in { status: 404 }
                Failure(error.with(code: :not_found))
              else
                Failure(error.with(code: :error))
              end
            end

            def parse_capabilities(json)
              app_json = json.dig(:ocs, :data, :capabilities, :integration_openproject)

              ProviderResults::Capabilities.build(
                app_enabled: app_json.present?,
                app_version: version(app_json&.dig(:app_version)),
                group_folder_enabled: !!app_json&.dig(:groupfolders_enabled),
                group_folder_version: version(app_json&.dig(:groupfolder_version))
              )
            end

            def version(str)
              return if str.nil?

              major, minor, patch = str.split(".").map(&:to_i)
              return if major.nil? || minor.nil? || patch.nil?

              SemanticVersion.new(major:, minor:, patch:)
            end
          end
        end
      end
    end
  end
end
