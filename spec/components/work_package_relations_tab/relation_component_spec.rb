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

RSpec.describe WorkPackageRelationsTab::RelationComponent, type: :component do
  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  current_user { user }

  shared_let_work_packages(<<~TABLE)
    hierarchy    | MTWTFSS    | scheduling mode | predecessors
    predecessor  | XXX        | manual          |
    work_package |          X | automatic       | predecessor with lag 2
      child      |            | automatic       |
  TABLE

  def render_component(**params)
    render_inline(described_class.new(work_package:, **params))
  end

  context "with child relations" do
    context "when visible" do
      it "renders a title link" do
        expect(render_component(relation: nil, child: child, visibility: :visible))
          .to have_link "child"
      end

      context "when editable" do
        it "renders an action menu" do
          component = render_component(relation: nil, child: child, visibility: :visible, editable: true)
          expect(component).to have_menu # FIXME: aria-labelledby does not resolve here "Relation actions"
          expect(component).to have_selector :menuitem, "Delete relation"
        end
      end
    end

    context "when ghost" do
      it "does not render a title link" do
        expect(render_component(relation: nil, child: child, visibility: :ghost))
          .to have_no_link "child"
      end

      it "renders a title and message without details" do
        expect(render_component(relation: nil, child: child, visibility: :ghost))
          .to have_text "Related work package"
        expect(render_component(relation: nil, child: child, visibility: :ghost))
          .to have_text "This is not visible to you due to permissions."
      end

      it "does not render an action menu" do
        expect(render_component(relation: nil, child: child, visibility: :ghost))
          .to have_no_menu
      end
    end
  end

  context "with follows relations" do
    context "when visible" do
      it "renders a title link" do
        expect(render_component(relation: _table.relation(predecessor: predecessor), visibility: :visible))
          .to have_link "predecessor"
      end

      it "renders the lag" do
        expect(render_component(relation: _table.relation(predecessor: predecessor), visibility: :visible))
          .to have_text "Lag: 2 days"
      end

      context "when editable" do
        it "renders a action menu" do
          component = render_component(relation: _table.relation(predecessor: predecessor), visibility: :visible, editable: true)
          expect(component).to have_menu # FIXME: aria-labelledby does not resolve here "Relation actions"
          expect(component).to have_selector :menuitem, "Edit relation"
          expect(component).to have_selector :menuitem, "Delete relation"
        end
      end
    end

    context "when ghost" do
      it "does not render a title link" do
        expect(render_component(relation: _table.relation(predecessor: predecessor), visibility: :ghost))
          .to have_no_link "child"
      end

      it "renders a title and message without details" do
        expect(render_component(relation: _table.relation(predecessor: predecessor), visibility: :ghost))
          .to have_text "Related work package"
        expect(render_component(relation: _table.relation(predecessor: predecessor), visibility: :ghost))
          .to have_text "This is not visible to you due to permissions."
      end

      it "does not render an action menu" do
        expect(render_component(relation: _table.relation(predecessor: predecessor), visibility: :ghost))
          .to have_no_menu
      end
    end

    context "when closest" do
      it "always renders a closest label" do
        expect(render_component(relation: _table.relation(predecessor: predecessor), visibility: :visible, closest: true))
          .to have_primer_label "Closest", scheme: :primary
        expect(render_component(relation: _table.relation(predecessor: predecessor), visibility: :ghost, closest: true))
          .to have_primer_label "Closest", scheme: :primary
      end
    end
  end
end
