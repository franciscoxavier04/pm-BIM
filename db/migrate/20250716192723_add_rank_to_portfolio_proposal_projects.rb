# frozen_string_literal: true

class AddRankToPortfolioProposalProjects < ActiveRecord::Migration[8.0]
  def change
    change_table :portfolio_proposal_projects do |t|
      t.integer :rank, index: true, null: false, default: 0
    end
  end
end
