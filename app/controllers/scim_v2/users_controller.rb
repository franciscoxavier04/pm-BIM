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

module ScimV2
  class UsersController < Scimitar::ResourcesController
    include BaseControllerActions

    def create
      super do |scim_resource|
        storage_class.transaction do
          user = storage_class.new
          user.from_scim!(scim_hash: scim_resource.as_json)
          user.firstname = "123" if user.firstname.blank?
          user.lastname = "456" if user.lastname.blank?
          call = Users::CreateService
                   .new(user: User.current, model: user)
                   .call(user.attributes)
                   .on_failure do |result|
            uniqueness_error = result.errors.find { |e| e.type == :taken }
            if uniqueness_error.present?
              raise Scimitar::ErrorResponse.new(
                status: 409,
                scimType: "uniqueness",
                detail: "Operation failed due to a uniqueness constraint: #{result.message}"
              )
            else
              raise result.message
            end
          end

          user = call.result
          user.to_scim(
            location: url_for(action: :show, id: user.id),
            include_attributes:
          )
        end
      end
    end

    def replace
      super do |user_id, scim_resource|
        storage_class.transaction do
          user = storage_scope.find(user_id)
          user.from_scim!(scim_hash: scim_resource.as_json)
          Users::UpdateService
            .new(user: User.current, model: user)
            .call
            .on_failure { |call| raise call.message }
          user.to_scim(
            location: url_for(action: :show, id: user.id),
            include_attributes:
          )
        end
      end
    end

    def update
      super do |user_id, patch_hash|
        storage_class.transaction do
          user = storage_scope.find(user_id)
          user.from_scim_patch!(patch_hash: patch_hash)
          Users::UpdateService
            .new(user: User.current, model: user)
            .call
            .on_failure { |call| raise call.message }
          user.to_scim(
            location: url_for(action: :show, id: user.id),
            include_attributes:
          )
        end
      end
    end

    def destroy
      super do |user_id|
        user = storage_scope.find(user_id)
        Users::DeleteService
          .new(user: User.current, model: user)
          .call
          .on_failure do |result|
          unauthorized_error = result.errors.find { |e| e.type == :error_unauthorized }
          if unauthorized_error.present?
            raise Scimitar::ErrorResponse.new(
              status: 403,
              detail: "User can't be deleted due to permission absence."
            )
          else
            raise result.message
          end

          raise call.message
        end
      end
    end

    protected

    def storage_class
      User
    end

    def storage_scope
      User
        .left_joins(:groups, :user_auth_provider_links)
        .includes(:groups, :user_auth_provider_links)
        .not_builtin
    end
  end
end
