# frozen_string_literal: true

class AddWorkspaceTypeToProject < ActiveRecord::Migration[8.0]
  def change
    change_table :projects, bulk: false do |t|
      t.string :workspace_type, null: false, default: "project", index: true
      t.change_default :workspace_type, from: "project", to: nil
    end

    change_table :project_journals, bulk: false do |t|
      t.string :workspace_type, null: false, default: "project"
      t.change_default :workspace_type, from: "project", to: nil
    end
  end
end
