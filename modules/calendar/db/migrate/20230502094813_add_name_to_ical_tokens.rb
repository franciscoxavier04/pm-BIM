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

class AddNameToICalTokens < ActiveRecord::Migration[7.0]
  def up
    # Add column with default value to avoid null values for existing records in preview environment
    add_column :ical_token_query_assignments, :name, :string, null: false, default: "Not provided in earlier version"
    # Remove default value after migration and applying it to existing records
    change_column_default :ical_token_query_assignments, :name, nil
  end

  def down
    remove_column :ical_token_query_assignments, :name
    # Remove all ical tokens as they have been created with a name before and
    # are not intended to be used without a name
    Token::ICal.delete_all
  end
end
