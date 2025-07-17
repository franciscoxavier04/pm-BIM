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
  belongs_to :portfolio, -> { where(project_type: :portfolio) }, class_name: "Project"

  has_many :portfolio_proposal_projects, dependent: :destroy
  has_many :projects, through: :portfolio_proposal_projects

  enum :state, {
    draft: 0,
    proposed: 1,
    approved: 3,
    archived: 4
  }

  validates :portfolio, presence: true

  after_save :update_project_hierarchy, if: :state_changed_to_approved?
  after_save :set_predecessor_state, if: :state_changed_to_approved?

  private

  def state_changed_to_approved?
    saved_change_to_state? && approved?
  end

  def update_project_hierarchy
    Project
      .where(parent_id: portfolio_id)
      .find_each do |project|
      project.parent_id = nil
      project.save
    end

    projects.each do |project|
      project.parent_id = portfolio_id
      project.save
    end
  end

  def set_predecessor_state
    self
      .class
      .where(portfolio_id: portfolio_id)
      .where(state: PortfolioProposal.states[:approved])
      .where.not(id: id)
      .update_all(state: PortfolioProposal.states[:phased_out])
  end
end
