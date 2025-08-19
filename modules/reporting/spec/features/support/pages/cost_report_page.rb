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

module Pages
  class CostReportPage < ::Pages::Page
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def clear
      # We often clear the page as the first action of the example,
      # which is why the frontend might not be fully initialized
      retry_block do
        scroll_to_and_click(find_by_id("query-link-clear", text: "Clear"))

        # Safeguard to force waiting for the form to be cleared
        expect(page)
          .to have_no_css(".group-by--selected-element")
      end
    end

    def save(as:, public: false)
      # Scroll to report bottom and click
      scroll_to_and_click(find_by_id("query-icon-save-as", text: "Save"))

      # Ensure the form is visible
      scroll_to_element find_by_id("save_as_form")

      page.within("#save_as_form") do
        fill_in "Name", with: as

        if public
          check "Public"
        end

        click_on "Save"
      end
    end

    def switch_to_type(label)
      choose label
      apply
    end

    def remove_row_element(text)
      element_name = find("#group-by--rows label", text:)[:for]
      find("##{element_name}_remove").click
    end

    def remove_column_element(text)
      element_name = find("#group-by--columns label", text:)[:for]
      find("##{element_name}_remove").click
    end

    def apply
      scroll_to_and_click(find_by_id("query-icon-apply-button"))
    end

    def add_to_rows(name)
      select name, from: "group-by--add-rows"
    end

    def add_to_columns(name)
      select name, from: "group-by--add-columns"
    end

    def expect_row_element(text, present: true)
      if present
        expect(page).to have_css("#group-by--selected-rows .group-by--selected-element", text:)
      else
        expect(page).to have_no_css("#group-by--selected-rows .group-by--selected-element", text:)
      end
    end

    def expect_column_element(text, present: true)
      if present
        expect(page).to have_css("#group-by--selected-columns .group-by--selected-element", text:)
      else
        expect(page).to have_no_css("#group-by--selected-columns .group-by--selected-element", text:)
      end
    end

    def wait_for_page_to_reload
      wait_for_network_idle
      expect(page).to have_no_css("#ajax-indicator")
    end

    def path
      cost_reports_path(project)
    end
  end
end
