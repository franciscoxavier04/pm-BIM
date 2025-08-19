# frozen_string_literal: true

module Bim::Bcf
  class NonExistentComment < Comment
    def readonly?
      true
    end
  end
end
