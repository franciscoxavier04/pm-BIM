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
require "rack/test"

RSpec.describe API::V3::EmojiReactions::EmojiReactionsByActivityCommentAPI do
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project, enabled_internal_comments: true) }
  let(:work_package) { create(:work_package, project:) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:admin) { create(:admin) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) do
    %i(view_work_packages add_work_package_comments view_internal_comments)
  end
  let(:activity) { create(:work_package_journal, journable: work_package, user: admin, version: 2) }
  let!(:emoji_reaction) { create(:emoji_reaction, reactable: activity, user: current_user) }

  before do
    allow(User).to receive(:current).and_return(current_user)
  end

  describe "GET /api/v3/activities/:id/emoji_reactions" do
    context "when user has permission to view work package" do
      before do
        get api_v3_paths.emoji_reactions_by_activity_comment(activity.id)
      end

      it "succeeds" do
        expect(last_response).to have_http_status :ok
      end

      it "returns the emoji reactions" do
        expect(last_response.body)
          .to be_json_eql(1.to_json)
          .at_path("total")

        expect(last_response.body)
          .to be_json_eql(1.to_json)
          .at_path("count")

        expect(last_response.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(last_response.body)
          .to be_json_eql("#{activity.id}-#{emoji_reaction.reaction}".to_json)
          .at_path("_embedded/elements/0/id")

        expect(last_response.body)
          .to be_json_eql(emoji_reaction.emoji.to_json)
          .at_path("_embedded/elements/0/emoji")
      end
    end

    context "when user does not have permission to view work package" do
      let(:current_user) { create(:user) }

      before do
        get api_v3_paths.emoji_reactions_by_activity_comment(activity.id)
      end

      it "fails with HTTP Not Found" do
        expect(last_response).to have_http_status :not_found
      end
    end

    context "when the activity is internal" do
      let(:internal_comment) do
        work_package.add_journal(user: current_user, notes: "Internal comment", internal: true)
        work_package.save(validate: false)
        work_package.journals.last
      end
      let!(:internal_emoji_reaction) { create(:emoji_reaction, reactable: internal_comment, user: current_user) }

      context "and user has permission to view internal comments" do
        before do
          get api_v3_paths.emoji_reactions_by_activity_comment(internal_comment.id)
        end

        it "succeeds" do
          expect(last_response).to have_http_status :ok
        end

        it "returns the emoji reactions" do
          expect(last_response.body)
            .to be_json_eql(1.to_json)
            .at_path("total")

          expect(last_response.body)
            .to be_json_eql(internal_emoji_reaction.emoji.to_json)
            .at_path("_embedded/elements/0/emoji")

          expect(last_response.body)
            .to be_json_eql(internal_emoji_reaction.reaction.to_json)
            .at_path("_embedded/elements/0/reaction")
        end
      end

      context "and user does not have permission to view internal comments" do
        before do
          role.role_permissions
            .find_by(permission: "view_internal_comments")
            .destroy
          get api_v3_paths.emoji_reactions_by_activity_comment(internal_comment.id)
        end

        it "fails with HTTP Not Found" do
          expect(last_response).to have_http_status :not_found
        end
      end
    end
  end

  describe "PATCH /api/v3/activities/:id/emoji_reactions" do
    let(:path) { api_v3_paths.emoji_reactions_by_activity_comment(activity.id) }
    let(:headers) { { "CONTENT_TYPE" => "application/json" } }
    let(:reaction) { "heart" }

    def make_request
      patch path, { reaction: }.to_json, headers
    end

    def destroy_all_reactions
      EmojiReaction.destroy_all
    end

    shared_examples "a successful reaction" do
      before do
        destroy_all_reactions
        make_request
      end

      it_behaves_like "API V3 collection response", 1, 1, "EmojiReaction" do
        let(:emoji_reaction) do
          build_stubbed(:emoji_reaction, reactable: activity, user: current_user, reaction:)
        end

        before do
          allow(emoji_reaction).to receive(:id).and_return("#{activity.id}-#{reaction}")
        end

        let(:elements) { [emoji_reaction] }

        it "creates the reaction" do
          expect(last_response.body)
            .to be_json_eql(EmojiReaction.emoji(reaction).to_json)
            .at_path("_embedded/elements/0/emoji")

          expect(last_response.body)
            .to be_json_eql([{ "href" => "/api/v3/users/#{current_user.id}", "title" => current_user.name }].to_json)
            .at_path("_embedded/elements/0/_links/reactingUsers")
        end
      end
    end

    context "when user has permission to add work package comments" do
      let(:permissions) { %i(view_work_packages add_work_package_comments) }

      context "when adding a new reaction" do
        let(:reaction) { "rocket" }

        it_behaves_like "a successful reaction"
      end

      context "when removing an existing reaction" do
        let(:reaction) { emoji_reaction.reaction }

        before { make_request }

        it_behaves_like "API V3 collection response", 0, 0, "EmojiReaction" do
          let(:elements) { [] }

          it "succeeds" do
            expect(last_response.body)
              .to be_json_eql([].to_json)
              .at_path("_embedded/elements")
          end
        end
      end

      context "with an invalid reaction" do
        let(:reaction) { "invalid_reaction" }

        it "fails with HTTP Bad Request" do
          make_request

          expect(last_response).to have_http_status :bad_request

          expect(last_response.body)
            .to include_json("Bad request: reaction does not have a valid value".to_json)
            .at_path("message")
        end
      end

      context "when the reaction is not provided" do
        it "false with HTTP Bad Request" do
          patch path, {}.to_json, headers

          expect(last_response).to have_http_status :bad_request

          expect(last_response.body)
            .to include_json("Bad request: reaction is missing, reaction does not have a valid value".to_json)
            .at_path("message")
        end
      end
    end

    context "when user does not have permission to add work package notes" do
      let(:permissions) { %i(view_work_packages) }

      it "fails with HTTP Forbidden" do
        make_request

        expect(last_response).to have_http_status :forbidden

        expect(last_response.body)
          .to be_json_eql("You are not authorized to access this resource.".to_json)
          .at_path("message")
      end
    end

    context "when the activity is internal" do
      let(:internal_comment) do
        work_package.add_journal(user: current_user, notes: "Internal comment", internal: true)
        work_package.save(validate: false)
        work_package.journals.last
      end
      let(:path) { api_v3_paths.emoji_reactions_by_activity_comment(internal_comment.id) }
      let(:reaction) { "thumbs_up" }

      context "and user has permission to create internal comments" do
        let(:reaction) { "rocket" }
        let(:permissions) { %i(view_work_packages add_work_package_comments view_internal_comments add_internal_comments) }

        it_behaves_like "a successful reaction" do
          let(:activity) { internal_comment }
        end
      end

      context "and user does not have permission to create internal comments" do
        let(:permissions) { %i(view_work_packages view_internal_comments) }

        it "fails with HTTP Forbidden" do
          make_request
          expect(last_response).to have_http_status :forbidden
        end
      end
    end

    it_behaves_like "handling anonymous user"
  end
end
