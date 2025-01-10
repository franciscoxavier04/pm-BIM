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

class CreateGoodJobs < ActiveRecord::Migration[7.0]
  def change
    # Uncomment for Postgres v12 or earlier to enable gen_random_uuid() support
    # enable_extension 'pgcrypto'

    create_table :good_jobs, id: :uuid do |t|
      t.text :queue_name
      t.integer :priority
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :performed_at
      t.datetime :finished_at
      t.text :error

      t.timestamps

      t.uuid :active_job_id
      t.text :concurrency_key
      t.text :cron_key
      t.uuid :retried_good_job_id
      t.datetime :cron_at
    end

    create_table :good_job_processes, id: :uuid do |t|
      t.timestamps
      t.jsonb :state
    end

    add_index :good_jobs, :scheduled_at, where: "(finished_at IS NULL)", name: :index_good_jobs_on_scheduled_at
    add_index :good_jobs, %i[queue_name scheduled_at], where: "(finished_at IS NULL)",
                                                       name: :index_good_jobs_on_queue_name_and_scheduled_at
    add_index :good_jobs, %i[active_job_id created_at], name: :index_good_jobs_on_active_job_id_and_created_at
    add_index :good_jobs, :concurrency_key, where: "(finished_at IS NULL)",
                                            name: :index_good_jobs_on_concurrency_key_when_unfinished
    add_index :good_jobs, %i[cron_key created_at], name: :index_good_jobs_on_cron_key_and_created_at
    add_index :good_jobs, %i[cron_key cron_at], name: :index_good_jobs_on_cron_key_and_cron_at, unique: true
    add_index :good_jobs, [:active_job_id], name: :index_good_jobs_on_active_job_id
    add_index :good_jobs, [:finished_at], where: "retried_good_job_id IS NULL AND finished_at IS NOT NULL",
                                          name: :index_good_jobs_jobs_on_finished_at
  end
end
