# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "Work package comments with restricted visibility",
               :js,
               with_flag: { comments_with_restricted_visibility: true } do
  include RestrictedVisibilityCommentsHelpers

  shared_let(:project) { create(:project, enabled_comments_with_restricted_visibility: true) }
  shared_let(:admin) { create(:admin) }
  shared_let(:viewer) { create_user_with_restricted_comments_view_permissions }
  shared_let(:viewer_with_commenting_permission) { create_user_with_restricted_comments_view_and_write_permissions }
  shared_let(:project_admin) { create_user_as_project_admin }

  shared_let(:work_package) { create(:work_package, project:, author: admin) }
  shared_let(:first_comment) do
    create(:work_package_journal, user: admin, notes: "A (restricted) comment by admin",
                                  journable: work_package, version: 2, restricted: true)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  context "with an admin user" do
    current_user { admin }

    context "when the feature is enabled for the project" do
      before do
        wp_page.visit!
        wp_page.wait_for_activity_tab
      end

      it "allows adding a comment with restricted visibility" do
        activity_tab.expect_input_field

        activity_tab.add_comment(text: "First (restricted) comment by admin", restricted: true)

        activity_tab.expect_journal_notes(text: "First (restricted) comment by admin")
      end
    end

    context "when the feature is not enabled for the project" do
      before do
        project.enabled_comments_with_restricted_visibility = false
        project.save!

        wp_page.visit!
        wp_page.wait_for_activity_tab
      end

      it "allows adding a comment with restricted visibility" do
        activity_tab.expect_input_field

        activity_tab.type_comment("This comment cannot be restricted")

        expect(page).not_to have_test_selector("op-work-package-journal-restricted-comment-checkbox")
      end
    end
  end

  context "with a user that is only allowed to view comments with restricted visibility" do
    current_user { viewer }

    before do
      first_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "does show restricted comments but does NOT enable editing or quoting comments" do
      activity_tab.expect_journal_notes(text: "A (restricted) comment by admin")

      activity_tab.within_journal_entry(first_comment) do
        page.find_test_selector("op-wp-journal-#{first_comment.id}-action-menu").click

        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-edit")
        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-quote")
      end
    end
  end

  context "with a user that is allowed to view, create and edit own comments" do
    current_user { viewer_with_commenting_permission }

    before do
      first_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "allows adding a comment with restricted visibility" do
      activity_tab.expect_input_field

      activity_tab.add_comment(text: "First (restricted) comment by member", restricted: true)

      activity_tab.expect_journal_notes(text: "First (restricted) comment by member")

      created_comment = work_package.journals.reload.last

      activity_tab.within_journal_entry(created_comment) do
        page.find_test_selector("op-wp-journal-#{created_comment.id}-action-menu").click
        page.find_test_selector("op-wp-journal-#{created_comment.id}-edit").click

        page.within_test_selector("op-work-package-journal-form-element") do
          expect(page).not_to have_test_selector("op-work-package-journal-restricted-comment-checkbox")
          activity_tab.get_editor_form_field_element.set_value("Edited comment by member")
          page.find_test_selector("op-submit-work-package-journal-form").click
        end

        wait_for { page }.to have_test_selector("op-journal-notes-body", text: "Edited comment by member")
      end
    end

    it "does show restricted comments but does NOT enable editing other users comments" do
      activity_tab.expect_journal_notes(text: "A (restricted) comment by admin")

      activity_tab.within_journal_entry(first_comment) do
        page.find_test_selector("op-wp-journal-#{first_comment.id}-action-menu").click

        # not allowed to edit other user's restricted comments
        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-edit")
        # allowed to quote other user's comments
        expect(page).to have_test_selector("op-wp-journal-#{first_comment.id}-quote")
      end
    end
  end

  context "with a user that is allowed to view, create and edit all comments" do
    current_user { project_admin }

    let(:unrestricted_comment) do
      create(:work_package_journal,
             user: project_admin, notes: "An unrestricted comment by member",
             journable: work_package, version: (work_package.journals.reload.last.version + 1), restricted: false)
    end

    before do
      first_comment
      unrestricted_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "allows editing and quoting restricted comments" do
      activity_tab.expect_journal_notes(text: "A (restricted) comment by admin")

      activity_tab.edit_comment(first_comment, text: "A (restricted) comment by admin - EDITED")

      activity_tab.within_journal_entry(first_comment) do
        activity_tab.expect_journal_notes(text: "A (restricted) comment by admin - EDITED")
      end

      activity_tab.quote_comment(first_comment)
      page.within_test_selector("op-work-package-journal-form-element") do
        expect(page).to have_checked_field("Restrict visibility")
      end

      activity_tab.quote_comment(unrestricted_comment)
      page.within_test_selector("op-work-package-journal-form-element") do
        expect(page).to have_checked_field("Restrict visibility")
      end
    end
  end

  describe "mentioning users in comments" do
    current_user { project_admin }

    shared_let(:user_without_restricted_comments_view_permissions) do
      create_user_without_restricted_comments_view_permissions
    end

    shared_let(:group) { create(:group, firstname: "A", lastname: "Group") }
    shared_let(:group_member) do
      group_role = create(:project_role)
      create(:member,
             principal: group,
             project:,
             roles: [group_role])
    end

    before do
      wp_page.visit!
      wait_for_reload
      expect_angular_frontend_initialized
      wp_page.wait_for_activity_tab
    end

    context "with restricted comments initially enabled" do
      it "restricts mentions to project members with view comments with restricted visibility permission" do
        activity_tab.open_new_comment_editor
        expect(page).to have_test_selector("op-work-package-journal-form-element")

        activity_tab.check_restricted_visibility_comment_checkbox
        activity_tab.refocus_editor
        activity_tab.type_comment("@")

        expect(page.all(".mention-list-item").map(&:text))
          .to contain_exactly("Project Admin", "Restricted Viewer", "Restricted ViewerCommenter")
      end
    end

    context "with restricted comments initially disabled" do
      it "allows mentioning project members but they are sanitized when the checkbox is checked" do
        activity_tab.type_comment("@")

        expect(page.all(".mention-list-item").map(&:text))
          .to contain_exactly("A Viewer", "Group", "Project Admin", "Restricted Viewer", "Restricted ViewerCommenter")

        page.find(".mention-list-item", text: "A Viewer").click
        activity_tab.type_comment("@Restricted")
        page.first(".mention-list-item", text: "Restricted Viewer").click
        activity_tab.type_comment("@Group")
        page.find(".mention-list-item", text: "Group").click

        activity_tab.check_restricted_visibility_comment_checkbox

        page.within_test_selector("op-work-package-journal-form-element") do
          expect(page.all("a.mention").map(&:text))
            .to contain_exactly("@Restricted Viewer")

          expect(page).to have_text("@A Viewer") & have_text("@Group")
        end
      end
    end

    context "when editing a restricted comment" do
      it "honors mentionable principals" do
        activity_tab.within_journal_entry(first_comment) do
          page.find_test_selector("op-wp-journal-#{first_comment.id}-action-menu").click
          page.find_test_selector("op-wp-journal-#{first_comment.id}-edit").click

          activity_tab.type_comment(" @")
        end

        expect(page.all(".mention-list-item").map(&:text))
            .to contain_exactly("Project Admin", "Restricted Viewer", "Restricted ViewerCommenter")
      end
    end

    context "with a server error" do
      before do
        allow(WorkPackages::ActivitiesTab::RestrictedMentionsSanitizer).to receive(:sanitize)
          .and_raise(RuntimeError, "Something went wrong!!!")
      end

      it "shows an error message" do
        activity_tab.type_comment("@Restricted")
        page.first(".mention-list-item", text: "Restricted Viewer").click

        activity_tab.check_restricted_visibility_comment_checkbox

        page.within_test_selector("op-primer-flash-message") do
          expect(page).to have_text("Something went wrong!!!")
        end
      end
    end
  end

  describe "making internal comments public" do
    context "when the user unchecks the 'internal comment' checkbox" do
      current_user { project_admin }

      before do
        wp_page.visit!
        wp_page.wait_for_activity_tab
      end

      it "asks for explicit confirmation from the user" do
        activity_tab.open_new_comment_editor

        aggregate_failures "empty comments do not ask for confirmation" do
          activity_tab.check_restricted_visibility_comment_checkbox
          activity_tab.uncheck_internal_comment_checkbox

          activity_tab.expect_internal_comment_unchecked
          expect(page).not_to have_test_selector("op-work-package-unrestrict-comment-confirmation-dialog")
        end

        activity_tab.check_restricted_visibility_comment_checkbox
        activity_tab.refocus_editor
        activity_tab.type_comment("This is an internal comment")

        aggregate_failures "non-empty comments ask for confirmation, cancel retains current state" do
          activity_tab.uncheck_internal_comment_checkbox
          activity_tab.expect_unrestrict_internal_comment_confirmation_dialog do
            click_on "Cancel"
          end
          activity_tab.expect_internal_comment_checked
        end

        aggregate_failures "non-empty comments ask for confirmation, confirm changes the state" do
          activity_tab.uncheck_internal_comment_checkbox

          activity_tab.expect_unrestrict_internal_comment_confirmation_dialog do
            click_on "Make public"
          end

          activity_tab.expect_internal_comment_unchecked
        end
      end
    end
  end
end
