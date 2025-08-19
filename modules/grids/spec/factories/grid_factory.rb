# frozen_string_literal: true

FactoryBot.define do
  factory :grid, class: "Grids::Grid" do
    row_count { 5 }
    column_count { 5 }
  end
end
