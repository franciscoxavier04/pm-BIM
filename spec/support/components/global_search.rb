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

module Components
  class GlobalSearch
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    def container
      page.find(".top-menu-search--input")
    end

    def selector
      ".top-menu-search--input"
    end

    def input
      container.find "input"
    end

    def dropdown
      container.find(".ng-dropdown-panel")
    end

    def click_input
      input.hover
      input.click
    end

    def search(query, submit: false)
      SeleniumHubWaiter.wait
      input.set ""
      click_input
      input.set query

      if submit
        submit_with_enter
      end
    end

    def submit_with_enter
      input.send_keys :enter
      SeleniumHubWaiter.wait
    end

    def expect_open
      expect(page).to have_selector(container)
    end

    def submit_in_project_and_subproject_scope
      page.find('.global-search--project-scope[title="current_project_and_all_descendants"]', wait: 10).click
    end

    def submit_in_current_project
      page.find('.global-search--project-scope[title="current_project"]', wait: 10).click
    end

    def submit_in_global_scope
      page.find('.global-search--project-scope[title="all_projects"]', wait: 10).click
    end

    def expect_global_scope_marked
      expect(page)
        .to have_css('.global-search--project-scope[title="all_projects"]', wait: 10)
    end

    def expect_in_project_and_subproject_scope_marked
      expect(page)
        .to have_css('.global-search--project-scope[title="current_project_and_all_descendants"]', wait: 10)
    end

    def expect_scope(text)
      expect(page)
        .to have_css(".global-search--project-scope", text:, wait: 10)
    end

    def expect_work_package_marked(wp)
      expect(page)
        .to have_css(".ng-option-marked", text: wp.subject.to_s, wait: 10)
    end

    def expect_work_package_option(wp)
      expect(page)
        .to have_css(".global-search--option", text: wp.subject.to_s, wait: 10)
    end

    def expect_no_work_package_option(wp)
      expect(page)
        .to have_no_css(".global-search--option", text: wp.subject.to_s)
    end

    def click_work_package(wp)
      find_work_package(wp).click
    end

    def find_work_package(wp)
      find_option wp.subject.to_s
    end

    def find_option(text)
      expect(page).to have_css(".global-search--wp-subject", text:, wait: 10)
      find(".global-search--wp-subject", text:)
    end

    def cancel
      input.send_keys :escape
    end
  end
end
