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

RSpec.describe Ldap::ImportUsersFromListService do
  include_context "with temporary LDAP"

  subject do
    described_class.new(ldap_auth_source, user_list).call
  end

  let(:user_list) do
    %w[aa729 bb459 cc414]
  end

  it "adds all three users" do
    subject

    user_aa729 = User.find_by(login: "aa729")
    expect(user_aa729).to be_present
    expect(user_aa729.firstname).to eq "Alexandra"
    expect(user_aa729.lastname).to eq "Adams"

    user_bb459 = User.find_by(login: "bb459")
    expect(user_bb459).to be_present
    expect(user_bb459.firstname).to eq "Belle"
    expect(user_bb459.lastname).to eq "Baldwin"

    user_cc414 = User.find_by(login: "cc414")
    expect(user_cc414).to be_present
    expect(user_cc414.firstname).to eq "Claire"
    expect(user_cc414.lastname).to eq "Carpenter"
  end

  context "when two users already exist" do
    let!(:user_aa729) { create(:user, login: "aa729", firstname: "Foobar", ldap_auth_source:) }
    let!(:user_bb459) { create(:user, login: "bb459", firstname: "Bla", ldap_auth_source:) }

    it "adds the third one, but does not update the other two" do
      subject

      user_aa729.reload
      user_bb459.reload

      expect(user_aa729.firstname).to eq "Foobar"
      expect(user_aa729.lastname).to eq "Bobbit"
      expect(user_bb459.firstname).to eq "Bla"
      expect(user_bb459.lastname).to eq "Bobbit"

      user_cc414 = User.find_by(login: "cc414")
      expect(user_cc414).to be_present
      expect(user_cc414.firstname).to eq "Claire"
      expect(user_cc414.lastname).to eq "Carpenter"
    end
  end
end
