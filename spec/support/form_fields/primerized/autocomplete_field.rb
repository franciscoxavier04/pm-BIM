# frozen_string_literal: true

require_relative "form_field"

module FormFields
  module Primerized
    class AutocompleteField < FormField
      ### actions

      def select_option(*values)
        values.each do |val|
          wait_for_autocompleter_options_to_be_loaded

          field_container.find(".ng-select-container").click

          expect(page).to have_css(".ng-option", text: val, visible: :all)
          page.find(".ng-option", text: val, visible: :all).click
          sleep 0.25 # still required?
        end
      end

      def deselect_option(*values)
        values.each do |val|
          wait_for_autocompleter_options_to_be_loaded

          field_container.find(".ng-select-container").click
          page.find(".ng-value", text: val, visible: :all).find(".ng-value-icon").click
          sleep 0.25 # still required?
        end
        field_container.find(".ng-arrow-wrapper").click # close dropdown
        sleep 0.25
      end

      def search(text)
        field_container.find(".ng-select-container input").set text
      end

      def close_autocompleter
        if page.has_css?(".ng-select-container input", wait: 0.1)
          field_container.find(".ng-select-container input").send_keys :escape
        end
      end

      def open_options
        wait_for_autocompleter_options_to_be_loaded
        field_container.find(".ng-select-container").click
      end

      def clear
        field_container.find(".ng-clear-wrapper", visible: :all).click
      end

      def wait_for_autocompleter_options_to_be_loaded
        if has_css?(".ng-spinner-loader", wait: 0.1)
          expect(page).to have_no_css(".ng-spinner-loader")
        end
      end

      ### expectations

      def expect_selected(*values)
        values.each do |val|
          expect(field_container).to have_css(".ng-value", text: val)
        end
      end

      def expect_not_selected(*values)
        values.each do |val|
          expect(field_container).to have_no_css(".ng-value", text: val, wait: 1)
        end
      end

      def expect_blank
        expect(field_container).to have_css(".ng-value", count: 0)
      end

      def expect_no_option(option)
        expect(page)
          .to have_no_css(".ng-option", text: option, visible: :all, wait: 1)
      end

      def expect_option(option, grouping: nil)
        if grouping
          # Make sure the option is displayed under correct grouping title.
          option_group = find(".ng-optgroup", text: grouping)
          option = find(".ng-option.ng-option-child", text: option, visible: :visible)

          expected_group = begin
            option.find(:xpath,
                        "preceding-sibling::*[contains(@class, 'ng-optgroup')][1]",
                        wait: false)
          rescue Capybara::ElementNotFound
            raise "Unable to find the '.ng-optgroup' grouping for option '#{option.text}'"
          end

          expect(option_group).to eq(expected_group), <<~MSG
            Expected the option '#{option.text}' to be under the group '#{option_group.text}',
            but it was under '#{expected_group.text}' instead.
          MSG
        else
          expect(page)
            .to have_css(".ng-option", text: option, visible: :visible)
        end
      end

      def expect_visible
        expect(field_container).to have_css("ng-select")
      end

      def expect_error(string = nil)
        expect(field_container).to have_css(".FormControl-inlineValidation", visible: :all)
        expect(field_container).to have_content(string) if string
      end
    end
  end
end
