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
    delegate :portfolio, to: :table

    def more_menu_items
      @more_menu_items ||= [more_menu_subproject_item,
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
                            more_menu_delete_item].compact
    end

    def portfolio_proposals
      PortfolioProposal.where(state: :draft)
    end

    def may_add_project_to_proposal?(project_ids, proposal)
      # We do not suggest proposals that already contain this project:
      !proposal.project_ids.intersect?(project_ids)
    end

    def find_all_child_project_ids(program)
      program.children.map do |child|
        if child.children.any?
          find_all_child_project_ids(child)
        elsif child.project?
          # We only want to return project IDs, not program IDs
          child.id
        end
      end.flatten.compact.uniq
    end

    def more_menu_add_to_proposal
      # We only allow adding programs and projects to proposals, not portfolios
      return if project.portfolio?

      project_ids_to_add = project.program? ? find_all_child_project_ids(project) : [project.id]

      proposal_entries = portfolio_proposals.filter_map do |proposal|
        if may_add_project_to_proposal?(project_ids_to_add, proposal)
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
          href: new_project_portfolio_management_proposal_path(portfolio, add_projects: project_ids_to_add),
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
  end
end
