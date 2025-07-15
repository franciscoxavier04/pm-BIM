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
  class RiskSeeder < Seeder
    def seed_data!
      Rails.logger.debug "*** Seeding Risiko work package type"

      type = Type.find_or_create_by!(name: "Risiko")
      risk_likelihood = risk_likelihood_cf
      risk_impact = risk_impact_cf
      risk_level = risk_level_cf

      new_attributes = [risk_likelihood.attribute_name, risk_impact.attribute_name, risk_level.attribute_name]
      attributes = type.attribute_groups.map(&:attributes).flatten
      if attributes.intersect?(new_attributes)
        Rails.logger.warn "*** Already found type group with risk attributes. Skipping"
        return
      end

      risk_group = [
        [
          "Risiken",
          new_attributes
        ]
      ]

      type.update!(
        attribute_groups: risk_group + type.default_attribute_groups
      )

      risk_likelihood.types << type
      risk_impact.types << type
      risk_level.types << type
    end

    def risk_likelihood_cf
      risk_likelihood = WorkPackageCustomField.find_or_initialize_by(name: "Eintrittswahrscheinlichkeit", field_format: "list", is_for_all: true)
      return risk_likelihood if risk_likelihood.persisted?

      [
        "1 - sehr niedrig",
        "2 - niedrig",
        "3 - mittel",
        "4 - hoch",
        "5 - sehr hoch"
      ].each do |ws|
        risk_likelihood.custom_options << CustomOption.build(custom_field: risk_likelihood, value: ws)
      end

      risk_likelihood.save!
      risk_likelihood
    end

    def risk_impact_cf
      risk_impact = WorkPackageCustomField.find_or_initialize_by(name: "Auswirkung", field_format: "list", is_for_all: true)
      return risk_impact if risk_impact.persisted?

      [
        "1 - unwesentlich",
        "2 - geringfügig",
        "3 - merklich",
        "4 - schwerwiegend",
        "5 - katastrophal"
      ].each do |ws|
        risk_impact.custom_options << CustomOption.build(custom_field: risk_impact, value: ws)
      end
      risk_impact.save!
      risk_impact
    end

    def risk_level_cf
      risk_level = WorkPackageCustomField.find_or_initialize_by(name: "Risiko-Level", field_format: "list", is_for_all: true)
      return risk_level if risk_level.persisted?

      %w[1 2 3 4 5 6 8 9 10 12 15 16 20 25].each do |level|
        risk_level.custom_options << CustomOption.build(custom_field: risk_level, value: level)
      end

      risk_level.save!
      risk_level
    end

    def applicable?
      WorkPackageCustomField.where(name: %w[Eintrittswahrscheinlichkeit Auswirkung Risiko-Level]).count < 3
    end
  end
end
