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

RSpec.describe Comments::CreateContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(comment, current_user) }
  let(:user) { build_stubbed(:admin) }
  let(:comment) { build_stubbed(:comment, author: user) }
  let(:current_user) { user }

  before do
    User.current = current_user
    allow(User).to receive(:exists?).with(current_user.id).and_return(true)
  end

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
    let(:user) { build_stubbed(:user) }

    context "with News and commenting permissions" do
      let(:comment) { build_stubbed(:comment, :commented_news, author: user) }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:comment_news, project: comment.commented.project)
        end
      end

      it_behaves_like "contract is valid"
    end

    context "with WorkPackage and commenting permissions" do
      let(:comment) { build_stubbed(:comment, :commented_work_package, author: user) }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_work_package(:add_work_package_comments, work_package: comment.commented)
        end
      end

      it_behaves_like "contract is valid"

      context "when internal comment", with_ee: %i[internal_comments] do
        let(:project) { build_stubbed(:project, enabled_internal_comments: true) }
        let(:work_package) { build_stubbed(:work_package, project:) }
        let(:comment) { build_stubbed(:comment, :internal, author: user, commented: work_package) }

        context "and internal comment permissions" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_in_project(:add_internal_comments, project:)
            end
          end

          it_behaves_like "contract is valid"
        end

        context "without internal comment permissions" do
          it_behaves_like "contract is invalid", base: :error_unauthorized
        end
      end
    end
  end

  describe "validate author" do
    context "when the current user is different from the comment's author" do
      let(:different_user) { build_stubbed(:user) }

      before do
        allow(User).to receive(:exists?).with(different_user.id).and_return(true)
        comment.author = different_user
      end

      it_behaves_like "contract is invalid", author: :invalid
    end
  end

  describe "validate commented object" do
    context "when commented is blank" do
      before { comment.commented = nil }

      it_behaves_like "contract is invalid", commented: :blank
    end

    context "when commented is a work package" do
      let(:work_package) { build_stubbed(:work_package) }

      before { comment.commented = work_package }

      it_behaves_like "contract is valid"
    end
  end
end
