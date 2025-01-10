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

class FixUntranslatedWorkPackageRoles < ActiveRecord::Migration[7.1]
  def up
    seed_work_package_roles_data.each_value do |work_package_role_data|
      work_package_role = WorkPackageRole.find_by(builtin: work_package_role_data[:builtin])
      work_package_role&.update(name: work_package_role_data[:name])
    end
  end

  def seed_work_package_roles_data
    seed_data = RootSeeder.new.translated_seed_data_for("work_package_roles", "modules_permissions")
    seeder = BasicData::WorkPackageRoleSeeder.new(seed_data)
    seeder.mapped_models_data
  end
end
