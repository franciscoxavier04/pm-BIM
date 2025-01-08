class RemoveIncorrectManageOwnRemindersPermission < ActiveRecord::Migration[7.1]
  def up
    # Remove manage_own_reminders permission from non member and anonymous roles
    RolePermission
      .where(
        role: Role.where(builtin: [Role::BUILTIN_NON_MEMBER, Role::BUILTIN_ANONYMOUS]),
        permission: :manage_own_reminders
      ).destroy_all

    # Remove all reminders created by anonymous user
    Reminder.where(creator_id: AnonymousUser.first.id).destroy_all
  end

  # No-op
  def down; end
end
