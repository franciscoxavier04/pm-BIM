# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require "open_project/plugins"

module Objectives
  class Engine < ::Rails::Engine
    engine_name :objectives

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "objectives.menu" do
      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:objectives,
                  { controller: "/objectives/objectives", action: "index" },
                  caption: :"objectives.label",
                  if: ->(project) {
                    project.module_enabled?("objectives") &&
                      User.current.allowed_in_project?(:view_work_packages, project)
                  },
                  after: :work_packages,
                  icon: :checklist)
      end
    end

    initializer "objectives.permissions" do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.map do |ac_map|
          ac_map.project_module(:objectives)
        end

        OpenProject::AccessControl
          .permission(:view_work_packages)
          .controller_actions << "objectives/objectives/index"
      end
    end
  end
end
