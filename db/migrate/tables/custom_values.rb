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

require_relative "base"

class Tables::CustomValues < Tables::Base
  def self.table(migration)
    create_table migration do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :customized_type, limit: 30, default: "", null: false
      t.bigint :customized_id, null: false
      t.bigint :custom_field_id, null: false
      t.text :value

      t.index :custom_field_id, name: "index_custom_values_on_custom_field_id"
      t.index %i[customized_type customized_id], name: "custom_values_customized"
      t.index :value,
              using: "gin",
              opclass: :gin_trgm_ops
    end
  end
end
