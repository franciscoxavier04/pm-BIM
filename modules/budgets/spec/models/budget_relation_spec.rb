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
    describe "bottom->up" do
      let(:portfolio) { create(:project, project_type: :portfolio) }
      let(:portfolio_budget) do
        create(:budget, project: portfolio, supplementary_amount: 0)
      end

      let(:program1) { create(:project, project_type: :program, parent: portfolio) }
      let(:program1_budget) { create(:budget, project: program1, supplementary_amount: 0) }

      let(:project1) { create(:project, project_type: :project, parent: program1) }
      let(:project1_budget) { create(:budget, project: project1, supplementary_amount: 5_000) }

      let(:project2) { create(:project, project_type: :project, parent: program1) }
      let(:project2_budget) { create(:budget, project: project2, supplementary_amount: 2_500) }

      context "without any relations" do
        it "calculates the correct values" do # rubocop:disable RSpec/MultipleExpectations
          expect(portfolio_budget.budget).to eq(0)
          expect(portfolio_budget.allocated_to_children).to eq(0)
          expect(portfolio_budget.spent).to eq(0)
          expect(portfolio_budget.available).to eq(0)

          expect(program1_budget.budget).to eq(0)
          expect(program1_budget.allocated_to_children).to eq(0)
          expect(program1_budget.spent).to eq(0)
          expect(program1_budget.available).to eq(0)

          expect(project1_budget.budget).to eq(5_000)
          expect(project1_budget.allocated_to_children).to eq(0)
          expect(project1_budget.spent).to eq(0)
          expect(project1_budget.available).to eq(5_000)

          expect(project2_budget.budget).to eq(2_500)
          expect(project2_budget.allocated_to_children).to eq(0)
          expect(project2_budget.spent).to eq(0)
          expect(project2_budget.available).to eq(2_500)
        end
      end

      context "when setting up project1 to add itself to the program1 budget" do
        before do
          described_class.create!(
            parent_budget: program1_budget,
            child_budget: project1_budget,
            relation_type: :add
          )
        end

        it "allocates the project's budget to the program's budget" do # rubocop:disable RSpec/MultipleExpectations
          expect(portfolio_budget.budget).to eq(0)
          expect(portfolio_budget.allocated_to_children).to eq(0)
          expect(portfolio_budget.spent).to eq(0)
          expect(portfolio_budget.available).to eq(0)

          expect(program1_budget.budget).to eq(5_000)
          expect(program1_budget.allocated_to_children).to eq(5_000)
          expect(program1_budget.spent).to eq(0)
          expect(program1_budget.available).to eq(0)

          expect(project1_budget.budget).to eq(5_000)
          expect(project1_budget.allocated_to_children).to eq(0)
          expect(project1_budget.spent).to eq(0)
          expect(project1_budget.available).to eq(5_000)

          expect(project2_budget.budget).to eq(2_500)
          expect(project2_budget.allocated_to_children).to eq(0)
          expect(project2_budget.spent).to eq(0)
          expect(project2_budget.available).to eq(2_500)
        end

        context "when also setting up project2 to add itself to the program1 budget" do
          before do
            described_class.create!(
              parent_budget: program1_budget,
              child_budget: project2_budget,
              relation_type: :add
            )
          end

          it "allocates both project's budget to the program's budget" do # rubocop:disable RSpec/MultipleExpectations
            expect(portfolio_budget.budget).to eq(0)
            expect(portfolio_budget.allocated_to_children).to eq(0)
            expect(portfolio_budget.spent).to eq(0)
            expect(portfolio_budget.available).to eq(0)

            expect(program1_budget.budget).to eq(7_500)
            expect(program1_budget.allocated_to_children).to eq(7_500)
            expect(program1_budget.spent).to eq(0)
            expect(program1_budget.available).to eq(0)

            expect(project1_budget.budget).to eq(5_000)
            expect(project1_budget.allocated_to_children).to eq(0)
            expect(project1_budget.spent).to eq(0)
            expect(project1_budget.available).to eq(5_000)

            expect(project2_budget.budget).to eq(2_500)
            expect(project2_budget.allocated_to_children).to eq(0)
            expect(project2_budget.spent).to eq(0)
            expect(project2_budget.available).to eq(2_500)
          end

          context "when setting program1 to add itself to the portfolio budget" do
            before do
              described_class.create!(
                parent_budget: portfolio_budget,
                child_budget: program1_budget,
                relation_type: :add
              )
            end

            it "allocates the program's budget to the portfolio's budget" do # rubocop:disable RSpec/MultipleExpectations
              expect(portfolio_budget.budget).to eq(7_500)
              expect(portfolio_budget.allocated_to_children).to eq(7_500)
              expect(portfolio_budget.spent).to eq(0)
              expect(portfolio_budget.available).to eq(0)

              expect(program1_budget.budget).to eq(7_500)
              expect(program1_budget.allocated_to_children).to eq(7_500)
              expect(program1_budget.spent).to eq(0)
              expect(program1_budget.available).to eq(0)

              expect(project1_budget.budget).to eq(5_000)
              expect(project1_budget.allocated_to_children).to eq(0)
              expect(project1_budget.spent).to eq(0)
              expect(project1_budget.available).to eq(5_000)

              expect(project2_budget.budget).to eq(2_500)
              expect(project2_budget.allocated_to_children).to eq(0)
              expect(project2_budget.spent).to eq(0)
              expect(project2_budget.available).to eq(2_500)
            end

            context "when adding some costs to the projects" do
              let(:work_package1) { create(:work_package, project: project1, budget: project1_budget) }
              let!(:cost_entry1) do
                create(:cost_entry, project: project1, entity: work_package1, overridden_costs: 500)
              end

              let(:work_package2) { create(:work_package, project: project2, budget: project2_budget) }
              let!(:cost_entry2) do
                create(:cost_entry, project: project2, entity: work_package2, overridden_costs: 750)
              end

              it "subtracts the costs from the budgets" do
                expect(portfolio_budget.spent).to eq(0)
                expect(portfolio_budget.spent_with_children).to eq(1_250)

                expect(program1_budget.spent).to eq(0)
                expect(program1_budget.spent_with_children).to eq(1_250)

                expect(project1_budget.budget).to eq(5_000)
                expect(project1_budget.spent).to eq(500)
                expect(project1_budget.available).to eq(4_500)

                expect(project2_budget.budget).to eq(2_500)
                expect(project2_budget.spent).to eq(750)
                expect(project2_budget.available).to eq(1_750)
              end
            end
          end
        end
      end
    end

    describe "top->down" do
      let(:portfolio) { create(:project, project_type: :portfolio) }
      let(:portfolio_budget) { create(:budget, project: portfolio, supplementary_amount: 10_000) }

      let(:program1) { create(:project, project_type: :program, parent: portfolio) }
      let(:program1_budget) { create(:budget, project: program1, supplementary_amount: 7_000) }

      let(:project1) { create(:project, project_type: :project, parent: program1) }
      let(:project1_budget) { create(:budget, project: project1, supplementary_amount: 5_000) }

      let(:program2) { create(:project, project_type: :program, parent: portfolio) }
      let(:program2_budget) { create(:budget, project: program2, supplementary_amount: 3_000) }

      let(:project2) { create(:project, project_type: :project, parent: program2) }
      let(:project2_budget) { create(:budget, project: project2, supplementary_amount: 2_000) }

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

    describe "bottom->up and top->down mixed" do
      # - The portfolio has a budget of 10.000€.
      # - The program does not have an assigned budget but is the sum of the project's budgets.
      # - The program budget is taken out of the portfolio budget.
      # - The projects have budgets of 5.000€ and 2.500€.
      # - The projects have half of their budgets already spent.

      let!(:portfolio) { create(:project, project_type: :portfolio) }
      let!(:portfolio_budget) { create(:budget, project: portfolio, supplementary_amount: 10_000) }

      let!(:program1) { create(:project, project_type: :program, parent: portfolio) }
      let!(:program1_budget) { create(:budget, project: program1, supplementary_amount: 0) }

      let!(:portfolio_program_relation) do
        create(:budget_relation, parent_budget: portfolio_budget, child_budget: program1_budget, relation_type: :subtract)
      end

      let!(:project1) { create(:project, project_type: :project, parent: program1) }
      let!(:project1_budget) { create(:budget, project: project1, supplementary_amount: 5_000) }

      let!(:project1_program_relation) do
        create(:budget_relation, parent_budget: program1_budget, child_budget: project1_budget, relation_type: :add)
      end

      let!(:work_package1) { create(:work_package, project: project1, budget: project1_budget) }
      let!(:cost_entry1) do
        create(:cost_entry, project: project1, entity: work_package1, overridden_costs: 2_500)
      end

      let!(:project2) { create(:project, project_type: :project, parent: program1) }
      let!(:project2_budget) { create(:budget, project: project2, supplementary_amount: 2_500) }

      let!(:project2_program_relation) do
        create(:budget_relation, parent_budget: program1_budget, child_budget: project2_budget, relation_type: :add)
      end

      let!(:work_package2) { create(:work_package, project: project2, budget: project2_budget) }
      let!(:cost_entry2) do
        create(:cost_entry, project: project2, entity: work_package2, overridden_costs: 1_250)
      end

      it "calculates the correct values" do # rubocop:disable RSpec/MultipleExpectations
        expect(portfolio_budget.budget).to eq(10_000)
        expect(portfolio_budget.allocated_to_children).to eq(7_500)
        expect(portfolio_budget.spent).to eq(0)
        expect(portfolio_budget.spent_with_children).to eq(3_750)
        expect(portfolio_budget.available).to eq(2_500)

        expect(program1_budget.budget).to eq(7_500)
        expect(program1_budget.allocated_to_children).to eq(7_500)
        expect(program1_budget.spent).to eq(0)
        expect(program1_budget.spent_with_children).to eq(3_750)
        expect(program1_budget.available).to eq(0)

        expect(project1_budget.budget).to eq(5_000)
        expect(project1_budget.allocated_to_children).to eq(0)
        expect(project1_budget.spent).to eq(2_500)
        expect(project1_budget.spent_with_children).to eq(2_500)
        expect(project1_budget.available).to eq(2_500)

        expect(project2_budget.budget).to eq(2_500)
        expect(project2_budget.allocated_to_children).to eq(0)
        expect(project2_budget.spent).to eq(1_250)
        expect(project2_budget.spent_with_children).to eq(1_250)
        expect(project2_budget.available).to eq(1_250)
      end
    end
  end
end
