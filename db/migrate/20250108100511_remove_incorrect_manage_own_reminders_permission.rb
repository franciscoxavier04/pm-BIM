class RemoveIncorrectManageOwnRemindersPermission < ActiveRecord::Migration[7.1]
  def up
    # Remove manage_own_reminders permission from non member and anonymous roles
    execute <<-SQL.squish
      DELETE FROM role_permissions
      WHERE role_id IN (
        SELECT id FROM roles WHERE builtin IN (#{Role::BUILTIN_NON_MEMBER}, #{Role::BUILTIN_ANONYMOUS})
      )
      AND permission = 'manage_own_reminders'
    SQL

    # Remove all reminders created by anonymous user and cascade delete related records
    execute <<-SQL.squish
      WITH deleted_reminders AS (
        DELETE FROM reminders
        WHERE creator_id IN (
          SELECT id FROM users WHERE type = 'AnonymousUser'
        )
        RETURNING id
      ),
      deleted_reminder_notifications AS (
        DELETE FROM reminder_notifications
        WHERE reminder_id IN (SELECT id FROM deleted_reminders)
        RETURNING notification_id
      )
      DELETE FROM notifications
      WHERE id IN (SELECT notification_id FROM deleted_reminder_notifications)
    SQL
  end

  # No-op
  def down; end
end
