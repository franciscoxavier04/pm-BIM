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
    include PlanForFeature

    # @param feature_key [Symbol, NilClass] The key of the feature to show the banner for.
    # @param dismissable [boolean] Allow this banner to be dismissed.
    # @param dismiss_key [String] Provide a string to identify this banner when being dismissed. Defaults to feature_key
    # @param skip_render [Boolean] Whether to skip rendering the banner.
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(feature_key,
                   dismissable: false,
                   dismiss_key: feature_key,
                   skip_render: EnterpriseToken.hide_banners?,
                   **system_arguments)
      @system_arguments = system_arguments
      @system_arguments[:tag] = :div
      @system_arguments[:mb] ||= 2
      @system_arguments[:id] = "op-enterprise-banner-#{feature_key.to_s.tr('_', '-')}"
      @system_arguments[:test_selector] = @system_arguments[:id]
      super

      @feature_key = feature_key
      @skip_render = skip_render
      @dismissable = dismissable
      @dismiss_key = dismiss_key
    end

    private

    attr_reader :skip_render,
                :feature_key

    def render?
      !(skip_render || dismissed?)
    end

    def dismissed?
      return false unless @dismissable

      User.current.pref.dismissed_banner?(@dismiss_key)
    end
  end
end
