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

module ::Gantt
  class GanttController < ApplicationController
    include Layout
    include QueriesHelper
    include WorkPackagesControllerHelper

    accept_key_auth :index

    before_action :load_and_authorize_in_optional_project, :protect_from_unauthorized_export, only: :index

    before_action :load_and_validate_query, only: :index, unless: -> { request.format.html? }

    menu_item :gantt
    def index
      # If there are no query_props given, redirect to the default query
      if params[:query_props].nil? && params[:query_id].nil?
        if @project.present?
          return redirect_to(
            project_gantt_index_path(
              @project,
              ::Gantt::DefaultQueryGeneratorService.new(with_project: @project).call
            )
          )
        else
          return redirect_to(
            gantt_index_path(Gantt::DefaultQueryGeneratorService.new(with_project: nil).call)
          )
        end
      end

      respond_to do |format|
        format.html do
          render :index,
                 locals: { query: @query, project: @project, menu_name: project_or_global_menu },
                 layout: "angular/angular"
        end

        format.any(*supported_list_formats) do
          export_list(request.format.symbol)
        end

        format.atom do
          atom_list
        end
      end
    end
  end
end
