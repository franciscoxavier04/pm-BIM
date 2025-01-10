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

class EnableRequiredProjectCustomFieldsInAllProjects < ActiveRecord::Migration[7.1]
  def up
    required_custom_field_ids = ProjectCustomField.required.ids

    # Gather the custom_field_ids for every project, then add a new mapping
    # of {project_id:, custom_field_id:} for every project that does not have
    # the required required_custom_field_ids activated.
    missing_custom_field_attributes =
      Project
        .includes(:project_custom_field_project_mappings)
        .pluck(:id, "project_custom_field_project_mappings.custom_field_id")
        .group_by(&:first)
        .transform_values { |values| values.map(&:last) }
        .reduce([]) do |acc, (project_id, custom_field_ids)|
          missing_custom_field_ids = required_custom_field_ids - custom_field_ids

          acc + missing_custom_field_ids.map do |custom_field_id|
            { project_id:, custom_field_id: }
          end
        end

    ProjectCustomFieldProjectMapping.insert_all!(missing_custom_field_attributes)
  end

  def down
    # reversing this migration is not possible as we don't store the original state
  end
end
