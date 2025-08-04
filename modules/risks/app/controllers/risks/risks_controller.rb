module Risks
  class RisksController < ApplicationController
    before_action :load_and_authorize_in_optional_project

    before_action :load_risks,
                  :derive_risk_counts,
                  :select_params

    menu_item :risks

    def index; end

    private

    def derive_risk_counts
      @risk_counts = Hash.new(0)
      @risk_work_packages.each do |work_package|
        likelihood_value = work_package.risk_likelihood
        impact_value = work_package.risk_impact

        if likelihood_value.present? && impact_value.present?
          @risk_counts[[likelihood_value.to_i, impact_value.to_i]] += 1
        end
      end
    end

    def load_risks
      @query = Query.new(name: "_", project: @project)
      @query.include_subprojects = params[:project_filter] != "current"

      if params[:likelihood]
        @query.add_filter(:risk_likelihood, "=", [params[:likelihood].to_i])
      end

      if params[:impact]
        @query.add_filter(:risk_impact, "=", [params[:impact].to_i])
      end

      if params[:risk_filter].present?
        @query.add_filter(:risk_level, "=", [params[:risk_filter]])
      end

      @query.sort_criteria = [[:risk_level, "desc"]]

      @risk_work_packages = @query
        .results
        .work_packages
        .where(work_package_type: "Risk") # TODO
    end

    def select_params
      @selected_likelihood = params[:likelihood]&.to_i
      @selected_impact = params[:impact]&.to_i
      @risk_filter = params[:risk_filter]
    end
  end
end
