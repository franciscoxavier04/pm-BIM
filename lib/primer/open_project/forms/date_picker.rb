# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class DatePicker < Primer::Forms::TextField
        include AngularHelper

        def initialize(input:, datepicker_options:)
          super(input:)

          @field_wrap_arguments[:invalid] = true if @input.invalid?
          @datepicker_options = datepicker_options
        end
      end
    end
  end
end
