module Objectives
  class ObjectivesController < ApplicationController
    before_action :load_and_authorize_in_optional_project

    # before_action :load_risks,
    #               :derive_risk_counts

    menu_item :objectives

    def index; end

    private

    def derive_risk_counts
      @likelihood_cf = BmdsHackathon::References.risk_likelihood_cf
      @impact_cf = BmdsHackathon::References.risk_impact_cf

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
      @risk_work_packages = WorkPackage
                              .visible
                              .where(type: BmdsHackathon::References.risk_type)
                              .where(project_id: @project.self_and_descendants.select(:id))
                              .includes(:custom_values)
    end
  end
end
