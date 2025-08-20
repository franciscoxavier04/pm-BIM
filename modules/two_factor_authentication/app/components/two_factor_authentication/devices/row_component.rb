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

module ::TwoFactorAuthentication
  module Devices
    class RowComponent < ::RowComponent
      def device
        model
      end

      def row_css_class
        is_default = "blocked" if device.default

        ["mobile-otp--two-factor-device-row", is_default].compact.join(" ")
      end

      def device_type
        device.identifier
      end

      def default
        if device.default
          helpers.op_icon "icon-yes"
        else
          "-"
        end
      end

      def confirmed
        if device.active
          helpers.op_icon "icon-yes"
        elsif table.self_table?
          link_to t("two_factor_authentication.devices.confirm_now"),
                  { controller: table.target_controller, action: :confirm, device_id: device.id }

        else
          helpers.op_icon "icon-no"
        end
      end

      ###

      def button_links
        links = [delete_link]
        links << make_default_link unless device.default

        links
      end

      def make_default_link
        helpers.password_confirmation_form_for(
          device,
          url: { controller: table.target_controller, action: :make_default, device_id: device.id },
          method: :post,
          html: { id: "two_factor_make_default_form", class: "form--inline" }
        ) do |f|
          f.submit I18n.t(:button_make_default),
                   class: "button--link two-factor--mark-default-button"
        end
      end

      def delete_link
        title =
          if deletion_blocked?
            I18n.t("two_factor_authentication.devices.is_default_cannot_delete")
          else
            I18n.t(:button_delete)
          end

        helpers.password_confirmation_form_for(
          device,
          url: { controller: table.target_controller, action: :destroy, device_id: device.id },
          method: :delete,
          html: { id: "two_factor_delete_form", class: "" }
        ) do |f|
          f.submit I18n.t(:button_delete),
                   class: "button--link two-factor--delete-button",
                   disabled: deletion_blocked?,
                   title:
        end
      end

      def deletion_blocked?
        return false if table.admin_table?

        device.default && table.enforced?
      end

      def column_css_class(_column)
        if device.default
          "mobile-otp--device-default"
        end
      end
    end
  end
end
