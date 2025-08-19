# frozen_string_literal: true

class AddListItemScore < ActiveRecord::Migration[8.0]
  def change
    add_column :hierarchical_items, :score, :decimal, default: nil, null: true
  end
end
