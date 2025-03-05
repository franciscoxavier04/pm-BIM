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

RSpec.describe WorkPackageRelationsTab::IndexComponent, type: :component do
  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  current_user { user }

  def render_component(**params)
    render_inline(described_class.new(work_package:, **params))
    page
  end

  context "with no relations" do
    it "renders a message" do
      expect(render_component).to have_heading "No relations"
      expect(page).to have_text "This work package does not have any relations yet."
    end
  end

  context "with child relations" do
    shared_let_work_packages(<<~TABLE)
      hierarchy      | MTWTFSS | scheduling mode |
      work_package   |       X | automatic       |
        child1       | XXX     | manual          |
        child2       |         | automatic       |
    TABLE

    it "renders the relations group" do
      expect(render_component).to have_test_selector("op-relation-group-children")
    end

    it "renders the relations" do
      expect(render_component).to have_list "Children"

      list = page.find(:list, "Children")
      expect(list).to have_list_item count: 2, text: /child\d/
    end
  end

  context "with follows relations" do
    shared_let_work_packages(<<~TABLE)
      hierarchy    | MTWTFSS    | scheduling mode | predecessors
      predecessor1 | XXX        | manual          |
      predecessor2 | XX         | manual          |
      predecessor3 | XX         | manual          |
      predecessor4 |            | manual          |
      work_package |          X | automatic       | predecessor1 with lag 2, predecessor2 with lag 7, predecessor3 with lag 7, predecessor4 with lag 10
    TABLE

    it "renders the relations group" do
      expect(render_component).to have_test_selector("op-relation-group-follows")
    end

    it "renders the relations" do
      expect(render_component).to have_list "Predecessors (before)"

      list = page.find(:list, "Predecessors (before)")
      expect(list).to have_list_item count: 4, text: /predecessor\d/
    end

    it "renders the closest relation" do
      render_component

      list_item = page.find(:list_item, text: "predecessor2")
      expect(list_item).to have_primer_label("Closest")
    end
  end
end
