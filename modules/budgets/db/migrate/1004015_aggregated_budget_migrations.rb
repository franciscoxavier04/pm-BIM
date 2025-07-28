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

require Rails.root.join("db/migrate/migration_utils/squashed_migration").to_s
require_relative "tables/budgets"
require_relative "tables/budget_journals"
require_relative "tables/labor_budget_items"
require_relative "tables/material_budget_items"

# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedBudgetMigrations < SquashedMigration
  squashed_migrations *%w[
    20200807083950_keep_enabled_module
    20200810152654_rename_cost_object_to_budget
  ]

  tables Tables::Budgets,
         Tables::BudgetJournals,
         Tables::LaborBudgetItems,
         Tables::MaterialBudgetItems

  modifications do
    add_column :work_packages, :budget_id, :integer
    add_column :work_package_journals, :budget_id, :integer, null: true
  end
end
