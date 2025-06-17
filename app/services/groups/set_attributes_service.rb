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

module Groups
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(params)
      set_users(params) if params.key?(:user_ids)
      set_user_auth_provider_links(params.delete(:identity_url))
      super
    end

    # We do not want to persist the associated users (members) in a
    # SetAttributesService. Therefore we are building the association here.
    #
    # Note that due to the way we handle members, via a specific AddUsersService
    # the group should no longer simply be saved after group_users have been added.
    def set_users(params)
      user_ids = (params.delete(:user_ids) || []).map(&:to_i)

      existing_user_ids = model.group_users.map(&:user_id)
      build_new_users user_ids - existing_user_ids
      mark_outdated_users existing_user_ids - user_ids
    end

    def set_user_auth_provider_links(identity_url)
      if identity_url.present?
        slug, external_id = identity_url.split(":", 2)
        if slug.present? && external_id.present?
          auth_provider_id = AuthProvider.where(slug:).pick(:id)
          if auth_provider_id.present?
            link = model.user_auth_provider_links
                     .find_or_initialize_by(auth_provider_id:)
            link.assign_attributes(external_id:, principal: model)
            if link.changed? && link.persisted?
              link.save!
              model.user_auth_provider_links.reload
              model.user_auth_provider_links.find { |l| l.id == link.id }.external_id_will_change!
            end
          else
            raise ActiveRecord::RecordNotFound, "AuthProvider with slug: \"#{slug}\" has been not found"
          end
        end
      end
    end

    def build_new_users(new_user_ids)
      new_user_ids.each do |id|
        model.group_users.build(user_id: id)
      end
    end

    def mark_outdated_users(removed_user_ids)
      removed_user_ids.each do |id|
        model.group_users.find { |gu| gu.user_id == id }.mark_for_destruction
      end
    end
  end
end
