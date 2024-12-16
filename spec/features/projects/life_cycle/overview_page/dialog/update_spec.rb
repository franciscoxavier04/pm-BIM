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

require "spec_helper"
require_relative "../shared_context"

RSpec.describe "Edit project stages and gates on project overview page", :js, :with_cuprite,
               with_flag: { stages_and_gates: true } do
  include_context "with seeded projects and stages and gates"
  let(:user) { create(:admin) }
  let(:overview_page) { Pages::Projects::Show.new(project) }

  before do
    # TODO: Could this work for all feature specs?
    allow(User).to receive(:current).and_return user
    overview_page.visit_page
  end

  describe "with the dialog open" do
    context "when all LifeCycleSteps are blank" do
      before do
        Project::LifeCycleStep.update_all(start_date: nil, end_date: nil)
      end

      it "shows all the Project::LifeCycleSteps without a value" do
        dialog = overview_page.open_edit_dialog_for_life_cycles

        dialog.expect_input("Initiating", value: "", type: :stage, position: 1)
        dialog.expect_input("Ready for Planning", value: "", type: :gate, position: 2)
        dialog.expect_input("Planning", value: "", type: :stage, position: 3)
        dialog.expect_input("Ready for Executing", value: "", type: :gate, position: 4)
        dialog.expect_input("Executing", value: "", type: :stage, position: 5)
        dialog.expect_input("Ready for Closing", value: "", type: :gate, position: 6)
        dialog.expect_input("Closing", value: "", type: :stage, position: 7)

        # Saving the dialog is successful
        dialog.submit
        dialog.expect_closed

        # Sidebar displays the same empty values
        project_life_cycles.each do |life_cycle|
          overview_page.within_life_cycle_container(life_cycle) do
            expect(page).to have_text "-"
          end
        end
      end
    end

    context "when all LifeCycleSteps have a value" do
      it "shows all the Project::LifeCycleSteps and updates them correctly" do
        dialog = overview_page.open_edit_dialog_for_life_cycles

        expect_angular_frontend_initialized

        project.available_life_cycle_steps.each do |step|
          dialog.expect_input_for(step)
        end

        initiating_dates = [start_date - 1.week, start_date]

        retry_block do
          # Retrying because, the caption update does not always kick in.
          original_dates = [life_cycle_initiating.start_date, life_cycle_initiating.end_date]
          dialog.set_date_for(life_cycle_initiating, value: original_dates)
          dialog.set_date_for(life_cycle_initiating, value: initiating_dates)

          dialog.expect_caption(life_cycle_initiating, text: "Duration: 8 working days")
        end

        ready_for_planning_date = start_date + 1.day
        dialog.set_date_for(life_cycle_ready_for_planning, value: ready_for_planning_date)
        dialog.expect_no_caption(life_cycle_ready_for_planning)

        # Saving the dialog is successful
        dialog.submit
        dialog.expect_closed

        # Sidebar is refreshed with the updated values
        expected_date_range = initiating_dates.map { |date| date.strftime("%m/%d/%Y") }.join(" - ")
        overview_page.within_life_cycle_container(life_cycle_initiating) do
          expect(page).to have_text expected_date_range
        end

        overview_page.within_life_cycle_container(life_cycle_ready_for_planning) do
          expect(page).to have_text ready_for_planning_date.strftime("%m/%d/%Y")
        end
      end

      it "shows the validation errors" do
        dialog = overview_page.open_edit_dialog_for_life_cycles

        expected_text = "Date can’t be earlier than the previous Stage's end date."

        # Retrying because, the validation does not always kick in.
        retry_block do
          dialog.set_date_for(life_cycle_ready_for_planning, value: start_date)
          dialog.set_date_for(life_cycle_ready_for_planning, value: start_date + 1.day)

          dialog.expect_validation_message(life_cycle_ready_for_planning, text: expected_text)
        end

        # Saving the dialog fails
        dialog.submit
        dialog.expect_open

        # The validation message is kept after the unsuccessful save attempt
        dialog.expect_validation_message(life_cycle_ready_for_planning, text: expected_text)

        # The validation message is cleared when date is changed
        dialog.set_date_for(life_cycle_ready_for_planning, value: start_date + 2.days)
        dialog.expect_no_validation_message(life_cycle_ready_for_planning)

        # Saving the dialog is successful
        dialog.submit
        dialog.expect_closed
      end
    end
  end
end
