module Meetings::PDF
  module Participants
    def write_participants
      write_participants_title
      write_participants_table
    end

    def write_participants_table
      columns_count = [participants.size, 3].min

      rows = participants_table_rows(columns_count)
      return if rows.empty?

      pdf.table(rows,
                column_widths: participants_table_column_widths(columns_count),
                cell_style: { borders: [], padding_left: 0, size: 10 })
      pdf.move_down(8)
    end

    def participants_table_column_widths(columns_count)

      width = pdf.bounds.width / columns_count
      [width] * columns_count
    end

    def participants
      meeting.invited_or_attended_participants
    end

    def participants_table_rows(columns_count)
      groups = participants.in_groups(columns_count)
      return [] if groups.empty?

      Array.new(groups[0].size) do |row_index|
        (0..(columns_count - 1)).map do |group_nr|
          { content: participant_name(groups.dig(group_nr, row_index)) }
        end
      end
    end

    def write_participants_title
      pdf.formatted_text([{ text: participants_title, size: 12, styles: [:bold] }])
      pdf.move_down(5)
    end

    def participant_name(participant)
      return "" if participant.nil?

      participant.name
    end

    def participants_title
      "#{Meeting.human_attribute_name(:participants)} (#{meeting.invited_or_attended_participants.count})"
    end
  end
end
