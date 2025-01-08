class RemoveIncorrectManageOwnRemindersPermission < ActiveRecord::Migration[7.1]
  def up
    RolePermission
      .where(
        role: Role.where(builtin: [Role::BUILTIN_NON_MEMBER, Role::BUILTIN_ANONYMOUS]),
        permission: :manage_own_reminders
      ).destroy_all
  end

  # No-op
  def down; end
end
