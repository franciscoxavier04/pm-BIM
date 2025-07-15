# frozen_string_literal: true

class AddNumericValueToCustomOption < ActiveRecord::Migration[8.0]
  def change
    add_column :custom_options, :numeric_value, :float, null: true
  end
end
