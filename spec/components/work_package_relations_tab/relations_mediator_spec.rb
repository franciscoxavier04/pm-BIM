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

require "rails_helper"

RSpec.describe WorkPackageRelationsTab::RelationsMediator do
  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  current_user { user }

  subject(:mediator) { described_class.new(work_package:) }

  shared_let_work_packages(<<~TABLE)
    hierarchy    | MTWTFSS    | scheduling mode | predecessors
    predecessor1 | XXX        | manual          |
    predecessor2 | XX         | manual          |
    predecessor3 | XX         | manual          |
    predecessor4 |            | manual          |
    work_package |          X | automatic       | predecessor1 with lag 2, predecessor2 with lag 7, predecessor3 with lag 7, predecessor4 with lag 10
  TABLE

  describe "RelationGroup" do
    let(:group) { mediator.relation_group("follows") }

    describe "#closest_relation" do
      it "returns the closest follows relation" do
        expect(group.closest_relation).to eq _table.relation(predecessor: predecessor2)
      end
    end

    describe "#closest_relation?(relation)" do
      it "returns true if the given relation is the closest one, false otherwise" do
        expect(group.closest_relation?(_table.relation(predecessor: predecessor2))).to be true
        expect(group.closest_relation?(_table.relation(predecessor: predecessor1))).to be false
      end
    end

    describe "#closest_relations" do
      it "returns all follows relations with dates set, with the closest first" do
        expect(group.closest_relations).to eq [
          _table.relation(predecessor: predecessor2),
          _table.relation(predecessor: predecessor3),
          _table.relation(predecessor: predecessor1)
        ]
      end

      it "does not return any follows relations without dates set" do
        expect(group.closest_relations).not_to include(_table.relation(predecessor: predecessor4))
      end
    end
  end
end
