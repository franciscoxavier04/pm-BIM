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

module WorkPackages
  module ActivitiesTab
    module Journals
      class ItemComponent::CommentView < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable
        include WorkPackages::ActivitiesTab::SharedHelpers
        include WorkPackages::ActivitiesTab::StimulusControllers

        def initialize(comment:, has_unread_notifications:, filter:, state: :show)
          super

          @comment = comment
          @has_unread_notifications = has_unread_notifications
          @filter = filter
          @state = state
        end

        private

        attr_reader :comment, :has_unread_notifications, :state, :filter

        def wrapper_uniq_by = comment.id
        def has_unread_notifications? = @has_unread_notifications

        def wrapper_data_attributes
          {
            controller: "work-packages--activities-tab--anchor",
            "work-packages--activities-tab--anchor-activity-url-value": activity_url(comment)
          }
        end

        def grouped_emoji_reactions
          EmojiReactions::GroupedQueries.grouped_emoji_reactions_by_reactable(
            reactable_id: [comment.id],
            reactable_type: "Comment"
          )[comment.id]
        end

        def container_classes
          [].tap do |classes|
            if comment.internal?
              classes << "work-packages-activities-tab-journals-item-component--container__internal-comment"
            end
          end
        end

        def comment_header_classes
          [].tap do |classes|
            if comment.internal?
              classes << "work-packages-activities-tab-journals-item-component--header__internal-comment"
            end
          end
        end

        def comment_body_classes
          ["work-packages-activities-tab-journals-item-component--journal-notes-body"].tap do |classes|
            if comment.internal?
              classes << "work-packages-activities-tab-journals-item-component--journal-notes-body__internal-comment"
            end
          end
        end

        # def allowed_to_edit?
        #   journal.editable_by?(User.current)
        # end

        # def allowed_to_quote?
        #   User.current.allowed_in_project?(:add_work_package_comments, journal.journable.project)
        # end

        def copy_url_action_item(menu)
          menu.with_item(label: t("button_copy_link_to_clipboard"),
                         tag: :button,
                         content_arguments: {
                           data: {
                             action: "click->work-packages--activities-tab--anchor#copyActivityUrlToClipboard"
                           }
                         }) do |item|
            item.with_leading_visual_icon(icon: :copy)
          end
        end

        # def edit_action_item(menu)
        #   menu.with_item(label: edit_action_label,
        #                  href: edit_work_package_activity_path(journal.journable, journal, filter:),
        #                  content_arguments: {
        #                    data: { turbo_stream: true, test_selector: "op-wp-journal-#{journal.id}-edit" }
        #                  }) do |item|
        #     item.with_leading_visual_icon(icon: :pencil)
        #   end
        # end

        # def edit_action_label
        #   if journal.user == User.current
        #     t("js.label_edit_comment")
        #   else
        #     t("js.label_moderate_comment")
        #   end
        # end

        # def quote_action_item(menu)
        #   menu.with_item(label: t("js.label_quote_comment"),
        #                  tag: :button,
        #                  content_arguments: {
        #                    data: quote_action_data_attributes
        #                  }) do |item|
        #     item.with_leading_visual_icon(icon: :quote)
        #   end
        # end

        # def quote_action_data_attributes
        #   {
        #     test_selector: "op-wp-journal-#{journal.id}-quote",
        #     controller: quote_comments_stimulus_controller,
        #     action: "click->#{quote_comments_stimulus_controller}#quote:prevent",
        #     quote_comments_stimulus_controller("-content-param") => journal.notes,
        #     quote_comments_stimulus_controller("-user-id-param") => journal.user_id,
        #     quote_comments_stimulus_controller("-user-name-param") => journal.user.name,
        #     quote_comments_stimulus_controller("-is-internal-param") => journal.internal?,
        #     quote_comments_stimulus_controller("-text-wrote-param") => I18n.t(:text_wrote),
        #     quote_comments_stimulus_controller("-#{internal_comment_stimulus_controller}-outlet") => add_comment_component_dom_selector, # rubocop:disable Layout/LineLength
        #     quote_comments_stimulus_controller("-#{editor_stimulus_controller}-outlet") => index_component_dom_selector
        #   }
        # end
      end
    end
  end
end
