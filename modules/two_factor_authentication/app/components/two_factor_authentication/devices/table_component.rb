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
    class TableComponent < ::TableComponent
      options :admin_table
      columns :device_type, :default, :confirmed

      def initial_sort
        %i[login asc]
      end

      def self_table?
        !admin_table
      end

      def admin_table?
        admin_table
      end

      def target_controller
        if self_table?
          "two_factor_authentication/my/two_factor_devices"
        else
          "two_factor_authentication/users/two_factor_devices"
        end
      end

      def sortable?
        false
      end

      delegate :enforced?, to: :strategy_manager

      def strategy_manager
        ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
      end

      def empty_row_message
        if admin_table?
          I18n.t "two_factor_authentication.admin.no_devices_for_user"
        else
          I18n.t "two_factor_authentication.devices.not_existing"
        end
      end

      def headers
        [
          ["device_type", { caption: I18n.t("two_factor_authentication.label_device_type") }],
          ["default", { caption: I18n.t(:label_default) }],
          ["confirmed", { caption: I18n.t(:label_confirmed) }]
        ]
      end
    end
  end
end
