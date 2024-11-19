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

RSpec.shared_examples_for "a LifeCycle event" do
  it "inherits from LifeCycle" do
    expect(described_class).to be < LifeCycle
  end

  describe "associations" do
    it { is_expected.to have_many(:project_life_cycles).dependent(:destroy) }
    it { is_expected.to have_many(:projects).through(:project_life_cycles) }
    it { is_expected.to belong_to(:color).required }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "is invalid if type is not Stage or Gate" do
      life_cycle = described_class.new
      life_cycle.type = "InvalidType"
      expect(life_cycle).not_to be_valid
      expect(life_cycle.errors[:type]).to include("must be either Stage or Gate")
    end
  end
end
