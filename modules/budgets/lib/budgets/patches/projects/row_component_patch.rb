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

module Budgets::Patches::Projects::RowComponentPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def budget_planned
      with_project_budgets do |project_budgets|
        number_to_currency(project_budgets.planned, precision: 0)
      end
    end

    def budget_spent
      with_project_budgets do |project_budgets|
        number_to_currency(project_budgets.spent, precision: 0)
      end
    end

    def budget_spent_ratio
      with_project_budgets do |project_budgets|
        helpers.extended_progress_bar(project_budgets.budget_ratio,
                                      legend: project_budgets.budget_ratio.to_s)
      end
    end

    def budget_allocated
      with_project_budgets do |project_budgets|
        number_to_currency(project_budgets.allocated_to_children, precision: 0)
      end
    end

    def budget_available
      with_project_budgets do |project_budgets|
        number_to_currency(project_budgets.available, precision: 0)
      end
    end

    def with_project_budgets
      @project_budgets ||= ::Budgets::ProjectBudgets.new(project)
      return unless @project_budgets.any?

      yield @project_budgets
    end
  end
end
