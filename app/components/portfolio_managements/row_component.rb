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

# Fix issue which did not allow using dividers within submenus:
class Primer::Alpha::ActionMenu::SubMenuItem
  delegate :with_divider, to: :@sub_menu
end

module PortfolioManagements
  class RowComponent < Projects::RowComponent
    delegate :portfolio, :proposal, to: :table

    def rank
      PortfolioProposalProject.find_by(project:, portfolio_proposal: proposal).try(:rank) || "N/A"
    end

    def more_menu_items
      @more_menu_items ||= [move_action_item(:higher, t(:label_increase_rank), "chevron-up"),
                            move_action_item(:lower, t(:label_decrease_rank), "chevron-down"),
                            (:divider if sorted_by_lft? && params[:proposal_id]),
                            more_menu_subproject_item,
                            more_menu_settings_item,
                            more_menu_activity_item,
                            more_menu_favorite_item,
                            more_menu_unfavorite_item,
                            *more_menu_add_to_proposal,
                            :divider,
                            more_menu_archive_item,
                            more_menu_unarchive_item,
                            more_menu_copy_item,
                            :divider,
                            more_menu_delete_item,
                            more_menu_remove_from_proposal].compact
    end

    def move_action_item(move_to, label, icon)
      return unless sorted_by_lft? || sorted_by_manual?
      return unless params[:proposal_id]

      column = sorted_by_lft? ? "lft" : "manual_sorting"
      href = move_project_path(
        project,
        move_to:,
        sortBy: JSON.dump([[column, "asc"]]),
        proposal_id: params[:proposal_id],
        **helpers.projects_query_params.slice(*helpers.projects_query_param_names_for_sort)
      )

      {
        scheme: :default,
        label:,
        icon:,
        href:,
        form_arguments: { method: :put, data: { "turbo-stream": true } }
      }
    end

    def portfolio_proposals
      PortfolioProposal.where(state: :draft)
    end

    def project_ids_for_proposal_without_duplicates(possible_project_ids, proposal)
      proposal_projects = proposal.projects.pluck(:id)

      possible_project_ids.select do |pid|
        proposal_projects.exclude?(pid)
      end
    end

    def find_all_child_project_ids(program)
      ([program.id] + program.children.map do |child|
        if child.children.any?
          find_all_child_project_ids(child)
        elsif child.project?
          # We only want to return project IDs, not program IDs
          child.id
        end
      end).flatten.compact.uniq
    end

    def project_ids_including_children
      @project_ids_including_children ||= project.program? ? find_all_child_project_ids(project) : [project.id]
    end

    def more_menu_add_to_proposal
      # We only allow adding programs and projects to proposals, not portfolios
      return if project.portfolio?

      proposal_entries = portfolio_proposals.filter_map do |proposal|
        project_ids_to_add = project_ids_for_proposal_without_duplicates(project_ids_including_children, proposal)

        if project_ids_to_add.any?
          project_count = proposal.projects.count
          description = if project_count == 0
                          I18n.t("portfolio_proposals.no_elements")
                        else
                          I18n.t("portfolio_proposals.contains_elements", count: project_count)
                        end

          ids_in_proposal = proposal.projects.pluck(:id) + project_ids_to_add
          inputs = ids_in_proposal.map do |pid|
            {
              name: "portfolio_proposal[project_ids][]",
              value: pid
            }
          end

          inputs << { name: "via_context_menu", value: true }

          {
            scheme: :default,
            icon: nil,
            href: project_portfolio_management_proposal_path(portfolio, proposal),
            form_arguments: {
              inputs:,
              method: :patch
            },
            data: { turbo: false },
            description:,
            label: proposal.name,
            aria: { label: proposal.name }
          }
        end
      end

      submenu_entries = [
        {
          scheme: :default,
          icon: "plus",
          "data-show-dialog-id": "proposal-creation-dialog-#{project.id}",
          label: I18n.t(:button_create_new_portfolio_proposal),
          aria: { label: I18n.t(:button_create_new_portfolio_proposal) }
        }
      ]

      if proposal_entries.any?
        submenu_entries += [:divider, *proposal_entries]
      end

      [
        :divider,
        {
          scheme: :default,
          icon: "briefcase",
          submenu_entries:,
          label: I18n.t(:button_add_to_proposal),
          aria: { label: I18n.t(:button_add_to_proposal) }
        }
      ]
    end

    def more_menu_delete_item
      # Overview screen:
      if User.current.admin && proposal.blank?
        {
          scheme: :danger,
          icon: :trash,
          label: I18n.t(:button_delete),
          href: confirm_destroy_project_path(project),
          data: { turbo: false }
        }
      end
    end

    def more_menu_remove_from_proposal
      if proposal.present? && proposal.draft? && (project.project? || project.program?)
        {
          scheme: :danger,
          icon: :"no-entry",
          label: I18n.t(:button_remove_from_proposal),
          href: remove_project_project_portfolio_management_proposal_path(portfolio, proposal, remove: project.id),
          form_arguments: {
            method: :delete
          },
          data: { turbo: false }
        }
      end
    end
  end
end
