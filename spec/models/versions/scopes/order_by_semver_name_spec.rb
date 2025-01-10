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

RSpec.describe Versions::Scopes::OrderBySemverName do
  let(:project) { create(:project) }
  let(:names) do
    [
      "1. xxxx",
      "1.1. aaa",
      "1.1. zzz",
      "1.2. mmm",
      "1.10. aaa",
      "9",
      "10.2",
      "10.10.2",
      "10.10.10",
      "aaaaa",
      "aaaaa 1."
    ]
  end
  let!(:versions) { names.map { |name| create(:version, name:, project:) } }

  subject { Version.order_by_semver_name.order(id: :desc).to_a }

  it "returns the versions in semver order" do
    expect(subject)
      .to eql versions
  end
end
