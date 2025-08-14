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


module Meetings::PDF::Common::Agenda
  def write_agenda
    return if meeting.sections.empty?

    write_optional_page_break
    write_agenda_sections
  end

  def write_agenda_sections
    meeting.sections.each_with_index { |section, index| write_section(section, index) }
  end

  def format_duration(duration)
    OpenProject::Common::DurationComponent.new(duration, :minutes, abbreviated: true).text
  end

  def section_title(section)
    section.title.presence || I18n.t("meeting_section.untitled_title")
  end

  def format_agenda_item_title(title)
    prawn_table_cell_inline_formatting_data(title, styles.agenda_item_title)
  end

  def format_agenda_item_subtitle(text)
    prawn_table_cell_inline_formatting_data(text, styles.agenda_item_subtitle)
  end

  def agenda_title_wp(work_package)
    href = url_helpers.work_package_url(work_package)
    make_link_href(
      href,
      prawn_table_cell_inline_formatting_data(
        "#{work_package.type.name} ##{work_package.id} #{work_package.subject}",
        { styles: [:underline] }
      )
    )
  end

  def agenda_wp_title_row(agenda_item)
    if agenda_item.visible_work_package?
      work_package = agenda_item.work_package
      [agenda_title_wp(work_package), "(#{work_package.status.name})"].join(" ")
    elsif agenda_item.linked_work_package?
      I18n.t(:label_agenda_item_undisclosed_wp, id: agenda_item.work_package_id)
    elsif agenda_item.deleted_work_package?
      I18n.t(:label_agenda_item_deleted_wp)
    else
      agenda_item.title
    end
  end

  def write_outcome(agenda_item)
    return unless agenda_item.outcomes.exists?

    outcome = agenda_item.outcomes.information_kind.last
    return if outcome.notes.blank?

    pdf.indent(styles.outcome_indent) do
      write_optional_page_break
      write_outcome_title
      write_outcome_notes(outcome.notes)
    end
  end

  def write_outcome_title
    with_vertical_margin(styles.outcome_title_margins) do
      style = styles.outcome_title
      pdf.formatted_text([
                           styles.outcome_symbol.merge({ text: "✓ " }),
                           style.merge({ text: I18n.t("label_agenda_outcome") })
                         ], style)
    end
  end

  def write_outcome_notes(notes)
    with_vertical_margin(styles.outcome_markdown_margins) do
      write_markdown!(
        apply_markdown_field_macros(notes, { project: meeting.project, user: User.current }),
        styles.outcome_markdown_styling_yml
      )
    end
  end
end
