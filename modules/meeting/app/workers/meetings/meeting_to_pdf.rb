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

module Meetings
  module MeetingToPdf
    def render_meeting!
      write_title!
      write_sections
    end

    def write_sections
      meeting.sections.each { |section| write_section(section) }
    end

    def write_section(section)
      write_section_title(section)
      write_agenda_items(section)
    end

    def write_section_title(section)
      row = [{ content: section_title(section), font_style: :bold }]
      row.push({ content: section_duration(section), align: :right }) if section.agenda_items_sum_duration_in_minutes > 0
      pdf.table([row],
                width: pdf.bounds.width,
                cell_style: {
                  borders: [],
                  background_color: "f6f8fa",
                  padding: [8, 2, 12, 2]
                })
      pdf.move_down 10
    end

    def section_duration(section)
      OpenProject::Common::DurationComponent.new(section.agenda_items_sum_duration_in_minutes, :minutes, abbreviated: true).text
    end

    def section_title(section)
      section.title.presence || I18n.t("meeting_section.untitled_title")
    end

    def write_agenda_items(section)
      section.agenda_items.each { |item| write_agenda_item(item) }
    end

    def write_agenda_item(agenda_item)
      case agenda_item.item_type.to_sym
      when :simple
        write_agenda_item_simple(agenda_item)
      when :work_package
        write_agenda_item_wp(agenda_item)
      end
      write_notes(agenda_item)
      pdf.move_down(20)
    end

    def write_agenda_item_wp(agenda_item)
      work_package = agenda_item.work_package
      pdf.formatted_text([{ text: "##{work_package.id} #{work_package.subject}" }])
      hr_style = styles.cover_header_border
      write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
      pdf.move_down(10)
    end

    def write_agenda_item_simple(agenda_item)
      pdf.formatted_text([{ text: agenda_item.title }])
      hr_style = styles.cover_header_border
      write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
      pdf.move_down(10)
    end

    def write_notes(agenda_item)
      return if agenda_item.notes.blank?

      with_margin(styles.notes_markdown_margins) do
        write_markdown!(
          agenda_item.notes,
          styles.notes_markdown_styling_yml
        )
      end
    end
  end
end
