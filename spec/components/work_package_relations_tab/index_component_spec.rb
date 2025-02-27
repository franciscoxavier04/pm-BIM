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
  # shared_let(:work_package) { create(:work_package) }

  let(:work_package) { build_stubbed(:work_package) }

  let!(:predecessor1) { build_stubbed(:work_package) }
  let!(:relation1) do
    build_stubbed(:relation, from: work_package,
                             to: predecessor1,
                             relation_type: "follows")
  end

  current_user { user }

  class HtmlSnapshotSerializer
    # @param [Nokogiri::HTML4::DocumentFragment] doc The value to serialize.
    # @return [String] The serialized value.
    def dump(doc)
      replace_attribute_values(doc, "[id]", :id)
      replace_attribute_values(doc, "input[name=authenticity_token]", :value)
      replace_attribute_value_ids(doc, "a[href]", :href)
      replace_attribute_value_ids(doc, "form[action]", :action)
      [
        "anchor",
        "aria-controls",
        "aria-labelledby",
        "data-test-selector",
        "for",
        "popovertarget"
      ].each do |attr|
        replace_attribute_value_ids(doc, "[#{attr}]", :"#{attr}")
      end
      doc.to_html
    end

    private

    def replace_attribute_values(doc, selector, attr)
      doc.css(selector).each do |node|
        node[attr] = "{{#{attr}}}"
      end
    end

    def replace_attribute_value_ids(doc, selector, attr)
      doc.css(selector).each do |node|
        node[attr] = node[attr].gsub(/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|\d+)/, "{{id}}")
      end
    end
  end

  # shared_let_work_packages(<<~TABLE)
  #   hierarchy    | MTWTFSS    | scheduling mode | predecessors
  #   predecessor1 | XXX        | manual          |
  #   predecessor2 | XX         | manual          |
  #   predecessor3 | XX         | manual          |
  #   predecessor4 |            | manual          |
  #   work_package |          X | automatic       | predecessor1 with lag 2, predecessor2 with lag 7, predecessor3 with lag 7, predecessor4 with lag 10
  # TABLE

  def render_component(**params)
    render_inline(described_class.new(work_package:, **params))
  end

  context "with follows relations" do
    it "renders the component" do
      expect(render_component).to match_snapshot("component", snapshot_serializer: HtmlSnapshotSerializer)
    end

    # it "renders a title link" do
    #  expect(render_component(relation: _table.relation(predecessor: predecessor1), visibility: :visible))
    #    .to have_link("predecessor1")
    # end
  end
end
