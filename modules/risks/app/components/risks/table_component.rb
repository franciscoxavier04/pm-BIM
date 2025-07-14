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
  class TableComponent < ViewComponent::Base
    attr_reader :likelihood_options, :impact_options, :risk_counts, :risk_work_packages

    def initialize(likelihood_options:, impact_options:, risk_counts:, risk_work_packages:)
      super
      @likelihood_options = likelihood_options
      @impact_options = impact_options
      @risk_counts = risk_counts
      @risk_work_packages = risk_work_packages
    end

    private

    def risk_class(likelihood_index, impact_index)
      likelihood_value = likelihood_options.length - likelihood_index
      impact_value = impact_index + 1
      risk_score = likelihood_value * impact_value

      case risk_score
      when 1..6
        "low-risk"
      when 7..15
        "medium-risk"
      when 16..25
        "high-risk"
      else
        "medium-risk"
      end
    end

    def work_package_count(likelihood, impact)
      risk_counts[[likelihood.id, impact.id]] || 0
    end
  end
end
