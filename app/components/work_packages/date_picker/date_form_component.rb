# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages
  module DatePicker
    class DateFormComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      attr_reader :work_package

      def initialize(work_package:,
                     schedule_manually:,
                     disabled:,
                     is_milestone:,
                     focused_field: :start_date,
                     touched_field_map: nil,
                     date_mode: nil)
        super()

        @work_package = work_package
        @schedule_manually = schedule_manually
        @is_milestone = is_milestone
        @date_mode = date_mode
        @touched_field_map = touched_field_map
        @focused_field = update_focused_field(focused_field)
        @disabled = disabled
      end

      private

      def container_classes(name)
        classes = "wp-datepicker-dialog-date-form--button-container"
        classes += " wp-datepicker-dialog-date-form--button-container_visible" unless show_text_field?(name)

        classes
      end

      def show_text_field?(name)
        return true if @is_milestone || !@schedule_manually
        return true if range_date_mode?

        show_text_field_in_single_date_mode?(name)
      end

      def text_field_options(name:, label:)
        text_field_options = default_field_options(name).merge(
          name: "work_package[#{name}]",
          id: "work_package_#{name}",
          value: field_value(name),
          disabled: disabled?(name),
          label:,
          show_clear_button: !disabled?(name) && !duration_field?(name),
          classes: "op-datepicker-modal--date-field #{'op-datepicker-modal--date-field_current' if @focused_field == name}",
          validation_message: validation_message(name),
          type: duration_field?(name) ? :number : :text
        )

        if duration_field?(name)
          text_field_options = text_field_options.merge(
            trailing_visual: { text: { text: I18n.t("datetime.units.day.other") } }
          )
        end

        text_field_options
      end

      def today(name:)
        return if duration_field?(name)

        text = I18n.t(:label_today).capitalize

        return text if @disabled

        render(Primer::Beta::Link.new(href: "",
                                      "aria-label": if name == :start_date
                                                      I18n.t(:label_today_as_start_date)
                                                    else
                                                      I18n.t(:label_today_as_finish_date)
                                                    end,
                                      data: {
                                        action: "work-packages--date-picker--preview#setTodayForField",
                                        "work-packages--date-picker--preview-field-reference-param": "work_package_#{name}",
                                        test_selector: "op-datepicker-modal--#{name.to_s.dasherize}-field--today"
                                      })) { text }
      end

      def duration_field?(name)
        name == :duration
      end

      def update_focused_field(focused_field)
        if @date_mode.nil? || @date_mode != "range"
          return focused_field_for_single_date_mode(focused_field)
        end

        date_fields = {
          "due_date" => :due_date,
          "start_date" => :start_date,
          "duration" => :duration
        }

        # Default is :start_date
        date_fields.fetch(focused_field.to_s.underscore, :start_date)
      end

      def focused_field_for_single_date_mode(focused_field)
        return :duration if focused_field.to_s == "duration"

        # When the combined date is triggered, we have to actually check for the values.
        # This happens only on initialization
        if focused_field == :combined_date
          return :due_date if field_value(:start_date).nil?
          return :start_date if field_value(:due_date).nil?
        end

        # Focus the field if it is shown..
        return focused_field if show_text_field?(focused_field)

        # .. if not, focus the other one
        focused_field == :start_date ? :due_date : :start_date
      end

      def disabled?(name)
        if name == :duration
          if !@schedule_manually && @work_package.children.any?
            return true
          end

          return false
        end

        @disabled
      end

      def field_value(name)
        errors = @work_package.errors.where(name)
        if (user_value = errors.map { |error| error.options[:value] }.find { !_1.nil? })
          user_value
        else
          @work_package.public_send(name)
        end
      end

      def validation_message(name)
        # it's ok to take the first error only, that's how primer_view_component does it anyway.
        message = @work_package.errors.messages_for(name).first
        message&.upcase_first
      end

      def default_field_options(name)
        data = { "work-packages--date-picker--preview-target": "fieldInput",
                 action: "work-packages--date-picker--preview#markFieldAsTouched " \
                         "work-packages--date-picker--preview#inputChanged " \
                         "focus->work-packages--date-picker--preview#onHighlightField",
                 test_selector: "op-datepicker-modal--#{name.to_s.dasherize}-field" }

        if @focused_field == name
          data[:qa_highlighted] = "true"
          data[:focus] = "true"
        end

        { data: }
      end

      def single_date_field_button_link(focused_field)
        permitted_params = params.merge(date_mode: "range", focused_field:).permit!

        if params[:action] == "new"
          new_work_package_datepicker_dialog_content_path(permitted_params)
        else
          work_package_datepicker_dialog_content_path(permitted_params)
        end
      end

      def range_date_mode?
        @date_mode.present? && @date_mode == "range"
      end

      def field_value_present_or_touched?(name)
        field_value(name).present? || @touched_field_map["#{name}_touched"]
      end

      def show_text_field_in_single_date_mode?(name)
        return true if field_value_present_or_touched?(name)

        # Start date is only shown in the assertion above
        return false if name != :due_date

        # This handles the edge case, that the datepicker starts in single date mode, with the due date being hidden.
        # Normally, the start date is the hidden one, except if only a start date is set.
        # In case we delete the start date, we have to ensure that the datepicker does not switch the fields
        # and suddenly hides the start date. That is why we check for the touched value.
        true if field_value(:start_date).nil? &&
          (@touched_field_map["start_date_touched"] == false || @touched_field_map["start_date_touched"].nil?)
      end
    end
  end
end
