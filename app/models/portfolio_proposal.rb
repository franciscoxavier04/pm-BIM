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

class PortfolioProposal < ApplicationRecord
  belongs_to :portfolio, -> { where(project_type: :portfolio) }, class_name: 'Project'

  has_many :portfolio_proposal_projects, dependent: :destroy
  has_many :projects, through: :portfolio_proposal_projects

  enum :state, {
    compose: 0,
    proposed: 1,
    approved: 2
  }

  validates :portfolio, presence: true
  validate :only_one_approved_proposal_per_portfolio

  after_save :update_project_hierarchy, if: :state_changed_to_approved?

  private

  def only_one_approved_proposal_per_portfolio
    return unless state == 'approved'

    existing_approved = PortfolioProposal.where(portfolio_id: portfolio_id, state: :approved)
    existing_approved = existing_approved.where.not(id: id) if persisted?

    if existing_approved.exists?
      errors.add(:state, :only_one_approved_proposal_allowed)
    end
  end

  def state_changed_to_approved?
    saved_change_to_state? && state == 'approved'
  end

  def update_project_hierarchy
    projects.each do |project|
      project.update(parent_id: portfolio_id)
    end
  end
end
