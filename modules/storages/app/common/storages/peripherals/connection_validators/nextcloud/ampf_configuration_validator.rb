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
        class AmpfConfigurationValidator < BaseValidatorGroup
          using ServiceResultRefinements

          private

          def validate
            register_checks(
              :files_request, :userless_access, :group_folder_presence, :group_folder_contents
            )

            files_request_failed_with_unknown_error
            userless_access_denied
            group_folder_not_found
            with_unexpected_content
          end

          def userless_access_denied
            if files.result == :unauthorized
              fail_check(:userless_access, message(:userless_access_denied))
            else
              pass_check(:userless_access)
            end
          end

          def group_folder_not_found
            if files.result == :not_found
              fail_check(:group_folder_presence, message(:group_folder_not_found))
            else
              pass_check(:group_folder_presence)
            end
          end

          def files_request_failed_with_unknown_error
            if files.result == :error
              error "Connection validation failed with unknown error:\n" \
                    "\tstorage: ##{@storage.id} #{@storage.name}\n" \
                    "\trequest: Group folder content\n" \
                    "\tstatus: #{files.result}\n" \
                    "\tresponse: #{files.error_payload}"

              fail_check(:files_request, message(:unknown_error))
            else
              pass_check(:files_request)
            end
          end

          def with_unexpected_content
            unexpected_files = files.result.files.reject { managed_project_folder_ids.include?(it.id) }
            return pass_check(:group_folder_contents) if unexpected_files.empty?

            log_extraneous_files(unexpected_files)
            warn_check(:group_folder_contents, message(:unexpected_content))
          end

          def log_extraneous_files(unexpected_files)
            file_representation = unexpected_files.map do |file|
              "Name: #{file.name}, ID: #{file.id}, Location: #{file.location}"
            end

            warn "Unexpected files/folder found in group folder:\n\t#{file_representation.join("\n\t")}"
          end

          def auth_strategy = Registry["nextcloud.authentication.userless"].call

          def managed_project_folder_ids
            @managed_project_folder_ids ||= ProjectStorage.automatic.where(storage: @storage)
                                                          .pluck(:project_folder_id).to_set
          end

          def files
            @files ||= Peripherals::Registry
              .resolve("#{@storage}.queries.files")
              .call(storage: @storage, auth_strategy:, folder: ParentFolder.new(@storage.group_folder))
          end
        end
      end
    end
  end
end
