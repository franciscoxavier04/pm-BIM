# frozen_string_literal: true

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

module Meetings::PDF
  module Participants
    def write_participants
      return if participants.empty?

      write_hr
      write_pdf_section_title(participants_title)
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

    def participant_name(participant)
      return "" if participant.nil?

      participant.name
    end

    def participants_title
      "#{Meeting.human_attribute_name(:participants)} (#{meeting.invited_or_attended_participants.count})"
    end
  end
end
