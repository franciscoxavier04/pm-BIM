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

module EnterpriseEdition
  # A banner indicating that a given feature requires the enterprise edition of OpenProject.
  # This component uses conventional names for translation keys or URL look-ups based on the feature_key passed in.
  # It will only be rendered if necessary.
  class BannerComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    # @param feature_key [Symbol, NilClass] The key of the feature to show the banner for.
    # @param title [String] The title of the banner.
    # @param description [String] The description of the banner.
    # @param href [String] The URL to link to.
    # @param skip_render [Boolean] Whether to skip rendering the banner.
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(feature_key,
                   title: nil,
                   description: nil,
                   link_title: nil,
                   href: nil,
                   skip_render: EnterpriseToken.hide_banners?,
                   **system_arguments)
      @system_arguments = system_arguments
      @system_arguments[:test_selector] = "op-enterprise-banner-#{feature_key.to_s.tr('_', '-')}"
      super

      @feature_key = feature_key
      @title = title
      @description = description
      @link_title = link_title
      @href = href
      @skip_render = skip_render
    end

    private

    attr_reader :skip_render,
                :feature_key

    def title
      @title || I18n.t("ee.upsale.#{feature_key}.title", default: default_title)
    end

    def default_title
      I18n.t("ee.upsale.plan_title", plan:)
    end

    def description
      @description || begin
        if I18n.exists?(:"ee.upsale.#{feature_key}.description_html")
          I18n.t("ee.upsale.#{feature_key}.description_html").html_safe
        else
          I18n.t("ee.upsale.#{feature_key}.description")
        end
      end
    rescue I18n::MissingTranslationData => e
      raise e.exception(
        <<~TEXT.squish
          The expected '#{I18n.locale}.ee.upsale.#{feature_key}.description' nor '#{I18n.locale}.ee.upsale.#{feature_key}.description_html' key does not exist.
          Ideally, provide it in the locale file.
          If that isn't applicable, a description parameter needs to be provided.
        TEXT
      )
    end

    def plan_text
      plan_name = render(Primer::Beta::Text.new(font_weight: :bold, classes: "upsale-colored")) { I18n.t("ee.upsale.plan_name", plan:) }
      I18n.t("ee.upsale.plan_text_html", plan_name:).html_safe
    end

    def features
      return @features if defined?(@features)

      @features = I18n.t("ee.upsale.#{feature_key}.features", default: nil)&.values
    end

    def buttons
      [
        free_trial_button,
        upgrade_now_button,
        more_info_button
      ].compact
    end

    def free_trial_button
      return if EnterpriseToken.active?
      helpers.angular_component_tag("opce-free-trial-button")
    end

    # Allow providing a custom upgrade now button
    def upgrade_now_button
      nil
    end

    def more_info_button
      render(Primer::Beta::Link.new(href:)) do |link|
        link.with_trailing_visual_icon(icon: "link-external")
        link_title
      end
    end

    def plan
      @plan ||= OpenProject::Token.lowest_plan_for(feature_key)&.capitalize
    end

    def link_title
      @link_title || I18n.t("ee.upsale.#{feature_key}.link_title", default: I18n.t("ee.upsale.link_title"))
    end

    def href
      href_value = @href || OpenProject::Static::Links.links.dig(:enterprise_docs, feature_key, :href)

      unless href_value
        raise "Neither a custom href is provided nor is a value set " \
              "in OpenProject::Static::Links.enterprise_docs[#{feature_key}][:href]"
      end

      href_value
    end

    def render?
      !skip_render
    end
  end
end
