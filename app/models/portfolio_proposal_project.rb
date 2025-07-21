# frozen_string_literal: true

# -- copyright
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
# ++

class PortfolioProposalProject < ApplicationRecord
  belongs_to :portfolio_proposal
  belongs_to :project, -> { where(project_type: [:project, :program]) }
  belongs_to :project_query, optional: true

  validates :portfolio_proposal, presence: true
  validates :project, presence: true
  validates :project_id, uniqueness: { scope: :portfolio_proposal_id }

  default_scope { order("rank NULLS LAST") }

  acts_as_list scope: :portfolio_proposal_id, column: :rank

  validate :project_not_portfolio

  private

  def project_not_portfolio
    if project && project.portfolio?
      errors.add(:project, :must_not_be_portfolio)
    end
  end
end
