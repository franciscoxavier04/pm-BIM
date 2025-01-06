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

class AddsPositionCacheToHierarchyItems < ActiveRecord::Migration[7.1]
  def change
    add_column :hierarchical_items, :position_cache, :bigint, null: true
    add_index :hierarchical_items, :position_cache

    reversible do |dir|
      dir.up do
        root_node = Struct.new(:id)
        service = CustomFields::Hierarchy::HierarchicalItemService.new
        sql = "select id from hierarchical_items where custom_field_id is not NULL;"
        ActiveRecord::Base.connection.execute(sql).each do |row|
          service.send :update_position_cache, root_node.new(**row)
        end
      end
    end
  end
end
