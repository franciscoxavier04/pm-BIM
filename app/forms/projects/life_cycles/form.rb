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
module Projects::LifeCycles
  class Form < ApplicationForm
    form do |f|
      f.group(layout: :horizontal) do |horizontal_form|
        start_date_input(horizontal_form)
        finish_date_input(horizontal_form)
        duration_input(horizontal_form)
      end
    end

    private

    def qa_field_name
      "life-cycle-step-#{model.id}"
    end

    def datepicker_attributes(field_name)
      {
        name: field_name,
        label: attribute_name(field_name),
        type: field_type,
        value: value(field_name),
        autofocus: autofocus?(field_name),
        placeholder:,
        show_clear_button: show_clear_button?(field_name),
        clear_button_id: "#{field_name}_clear_button",
        inset: true,
        data: {
          action: "focusin->overview--project-life-cycles-form#onHighlightField " \
                  "overview--project-life-cycles-form#previewForm ",
          "overview--project-life-cycles-form-target": field_name.to_s.camelize(:lower)
        },
        wrapper_data_attributes: {
          "qa-field-name": qa_field_name
        }
      }
    end

    def start_date_input(form)
      input_attributes = {
        disabled: start_date_disabled?,
        caption: start_date_caption,
      }
      form.text_field **datepicker_attributes(:start_date), **input_attributes
    end

    def finish_date_input(form)
      form.text_field **datepicker_attributes(:finish_date)
    end

    def duration_input(form)
      input_attributes = {
        name: :duration,
        label: attribute_name(:duration),
        type: :number,
        inset: true,
        disabled: true,
        value: model.duration,
        trailing_visual: { text: { text: I18n.t("datetime.units.day", count: model.duration) } },
        data: { "overview--project-life-cycles-form-target": "duration" }
      }
      form.text_field **input_attributes
    end

    def autofocus?(field_name)
      start_date_blank = model.start_date.blank? && model.default_start_date.blank?
      case field_name
      when :start_date
        start_date_blank
      when :finish_date
        !start_date_blank && model.finish_date.blank?
      end
    end

    def show_clear_button?(field_name)
      value_is_present = value(field_name).present?
      case field_name
      when :start_date
        value_is_present && !start_date_disabled?
      when :finish_date
        value_is_present
      end
    end

    def value(field_name)
      case field_name
      when :start_date
        model.default_start_date || model.start_date_before_type_cast
      when :finish_date
        model.finish_date_before_type_cast
      end
    end

    def start_date_disabled?
      model.default_start_date.present?
    end

    def start_date_caption
      start_date_disabled? ? I18n.t("activerecord.attributes.project/phase.start_date_caption") : nil
    end

    def field_type
      # Do not show the native datepicker on iOS safari because it
      # behaves totally different than all other browsers and destroys the behavior of the datepicker
      # Given a date field with no value: When Safari opens its native datepicker, the first thing it does is to
      # set the date to Today. And not only in the datepicker but directly in the field.
      # This behaviour has however consequences:
      # * The "reset" button in the datepicker does not clear the input (as the other browsers do it) but it resets
      #   it to the original value it had when you opened it. So if the value was empty, it sets it back to empty.
      #   If the value was set before, you cannot clear it, but only set it back to that value.
      # * Since the input changes, the whole datepicker updates without the user even knowing about it,
      #   since the form is hidden behind the datepicker. That leads to this:
      #     when you enter a start date after today, and then open the datepicker for finish date,
      #     it will reset the start date because the finish date is set automatically to today,
      #     but the finish date can't be before the start date.
      helpers.browser.device.mobile? && !helpers.browser.safari? ? :date : :text
    end

    def placeholder
      helpers.browser.device.mobile? ? "yyyy-mm-dd" : nil
    end
  end
end
