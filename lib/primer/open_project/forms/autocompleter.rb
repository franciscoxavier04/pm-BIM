# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class Autocompleter < Primer::Forms::BaseComponent
        include AngularHelper
        prepend WrappedInput

        delegate :builder, :form, to: :@input

        def initialize(input:, autocomplete_options:, wrapper_data_attributes: {})
          super()
          @input = input
          @with_search_icon = autocomplete_options.delete(:with_search_icon) { false }
          @autocomplete_component = autocomplete_options.delete(:component) { "opce-autocompleter" }
          @autocomplete_data = autocomplete_options.delete(:data) { {} }
          @autocomplete_inputs = extend_autocomplete_inputs(autocomplete_options)
          @wrapper_data_attributes = wrapper_data_attributes
        end

        def extend_autocomplete_inputs(inputs) # rubocop:disable Metrics/AbcSize
          inputs[:classes] = "ng-select--primerized #{@input.invalid? ? '-error' : ''}"
          inputs[:inputName] ||= builder.field_name(@input.name)
          inputs[:inputValue] ||= builder.object.send(@input.name)
          inputs[:defaultData] ||= true

          if inputs.delete(:decorated)
            inputs[:items] = @input.select_options.map(&:to_h)
            inputs[:model] = selected_options
            inputs[:defaultData] = false
          end

          inputs
        end

        def selected_options
          @input.select_options.filter_map do |item|
            item.value if item.selected
          end
        end
      end
    end
  end
end
