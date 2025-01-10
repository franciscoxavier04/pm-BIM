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

class ChangeViewOfQueriesWithTimelineToGantt < ActiveRecord::Migration[7.0]
  class MigrationQuery < ApplicationRecord
    self.table_name = "queries"
  end

  class MigrationView < ApplicationRecord
    self.table_name = "views"

    # disable STI
    self.inheritance_column = :_type_disabled

    belongs_to :query, class_name: "MigrationQuery"
  end

  def up
    update_view_type_for_timeline_queries(from_view_type: "work_packages_table", to_view_type: "gantt")
  end

  def down
    update_view_type_for_timeline_queries(from_view_type: "gantt", to_view_type: "work_packages_table")
  end

  private

  def update_view_type_for_timeline_queries(from_view_type:, to_view_type:)
    MigrationView
      .joins(:query)
      .where("queries.timeline_visible": true)
      .where(type: from_view_type)
      .update_all(type: to_view_type)
  end
end
