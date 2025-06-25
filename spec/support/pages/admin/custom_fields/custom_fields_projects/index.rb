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

require "support/pages/custom_fields/index_page"

module Pages
  module Admin
    module CustomFields
      module CustomFieldsProjects
        class Index < ::Pages::CustomFields::IndexPage
          def path
            "/admin/settings/project_custom_fields"
          end

          def click_to_create_new_custom_field(type)
            wait_for_network_idle

            click_button "Add"

            click_button "Project attribute"

            click_on type
          end

          def expect_having_create_item(type)
            wait_for_network_idle

            click_button "Add"

            click_button "Project attribute"

            expect(page).to have_link(type)
          end

          def expect_not_having_create_item(type)
            wait_for_network_idle

            click_button "Add"

            click_button "Project attribute"

            expect(page).to have_no_link(type)
          end
        end
      end
    end
  end
end
