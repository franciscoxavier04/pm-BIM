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

class UpdateProgressCalculation < ActiveRecord::Migration[7.1]
  # See https://community.openproject.org/wp/40749 for migration details
  def up
    current_mode = progress_calculation_mode
    if current_mode == "disabled"
      set_progress_calculation_mode_to_work_based
      previous_mode = "disabled"
      current_mode = "field"
    end

    perform_method = Rails.env.development? ? :perform_now : :perform_later
    WorkPackages::Progress::MigrateValuesJob.public_send(perform_method, current_mode:, previous_mode:)
  end

  def progress_calculation_mode
    value_from_db = ActiveRecord::Base.connection
      .execute("SELECT value FROM settings WHERE name = 'work_package_done_ratio'")
      .first
      &.fetch("value", nil)
    value_from_db || "field"
  end

  def set_progress_calculation_mode_to_work_based
    ActiveRecord::Base.connection.execute("UPDATE settings SET value = 'field' WHERE name = 'work_package_done_ratio'")
  end
end
