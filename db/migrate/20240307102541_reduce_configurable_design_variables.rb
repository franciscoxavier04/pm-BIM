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

class ReduceConfigurableDesignVariables < ActiveRecord::Migration[7.1]
  class MigrationDesignColor < ApplicationRecord
    self.table_name = "design_colors"
  end

  def up
    # Delete "primary-color" and "primary-color-dark"
    MigrationDesignColor
      .where(variable: %w(primary-color primary-color-dark))
      .delete_all

    # Rename "alternative-color" to "primary-button-color"
    MigrationDesignColor
      .where(variable: "alternative-color")
      .update(variable: "primary-button-color")

    # Rename "content-link-color" to "accent-color"
    MigrationDesignColor
      .where(variable: "content-link-color")
      .update(variable: "accent-color")
  end

  def down
    MigrationDesignColor
      .create(variable: "primary-color", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_PRIMARY_COLOR)
    MigrationDesignColor
      .create(variable: "primary-color-dark", hexcode: OpenProject::CustomStyles::ColorThemes::DEPRECATED_PRIMARY_DARK_COLOR)

    MigrationDesignColor
      .where(variable: "primary-button-color")
      .update(variable: "alternative-color")

    MigrationDesignColor
      .where(variable: "accent-color")
      .update(variable: "content-link-color")
  end
end
