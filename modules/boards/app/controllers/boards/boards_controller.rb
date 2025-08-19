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

module ::Boards
  class BoardsController < BaseController
    include Layout

    before_action :load_and_authorize_in_optional_project

    # The boards permission alone does not suffice
    # to view work packages
    before_action :authorize_work_package_permission, only: %i[show]

    before_action :build_board_grid, only: %i[new]
    before_action :load_query, only: %i[index]
    before_action :find_board_grid, only: %i[destroy]
    before_action :ensure_board_type_not_restricted, only: %i[create]

    menu_item :boards

    def index
      render "index", locals: { menu_name: project_or_global_menu }
    end

    def show
      render layout: "angular/angular"
    end

    def new; end

    def create
      service_result = service_call

      @board_grid = service_result.result

      if service_result.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_work_package_board_path(@project, @board_grid)
      else
        render action: :new, status: :unprocessable_entity
      end
    end

    def destroy
      @board_grid.destroy

      flash[:notice] = I18n.t(:notice_successful_delete)

      respond_to do |format|
        format.json do
          render json: { redirect_url: project_work_package_boards_path(@project) }
        end
        format.html do
          redirect_to action: "index", project_id: @project
        end
      end
    end

    private

    def load_query
      projects = @project || Project.allowed_to(User.current, :show_board_views)

      @board_grids = Boards::Grid.includes(:project)
                                 .references(:project)
                                 .where(project: projects)
    end

    def find_board_grid
      @board_grid = Boards::Grid.find(params[:id])
      @project = @board_grid.project
    end

    def authorize_work_package_permission
      unless user_allowed_to_view_work_packages?
        deny_access
      end
    end

    def user_allowed_to_view_work_packages?
      if @project
        current_user.allowed_in_project?(:view_work_packages, @project)
      else
        current_user.allowed_in_any_project?(:view_work_packages)
      end
    end

    def build_board_grid
      @board_grid = Boards::Grid.new
    end

    def ensure_board_type_not_restricted
      render_403 if restricted_board_type?
    end

    def restricted_board_type?
      !EnterpriseToken.allows_to?(:board_view) && board_grid_params[:attribute] != "basic"
    end

    def service_call
      service_class.new(user: User.current)
                   .call(
                     project: @project,
                     name: board_grid_params[:name],
                     attribute: board_grid_params[:attribute]
                   )
    end

    def service_class
      {
        "basic" => Boards::BasicBoardCreateService,
        "status" => Boards::StatusBoardCreateService,
        "assignee" => Boards::AssigneeBoardCreateService,
        "version" => Boards::VersionBoardCreateService,
        "subproject" => Boards::SubprojectBoardCreateService,
        "subtasks" => Boards::SubtasksBoardCreateService
      }.fetch(board_grid_params[:attribute])
    end

    def board_grid_params
      params.require(:boards_grid).permit(%i[name attribute])
    end
  end
end
