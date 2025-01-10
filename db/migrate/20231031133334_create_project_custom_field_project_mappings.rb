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

class CreateProjectCustomFieldProjectMappings < ActiveRecord::Migration[7.0]
  def up
    create_table :project_custom_field_project_mappings do |t|
      t.references :custom_field, foreign_key: true, index: {
        name: "index_project_cf_project_mappings_on_custom_field_id"
      }
      t.references :project, foreign_key: true

      t.timestamps
    end

    create_default_mapping
  end

  def down
    drop_table :project_custom_field_project_mappings
  end

  private

  def create_default_mapping
    project_ids = Project.pluck(:id)
    custom_field_ids = ProjectCustomField.pluck(:id)
    mappings = []

    project_ids.each do |project_id|
      custom_field_ids.each do |custom_field_id|
        mappings << { custom_field_id:, project_id: }
      end
    end

    ProjectCustomFieldProjectMapping.create!(mappings)
  end
end
