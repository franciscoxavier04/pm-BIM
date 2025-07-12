# frozen_string_literal: true

class AddTypeToProject < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :type, :integer, default: 0, null: false
  end
end
