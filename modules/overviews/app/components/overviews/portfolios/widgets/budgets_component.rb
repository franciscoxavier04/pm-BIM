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

module Overviews
  module Portfolios
    module Widgets
      class BudgetsComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include ApplicationHelper

        attr_reader :project, :project_budgets

        def initialize(model = nil, project:, **)
          super(model, **)

          @project = project
          @project_budgets = ::Budgets::ProjectBudgets.new(project)
        end

        def projects_list_with_budgets_columns_path
          projects_path(
            columns: [
              "name",
              Queries::Projects::Selects::BudgetPlanned,
              Queries::Projects::Selects::BudgetAllocated,
              Queries::Projects::Selects::BudgetSpent,
              Queries::Projects::Selects::BudgetAvailable
            ].map { column_key(it) }.join(" "),
            filters: [
              "#{Queries::Projects::Filters::ActiveFilter.key} = t",
              "#{Queries::Projects::Filters::AncestorOrSelfFilter.key} = #{project.id}"
            ].join("&"),
            query_id: "active"
          )
        end

        def column_key(column)
          column.respond_to?(:key) ? column.key.to_s : column
        end
      end
    end
  end
end
