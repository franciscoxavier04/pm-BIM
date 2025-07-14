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
  class KpiSeeder < Seeder
    def seed_data!
      Rails.logger.debug "*** Seeding KPI work package type"

      type = Type.find_or_create_by!(name: "KPI")
      kpi_ziel = WorkPackageCustomField.find_or_create_by!(name: "Zielwert", field_format: "int", is_for_all: true)
      kpi_ist = WorkPackageCustomField.find_or_create_by!(name: "Istwert", field_format: "int", is_for_all: true)

      kpi_group = [
        ["KPI", [kpi_ziel.attribute_name, kpi_ist.attribute_name]]
      ]

      type.update!(
        attribute_groups: kpi_group + type.default_attribute_groups
      )
    end

    def applicable?
      WorkPackageCustomField.where(name: %w[Zielwert Istwert]).empty?
    end
  end
end
