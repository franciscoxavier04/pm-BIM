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
      end
    end

    context "when all LifeCycleSteps have a value" do
      it "shows all the Project::LifeCycleSteps including value" do
        dialog = overview_page.open_edit_dialog_for_life_cycles

        project.available_life_cycle_steps.each do |step|
          dialog.expect_input_for(step)
        end
      end
    end
  end
end
