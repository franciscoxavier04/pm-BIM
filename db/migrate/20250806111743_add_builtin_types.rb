# frozen_string_literal: true

class AddBuiltinTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :types, :builtin, :string, default: nil, null: true
    add_index :types, :builtin, unique: true
  end
end
