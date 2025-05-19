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
  class UpsellButtonsComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    # @param feature_key [Symbol, NilClass] The key of the feature to show the banner for.
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(feature_key, **system_arguments)
      super

      @system_arguments = system_arguments
      @system_arguments[:align_items] ||= :center
      @feature_key = feature_key
    end

    def call
      flex_layout(**@system_arguments) do |flex|
        buttons.each_with_index do |button, i|
          flex.with_column(ml: (i == 0 ? 0 : 2)) do
            button
          end
        end
      end
    end

    private

    attr_reader :feature_key

    def buttons
      [
        free_trial_button,
        upgrade_now_button,
        more_info_button
      ].compact
    end

    def free_trial_button
      return if EnterpriseToken.active?
      return unless User.current.admin?

      angular_component(
        "opce-free-trial-button",
        inputs: helpers.enterprise_angular_trial_inputs
      )
    end

    # Allow providing a custom upgrade now button
    def upgrade_now_button
      nil
    end

    def more_info_button
      render(Primer::Beta::Link.new(href: enterprise_link)) do |link|
        link.with_trailing_visual_icon(icon: "link-external")
        link_title
      end
    end

    def link_title
      I18n.t("ee.upsell.#{feature_key}.link_title", default: I18n.t(:label_more_information))
    end

    def enterprise_link
      href_value = OpenProject::Static::Links.links.dig(:enterprise_features, feature_key, :href)
      default_value = OpenProject::Static::Links.links.dig(:enterprise_features, :default, :href)

      href_value || default_value
    end
  end
end
