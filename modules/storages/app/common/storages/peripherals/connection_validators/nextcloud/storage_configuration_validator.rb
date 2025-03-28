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
        class StorageConfigurationValidator < BaseValidatorGroup
          private

          def validate
            register_checks(:storage_configured, :capabilities_request,
                            :host_url_accessible, :dependencies_check, :dependencies_versions)

            storage_configuration_status
            capabilities_request_status
            host_url_not_found
            missing_dependencies
            version_mismatch
          end

          def storage_configuration_status
            if @storage.configured?
              pass_check(:storage_configured)
            else
              fail_check(:storage_configured, message(:not_configured))
            end
          end

          def capabilities_request_status
            if capabilities.failure? && capabilities.result != :not_found
              fail_check(:capabilities_request, message(:unknown_error))
            else
              pass_check(:capabilities_request)
            end
          end

          def version_mismatch
            min_app_version = SemanticVersion.parse(nextcloud_dependencies.dig("dependencies", "integration_app", "min_version"))
            capabilities_result = capabilities.result

            if capabilities_result.app_version < min_app_version
              fail_check(:dependencies_versions, message(:app_version_mismatch))
            else
              pass_check(:dependencies_versions)
            end
          end

          def missing_dependencies
            capabilities_result = capabilities.result
            app_name = I18n.t("storages.dependencies.nextcloud.integration_app")

            if capabilities_result.app_disabled?
              fail_check(:dependencies_check, message(:missing_dependencies, dependency: app_name))
            else
              pass_check(:dependencies_check)
            end
          end

          def host_url_not_found
            if capabilities.result == :not_found
              fail_check(:host_url_accessible, message(:host_not_found))
            else
              pass_check(:host_url_accessible)
            end
          end

          def noop = StorageInteraction::AuthenticationStrategies::Noop.strategy

          def capabilities
            @capabilities ||= Peripherals::Registry.resolve("#{@storage}.queries.capabilities")
                                                   .call(storage: @storage, auth_strategy: noop)
          end

          def nextcloud_dependencies
            @nextcloud_dependencies ||= YAML.load_file(path_to_config).deep_stringify_keys!
          end

          def path_to_config = Rails.root.join("modules/storages/config/nextcloud_dependencies.yml")
        end
      end
    end
  end
end
