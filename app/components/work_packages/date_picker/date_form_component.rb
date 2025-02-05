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
                     focused_field: :start_date)
        super()

        @work_package = work_package
        @schedule_manually = schedule_manually
        @is_milestone = is_milestone
        @focused_field = update_focused_field(focused_field)
        @disabled = disabled
      end

      private

      def container_classes(name)
        classes = "wp-datepicker-dialog-date-form--date-container"
        classes += " wp-datepicker-dialog-date-form--date-container_date-field-hidden" unless show_text_field?(name)

        classes
      end

      def show_text_field?(name)
        field_value(name).present? || (name == :due_date && field_value(:start_date).nil?)
      end

      def text_field_options(name:, label:)
        text_field_options = default_field_options(name).merge(
          name: "work_package[#{name.to_s}]",
          id: "work_package_#{name.to_s}",
          value: field_value(name),
          disabled: disabled?(name),
          label:,
          caption: caption(name),
          show_clear_button: !duration_field?(name),
          classes: "op-datepicker-modal--date-field #{'op-datepicker-modal--date-field_current' if @focused_field == name}",
          validation_message: validation_message(name)
        )

        if duration_field?(name)
          text_field_options = text_field_options.merge(
            trailing_visual: { text: { text: I18n.t("datetime.units.day.other") } }
          )
        end

        text_field_options
      end

      def caption(name)
        return if duration_field?(name)

        text = I18n.t(:label_today).capitalize

        return text if @disabled

        render(Primer::Beta::Link.new(href: "",
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
        return :start_date if focused_field.nil?

        case focused_field.to_s.underscore
        when "combined_date"
          if field_value(:due_date).present? && field_value(:start_date).nil?
            :due_date
          else
            :start_date
          end
        when "due_date"
          :due_date
        when "duration"
          :duration
        else
          :start_date
        end
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
                         "focus->work-packages--date-picker--preview#onHighlightField",
                 test_selector: "op-datepicker-modal--#{name.to_s.dasherize}-field" }

        if @focused_field == name
          data[:qa_highlighted] = "true"
        end

        if @focused_field == name
          data[:focus] = "true"
        end
        { data: }
      end
    end
  end
end
