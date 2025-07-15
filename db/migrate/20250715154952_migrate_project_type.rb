# frozen_string_literal: true

class MigrateProjectType < ActiveRecord::Migration[8.0]
  def up
    add_column :projects, :project_type, :string, null: false, default: "project"
    execute <<~SQL.squish
      UPDATE projects SET project_type = CASE type
        WHEN 2 THEN 'portfolio'
        WHEN 1 THEN 'program'
        ELSE 'project'
      END;
    SQL
    remove_column :projects, :type
  end

  def down
    add_column :projects, :type, :integer, default: 0, null: false
    execute <<~SQL.squish
      UPDATE projects SET type = CASE project_type
        WHEN 'portfolio' THEN 2
        WHEN 'program' THEN 1
        ELSE 0
      END;
    SQL
    remove_column :projects, :project_type
  end
end
