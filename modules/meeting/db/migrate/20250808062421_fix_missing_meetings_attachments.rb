# frozen_string_literal: true

class FixMissingMeetingsAttachments < ActiveRecord::Migration[8.0]
  def change
    attachments = Attachment.where(container_type: "MeetingContent").includes(:container)
    meeting_ids = attachments.map { |attachment| attachment.container.meeting_id }.uniq
    meetings_by_id = Meeting.where(id: meeting_ids).index_by(&:id)

    attachments.find_each do |attachment|
      container = meetings_by_id[attachment.container.meeting_id]
      attachment.container = container
      attachment.save!(validate: false)
    end
  end
end
