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

RSpec.describe WorkPackageActivity do
  shared_let(:project) { create(:project) }
  shared_let(:repository) { create(:repository_git, project:) }
  shared_let(:user) { create(:user) }
  shared_let(:work_package) { create(:work_package, project:, author: user) }

  let(:work_package_journals) { create_work_package_journals(work_package, user) }
  let(:work_package_changesets) { create_work_package_changesets(work_package, repository) }
  let(:work_package_comments) { create_list(:comment, 3, commented: work_package) }

  subject(:work_package_activities) { work_package.activities }

  describe "associations" do
    subject { work_package_activities.first }

    it { is_expected.to belong_to(:work_package) }
    it { is_expected.to belong_to(:user) }
  end

  it { expect(work_package_activities.first).to be_readonly }

  describe "enums" do
    it "defines compatible kinds" do
      expect(described_class.kinds)
        .to eq({ "Journal" => "Journal", "Comment" => "Comment", "Revision" => "Revision" })
    end
  end

  describe "notes" do
    it "aliases notes to comments for compatibility" do
      activity = described_class.new(comments: "Test comment")
      expect(activity.notes).to eq("Test comment")
    end
  end

  context "when work package has activities" do
    before do
      work_package_journals
      work_package_changesets
      work_package_comments
    end

    it "returns activities for the work package" do
      expected_count = work_package_journals.count + work_package_changesets.count + work_package_comments.count
      expect(work_package_activities.count).to eq(expected_count + 1) # +1 for the initial version
      expect(work_package_activities.pluck(:work_package_id)).to all(eq(work_package.id))

      expect(work_package_activities.pluck(:kind).uniq).to match_array(described_class.compatible_kinds)
    end
  end

  describe "#initial?" do
    it "returns true for the initial version" do
      first_activity_journal = work_package_activities.where(kind: "Journal").first
      expect(first_activity_journal).to be_initial.and be_a_journal
      expect(first_activity_journal.version).to eq(1)
    end
  end

  def create_work_package_journals(work_package, user)
    [
      create(:work_package_journal, user:, notes: "Test comment 1", journable: work_package, version: 2),
      create(:work_package_journal, user:, notes: "", journable: work_package, version: 3),
      create(:work_package_journal, user:, notes: nil, journable: work_package, version: 4)
    ]
  end

  def create_work_package_changesets(work_package, repository)
    work_package.changesets << [
      create(:changeset, repository:, comments: "Test comment 1", committed_on: 1.day.ago),
      create(:changeset, repository:, comments: "", committed_on: 2.days.ago),
      create(:changeset, repository:, comments: nil, committed_on: 3.days.ago)
    ]
  end
end
