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

module Risks
  class MatrixComponent < ViewComponent::Base
    attr_reader :project, :params,
                :likelihood_options, :impact_options, :risk_counts, :risk_work_packages

    def initialize(project:,
                   params:,
                   likelihood_options:,
                   impact_options:,
                   risk_counts:,
                   risk_work_packages:,
                   selected_likelihood:,
                   selected_impact:,
                   risk_filter:,
                   groups:)
      super

      @project = project
      @params = params
      @likelihood_options = likelihood_options
      @impact_options = impact_options
      @risk_counts = risk_counts
      @risk_work_packages = risk_work_packages
      @groups = groups

      @selected_likelihood = params[:likelihood].to_i
      @selected_impact = params[:impact].to_i
      @risk_filter = risk_filter.present?
    end

    private

    def risk_class(likelihood, impact)
      risk_score = likelihood.value.to_i * impact.value.to_i

      case risk_score
      when 1..6
        "low-risk"
      when 7..15
        "medium-risk"
      else
        "high-risk"
      end
    end

    def work_package_count(likelihood, impact)
      risk_counts[[likelihood.id, impact.id]] || 0
    end

    def selected(likelihood, impact)
      "risk-selected" if @selected_likelihood == likelihood.id && @selected_impact == impact.id
    end
  end
end
