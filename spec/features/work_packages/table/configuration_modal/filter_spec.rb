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

RSpec.describe "Work Package table configuration modal filters spec", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let!(:wp_1) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }
  let(:filters) { Components::WorkPackages::TableConfiguration::Filters.new }

  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = ["subject", "done_ratio"]

    query.save!
    query
  end

  before do
    login_as(user)
  end

  context "by version in project" do
    let(:version) { create(:version, project:) }
    let(:work_package_with_version) { create(:work_package, project:, version:) }
    let(:work_package_without_version) { create(:work_package, project:) }

    before do
      work_package_with_version
      work_package_without_version

      wp_table.visit!
    end

    it "allows filtering, saving, retrieving and altering the saved filter" do
      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version
      filters.open

      filters.expect_filter_count 2
      filters.add_filter_by("Version", "is (OR)", version.name)
      filters.save

      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version

      wp_table.save_as("Some query name")

      filters.open
      filters.expect_filter_count 3
      filters.remove_filter "version"
      filters.save

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version

      last_query = Query.last

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version
    end
  end
end
