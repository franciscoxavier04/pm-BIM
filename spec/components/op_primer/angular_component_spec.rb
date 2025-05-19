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

RSpec.describe OpPrimer::AngularComponent, type: :component do
  let(:data) { { "test-selector": "foo" } }

  subject do
    render_inline(described_class.new(tag: "op-test", classes: "op-classname", inputs:, data:))
  end

  describe "inputs transformations" do
    let(:inputs) do
      {
        key: "value",
        number: 1,
        anArray: [1, 2, 3],
        someRandomObject: { complex: true, foo: "bar" }
      }
    end

    let(:expected) do
      <<~HTML.squish
        <op-test
          class="op-classname op-angular-component"
          data-key='"value"'
          data-number="1"
          data-an-array="[1,2,3]"
          data-some-random-object='{"complex":true,"foo":"bar"}'
          data-test-selector="foo"
          data-view-component="true"
          ></op-test>
      HTML
    end

    it "converts the inputs" do
      expect(subject).to be_dom_eql(expected)
    end
  end
end
