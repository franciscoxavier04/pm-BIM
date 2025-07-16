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
module HackathonData
  class OkrSeeder < Seeder
    def seed_data!
      Rails.logger.debug "*** Seeding Objective and Key result work package types"

      # Create the work package types
      Type.find_or_create_by!(name: "Objective")
      key_result_type = Type.find_or_create_by!(name: "Key Result")

      # Create custom fields
      ziel_field = WorkPackageCustomField.find_or_create_by!(name: "Zielwert", field_format: "int", is_for_all: true)
      ist_field = WorkPackageCustomField.find_or_create_by!(name: "Istwert", field_format: "int", is_for_all: true)

      return if key_result_type.custom_fields.include?(ziel_field)

      # Define the attribute group for both types
      custom_fields_group = [
        ["Metriken", [ziel_field.attribute_name, ist_field.attribute_name]]
      ]

      key_result_type.update!(
        attribute_groups: custom_fields_group + key_result_type.default_attribute_groups
      )
    end

    def applicable?
      true
    end
  end
end
