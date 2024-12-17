# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

RSpec.describe Queries::Projects::Filters::AnyStageOrGateFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :any_stage_or_gate }
    let(:type) { :date }
    let(:model) { Project }
    let(:attribute) { :created_at }
    let(:values) { ["3"] }

    describe "human_name" do
      it "is 'Any stage or gate'" do
        expect(instance.human_name)
          .to eql I18n.t("project.filters.any_stage_or_gate")
      end
    end

    describe "default_operator" do
      it "is 'on'" do
        expect(instance.default_operator)
          .to eql Queries::Operators::OnDate
      end
    end

    describe "#available?" do
      let(:project) { build_stubbed(:project) }
      let(:user) { build_stubbed(:user) }

      current_user { user }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(*permissions, project:)
        end
      end

      context "for a user with the necessary permission and the feature flag on", with_flag: { stages_and_gates: true } do
        let(:permissions) { %i[view_project_stages_and_gates] }

        it "is true" do
          expect(instance)
            .to be_available
        end
      end

      context "for a user with the necessary permission and the feature flag off", with_flag: { stages_and_gates: false } do
        let(:permissions) { %i[view_project_stages_and_gates] }

        it "is false" do
          expect(instance)
            .not_to be_available
        end
      end

      context "for a user without the necessary permission", with_flag: { stages_and_gates: true } do
        let(:permissions) { %i[view_project] }

        it "is false" do
          expect(instance)
            .not_to be_available
        end
      end
    end
  end
end
