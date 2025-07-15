module Risks
  class RisksController < ApplicationController
    before_action :load_and_authorize_in_optional_project

    before_action :find_custom_fields,
    :load_risks,
                  :derive_risk_counts

    menu_item :risks

    def index; end

    private

    def find_custom_fields
      @likelihood_cf = CustomField.find_by(name: "Eintrittswahrscheinlichkeit")
      @impact_cf = CustomField.find_by(name: "Auswirkung")
      @level_cf = CustomField.find_by(name: "Risiko-Level")
    end

    def derive_risk_counts
      @likelihood_options = @likelihood_cf.custom_options
      @impact_options = @impact_cf.custom_options

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
      @query.include_subprojects = true

      if params[:likelihood]
        @query.add_filter(@likelihood_cf.column_name, "=", [params[:likelihood].to_i])
      end

      if params[:impact]
        @query.add_filter(@likelihood_cf.column_name, "=", [params[:likelihood].to_i])
      end

      @query.sort_criteria = [[@level_cf.column_name, "desc"]]

      @risk_work_packages = @query
        .results
        .work_packages
        .includes(:custom_values)
    end
  end
end
