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

module BmdsHackathon
  module References
    module_function

    def kpi_type
      @kpi_type ||= Type.find_by!(name: "KPI")
    end

    def objective_type
      @kpi_type ||= Type.find_by!(name: "Objective")
    end

    def key_result_type
      @key_result_type ||= Type.find_by!(name: "Key Result")
    end

    def risk_type
      @risk_type ||= Type.find_by!(name: "Risiko")
    end

    def risk_likelihood_cf
      @risk_likelihood_cf ||= CustomField.find_by!(name: "Eintrittswahrscheinlichkeit")
    end

    def risk_likelihood_attribute
      @risk_likelihood_attribute ||= risk_likelihood_cf.attribute_name.to_sym
    end

    def risk_impact_cf
      @risk_impact_cf ||= CustomField.find_by!(name: "Auswirkung")
    end

    def risk_impact_attribute
      @risk_impact_attribute ||= risk_impact_cf.attribute_name.to_sym
    end

    def risk_level_cf
      @risk_level_cf ||= CustomField.find_by!(name: "Risiko-Level")
    end

    def kpi_target_cf
      @kpi_target_cf ||= CustomField.find_by!(name: "Zielwert")
    end

    def kpi_current_cf
      @kpi_current_cf ||= CustomField.find_by!(name: "Istwert")
    end

    def rank_cf
      @rank_cf ||= ProjectCustomField.find_by!(name: "Rang")
    end
  end
end
