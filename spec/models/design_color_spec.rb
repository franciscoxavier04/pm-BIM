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

RSpec.describe DesignColor do
  let(:default_primary) { OpenProject::CustomStyles::Design.variables["primary-button-color"] }
  let(:primary_color) { create(:"design_color_primary-button-color") }

  describe "#setables" do
    it "returns an Array of instances" do
      expect(described_class.setables).to be_a(Array)
      expect(described_class.setables.first).to be_a(described_class)
    end

    it "not overwritten defaults do not have a color set" do
      expect(described_class.setables.first.hexcode).to be_nil
    end

    it "instances overwrite defaults" do
      primary_color
      expect(described_class.setables.first.hexcode).to eq("#3493B3")
      expect(described_class.setables.second.hexcode).to be_nil
    end
  end

  describe "#get_hexcode" do
    it "returns hexcode if present" do
      primary_color
      expect(primary_color.hexcode).to eq("#3493B3")
    end

    it "returns nil hexcode if hexcode not present" do
      expect(described_class.new(variable: "primary-button-color").hexcode)
        .to be_nil
    end
  end

  describe "validations" do
    context "a color_variable already exists" do
      let(:design_color) do
        DesignColor.new variable: "foo", hexcode: "#AB1234"
      end

      before do
        design_color.save
      end

      it "fails validation for another design_color with same name" do
        second_color_variable = DesignColor.new variable: "foo", hexcode: "#888888"
        expect(second_color_variable.valid?).to be_falsey
      end
    end

    context "the hexcode's validation" do
      it "fails validations" do
        expect(DesignColor.new(variable: "foo", hexcode: "1").valid?).to be_falsey
        expect(DesignColor.new(variable: "foo", hexcode: "#1").valid?).to be_falsey
        expect(DesignColor.new(variable: "foo", hexcode: "#1111111").valid?).to be_falsey
        expect(DesignColor.new(variable: "foo", hexcode: "#HHHHHH").valid?).to be_falsey
      end

      it "passes validations" do
        expect(DesignColor.new(variable: "foo", hexcode: "111111").valid?).to be_truthy
        expect(DesignColor.new(variable: "foo", hexcode: "#111111").valid?).to be_truthy
        expect(DesignColor.new(variable: "foo", hexcode: "#ABC123").valid?).to be_truthy
        expect(DesignColor.new(variable: "foo", hexcode: "#111").valid?).to be_truthy
        expect(DesignColor.new(variable: "foo", hexcode: "111").valid?).to be_truthy
      end
    end
  end

  describe "#create" do
    context "no CustomStyle.current exists yet" do
      subject { DesignColor.new variable: "foo", hexcode: "#111111" }

      it "creates a CustomStyle.current" do
        expect(CustomStyle.current).to be_nil
        subject.save
        expect(CustomStyle.current).to be_present
      end
    end
  end
end
