# frozen_string_literal: true

class AddTypeToProject < ActiveRecord::Migration[8.0]
  def change
    change_table :projects, bulk: false do |t|
      t.string :type, default: "Project", null: false
      t.change_default :type, from: "Project", to: nil
    end
  end
end
