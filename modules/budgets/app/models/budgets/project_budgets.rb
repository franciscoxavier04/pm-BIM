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

module Budgets
  # Provides aggregated budget information for a project.
  class ProjectBudgets
    attr_reader :project

    def initialize(project)
      @project = project
    end

    delegate :any?, :none?, to: :budgets

    def children_budgets_count
      @children_budgets_count ||= budgets.sum(&:children_budgets_count)
    end

    def planned
      @planned ||= budgets.sum(&:budget)
    end

    def allocated_to_children
      @allocated_to_children ||= budgets.sum(&:allocated_to_children)
    end

    def allocated_unused
      @allocated_unused ||= budgets.sum(&:allocated_unused)
    end

    def spent_with_children
      @spent_with_children ||= budgets.sum(&:spent_with_children)
    end

    def spent
      @spent ||= budgets.sum(&:spent)
    end

    def available
      @available ||= budgets.sum(&:available)
    end

    def budget_ratio
      gone = spent + allocated_to_children
      @budget_ratio ||= planned.zero? ? 0 : ((gone / planned) * 100).round
    end

    def budgets
      @budgets ||= project.budgets.to_a
    end
  end
end
