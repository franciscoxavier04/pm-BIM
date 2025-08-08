# frozen_string_literal: true

class FixMissingMeetingsAttachments < ActiveRecord::Migration[8.0]
  def change
    Attachment.where(container_type: "MeetingContent").each do |attachment| 
      container = Meeting.find(attachment.container.meeting_id)
      attachment.container = container
      attachment.save!(validate: false) 
    end
  end
end
