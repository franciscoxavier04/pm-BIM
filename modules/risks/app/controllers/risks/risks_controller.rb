module Risks
  class RisksController < ApplicationController
    include ::RisksHelper

    before_action :load_and_authorize_in_optional_project

    before_action :find_custom_fields,
                  :load_risks,
                  :derive_risk_counts, :select_params

    menu_item :risks

    def index; end

    private

    def find_custom_fields
      @likelihood_cf = BmdsHackathon::References.risk_likelihood_cf
      @impact_cf = BmdsHackathon::References.risk_impact_cf
      @level_cf = BmdsHackathon::References.risk_level_cf

      @likelihood_options = @likelihood_cf.custom_options
      @impact_options = @impact_cf.custom_options
      @level_options = @level_cf.custom_options
    end

    def derive_risk_counts
      @risk_counts = Hash.new(0)
      @risk_work_packages.each do |work_package|
        likelihood_value = work_package.custom_value_for(@likelihood_cf)&.value
        impact_value = work_package.custom_value_for(@impact_cf)&.value

        if likelihood_value.present? && impact_value.present?
          @risk_counts[[likelihood_value.to_i, impact_value.to_i]] += 1
        end
      end
    end

    def load_risks
      @query = Query.new(name: "_", project: @project)
      @query.add_filter("type_id", "=", [BmdsHackathon::References.risk_type.id])
      @query.include_subprojects = params[:project_filter] != "current"

      if params[:likelihood]
        @query.add_filter(@likelihood_cf.column_name, "=", [params[:likelihood].to_i])
      end

      if params[:impact]
        @query.add_filter(@impact_cf.column_name, "=", [params[:impact].to_i])
      end

      if params[:risk_filter].present?
        options = risk_level_options(@level_cf, range: params[:risk_filter].to_sym)
        @query.add_filter(@level_cf.column_name, "=", options.map(&:id))
      end

      @query.sort_criteria = [[@level_cf.column_name, "desc"]]

      @risk_work_packages = @query
        .results
        .work_packages
        .includes(:custom_values)
    end

    def select_params
      @selected_likelihood = params[:likelihood]&.to_i
      @selected_impact = params[:impact]&.to_i
      @risk_filter = params[:risk_filter]
    end
  end
end
