class ReminderNotification < ApplicationRecord
  belongs_to :reminder
  belongs_to :notification, dependent: :destroy
end
