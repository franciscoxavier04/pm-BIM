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

module OpPrimer
  # @logical_path OpenProject/Primer
  class EmailUpdatesModeSelectorComponentPreview < Lookbook::Preview
    # See the [component documentation](/lookbook/pages/components/email_updates_mode_selector) for more details.
    # @param toggle [Boolean]
    # @param path [String]
    # @param title [String]
    # @param enabled_description [String]
    # @param disabled_description [String]
    # @param alt_text [String]
    # @param show_button [Boolean]
    # @param method [Symbol] select [get, post, patch]
    def playground(
      toggle: true,
      path: "/projects/demo-project/meetings/113/toggle_notifications",
      title: "Sidebar component title",
      enabled_description: "Email updates are enabled for all users.",
      disabled_description: "Email updates are disabled for all users.",
      alt_text: "To change this, edit the series template.",
      show_button: true,
      method: :patch
    )
      render OpPrimer::EmailUpdatesModeSelectorComponent.new(
        toggle:,
        path:,
        title:,
        enabled_description:,
        disabled_description:,
        alt_text:,
        show_button:,
        method:
      )
    end

    def enabled(toggle: true, path: "", title: "Sidebar component title",
                enabled_description: "Email updates are enabled for all users.",
                disabled_description: "Email updates are disabled for all users.")
      render OpPrimer::EmailUpdatesModeSelectorComponent.new(
        toggle:,
        path:,
        title:,
        enabled_description:,
        disabled_description:
      )
    end

    def disabled(toggle: false, path: "", title: "Sidebar component title",
                 enabled_description: "Email updates are enabled for all users.",
                 disabled_description: "Email updates are disabled for all users.")
      render OpPrimer::EmailUpdatesModeSelectorComponent.new(
        toggle:,
        path:,
        title:,
        enabled_description:,
        disabled_description:
      )
    end

    def with_conditional_alt_text(toggle: true, path: "", title: "Sidebar component title",
                                  enabled_description: "Email updates are enabled for all users.",
                                  disabled_description: "Email updates are disabled for all users.",
                                  alt_text: "To change this, edit the series template.", show_button: false)
      render OpPrimer::EmailUpdatesModeSelectorComponent.new(
        toggle:,
        path:,
        title:,
        enabled_description:,
        disabled_description:,
        alt_text:,
        show_button:
      )
    end

    def with_different_button_method(toggle: true, path: "", title: "Sidebar component title",
                                     enabled_description: "Email updates are enabled for all users.",
                                     disabled_description: "Email updates are disabled for all users.", method: :patch)
      render OpPrimer::EmailUpdatesModeSelectorComponent.new(
        toggle:,
        path:,
        title:,
        enabled_description:,
        disabled_description:,
        method:
      )
    end
  end
end
