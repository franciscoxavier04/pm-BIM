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

module Dashboards
  class GridRegistration < ::Grids::Configuration::InProjectBaseRegistration
    grid_class "Grids::Dashboard"
    to_scope :project_dashboards_path

    defaults -> {
      {
        row_count: 1,
        column_count: 2,
        widgets: [
          {
            identifier: "work_packages_table",
            start_row: 1,
            end_row: 2,
            start_column: 1,
            end_column: 2,
            options: {
              name: I18n.t("js.grid.widgets.work_packages_table.title"),
              queryProps: {
                "columns[]": %w(id project type subject),
                filters: JSON.dump([{ status: { operator: "o", values: [] } }])
              }
            }
          }
        ]
      }
    }

    view_permission :view_dashboards
    edit_permission :manage_dashboards
    in_project_scope_path ["dashboards"]
  end
end
