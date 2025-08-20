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

module ::TeamPlanner
  class TeamPlannerController < BaseController
    include EnterpriseHelper
    include Layout
    before_action :load_and_authorize_in_optional_project
    before_action :build_plan_view, only: %i[new]
    before_action :find_plan_view, only: %i[destroy]

    guard_enterprise_feature(:team_planner_view, except: %i[index overview]) do
      redirect_to action: :index
    end

    menu_item :team_planner_view

    def index
      @views = visible_plans(@project)
    end

    def overview
      @views = visible_plans
      render layout: "global"
    end

    def new; end

    def create
      service_result = create_service_class.new(user: User.current)
                                           .call(plan_view_params)

      @view = service_result.result

      if service_result.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_team_planner_path(@project, @view.query)
      else
        render action: :new, status: :unprocessable_entity
      end
    end

    def show
      render layout: "angular/angular"
    end

    def upsell; end

    def destroy
      if @view.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = t(:error_can_not_delete_entry)
      end

      redirect_to action: :index
    end

    current_menu_item :index do
      :team_planner_view
    end

    current_menu_item :overview do
      :team_planners
    end

    private

    def create_service_class
      TeamPlanner::Views::GlobalCreateService
    end

    def plan_view_params
      params.require(:query).permit(:name, :public, :starred).merge(project_id: @project&.id)
    end

    def build_plan_view
      @view = Query.new
    end

    def find_plan_view
      @view = Query
        .visible(current_user)
        .find(params[:id])
    end

    def visible_plans(project = nil)
      query = Query
        .visible(current_user)
        .includes(:project)
        .joins(:views)
        .references(:projects)
        .where("views.type" => "team_planner")
        .order("queries.name ASC")

      if project
        query = query.where("queries.project_id" => project.id)
      else
        allowed_projects = Project.allowed_to(User.current, :view_team_planner)
        query = query.where(queries: { project: allowed_projects })
      end

      query
    end
  end
end
