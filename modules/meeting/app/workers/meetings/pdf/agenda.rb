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
  module Agenda
    def write_agenda
      write_agenda_title
      write_agenda_sections
    end

    def write_agenda_sections
      meeting.sections.each { |section| write_section(section) }
    end

    def write_agenda_title
      pdf.formatted_text([{ text: I18n.t("meeting.export.label_meeting_agenda"), size: 12, styles: [:bold] }])
      pdf.move_down(10)
    end

    def write_section(section)
      write_section_title(section)
      write_agenda_items(section)
    end

    def write_section_title(section)
      content = ["<b>#{section_title(section)}</b>"]
      if section.agenda_items_sum_duration_in_minutes > 0
        content.push(
          table_formatted_text(
            format_duration(section.agenda_items_sum_duration_in_minutes),
            11, "636C76"
          )
        )
      end
      pdf.table(
        [[{ content: content.join("  "), size: 12 }]],
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          inline_format: true,
          background_color: "EAEAEA",
          padding: [5, 2, 10, 5]
        }
      )
      pdf.move_down 10
    end

    def format_duration(duration)
      OpenProject::Common::DurationComponent.new(duration, :minutes, abbreviated: true).text
    end

    def section_title(section)
      section.title.presence || I18n.t("meeting_section.untitled_title")
    end

    def write_agenda_items(section)
      section.agenda_items.each_with_index do |item, index|
        if index > 0
          pdf.move_down 6
          write_horizontal_line(pdf.cursor, 1, "D0D7DE")
          pdf.move_down(6)
        end
        write_agenda_item(item)
      end
    end

    def write_agenda_item(agenda_item)
      case agenda_item.item_type.to_sym
      when :simple
        write_agenda_title_item_simple(agenda_item)
      when :work_package
        write_agenda_title_item_wp(agenda_item)
      end
      write_notes(agenda_item)
    end

    def table_formatted_text(content, size, color)
      "<font size='#{size}'><color rgb='#{color}'>#{content}</color></font>"
    end

    def write_agenda_item_title(title, duration, user)
      content = ["<b>#{title}</b>"]
      content.push(table_formatted_text(format_duration(duration), 10, "636C76")) if duration > 0
      content.push(table_formatted_text(user.name, 10, "636C76")) unless user.nil?
      pdf.table(
        [[{ content: content.join("  "), size: 11 }]],
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          inline_format: true,
          padding: [5, 2, 2, 5]
        }
      )
      pdf.move_down(3)
    end

    def agenda_title_wp(work_package)
      href = url_helpers.work_package_url(work_package)
      make_link_href(href, "<u>#{work_package.type.name} ##{work_package.id} #{work_package.subject}</u>")
    end

    def write_agenda_title_item_wp(agenda_item)
      work_package = agenda_item.work_package
      write_agenda_item_title(
        [agenda_title_wp(work_package), "(#{work_package.status.name})"].join(" "),
        agenda_item.duration_in_minutes || 0, agenda_item.presenter
      )
    end

    def write_agenda_title_item_simple(agenda_item)
      write_agenda_item_title(agenda_item.title, agenda_item.duration_in_minutes || 0, agenda_item.presenter)
    end

    def write_notes(agenda_item)
      if agenda_item.notes.blank?
        pdf.move_down(10)
        return
      end

      pdf.indent(5) do
        write_markdown!(
          agenda_item.notes,
          styles.notes_markdown_styling_yml
        )
      end
    end
  end
end
