# frozen_string_literal: true

class CreateBeyondDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :beyond_documents do |t|
      t.string :name, null: false
      t.text :content
      t.references :author, foreign_key: { to_table: :users }, null: false
      t.references :project, foreign_key: true, null: false
      t.references :type, foreign_key: { to_table: :types }
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :status, foreign_key: true

      t.timestamps
    end
  end
end
