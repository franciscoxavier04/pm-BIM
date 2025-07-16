module Objectives
  class ObjectivesController < ApplicationController
    before_action :load_and_authorize_in_optional_project

    before_action :load_objectives


    menu_item :risks

    def index; end

    private

    def load_objectives
      @query = Query.new(name: "_", project: @project)
      @query.add_filter("type_id", "=", [BmdsHackathon::References.objective_type.id])
      @query.include_subprojects = params[:project_filter] != "current"
      @query.add_filter("status_id", "=", BmdsHackathon::Objectives.objective_statuses.map(&:id))
      @query.group_by = "status"

      @objectives = @query
                    .results
                    .work_packages
                    .includes(:custom_values)

    end
  end
end
