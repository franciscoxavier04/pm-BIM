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

class RecreateGoodJobCronIndexesWithConditional < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at_cond)
          add_index :good_jobs, %i[cron_key created_at], where: "(cron_key IS NOT NULL)",
                                                         name: :index_good_jobs_on_cron_key_and_created_at_cond,
                                                         algorithm: :concurrently
        end
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at_cond)
          add_index :good_jobs, %i[cron_key cron_at], where: "(cron_key IS NOT NULL)",
                                                      unique: true,
                                                      name: :index_good_jobs_on_cron_key_and_cron_at_cond,
                                                      algorithm: :concurrently
        end

        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at
        end
        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_cron_at
        end
      end

      dir.down do
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
          add_index :good_jobs, %i[cron_key created_at], name: :index_good_jobs_on_cron_key_and_created_at,
                                                         algorithm: :concurrently
        end
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at)
          add_index :good_jobs, %i[cron_key cron_at], unique: true,
                                                      name: :index_good_jobs_on_cron_key_and_cron_at,
                                                      algorithm: :concurrently
        end

        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at_cond)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at_cond
        end
        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at_cond)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_cron_at_cond
        end
      end
    end
  end
end
