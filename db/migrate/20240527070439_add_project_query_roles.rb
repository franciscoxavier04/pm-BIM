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

class AddProjectQueryRoles < ActiveRecord::Migration[7.1]
  def up
    view_role ||= ProjectQueryRole.find_or_initialize_by(builtin: Role::BUILTIN_PROJECT_QUERY_VIEW)

    view_role.update!(
      name: I18n.t("seeds.common.project_query_roles.item_0.name", default: "Project query viewer"),
      permissions: %i[
        view_project_query
      ]
    )

    edit_role ||= ProjectQueryRole.find_or_initialize_by(builtin: Role::BUILTIN_PROJECT_QUERY_EDIT)
    edit_role.update!(
      name: I18n.t("seeds.common.project_query_roles.item_1.name", default: "Project query editor"),
      permissions: %i[
        view_project_query
        edit_project_query
      ]
    )
  end
end
