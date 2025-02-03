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
    class NextcloudStorageWizard < Wizard
      step :general_info, completed_if: ->(storage) { storage.host.present? && storage.name.present? }

      step :oauth_application,
           completed_if: ->(storage) { storage.oauth_application.present? },
           preparation: :prepare_oauth_application

      step :oauth_client,
           completed_if: ->(storage) { storage.oauth_client.present? },
           preparation: ->(storage) { storage.build_oauth_client }

      step :automatically_managed_project_folders,
           completed_if: ->(storage) { !storage.automatic_management_unspecified? },
           preparation: :prepare_storage_for_automatic_management_form

      private

      def prepare_oauth_application(storage)
        create_result = ::Storages::OAuthApplications::CreateService.new(storage:, user:).call
        storage.oauth_application = create_result.result if create_result.success?
      end

      def prepare_storage_for_automatic_management_form(storage)
        ::Storages::Storages::SetProviderFieldsAttributesService
          .new(user:, model: storage, contract_class: EmptyContract)
          .call
      end
    end
  end
end
