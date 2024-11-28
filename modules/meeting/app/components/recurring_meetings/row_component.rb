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

module RecurringMeetings
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    delegate :meeting, to: :model
    delegate :cancelled?, to: :model
    delegate :recurring_meeting, to: :model
    delegate :project, to: :recurring_meeting
    delegate :schedule, to: :meeting

    def instantiated?
      meeting.present?
    end

    def column_args(column)
      if column == :title
        { style: "grid-column: span 2" }
      else
        super
      end
    end

    def start_time
      if instantiated?
        link_to start_time_title, meeting_path(meeting)
      else
        start_time_title
      end
    end

    def start_time_title
      helpers.format_time(start_time_value, include_date: true)
    end

    def relative_time
      render(OpPrimer::RelativeTimeComponent.new(datetime: start_time_value, prefix: I18n.t(:label_on)))
    end

    def start_time_value
      if instantiated?
        meeting.start_time
      else
        recurring_meeting
          .template
          .start_time
          .change(year: model.date.year, month: model.date.month, day: model.date.day)
      end
    end

    def last_edited
      return unless instantiated?

      helpers.format_time(meeting.updated_at, include_date: true)
    end

    def state
      if model.cancelled?
        :cancelled
      elsif instantiated?
        meeting.state
      else
        :scheduled
      end
    end

    def status
      scheme = status_scheme(state)

      render(Primer::Beta::Label.new(title:, scheme:)) do
        render(Primer::Beta::Text.new) { t("label_meeting_state_#{state}") }
      end
    end

    def status_scheme(state)
      case state
      when "open"
        :success
      when "cancelled"
        :severe
      else
        :secondary
      end
    end

    def create
      return if instantiated?

      render(
        Primer::Beta::Button.new(
          scheme: :default,
          size: :medium,
          tag: :a,
          data: { "turbo-method": "post"},
          href: init_recurring_meeting_path(model.recurring_meeting.id, date: model.date)
        )
      ) do |_c|
        I18n.t("label_recurring_meeting_create")
      end
    end

    def button_links
      [
        action_menu
      ]
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": "More",
                              scheme: :invisible,
                              data: {
                                "test-selector": "more-button"
                              })

        if instantiated? && !cancelled?
          ical_action(menu)

          if delete_allowed?
            delete_action(menu)
          end
        end

        if cancelled?
          restore_action(menu)
        end
      end
    end

    def ical_action(menu)
      menu.with_item(label: I18n.t(:label_icalendar_download),
                     href: download_ics_meeting_path(meeting),
                     content_arguments: {
                       data: { turbo: false }
                     }) do |item|
        item.with_leading_visual_icon(icon: :download)
      end
    end

    def delete_action(menu)
      menu.with_item(label: I18n.t(:label_recurring_meeting_cancel),
                     scheme: :danger,
                     href: meeting_path(meeting),
                     form_arguments: {
                       method: :delete, data: { confirm: I18n.t("text_are_you_sure"), turbo: false }
                     }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def restore_action(menu)
      menu.with_item(label: I18n.t(:label_recurring_meeting_restore),
                     href: init_recurring_meeting_path(recurring_meeting, date: model.date)) do |item|
        item.with_leading_visual_icon(icon: :history)
      end
    end

    def delete_allowed?
      User.current.allowed_in_project?(:delete_meetings, project)
    end

    def copy_allowed?
      User.current.allowed_in_project?(:create_meetings, project)
    end
  end
end
