class CreateScheduledMeetings < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_meetings do |t|
      t.belongs_to :recurring_meeting, null: false, foreign_key: true, index: true
      t.belongs_to :meeting, null: true, foreign_key: true, index: true
      t.date :date, null: false
      t.boolean :cancelled, default: false, null: false

      t.timestamps
    end

    add_index :scheduled_meetings,
              %i[recurring_meeting_id date],
              unique: true
  end
end
