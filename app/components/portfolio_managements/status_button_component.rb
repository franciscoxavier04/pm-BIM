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
  class StatusButtonComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(proposal:, size: :medium)
      super

      @proposal = proposal
      @project = proposal.portfolio
      @size = size
    end

    def call
      render(
        OpPrimer::StatusButtonComponent.new(
          current_status: current_status,
          items: [draft_status, proposed_status],
          button_arguments: {
            title: t("label_meeting_state"),
            size: @size
          },
          menu_arguments: { size: :small }
        )
      )
    end

    private

    def current_status
      case @proposal.state
      when "draft"
        draft_status
      when "proposed"
        proposed_status
      end
    end

    def draft_status
      OpPrimer::StatusButtonOption.new(name: t("portfolio_proposals.states.draft"),
                                       color_ref: Meetings::Statuses::OPEN.id,
                                       color_namespace: :meeting_status,
                                       icon: :"issue-opened",
                                       tag: :a,
                                       href: href("draft"),
                                       content_arguments: {
                                         data: data_attributes(href("draft"))
                                       })
    end

    def proposed_status
      OpPrimer::StatusButtonOption.new(name: t("portfolio_proposals.states.proposed"),
                                       color_ref: Meetings::Statuses::CLOSED.id,
                                       color_namespace: :meeting_status,
                                       icon: :play,
                                       tag: :a,
                                       href: href("proposed"),
                                       content_arguments: {
                                         data: data_attributes(href("proposed"))
                                       })
    end

    def closed_status
      OpPrimer::StatusButtonOption.new(name: t("label_meeting_state_closed"),
                                       color_ref: Meetings::Statuses::CLOSED.id,
                                       color_namespace: :meeting_status,
                                       icon: :"issue-closed",
                                       tag: :a,
                                       href: href("closed"),
                                       description: t("text_meeting_closed_dropdown_description"),
                                       content_arguments: {
                                         data: data_attributes(href("closed"))
                                       })
    end

    def href(state)
      change_state_project_portfolio_management_proposal_path(project_id: @project.id, id: @proposal.id, state:)
    end

    def data_attributes(href)
      {
        href: href,
        method: :patch
      }
    end
  end
end
