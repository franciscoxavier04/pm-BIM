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
module BasicData
  class LifeCycleSeeder < ModelSeeder
    self.model_class = LifeCycle
    self.seed_data_model_key = "life_cycles"
    self.needs = [
      BasicData::ColorSeeder,
      BasicData::ColorSchemeSeeder
    ]
    self.attribute_names_for_lookups = %i[name type]

    def seed_data!
      seed_missing_colors! if models_data.any?
      super
    end

    def model_attributes(life_cyle_data)
      {
        name: life_cyle_data["name"],
        type: life_cyle_data["type"],
        color_id: color_id(life_cyle_data["color_name"])
      }
    end

    private

    def seed_missing_colors!
      color_seeder.seed_models!(missing_colors)
    end

    def color_seeder
      @color_seeder ||= BasicData::ColorSeeder.new(seed_data)
    end

    def missing_colors
      # Build map for color names and references for a reverse lookup
      # ie: { "PM2 Orange" => :default_color_pm2_orange, "PM2 Red"=>:default_color_pm2_red }
      required_colors = models_data.pluck("color_name")
      required_color_map = required_colors.each_with_object({}) do |reference, colors|
        color_name = color_seeder.mapped_models_data.dig(reference, :name) or
                     raise ArgumentError, "Could not find required color #{reference} in seed data definition."
        colors[color_name] = reference
      end
      existing_names = Color.where(name: required_color_map.keys).pluck(:name)
      missing_names = required_color_map.keys - existing_names
      required_color_map.values_at(*missing_names)
    end
  end
end
