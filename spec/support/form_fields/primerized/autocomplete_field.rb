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

require_relative "form_field"

module FormFields
  module Primerized
    class AutocompleteField < FormField
      ### actions

      def select_option(*values)
        values.each do |val|
          wait_for_autocompleter_options_to_be_loaded

          field_container.find(".ng-select-container").click

          expect(page).to have_css(".ng-option", text: val, visible: :all)
          page.find(".ng-option", text: val, visible: :all).click
          sleep 0.25 # still required?
        end
      end

      def deselect_option(*values)
        values.each do |val|
          wait_for_autocompleter_options_to_be_loaded

          field_container.find(".ng-select-container").click
          page.find(".ng-value", text: val, visible: :all).find(".ng-value-icon").click
          sleep 0.25 # still required?
        end
        field_container.find(".ng-arrow-wrapper").click # close dropdown
        sleep 0.25
      end

      def search(text)
        field_container.find(".ng-select-container input").set text
      end

      def close_autocompleter
        if page.has_css?(".ng-select-container input", wait: 0.1)
          field_container.find(".ng-select-container input").send_keys :escape
        end
      end

      def open_options
        wait_for_autocompleter_options_to_be_loaded
        field_container.find(".ng-select-container").click
      end

      def clear
        field_container.find(".ng-clear-wrapper", visible: :all).click
      end

      def wait_for_autocompleter_options_to_be_loaded
        if has_css?(".ng-spinner-loader", wait: 0.1)
          expect(page).to have_no_css(".ng-spinner-loader")
        end
      end

      ### expectations

      def expect_selected(*values)
        values.each do |val|
          expect(field_container).to have_css(".ng-value", text: val)
        end
      end

      def expect_not_selected(*values)
        values.each do |val|
          expect(field_container).to have_no_css(".ng-value", text: val, wait: 1)
        end
      end

      def expect_blank
        expect(field_container).to have_css(".ng-value", count: 0)
      end

      def expect_no_option(option)
        expect(page)
          .to have_no_css(".ng-option", text: option, visible: :all, wait: 1)
      end

      def expect_option(option)
        expect(page)
          .to have_css(".ng-option", text: option, visible: :visible)
      end

      def expect_visible
        expect(field_container).to have_css("ng-select")
      end

      def expect_error(string = nil)
        expect(field_container).to have_css(".FormControl-inlineValidation", visible: :all)
        expect(field_container).to have_content(string) if string
      end
    end
  end
end
