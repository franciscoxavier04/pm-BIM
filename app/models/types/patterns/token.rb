# frozen_string_literal: true

#-- copyright
#++

module Types
  module Patterns
    Token = Data.define(:pattern) do
      def key = pattern.tr("{}", "").to_sym
    end
  end
end
