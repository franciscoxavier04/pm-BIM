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

RSpec.describe WorkPackage::PDFExport::Common::Badge do
  let(:badge) { Class.new { extend WorkPackage::PDFExport::Common::Badge } }

  describe "#readable_color" do
    it "returns white for dark colors: black" do
      expect(badge.readable_color("000000")).to eq("FFFFFF")
    end

    it "returns white for dark colors: dark blue" do
      expect(badge.readable_color("1864AB")).to eq("FFFFFF")
    end

    it "returns white for dark colors: blue-6" do
      expect(badge.readable_color("228BE6")).to eq("000000")
    end

    it "returns black for light colors: orange-2" do
      expect(badge.readable_color("FFD8A8")).to eq("000000")
    end

    it "returns black for light colors: cyan-0" do
      expect(badge.readable_color("E3FAFC")).to eq("000000")
    end

    it "returns black for light colors: white" do
      expect(badge.readable_color("FFFFFF")).to eq("000000")
    end
  end
end
