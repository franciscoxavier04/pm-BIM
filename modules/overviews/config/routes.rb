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
  constraints(project_id: Regexp.new("(?!(#{Project::RESERVED_IDENTIFIERS.join('|')})$)(\\w|-)+"), format: :html) do
    get "projects/:project_id",
        to: "overviews/overviews#show",
        as: :project_overview
    get "projects/:project_id/project_custom_fields_sidebar", to: "overviews/overviews#project_custom_fields_sidebar",
                                                              as: :project_custom_fields_sidebar
    get "projects/:project_id/project_custom_field_section_dialog/:section_id", to: "overviews/overviews#project_custom_field_section_dialog",
                                                                                as: :project_custom_field_section_dialog
    put "projects/:project_id/update_project_custom_values/:section_id", to: "overviews/overviews#update_project_custom_values",
                                                                         as: :update_project_custom_values

    get "projects/:project_id/project_life_cycle_sidebar",
        to: "overviews/overviews#project_life_cycle_sidebar", as: :project_life_cycle_sidebar
  end

  resources :project_phases, controller: "overviews/project_phases", only: %i[edit update] do
    member do
      put :preview
    end
  end
end
