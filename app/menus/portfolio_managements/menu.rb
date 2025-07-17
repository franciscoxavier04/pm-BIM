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

module PortfolioManagements
  class Menu < Submenu
    include Rails.application.routes.url_helpers

    attr_reader :controller_path, :params, :current_user

    def initialize(project:, params:, controller_path:, current_user:)
      @params = params
      @controller_path = controller_path
      @current_user = current_user

      super(view_type:, project:, params:)
    end

    def menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil, children: main_static_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:'portfolio_proposals.states.proposed'), children: portfolio_proposals(:proposed)),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:'portfolio_proposals.states.draft'), children: portfolio_proposals(:draft))
      ]
    end

    def selected?(query_params)
      case controller_path
      when "portfolio_managements"
        case params[:proposal_id]
        when /\A\d+\z/
          query_params[:proposal_id].to_s == params[:proposal_id]
        end
      when "portfolio_managements/proposals"
        query_params[:controller] == "portfolio_managements/proposals"
      end
    end

    def favored?(query_params)
      query_params[:query_id].in?(favored_ids)
    end

    def query_path(query_params)
      project_portfolio_management_path(query_params.merge(project_id: project.id))
    end

    private

    def main_static_filters
      static_filters [
        ProjectQueries::Static::CURRENT_PORTFOLIO
      ].compact
    end

    def static_filters(ids)
      ids.map do |id|
        menu_item(title: ::ProjectQueries::Static.query(id).name, query_params: { query_id: id })
      end
    end

    def portfolio_proposals(state_name)
      PortfolioProposal
        .where(portfolio: project)
        .where(state: PortfolioProposal.states[state_name])
        .map do |proposal|
        menu_item(title: proposal.name,
                  query_params: { proposal_id: proposal.id,
                                  filters: JSON.dump([{ portfolio_proposal: { operator: "=", values: [proposal.id.to_s] } }]) })
      end
    end

    def persisted_filters
      @persisted_filters ||= ::ProjectQuery
                               .visible(current_user)
                               .with_favored_by_user(current_user)
                               .order(favored: :desc, name: :asc)
    end

    def favored_ids
      @favored_ids ||= persisted_filters.select(&:favored).to_set(&:id)
    end

    def modification_params?
      params.values_at(:filters, :columns, :sortBy).any?
    end
  end
end
