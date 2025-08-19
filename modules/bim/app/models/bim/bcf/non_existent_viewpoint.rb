# frozen_string_literal: true

module Bim::Bcf
  class NonExistentViewpoint < Viewpoint
    def readonly?
      true
    end
  end
end
