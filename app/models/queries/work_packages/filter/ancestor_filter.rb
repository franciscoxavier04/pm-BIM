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

class Queries::WorkPackages::Filter::AncestorFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  include ::Queries::WorkPackages::Filter::FilterForWpMixin

  def apply_to(_query_scope)
    # We are searching for all work packages that are descendants of a list of given ancestors. To do so, we use
    # a recursive CTE.
    cte = <<~SQL.squish
      WITH RECURSIVE descendants AS (
        SELECT id
        FROM work_packages
        WHERE id IN (:ids)
        UNION ALL
        SELECT wp.id
        FROM work_packages wp
        INNER JOIN descendants d ON wp.parent_id = d.id
      )
    SQL

    # We have our descendants, now we need to select them based on the chosen operator:
    select = if operator_strategy.symbol == "="
               # IS (OR)
               # Select all descendants, including the ancestors themselves.
               # Strictly speaking the ancestors should be excluded from the result, but users can easily exclude
               # them by an additional filter if desired. It is more difficult the other way around.
               "SELECT id FROM descendants;"
             else
               # IS NOT
               # Exclude all descendants from the result, including the ancestors themselves.
               "SELECT id FROM work_packages WHERE id NOT IN (SELECT id from descendants);"
             end

    sql = ActiveRecord::Base.sanitize_sql([cte + select, { ids: no_templated_values }])

    descendants = super.find_by_sql(sql).pluck(:id)
    WorkPackage.where(id: descendants)
  end

  def where
    "1=1"
  end
end
