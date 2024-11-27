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

# require_relative "../meetings/show"

module Pages::RecurringMeeting
  class Show < ::Pages::Meetings::Show
    include ::Components::Autocompleter::NgSelectAutocompleteHelpers

    def expect_scheduled_meeting(date:)
      within("li", text: date) do
        expect(page).to have_css(".status", text: "Scheduled")
      end
    end

    def expect_no_scheduled_meeting(date:)
      within("li", text: date) do
        expect(page).to have_no_css(".status", text: "Scheduled")
      end
    end

    def expect_open_meeting(date:)
      within("li", text: date) do
        expect(page).to have_css(".status", text: "Open")
      end
    end

    def expect_no_open_meeting(date:)
      within("li", text: date) do
        expect(page).to have_no_css(".status", text: "Open")
      end
    end

    def expect_cancelled_meeting(date:)
      within("li", text: date) do
        expect(page).to have_css(".status", text: "Cancelled")
      end
    end

    def create_from_template(date:)
      within("li", text: date) do
        click_on "Create from template"
      end
    end

    def cancel_occurrence(date:)
      within("li", text: date) do
        click_on "more-button"
        click_on "Cancel this occurrence"
      end
    end

    # def for_meeting(date:, &)
    #   within("li", text: date, &)
    # end
  end
end
