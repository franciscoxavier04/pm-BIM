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

RSpec.describe Dashboards::GridRegistration do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:grid) { build_stubbed(:dashboard, project:) }

  describe "from_scope" do
    context "with a relative URL root", with_config: { rails_relative_url_root: "/foobar" } do
      subject { described_class.from_scope "/foobar/projects/an_id/dashboards" }

      it "returns the class" do
        expect(subject[:class]).to eq(Grids::Dashboard)
      end

      it "returns the project_id" do
        expect(subject[:project_id]).to eq("an_id")
      end

      context "with a different route" do
        subject { described_class.from_scope "/barfoo/projects/an_id/dashboards" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end
    end

    context "without a relative URL root" do
      subject { described_class.from_scope "/projects/an_id/dashboards" }

      it "returns the class" do
        expect(subject[:class]).to eq(Grids::Dashboard)
      end

      it "returns the project_id" do
        expect(subject[:project_id]).to eq("an_id")
      end

      context "with a different route" do
        subject { described_class.from_scope "/projects/an_id/boards" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe "defaults" do
    it "returns the initialized widget" do
      expect(described_class.defaults[:widgets].map(&:identifier))
        .to contain_exactly("work_packages_table")
    end
  end

  describe "writable?" do
    let(:permissions) { [:manage_dashboards] }
    let(:allowed) { true }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project *permissions, project:
      end
    end

    context "if the user has the :manage_dashboards permission" do
      it "is truthy" do
        expect(described_class)
          .to be_writable(grid, user)
      end
    end

    context "if the user lacks the :manage_dashboards permission" do
      let(:permissions) { [] }

      it "is falsey" do
        expect(described_class)
          .not_to be_writable(grid, user)
      end
    end
  end
end
