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
  class RowComponent < Projects::RowComponent
    def more_menu_items
      @more_menu_items ||= [more_menu_subproject_item,
                            more_menu_settings_item,
                            more_menu_activity_item,
                            more_menu_favorite_item,
                            more_menu_unfavorite_item,
                            :divider,
                            more_menu_add_to_proposal,
                            :divider,
                            more_menu_archive_item,
                            more_menu_unarchive_item,
                            more_menu_copy_item,
                            :divider,
                            more_menu_delete_item].compact
    end

    def more_menu_add_to_proposal
      return unless params[:controller] == "portfolio_managements"

      {
        scheme: :default,
        icon: "briefcase",
        href: "#",
        label: I18n.t(:button_add_to_proposal),
        aria: { label: I18n.t(:button_add_to_proposal) }
      }
    end
  end
end
