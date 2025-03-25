# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Queries::Principals::Filters::RestrictedMentionableOnWorkPackageFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :restricted_mentionable_on_work_package }
    let(:type) { :list_optional }
    let(:human_name) { "restricted mentionable" }

    shared_let(:project) { create(:project) }
    shared_let(:work_package) { create(:work_package, project:) }
    shared_let(:other_work_package) { create(:work_package, project:) }

    shared_let(:user_without_restricted_comments_view_permissions) { create_user_without_restricted_comments_view_permissions }
    shared_let(:user_with_restricted_comments_view_permissions) { create_user_with_restricted_comments_view_permissions }
    shared_let(:user_with_restricted_comments_view_and_write_permissions) do
      create_user_with_restricted_comments_view_and_write_permissions
    end

    let(:user) { user_with_restricted_comments_view_permissions }

    before { allow(User).to receive(:current).and_return(user) }

    describe "#validate" do
      it "is valid with a single work package id" do
        instance.values = [work_package.id.to_s]
        expect(instance).to be_valid
      end

      it "is invalid with multiple work package ids" do
        instance.values = [work_package.id.to_s, other_work_package.id.to_s]
        expect(instance).not_to be_valid
        expect(instance.errors.messages).to eq(values: ["must be a single work package"])
      end

      it "is invalid with no work package id" do
        instance.values = []
        expect(instance).not_to be_valid
        expect(instance.errors.messages).to eq(values: ["can't be blank.", "filter has invalid values."])
      end
    end

    describe "#scope" do
      subject { instance.apply_to(Principal.visible(user)) }

      let(:values) { [work_package.id.to_s] }

      let(:instance) do
        described_class.create!.tap do |filter|
          filter.values = values
          filter.operator = operator
        end
      end

      context "with an = operator" do
        let(:operator) { "=" }

        it "returns all mentionable principals on the work package and its project" do
          expect(subject)
            .to contain_exactly(user_with_restricted_comments_view_permissions,
                                user_with_restricted_comments_view_and_write_permissions)
        end
      end

      context "with a ! operator" do
        let(:operator) { "!" }

        it "returns all non-mentionable users on the work package and its project" do
          expect(subject)
            .to contain_exactly(user_without_restricted_comments_view_permissions)
        end
      end
    end

    def create_user_without_restricted_comments_view_permissions
      viewer_role = create(:project_role, permissions: %i[view_work_packages])
      create(:user,
             firstname: "A",
             lastname: "Viewer",
             member_with_roles: { project => viewer_role })
    end

    def create_user_with_restricted_comments_view_permissions
      viewer_role = create(:project_role, permissions: %i[view_work_packages view_comments_with_restricted_visibility])
      create(:user,
             firstname: "Restricted",
             lastname: "Viewer",
             member_with_roles: { project => viewer_role })
    end

    def create_user_with_restricted_comments_view_and_write_permissions
      viewer_role_with_commenting_permission = create(:project_role,
                                                      permissions: %i[view_work_packages add_work_package_notes
                                                                      edit_own_work_package_notes
                                                                      view_comments_with_restricted_visibility
                                                                      add_comments_with_restricted_visibility
                                                                      edit_own_comments_with_restricted_visibility])
      create(:user,
             firstname: "Restricted",
             lastname: "ViewerCommenter",
             member_with_roles: { project => viewer_role_with_commenting_permission })
    end
  end
end
