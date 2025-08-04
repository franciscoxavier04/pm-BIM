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

require "open_project/plugins"

module OpenProject
  module Risks
    class Engine < ::Rails::Engine
      engine_name :openproject_risks

      include OpenProject::Plugins::ActsAsOpEngine

      register "openproject-risks", author_url: "https://www.openproject.org", bundled: true do
        project_module :risks do
          permission :view_risks,
                     {},
                     permissible_on: :project
          permission :edit_risks,
                     {},
                     permissible_on: :project
          permission :manage_risks,
                     {},
                     permissible_on: :project
        end

        # Menu extensions
        menu :project_menu,
             :risks,
             { controller: "/risks/risks", action: "index" },
             if: ->(project) {
               OpenProject::FeatureDecisions.risk_management_active? &&
                 project.module_enabled?("risks") &&
                 User.current.allowed_in_project?(:view_work_packages, project)
             },
             after: :work_packages,
             caption: :label_risks,
             icon: :alert
      end

      initializer "risks.permissions" do
        Rails.application.reloader.to_prepare do
          OpenProject::AccessControl.map do |ac_map|
            ac_map.project_module(
              :risks,
              if: ->(*) { OpenProject::FeatureDecisions.risk_management_active? }
            )
          end

          OpenProject::AccessControl
            .permission(:view_work_packages)
            .controller_actions << "risks/risks/index"
        end
      end

      config.to_prepare do
        # Register risk filters and selects
        ::Queries::Register.register(::Query) do
          filter ::Queries::WorkPackages::Filter::RiskImpactFilter
          filter ::Queries::WorkPackages::Filter::RiskLikelihoodFilter
          filter ::Queries::WorkPackages::Filter::RiskLevelFilter
          select ::Queries::WorkPackages::Selects::RiskPropertySelect
        end
      end

      extend_api_response(:v3, :work_packages, :schema, :work_package_schema) do
        schema :risk_impact,
               type: "Integer",
               show_if: ->(*) { represented.risk? && represented&.project&.module_enabled?(:risks) }

        schema :risk_likelihood,
               type: "Integer",
               show_if: ->(*) { represented.risk? && represented&.project&.module_enabled?(:risks) }

        schema :risk_level,
               type: "Integer",
               show_if: ->(*) { represented.risk? && represented&.project&.module_enabled?(:risks) }
      end

      # Add risk attributes to work package representer
      extend_api_response(:v3, :work_packages, :work_package) do
        property :risk_impact,
                 render_nil: false,
                 if: ->(*) { risk? }

        property :risk_likelihood,
                 render_nil: true,
                 if: ->(*) { risk? }

        property :risk_level,
                 render_nil: true,
                 if: ->(*) { risk? }
      end
    end
  end
end
