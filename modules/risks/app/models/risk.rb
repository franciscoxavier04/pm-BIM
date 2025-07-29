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

class Risk < WorkPackage
  include RiskConstants

  validates :risk_impact, presence: true, inclusion: { in: IMPACT_RANGE }
  validates :risk_likelihood, presence: true, inclusion: { in: LIKELIHOOD_RANGE }
  validates :risk_level, presence: true, inclusion: { in: RISK_LEVEL_RANGE }

  before_save :calculate_risk_level

  def self.sti_name
    "Risk"
  end

  def risk?
    true
  end

  def risk_level_category
    return nil unless risk_level

    RISK_LEVEL_RANGES.find { |range, _| range.include?(risk_level) }&.last
  end

  private

  def calculate_risk_level
    return unless risk_impact && risk_likelihood

    # Simple risk calculation: impact * likelihood
    self.risk_level = risk_impact * risk_likelihood
  end
end
