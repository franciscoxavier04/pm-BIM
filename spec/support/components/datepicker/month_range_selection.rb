module Components
  module MonthRangeSelection
    ##
    # Select month from datepicker
    def select_month(month)
      month = Date::MONTHNAMES.index(month) if month.is_a?(String)
      retry_block do
        current_month = current_month_index

        if current_month < month
          month_difference = month - current_month
          month_difference.times { flatpickr_container.find(".flatpickr-next-month").click }
        elsif current_month > month
          month_difference = current_month - month
          month_difference.times { flatpickr_container.find(".flatpickr-prev-month").click }
        end
        current_month_index
      end
    end

    # Returns the index of the current month.
    #
    # 1 for January, 2 for February, etc.
    #
    # When multiple months are displayed, it returns the value for the first one
    # displayed.
    def current_month_index
      # ensure flatpicker month is displayed
      flatpickr_container.first(".flatpickr-month")

      # Checking if showing multiple months or using `monthSelectorType: "static"`,
      # in which case the month is simply some static text in a span instead of a
      # `<select>` dropdown input.
      if flatpickr_container.all(".cur-month", wait: 0).any?
        # Get value from month name and convert to index
        current_month_element = flatpickr_container.first(".cur-month")
        Date::MONTHNAMES.index(current_month_element.text)
      else
        # get value from select dropdown value
        flatpickr_container.first(".flatpickr-monthDropdown-months").value.to_i + 1
      end
    end
  end
end
