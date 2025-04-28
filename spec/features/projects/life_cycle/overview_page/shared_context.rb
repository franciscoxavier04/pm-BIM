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

RSpec.shared_context "with seeded projects and phases" do
  shared_let(:project) { create(:project, name: "Foo project", identifier: "foo-project") }
  shared_let(:standard) { create(:standard_global_role) }
  shared_let(:admin) { create(:admin) }

  shared_let(:life_cycle_initiating_definition) do
    create :project_phase_definition, name: "Initiating"
  end
  shared_let(:life_cycle_planning_definition) do
    create :project_phase_definition, :with_gates, name: "Planning"
  end
  shared_let(:life_cycle_executing_definition) do
    create :project_phase_definition, :with_gates, name: "Executing"
  end
  shared_let(:life_cycle_closing_definition) do
    create :project_phase_definition, name: "Closing"
  end

  let(:start_date) { Time.zone.today.next_week }

  let(:life_cycle_initiating) do
    create :project_phase,
           definition: life_cycle_initiating_definition,
           start_date:,
           finish_date: start_date + 1.day,
           project:
  end
  let(:life_cycle_planning) do
    create :project_phase,
           definition: life_cycle_planning_definition,
           start_date: start_date + 4.days,
           finish_date: start_date + 7.days,
           project:
  end
  let(:life_cycle_executing) do
    create :project_phase,
           definition: life_cycle_executing_definition,
           start_date: start_date + 9.days,
           finish_date: start_date + 10.days,
           project:
  end
  let(:life_cycle_closing) do
    create :project_phase,
           definition: life_cycle_closing_definition,
           start_date: start_date + 14.days,
           finish_date: start_date + 18.days,
           project:
  end

  let!(:project_life_cycles) do
    [
      life_cycle_initiating,
      life_cycle_planning,
      life_cycle_executing,
      life_cycle_closing
    ]
  end

  before do
    project.add_journal(user: SystemUser.first)

    project.save_journals
  end
end
