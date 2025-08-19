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

module API::V3::CostsApiUserPermissionCheck
  def overall_costs_visible?
    (view_time_entries_allowed? && user_has_hourly_rate_permissions?) ||
      (user_has_cost_entry_permissions? && user_has_cost_rates_permission?)
  end

  def labor_costs_visible?
    view_time_entries_allowed? && user_has_hourly_rate_permissions?
  end

  def material_costs_visible?
    user_has_cost_entry_permissions? && user_has_cost_rates_permission?
  end

  def costs_by_type_visible?
    user_has_cost_entry_permissions?
  end

  def spent_time_visible?
    view_time_entries_allowed?
  end

  private

  def user_has_hourly_rate_permissions?
    current_user.allowed_in_project?(:view_hourly_rates, represented.project) ||
    current_user.allowed_in_project?(:view_own_hourly_rate, represented.project)
  end

  def user_has_cost_rates_permission?
    current_user.allowed_in_project?(:view_cost_rates, represented.project)
  end

  def user_has_cost_entry_permissions?
    current_user.allowed_in_project?(:view_own_cost_entries, represented.project) ||
    current_user.allowed_in_project?(:view_cost_entries, represented.project)
  end
end
