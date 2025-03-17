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

  # TODO all of the below is just copied. Change!
  def relation_type
    # While this is not a relation (in the sense of it being stored in a different database table) we still
    # want it to be used same as every other relation filter.
    Relation::TYPE_PARENT
  end

  def apply_to(_query_scope)
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
      SELECT * FROM descendants;
    SQL

    sql = ActiveRecord::Base.sanitize_sql([cte, { ids: no_templated_values }])

    descendants = super.find_by_sql(sql)

    WorkPackage.where(id: descendants.pluck(:id))
  end

  def where
    "1 = 1"
  end
end
