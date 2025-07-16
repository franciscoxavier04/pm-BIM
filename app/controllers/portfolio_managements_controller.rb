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

class PortfolioManagementsController < ApplicationController
  include Layout
  include OpTurbo::ComponentStream

  before_action :find_project_by_project_id

  before_action :set_query_id_if_nil
  before_action :load_query_or_deny_access
  before_action :authorize

  include SortHelper
  include PaginationHelper
  include QueriesHelper
  include ProjectsHelper
  include Queries::Loading

  menu_item :portfolio

  def show # rubocop:disable Metrics/AbcSize
    respond_to do |format|
      format.html do
        flash.now[:error] = @query.errors.full_messages if @query.errors.any?

        render locals: { query: @query, state: :show, menu_name: :project_menu }
      end

      format.turbo_stream do
        replace_via_turbo_stream(
          component: PortfolioManagements::IndexPageHeaderComponent.new(project: @project, query: @query, current_user:,
                                                                        state: :show, params:)
        )
        update_via_turbo_stream(
          component: Filter::FilterButtonComponent.new(query: @query, disable_buttons: false)
        )
        replace_via_turbo_stream(component: PortfolioManagements::TableComponent.new(query: @query, current_user:, params:))

        current_url = url_for(params.permit(:controller, :action, :query_id, :filters, :columns, :sortBy, :page, :per_page))
        turbo_streams << turbo_stream.push_state(current_url)
        turbo_streams << turbo_stream.turbo_frame_set_src(
          "portfolio_management_sidemenu",
          project_portfolio_management_menu_url(query_id: @query.id,
                                                project_id: @project.id,
                                                controller_path: "portfolio_management")
        )

        turbo_streams << turbo_stream.replace("flash-messages", helpers.render_flash_messages)

        render turbo_stream: turbo_streams
      end
    end
  end

  private

  def load_query_or_deny_access
    super
    if @query && params[:query_id] == ProjectQueries::Static::CURRENT_PORTFOLIO
      @query.where(:ancestor_or_self, "=", [@project.id])
      @query.clear_changes_information
    end
  end

  def set_query_id_if_nil
    params[:query_id] = ProjectQueries::Static::CURRENT_PORTFOLIO
  end

  def query_class
    ProjectQuery
  end
end
