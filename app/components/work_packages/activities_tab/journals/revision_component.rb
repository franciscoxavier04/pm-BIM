require 'sanitize'

module WorkPackages
  module ActivitiesTab
    module Journals
      class RevisionComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(changeset:, filter:)
          super

          @changeset = changeset
          @filter = filter
        end

        private

        attr_reader :changeset, :filter

        def render?
          filter != :only_comments
        end

        def user_name
          if changeset.user
            changeset.user.name
          else
            # Extract name from committer string (format: "name <email>")
            changeset.committer.split("<").first.strip
          end
        end

        def revision_url
          repository = changeset.repository
          project = repository.project

          show_revision_project_repository_path(project_id: project.id, rev: changeset.revision)
        end

        def short_revision
          changeset.revision[0..7]
        end

        def copy_url_action_item(menu)
          menu.with_item(label: t("button_copy_link_to_clipboard"),
                         tag: :button,
                         content_arguments: {
                           data: {
                             action: "click->work-packages--activities-tab--item#copyActivityUrlToClipboard"
                           }
                         }) do |item|
            item.with_leading_visual_icon(icon: :copy)
          end
        end

        def render_user_name
          if changeset.user
            render_user_link(changeset.user)
          else
            render_committer_name(changeset.committer)
          end
        end

        def render_user_link(user)
          render(Primer::Beta::Link.new(
                   href: user_url(user),
                   target: "_blank",
                   scheme: :primary,
                   underline: false,
                   font_weight: :bold
                 )) do
            changeset.user.name
          end
        end

        def render_committer_name(committer)
          render(Primer::Beta::Text.new(font_weight: :bold, mr: 1)) do
            Sanitize.fragment(committer.gsub(%r{<.+@.+>}, "").strip)
          end
        end
      end
    end
  end
end
