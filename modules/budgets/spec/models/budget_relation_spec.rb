# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"

RSpec.describe BudgetRelation do
  shared_let(:admin) { create(:admin) }
  before do
    allow(User).to receive(:current).and_return(admin)
  end

  describe "calculation logic" do
    describe "top->down" do
      let(:portfolio) { create(:project, type: :portfolio) }
      let(:portfolio_budget) { create(:budget, subject: "Portfolio Budget", project: portfolio, supplementary_amount: 10_000) }

      let(:program1) { create(:project, type: :program, parent: portfolio) }
      let(:program1_budget) { create(:budget, subject: "Program 1 Budget", project: program1, supplementary_amount: 7_000) }

      let(:project1) { create(:project, type: :project, parent: program1) }
      let(:project1_budget) { create(:budget, subject: "Project 1 Budget", project: project1, supplementary_amount: 5_000) }

      let(:program2) { create(:project, type: :program, parent: portfolio) }
      let(:program2_budget) { create(:budget, subject: "Program 2 Budget", project: program2, supplementary_amount: 3_000) }

      let(:project2) { create(:project, type: :project, parent: program2) }
      let(:project2_budget) { create(:budget, subject: "Project 2 Budget", project: project2, supplementary_amount: 2_000) }

      def reload_all
        [
          portfolio, program1, program2, project1, project2,
          portfolio_budget, program1_budget, project1_budget, program2_budget, project2_budget
        ].each(&:reload)
      end

      context "without any relations" do
        it "calculates the correct values" do
          # without any budget relations
          expect(portfolio_budget.budget).to eq(10_000)
          expect(portfolio_budget.allocated_to_children).to eq(0)
          expect(portfolio_budget.spent).to eq(0)
          expect(portfolio_budget.available).to eq(10_000)
        end
      end

      context "with the portfolio -> program1 relation" do
        before do
          described_class.create!(
            parent_budget: portfolio_budget,
            child_budget: program1_budget,
            relation_type: :subtract
          )
          reload_all
        end

        it "allocates the program's budget out of the portfolio budget" do
          expect(portfolio_budget.budget).to eq(10_000)
          expect(portfolio_budget.allocated_to_children).to eq(7_000)
          expect(portfolio_budget.spent).to eq(0)
          expect(portfolio_budget.available).to eq(3_000)

          expect(program1_budget.budget).to eq(7_000)
          expect(program1_budget.allocated_to_children).to eq(0)
          expect(program1_budget.spent).to eq(0)
          expect(program1_budget.available).to eq(7_000)
        end

        context "with the program1 -> project1 relation" do
          before do
            described_class.create!(
              parent_budget: program1_budget,
              child_budget: project1_budget,
              relation_type: :subtract
            )
            reload_all
          end

          it "allocates the project's budget out of the program's budget" do
            expect(portfolio_budget.budget).to eq(10_000)
            expect(portfolio_budget.allocated_to_children).to eq(7_000)
            expect(portfolio_budget.spent).to eq(0)
            expect(portfolio_budget.available).to eq(3_000)

            expect(program1_budget.budget).to eq(7_000)
            expect(program1_budget.allocated_to_children).to eq(5_000)
            expect(program1_budget.spent).to eq(0)
            expect(program1_budget.available).to eq(2_000)

            expect(project1_budget.budget).to eq(5_000)
            expect(project1_budget.allocated_to_children).to eq(0)
            expect(project1_budget.spent).to eq(0)
            expect(project1_budget.available).to eq(5_000)
          end
        end

        context "with the portfolio -> program1, program2 relation" do
          before do
            described_class.create!(
              parent_budget: portfolio_budget,
              child_budget: program2_budget,
              relation_type: :subtract
            )
            reload_all
          end

          it "allocates the program's budget out of the portfolio's budget" do
            expect(portfolio_budget.budget).to eq(10_000)
            expect(portfolio_budget.allocated_to_children).to eq(10_000)
            expect(portfolio_budget.spent).to eq(0)
            expect(portfolio_budget.available).to eq(0)

            expect(program1_budget.budget).to eq(7_000)
            expect(program1_budget.allocated_to_children).to eq(0)
            expect(program1_budget.spent).to eq(0)
            expect(program1_budget.available).to eq(7_000)

            expect(program2_budget.budget).to eq(3_000)
            expect(program2_budget.allocated_to_children).to eq(0)
            expect(program2_budget.spent).to eq(0)
            expect(program2_budget.available).to eq(3_000)
          end

          context "with the program2 -> project2 relation" do
            before do
              described_class.create!(
                parent_budget: program2_budget,
                child_budget: project2_budget,
                relation_type: :subtract
              )
              reload_all
            end

            it "allocates the project's budget out of the program's budget" do
              expect(portfolio_budget.budget).to eq(10_000)
              expect(portfolio_budget.allocated_to_children).to eq(10_000)
              expect(portfolio_budget.spent).to eq(0)
              expect(portfolio_budget.available).to eq(0)

              expect(program2_budget.budget).to eq(3_000)
              expect(program2_budget.allocated_to_children).to eq(2_000)
              expect(program2_budget.spent).to eq(0)
              expect(program2_budget.available).to eq(1_000)

              expect(project2_budget.budget).to eq(2_000)
              expect(project2_budget.allocated_to_children).to eq(0)
              expect(project2_budget.spent).to eq(0)
              expect(project2_budget.available).to eq(2_000)
            end

            context "with logged costs on project1" do
              let(:work_package) { create(:work_package, project: project2, budget: project2_budget) }
              let!(:cost_entry) do
                create(:cost_entry, project: project2, entity: work_package, overridden_costs: 500)
              end

              before do
                reload_all
              end

              it "subtracts the cost from project2's budget" do
                expect(portfolio_budget.spent).to eq(0)
                expect(portfolio_budget.spent_with_children).to eq(500)

                expect(program2_budget.spent).to eq(0)
                expect(program2_budget.spent_with_children).to eq(500)

                expect(project2_budget.budget).to eq(2_000)
                expect(project2_budget.allocated_to_children).to eq(0)
                expect(project2_budget.spent).to eq(500)
                expect(project2_budget.available).to eq(1_500)
              end
            end
          end
        end
      end
    end
  end
end
