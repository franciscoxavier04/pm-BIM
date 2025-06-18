# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

require "support/pages/page"

module Pages
  module Projects
    module Settings
      class General < Pages::Page
        attr_reader :project

        def initialize(project)
          super()

          @project = project
        end

        def path
          "/projects/#{project.identifier}/settings/general"
        end

        def click_copy_action
          page.find_test_selector("project-settings-more-menu").click
          page.find_test_selector("project-settings--copy").click
        end

        def expect_field_label_with_help_text(label_text)
          expect_field_label(label_text)
          expect(find_field_label(label_text)).to have_link accessible_name: "Show help text"
        end

        def expect_field_label_without_help_text(label_text)
          expect_field_label(label_text)
          expect(find_field_label(label_text)).to have_no_link accessible_name: "Show help text"
        end

        def click_help_text_link_for_label(label_text)
          link = find_field_label(label_text).find(:link, accessible_name: "Show help text")
          link.click
        end

        def expect_field_label(label_text)
          expect(page).to have_element :label, text: label_text
        end

        def find_field_label(label_text)
          page.find(:element, :label, text: label_text)
        end
      end
    end
  end
end
