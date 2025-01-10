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

class AddWorkPackageRoles < ActiveRecord::Migration[7.0]
  def up
    # This is how the role was seeded in the first iteration of seeds
    editor_role = WorkPackageRole.find_by(builtin: Role::NON_BUILTIN, name: "Work Package Editor")
    # If we couldn't find a WP from the first iteration of the seeds, find it by the builtin
    editor_role ||= WorkPackageRole.find_or_initialize_by(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR)

    editor_role.update!(
      builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR,
      name: I18n.t("seeds.common.work_package_roles.item_0.name", default: "Work package editor"),
      permissions: %i[
        view_work_packages
        edit_work_packages
        work_package_assigned
        add_work_package_notes
        edit_own_work_package_notes
        manage_work_package_relations
        copy_work_packages
        export_work_packages
        view_own_time_entries
        log_own_time
        edit_own_time_entries
        show_github_content
        view_file_links
      ]
    )

    # This is how the role was seeded in the first iteration of seeds
    commenter_role = WorkPackageRole.find_by(builtin: Role::NON_BUILTIN, name: "Work Package Commenter")
    # If we couldn't find a WP from the first iteration of the seeds, find it by the builtin
    commenter_role ||= WorkPackageRole.find_or_initialize_by(builtin: Role::BUILTIN_WORK_PACKAGE_COMMENTER)
    commenter_role.update!(
      builtin: Role::BUILTIN_WORK_PACKAGE_COMMENTER,
      name: I18n.t("seeds.common.work_package_roles.item_1.name", default: "Work package commenter"),
      permissions: %i[
        view_work_packages
        work_package_assigned
        add_work_package_notes
        add_work_package_attachments
        edit_own_work_package_notes
        export_work_packages
        view_own_time_entries
        log_own_time
        edit_own_time_entries
        show_github_content
        view_file_links
      ]
    )

    # This is how the role was seeded in the first iteration of seeds
    viewer_role = WorkPackageRole.find_by(builtin: Role::NON_BUILTIN, name: "Work Package Viewer")
    # If we couldn't find a WP from the first iteration of the seeds, find it by the builtin
    viewer_role ||= WorkPackageRole.find_or_initialize_by(builtin: Role::BUILTIN_WORK_PACKAGE_VIEWER)
    # Set up attributes
    viewer_role.update!(
      builtin: Role::BUILTIN_WORK_PACKAGE_VIEWER,
      name: I18n.t("seeds.common.work_package_roles.item_2.name", default: "Work package viewer"),
      permissions: %i[
        view_work_packages
        export_work_packages
        show_github_content
      ]
    )
  end
end
