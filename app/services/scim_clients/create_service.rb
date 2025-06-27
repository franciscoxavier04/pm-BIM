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

class ScimClients::CreateService < BaseServices::Create
  def after_perform(_)
    super.tap do |service_result|
      self.model = service_result.result

      update_service_account
      update_oauth_application(service_result)
    end
  end

  private

  def update_service_account
    service_account.name = params[:name]
    if model.authentication_method_sso?
      service_account.user_auth_provider_links.build(
        auth_provider_id: params[:auth_provider_id],
        external_id: params[:jwt_sub]
      )
    end
    service_account.save!
  end

  def update_oauth_application(service_result)
    return if !model.authentication_method_oauth2_client? && !model.authentication_method_oauth2_token?

    persist_service_result = create_oauth_application
    model.oauth_application = persist_service_result.result if persist_service_result.success?
    service_result.add_dependent!(persist_service_result)
  end

  def service_account
    @service_account ||= model.build_service_account(admin: true)
  end

  def create_oauth_application
    ::OAuth::Applications::CreateService
      .new(user:)
      .call(
        name: "#{model.name} (#{ScimClient.model_name.human})",
        redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
        scopes: "scim_v2",
        confidential: true,
        integration: model,
        owner: user
      )
  end
end
