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

class ChangeDefaultAccentAndBimPrimaryColor < ActiveRecord::Migration[7.1]
  class MigrationDesignColor < ApplicationRecord
    self.table_name = "design_colors"
  end

  def up
    # The default Bim value was forgotten in previous migrations
    if OpenProject::Configuration.bim?
      MigrationDesignColor
        .where(variable: "primary-button-color", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_BIM_ALTERNATIVE_COLOR)
        .update_all(hexcode: OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR)
    end

    # When merging the old "primary" and "link" color into the new "accent" color,
    # it was forgotten to use the value of "primary" for it.
    MigrationDesignColor
      .where(variable: "accent-color", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_LINK_COLOR)
      .update_all(hexcode: OpenProject::CustomStyles::ColorThemes::ACCENT_COLOR)
  end

  def down
    if OpenProject::Configuration.bim?
      MigrationDesignColor
        .where(variable: "primary-button-color", hexcode: OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR)
        .update_all(hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_BIM_ALTERNATIVE_COLOR)
    end

    MigrationDesignColor
      .where(variable: "accent-color", hexcode: OpenProject::CustomStyles::ColorThemes::ACCENT_COLOR)
      .update_all(hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_LINK_COLOR)
  end
end
