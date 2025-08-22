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

Rails.application.routes.draw do
  scope "projects/:project_id", as: "project" do
    resources :gantt, controller: "gantt/gantt", only: [:index] do
      collection do
        # The menu route has to be above the state routes! Otherwise, the menu will be interpreted as another state
        get "menu" => "gantt/menus#show"
        get "/export_dialog" => "work_packages#export_dialog"

        # states managed by client-side routing on work_package#index
        get "(/*state)" => "gantt/gantt#index", as: ""
        get "/create_new" => "gantt/gantt#index", as: "new_split"
      end
    end
  end

  resources :gantt, controller: "gantt/gantt", only: [:index] do
    collection do
      get "/export_dialog" => "work_packages#export_dialog"

      # states managed by client-side routing on work_package#index
      get "details/*state" => "gantt/gantt#index", as: :details

      # states managed by client-side (angular) routing on work_package#show
      get "/" => "gantt/gantt#index", as: "index"
    end
  end

  namespace :gantt do
    resource :menu, only: %[show]
  end
end
