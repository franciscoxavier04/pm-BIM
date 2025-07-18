# frozen_string_literal: true

class NonWorkingDay < ApplicationRecord
  validates :name, :date, presence: true
  validates :date, uniqueness: true
end
