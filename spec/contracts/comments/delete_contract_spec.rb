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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Comments::DeleteContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(comment, current_user) }
  let(:current_user) { build_stubbed(:admin) }
  let(:comment) { build_stubbed(:comment, author: current_user) }

  describe "admin user" do
    context "with News" do
      it_behaves_like "contract is valid for active admins and invalid for regular users" do
        let(:comment) { build_stubbed(:comment, :commented_news, author: current_user) }
      end
    end

    context "with WorkPackage" do
      it_behaves_like "contract is valid for active admins and invalid for regular users" do
        let(:comment) { build_stubbed(:comment, :commented_work_package, author: current_user) }
      end
    end
  end

  describe "non-admin user" do
    let(:current_user) { build_stubbed(:user) }

    context "when the comment is a news comment" do
      let(:comment) { build_stubbed(:comment, :commented_news, author: current_user) }

      context "and the user is not allowed to manage the news" do
        it_behaves_like "contract user is unauthorized"
      end

      context "and the user is allowed to manage the news" do
        before do
          mock_permissions_for(current_user) do |mock|
            mock.allow_in_project(:manage_news, project: comment.commented.project)
          end
        end

        it_behaves_like "contract is valid"
      end
    end

    context "when the comment is a work package comment" do
      let(:comment) { build_stubbed(:comment, :commented_work_package, author: current_user) }

      context "and the user is not allowed to manage the work package" do
        it_behaves_like "contract user is unauthorized"
      end

      context "and the user is allowed to manage the work package" do
        before do
          mock_permissions_for(current_user) do |mock|
            mock.allow_in_project(:edit_work_package_comments, project: comment.commented.project)
          end
        end

        it_behaves_like "contract is valid"
      end
    end
  end

  include_examples "contract reuses the model errors"
end
