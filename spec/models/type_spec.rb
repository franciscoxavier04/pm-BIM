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

RSpec.describe Type do
  describe "builtin types" do
    let(:builtin_type) { create(:type, name: "Risk", builtin: "risk") }
    let(:regular_type) { create(:type, name: "Task", builtin: nil) }

    describe "#builtin?" do
      it "returns true for builtin types" do
        expect(builtin_type.builtin?).to be true
      end

      it "returns false for regular types" do
        expect(regular_type.builtin?).to be false
      end
    end

    describe "#name" do
      it "returns translated name for builtin types" do
        allow(I18n).to receive(:t).with("types.builtin.risk").and_return("Risk")
        expect(builtin_type.name).to eq("Risk")
      end

      it "returns stored name for regular types" do
        expect(regular_type.name).to eq("Task")
      end
    end

    describe "#deletable?" do
      it "returns false for builtin types" do
        expect(builtin_type.deletable?).to be false
      end

      it "returns false for standard types" do
        standard_type = create(:type, is_standard: true)
        expect(standard_type.deletable?).to be false
      end

      it "returns false for types with work packages" do
        type_with_wp = create(:type)
        create(:work_package, type: type_with_wp)
        expect(type_with_wp.deletable?).to be false
      end

      it "returns true for regular types without work packages" do
        expect(regular_type.deletable?).to be true
      end
    end

    describe "validation" do
      it "allows builtin types without explicit name" do
        type = build(:type, name: "", builtin: "risk")
        expect(type).to be_valid
      end

      it "requires name for regular types" do
        type = build(:type, name: nil, builtin: nil)
        expect(type).not_to be_valid
        expect(type.errors[:name]).to include("can't be blank.")
      end

      it "validates name presence for regular types only" do
        regular_type = build(:type, name: "", builtin: nil)
        expect(regular_type).not_to be_valid
        expect(regular_type.errors[:name]).to include("can't be blank.")
      end

      it "validates uniqueness of builtin values" do
        create(:type, builtin: "risk")
        duplicate_type = build(:type, builtin: "risk")
        expect(duplicate_type).not_to be_valid
        expect(duplicate_type.errors[:builtin]).to include("has already been taken.")
      end
    end

    describe "scopes" do
      before do
        builtin_type
        regular_type
      end

      describe ".builtin" do
        it "returns only builtin types" do
          expect(described_class.builtin).to include(builtin_type)
          expect(described_class.builtin).not_to include(regular_type)
        end
      end

      describe ".not_builtin" do
        it "returns only non-builtin types" do
          expect(described_class.not_builtin).to include(regular_type)
          expect(described_class.not_builtin).not_to include(builtin_type)
        end
      end
    end

    describe "destruction" do
      it "prevents destruction of builtin types" do
        builtin_type.save!
        expect { builtin_type.destroy }.not_to change(described_class, :count)
      end

      it "prevents destruction via check_integrity callback" do
        builtin_type = create(:type, builtin: "risk")
        expect { builtin_type.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end

      it "allows soft validation via deletable?" do
        builtin_type = create(:type, builtin: "risk")
        expect(builtin_type.deletable?).to be false
      end

      it "allows destruction of regular types" do
        regular_type.save!
        expect { regular_type.destroy }.to change(described_class, :count).by(-1)
      end
    end
  end
end
