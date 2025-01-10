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

class AddUniquenessIndexToProjectCustomFieldProjectMappings < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      DELETE FROM project_custom_field_project_mappings AS pcfpm_1
        USING project_custom_field_project_mappings AS pcfpm_2
      WHERE pcfpm_1.project_id = pcfpm_2.project_id
        AND pcfpm_1.custom_field_id = pcfpm_2.custom_field_id
        AND pcfpm_1.id > pcfpm_2.id;
    SQL

    add_index :project_custom_field_project_mappings, %i[project_id custom_field_id],
              unique: true,
              name: "index_project_custom_field_project_mappings_unique"
  end

  def down
    remove_index :project_custom_field_project_mappings, name: "index_project_custom_field_project_mappings_unique"
  end
end
