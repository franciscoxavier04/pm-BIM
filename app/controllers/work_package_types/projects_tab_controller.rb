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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  class ProjectsTabController < ApplicationController
    layout "admin"

    before_action :require_admin
    before_action :find_type
    before_action :load_projects, only: :edit

    current_menu_item [:edit, :update] do
      :types
    end

    def edit; end

    def update
      result = UpdateService.new(user: current_user, model: @type, contract_class: UpdateProjectsContract)
                            .call(permitted_project_params)

      if result.success?
        redirect_to edit_type_projects_path(type_id: @type.id), notice: I18n.t(:notice_successful_update)
      else
        params[:tab] = "projects"
        flash_error(result)
        load_projects
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def flash_error(result)
      flash.now[:error] = result.errors.messages_for(:project_ids).to_sentence
    end

    def load_projects
      @projects = Project.all
    end

    def find_type
      @type = ::Type.find(params[:type_id])
    end

    def permitted_project_params
      # TODO: once the input is correctly delivered just return: params.expect(type: [:project_ids])

      { project_ids: JSON.parse(params.expect(type: [:project_ids])[:project_ids]) }
    end
  end
end
