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

module WorkPackageTypes
  class TypesController < ApplicationController
    include PaginationHelper

    layout "admin"

    before_action :require_admin
    before_action :find_type, only: %i[move destroy]

    current_menu_item do
      :types
    end

    def index
      @types = ::Type
                .includes(:workflows, :projects, :custom_fields, :color)
                .page(page_param)
                .per_page(per_page_param)
    end

    def type
      @type
    end

    def new
      @type = Type.new(params[:type])
      load_projects_and_types
    end

    def create
      additional_params = {}
      value = params.dig(:type, :copy_workflow_from)
      additional_params[:copy_workflow_from] = value if value.present?

      service_call = WorkPackageTypes::CreateService
                      .new(user: current_user)
                      .call(permitted_type_params.merge(additional_params))

      @type = service_call.result
      if service_call.success?
        redirect_to edit_type_settings_path(@type), notice: t(:notice_successful_create), status: :see_other
      else
        render action: :new, status: :unprocessable_entity
      end
    end

    def move
      if @type.update(permitted_params.type_move)
        flash[:notice] = I18n.t(:notice_successful_update)
      else
        flash.now[:error] = I18n.t(:error_type_could_not_be_saved)
      end
      redirect_to types_path
    end

    def destroy
      if @type.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = destroy_error_message
      end
      redirect_to action: "index"
    end

    protected

    def find_type
      @type = ::Type.find(params[:id])
    end

    def permitted_type_params
      # having to call #to_unsafe_h as a query hash the attribute_groups
      # parameters would otherwise still be an ActiveSupport::Parameter
      permitted_params.type.to_unsafe_h
    end

    def load_projects_and_types
      @types = ::Type.order(Arel.sql("position"))
      @projects = Project.all
    end

    def destroy_error_message # rubocop:disable Metrics/AbcSize
      if @type.is_standard?
        t(:error_can_not_delete_standard_type)
      elsif @type.builtin?
        t(:error_can_not_delete_builtin_type)
      else
        error_message = [
          ApplicationController.helpers.sanitize(
            t(:"error_can_not_delete_type.explanation", url: belonging_wps_url(@type.id)),
            attributes: %w(href target)
          )
        ]

        if archived_projects.any?
          error_message << ApplicationController.helpers.sanitize(
            t(:error_can_not_delete_in_use_archived_work_packages,
              archived_projects_urls: helpers.archived_projects_urls_for(archived_projects)),
            attributes: %w(href target)
          )
        end

        error_message
      end
    end

    def belonging_wps_url(type_id)
      work_packages_path query_props: { f: [{ n: "type", o: "=", v: [type_id] }] }.to_json
    end

    def archived_projects
      @archived_projects ||= @type.projects.archived
    end
  end
end
