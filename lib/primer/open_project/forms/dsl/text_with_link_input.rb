# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class TextWithLinkInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label

          def initialize(text_input_object: {}, link_object: {}, **system_arguments)
            @text_input_object = text_input_object
            @link_object = link_object

            super(**system_arguments) # Pass any other system arguments like classes, etc.
          end

          def to_component
            # Pass the text_input_object and link_object to TextWithLink
            TextWithLink.new(input: self, text_input_object: @text_input_object, link_object: @link_object)
          end

          def focusable?
            true
          end
        end
      end
    end
  end
end
