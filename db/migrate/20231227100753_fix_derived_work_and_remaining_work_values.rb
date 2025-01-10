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

class FixDerivedWorkAndRemainingWorkValues < ActiveRecord::Migration[7.0]
  def up
    execute(update_derived_values_as_sum_of_self_and_descendants_sql)
  end

  def down
    execute(update_derived_values_as_sum_of_descendants_sql)
    execute(update_leaf_derived_values_to_null_sql)
  end

  def update_derived_values_as_sum_of_self_and_descendants_sql
    <<~SQL.squish
      WITH wp_derived AS (
        SELECT
          wph.ancestor_id AS id,
          sum(wp.estimated_hours) AS estimated_hours_sum,
          sum(wp.remaining_hours) AS remaining_hours_sum
        FROM work_package_hierarchies wph
          LEFT JOIN work_packages wp ON wph.descendant_id = wp.id
        GROUP BY wph.ancestor_id
      )
      UPDATE
        work_packages
      SET
        derived_estimated_hours = wp_derived.estimated_hours_sum,
        derived_remaining_hours = wp_derived.remaining_hours_sum
      FROM
        wp_derived
      WHERE work_packages.id = wp_derived.id
    SQL
  end

  def update_derived_values_as_sum_of_descendants_sql
    <<~SQL.squish
      WITH wp_derived AS (
        SELECT
          wph.ancestor_id AS id,
          sum(wp.estimated_hours) AS estimated_hours_sum,
          sum(wp.remaining_hours) AS remaining_hours_sum
        FROM work_package_hierarchies wph
          LEFT JOIN work_packages wp ON wph.descendant_id = wp.id
        WHERE wph.ancestor_id != wph.descendant_id
        GROUP BY wph.ancestor_id
      )
      UPDATE
        work_packages
      SET
        derived_estimated_hours = wp_derived.estimated_hours_sum,
        derived_remaining_hours = wp_derived.remaining_hours_sum
      FROM
        wp_derived
      WHERE work_packages.id = wp_derived.id
    SQL
  end

  def update_leaf_derived_values_to_null_sql
    <<~SQL.squish
      UPDATE
        work_packages
      SET
        derived_estimated_hours = NULL,
        derived_remaining_hours = NULL
      WHERE
        id NOT IN (
          SELECT ancestor_id
          FROM work_package_hierarchies
          WHERE generations > 0
        )
    SQL
  end
end
