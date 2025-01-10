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
  module Grids
    class GridArea
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      attr_accessor :area_selector

      def initialize(*selector)
        self.area_selector = selector
      end

      def resize_to(row, column)
        area.hover

        area.find(".grid--resizer").drag_to self.class.of(row * 2, column * 2).area
      end

      def open_menu
        area.hover
        area.find("icon-triggered-context-menu").click
      end

      def click_menu_item(text)
        # Ensure there are no active toasters
        dismiss_toaster!

        open_menu

        SeleniumHubWaiter.wait
        click_link_or_button text
      end

      def expect_menu_item(text)
        # Ensure there are no active toasters
        dismiss_toaster!

        open_menu

        within("ul.dropdown-menu") do |element|
          expect(element).to have_css("span", text:)
        end
      end

      def remove
        click_menu_item(I18n.t("js.grid.remove"))
      end

      def configure_wp_table
        click_menu_item(I18n.t("js.toolbar.settings.configure_view"))
      end

      def drag_to(row, column)
        handle = drag_handle
        drop_area = self.class.of(row * 2, column * 2).area

        scroll_to_element(handle)

        move_to(handle) do |action|
          action.click_and_hold(handle.native)
        end

        scroll_to_element(drop_area)
        drop_area.hover

        sleep(1)

        move_to(drop_area, &:release)
      end

      def expect_to_exist
        expect(page)
          .to have_selector(*area_selector)
      end

      def expect_to_span(startRow, startColumn, endRow, endColumn)
        expect_to_exist
        [["grid-row-start", startRow * 2],
         ["grid-column-start", startColumn * 2],
         ["grid-row-end", (endRow * 2) - 1],
         ["grid-column-end", (endColumn * 2) - 1]].each do |style, expected|
          actual = area.native.style(style)

          expect(actual)
            .to eql(expected.to_s), "expected #{style} to be #{expected} but it is #{actual}"
        end
      end

      def expect_not_resizable
        within area do
          expect(page)
            .to have_no_css(".grid--area.-widgeted resizer")
        end
      end

      def expect_not_draggable
        area.hover

        within area do
          expect(page)
            .to have_no_css(".grid--area-drag-handle")
        end
      end

      def expect_not_renameable
        within area do
          expect(page)
            .to have_css(".editable-toolbar-title--fixed")
        end
      end

      def expect_no_menu
        area.hover

        within area do
          expect(page)
            .to have_no_css(".icon-show-more-horizontal")
        end
      end

      def area
        page.find(*area_selector)
      end

      def drag_handle
        area.hover
        area.find(".cdk-drag-handle")
      end

      def self.of(row_number, column_number)
        area_style = "grid-area: #{row_number} / #{column_number} / #{row_number + 1} / #{column_number + 1}"

        new(".grid--area:not(.-widgeted)[style*='#{area_style}']")
      end

      def move_to(element)
        action = page
                 .driver
                 .browser
                 .action
                 .move_to(element.native)

        yield action

        action.perform
      end

      def dismiss_toaster!
        if page.has_selector?(".op-toast--close")
          page.find(".op-toast--close").click
        end

        expect(page).to have_no_css(".op-toast")
      end
    end
  end
end
