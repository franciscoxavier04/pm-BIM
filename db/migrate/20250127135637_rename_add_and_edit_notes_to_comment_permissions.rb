# frozen_string_literal: true

class RenameAddAndEditNotesToCommentPermissions < ActiveRecord::Migration[7.1]
  def change
    RolePermission.where(permission: "add_work_package_notes").update_all(permission: "add_work_package_comments")
    RolePermission.where(permission: "edit_work_package_notes").update_all(permission: "edit_work_package_comments")
    RolePermission.where(permission: "edit_own_work_package_notes").update_all(permission: "edit_own_work_package_comments")
  end
end
