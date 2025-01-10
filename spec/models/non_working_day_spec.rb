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

RSpec.describe NonWorkingDay do
  subject { build(:non_working_day) }

  describe "validations" do
    it "is valid when all attributes are present" do
      expect(subject).to be_valid
    end

    it "is invalid without name" do
      subject.name = nil
      expect(subject).to be_invalid
      expect(subject.errors[:name]).to be_present
    end

    it "is invalid without date" do
      subject.date = nil
      expect(subject).to be_invalid
      expect(subject.errors[:date]).to be_present
    end

    it "is invalid with an already existing date" do
      existing = create(:non_working_day)
      subject.date = existing.date
      expect(subject).to be_invalid
      expect(subject.errors[:date]).to be_present
    end
  end
end
