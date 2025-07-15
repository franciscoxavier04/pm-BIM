# frozen_string_literal: true

class AddNumericValueToCustomOption < ActiveRecord::Migration[8.0]
  def change
    # it is probably better to use string mapped to big decimal, as it should handle arbitary precision
    add_column :custom_options, :numeric_value, :float, null: true
  end
end
