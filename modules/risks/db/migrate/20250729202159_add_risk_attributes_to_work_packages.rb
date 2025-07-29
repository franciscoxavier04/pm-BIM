# frozen_string_literal: true

class AddRiskAttributesToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :risk_impact, :integer
    add_column :work_packages, :risk_likelihood, :integer
    add_column :work_packages, :risk_level, :integer
    add_column :work_packages, :work_package_type, :string, default: "WorkPackage"

    add_index :work_packages, :risk_impact
    add_index :work_packages, :risk_likelihood
    add_index :work_packages, :risk_level
    add_index :work_packages, :work_package_type
  end
end
