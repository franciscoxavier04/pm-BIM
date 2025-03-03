# frozen_string_literal: true

require_relative "datepicker"

module Components
  class WorkPackageDatepicker < Datepicker
    include MonthRangeSelection

    def clear!
      super

      set_field(duration_field, "", wait_for_changes_to_be_applied: false)
    end

    ##
    # Expect the selected month
    def expect_month(month)
      field = flatpickr_container.first(".cur-month")
      expect(field.text).to eq(month)
    end

    ##
    # Expect duration
    def expect_duration(value)
      if value.blank?
        value = ""
      end

      expect(container).to have_field("work_package[duration]", with: value, wait: 10)
    end

    def milestone_date_field
      container.find_field "work_package[start_date]"
    end

    def start_date_field
      container.find_field "work_package[start_date]"
    end

    def due_date_field
      container.find_field "work_package[due_date]"
    end

    def focus_milestone_date
      focus_field(milestone_date_field)
    end

    def focus_start_date
      focus_field(start_date_field)
    end

    def focus_due_date
      focus_field(due_date_field)
    end

    ##
    # Expect date (milestone type)
    def expect_milestone_date(value, **)
      expect(container).to have_field("work_package[start_date]", with: value, **)
    end

    ##
    # Expect start date
    def expect_start_date(value, **)
      expect(container).to have_field("work_package[start_date]", with: value, **)
    end

    ##
    # Expect due date
    def expect_due_date(value, **)
      expect(container).to have_field("work_package[due_date]", with: value, **)
    end

    def set_milestone_date(value)
      set_field(milestone_date_field, value)
    end

    def set_start_date(value)
      set_field(start_date_field, value)
    end

    def set_due_date(value)
      set_field(due_date_field, value)
    end

    def expect_start_highlighted
      expect(container).to have_css('[data-test-selector="op-datepicker-modal--start-date-field"][data-qa-highlighted]')
    end

    def expect_due_highlighted
      expect(container).to have_css('[data-test-selector="op-datepicker-modal--due-date-field"][data-qa-highlighted]')
    end

    def duration_field
      container.find_field "work_package[duration]"
    end

    def focus_duration
      focus_field(duration_field)
    end

    def set_today(date)
      page.find_test_selector("op-datepicker-modal--#{date}-date-field--today").click
    end

    def set_duration(value)
      set_field(duration_field, value)
    end

    def expect_duration_highlighted
      expect(container).to have_css('[data-test-selector="op-datepicker-modal--duration-field"][data-qa-highlighted]')
    end

    def expect_start_date_error(expected_error)
      expect_field_error(start_date_field, expected_error)
    end

    def expect_due_date_error(expected_error)
      expect_field_error(due_date_field, expected_error)
    end

    def expect_duration_error(expected_error)
      expect_field_error(duration_field, expected_error)
    end

    def expect_manual_scheduling_mode
      expect(container)
        .to have_css('[data-test-selector="op-datepicker-modal--scheduling_manual"][data-qa-selected="true"]')
    end

    def expect_automatic_scheduling_mode
      expect(container)
        .to have_css('[data-test-selector="op-datepicker-modal--scheduling_automatic"][data-qa-selected="true"]')
    end

    def toggle_scheduling_mode
      page.within_test_selector "op-datepicker-modal--scheduling" do
        page.find('[data-qa-selected="false"]').click
      end
    end

    def expect_working_days_only_disabled
      expect(container)
        .to have_field("work_package[ignore_non_working_days]", disabled: true)
    end

    def expect_working_days_only_enabled
      expect(container)
        .to have_field("work_package[ignore_non_working_days]", disabled: false)
    end

    def expect_working_days_only(checked)
      expect(container)
        .to have_field("work_package[ignore_non_working_days]", checked:, disabled: :all)
    end

    def toggle_working_days_only
      find("label", text: "Working days only").click
    end

    def clear_duration
      set_duration("")
    end

    private

    def save_button_label
      I18n.t(:button_save)
    end

    def expect_field_error(field, expected_error)
      input_validation_element = input_aria_related_element(field, describedby: "validation")
      if expected_error.nil?
        expect(input_validation_element&.visible?)
          .to be_falsey, "Expected no error message for #{field['name']} field, " \
                         "got \"#{input_validation_element&.text}\""
      else
        expect(input_validation_element).to have_text(expected_error)
      end
    end

    def input_aria_related_element(input_element, describedby:)
      input_element["aria-describedby"]
        .split
        .find { _1.start_with?("#{describedby}-") }
        &.then { |id| find(id:, visible: :all) }
    end
  end
end
