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

class ScimClients::UpdateService < BaseServices::Update
  def after_perform(_)
    super.tap do |result|
      update_service_account(result.result)
    end
  end

  private

  def update_service_account(scim_client)
    scim_client.service_account&.update!(params.slice(:name))

    if model.authentication_method_sso?
      link = scim_client.service_account&.user_auth_provider_links&.find_or_initialize_by({})
      update_user_auth_provider_link(link)
    end
  end

  def update_user_auth_provider_link(link)
    return if link.nil?

    link.auth_provider_id = params[:auth_provider_id] if params.key?(:auth_provider_id)
    link.external_id = params[:jwt_sub] if params.key?(:jwt_sub)
    link.save!
  end
end
