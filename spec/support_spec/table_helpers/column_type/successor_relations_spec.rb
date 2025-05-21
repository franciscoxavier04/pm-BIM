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

require "spec_helper"

module TableHelpers::ColumnType
  RSpec.describe SuccessorRelations do
    subject(:column_type) { described_class.new }

    def parsed_data(table)
      TableHelpers::TableParser.new.parse(table)
    end

    describe "empty" do
      it "stores nothing when empty" do
        work_package_data = parsed_data(<<~TABLE).first
          | successors |
          |            |
        TABLE
        expect(work_package_data[:relations]).to be_nil
        expect(work_package_data[:attributes]).to be_empty

        work_package_data = parsed_data(<<~TABLE).first
          | successors |
          |            |
        TABLE
        expect(work_package_data[:relations]).to be_nil
        expect(work_package_data[:attributes]).to be_empty
      end
    end

    describe "[precedes] <successor> [with lag <nb_days>]" do
      it "stores precedes relations in work_package_data" do
        work_package_data = parsed_data(<<~TABLE).pluck(:relations)
          | successors               |
          | precedes main with lag 3 |
          | main with lag 3          |
        TABLE
        expect(work_package_data)
          .to eq([
                   {
                     "main" => { raw: "precedes main with lag 3", type: :precedes, with: "main", lag: 3 }
                   },
                   {
                     "main" => { raw: "main with lag 3", type: :precedes, with: "main", lag: 3 }
                   }
                 ])
      end

      it "has a default lag of 0 days when not specified" do
        work_package_data = parsed_data(<<~TABLE).pluck(:relations)
          | successors    |
          | precedes main |
          | main          |
        TABLE
        expect(work_package_data)
          .to eq([
                   {
                     "main" => { raw: "precedes main", type: :precedes, with: "main", lag: 0 }
                   },
                   {
                     "main" => { raw: "main", type: :precedes, with: "main", lag: 0 }
                   }
                 ])
      end

      it "can store multiple relations" do
        work_package_data = parsed_data(<<~TABLE).pluck(:relations)
          | successors                 |
          | precedes wp1, precedes wp2 |
          | precedes wp1, wp2, wp3     |
        TABLE
        expect(work_package_data)
          .to eq([
                   {
                     "wp1" => { raw: "precedes wp1", type: :precedes, with: "wp1", lag: 0 },
                     "wp2" => { raw: "precedes wp2", type: :precedes, with: "wp2", lag: 0 }
                   },
                   {
                     "wp1" => { raw: "precedes wp1", type: :precedes, with: "wp1", lag: 0 },
                     "wp2" => { raw: "wp2", type: :precedes, with: "wp2", lag: 0 },
                     "wp3" => { raw: "wp3", type: :precedes, with: "wp3", lag: 0 }
                   }
                 ])
      end
    end
  end
end
