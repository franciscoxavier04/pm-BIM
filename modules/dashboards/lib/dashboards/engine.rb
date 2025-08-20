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

# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require "open_project/plugins"

module Dashboards
  class Engine < ::Rails::Engine
    engine_name :dashboards

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "dashboards.menu" do
      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:dashboards,
                  { controller: "/dashboards/dashboards", action: "show" },
                  caption: :"dashboards.label",
                  after: :work_packages,
                  icon: "meter",
                  badge: "label_menu_badge.alpha")
      end
    end

    initializer "dashboards.permissions" do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.map do |ac_map|
          ac_map.project_module(:dashboards) do |pm_map|
            pm_map.permission(:view_dashboards,
                              { "dashboards/dashboards": %i[show] },
                              permissible_on: :project)
            pm_map.permission(:manage_dashboards,
                              { "dashboards/dashboards": %i[show] },
                              permissible_on: :project)
          end
        end
      end
    end

    initializer "dashboards.conversion" do
      require Rails.root.join("config/constants/ar_to_api_conversions")

      Constants::ARToAPIConversions.add("grids/dashboard": "grid")
    end

    config.to_prepare do
      Dashboards::GridRegistration.register!
    end
  end
end
