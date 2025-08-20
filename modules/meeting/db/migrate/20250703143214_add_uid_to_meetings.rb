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

class AddUidToMeetings < ActiveRecord::Migration[8.0]
  class MigrationSeries < ApplicationRecord
    self.table_name = "recurring_meetings"
  end

  def change
    add_column :meetings, :uid, :string
    add_column :recurring_meetings, :uid, :string

    add_index :meetings, :uid, unique: true
    add_index :recurring_meetings, :uid, unique: true

    reversible do |dir|
      dir.up do
        # Backfill Meeting UIDs using current ICal logic
        execute <<~SQL.squish
          UPDATE meetings
          SET uid = meetings.id || '@' || projects.identifier
          FROM projects
          WHERE meetings.project_id = projects.id;
        SQL

        MigrationSeries.select(:id).find_each do |series|
          uid = "#{Setting.app_title}-#{Setting.host_name}-meeting-series-#{series.id}".dasherize
          series.update_columns(uid:)
        end
      end
    end
  end
end
