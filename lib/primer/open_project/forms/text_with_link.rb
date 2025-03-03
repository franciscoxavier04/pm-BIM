# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      class TextWithLink < Primer::Forms::BaseComponent
        prepend WrappedInput

        delegate :builder, :form, to: :@input

        def initialize(input:, text_input_object:, link_object:)
          super()
          @input = input
          @text_input_object = text_input_object
          @link_object = link_object
        end
      end
    end
  end
end
