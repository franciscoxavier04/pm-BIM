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

module Flash
  module Expectations
    def expect_flash(message:, type: :success, wait: 20)
      expected_css = expected_flash_css(type)
      expect(page).to have_css(expected_css, text: message, wait:)
    end

    def find_flash_element(type:)
      expected_css = expected_flash_css(type)
      page.find(expected_css)
    end

    def expect_and_dismiss_flash(message: nil, type: :success, wait: 20)
      expect_flash(type:, message:, wait:)
      dismiss_flash!
      expect_no_flash(type:, message:, wait: 0.1)
    end

    def dismiss_flash!
      page.find(".Banner-close button").click # rubocop:disable Capybara/SpecificActions
    end

    def expect_no_flash(type: :success, message: nil, wait: 10)
      if type.nil?
        expect(page).not_to have_test_selector("op-primer-flash-message")
      else
        expected_css = expected_flash_css(type)
        expect(page).to have_no_css(expected_css, text: message, wait:)
      end
    end

    def expected_flash_css(type)
      scheme = mapped_flash_type(type)
      case scheme
      when :default
        %{[data-test-selector="op-primer-flash-message"].Banner}
      else
        %{[data-test-selector="op-primer-flash-message"].Banner--#{scheme}}
      end
    end

    def mapped_flash_type(type)
      case type
      when :error
        :error # The class is error, but the scheme is danger
      when :warning
        :warning
      when :success, :notice
        :success
      else
        :default
      end
    end
  end
end

RSpec.configure do |config|
  config.include Flash::Expectations
end
