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
  module MonthRangeSelection
    ##
    # Select month from datepicker
    def select_month(month)
      month = Date::MONTHNAMES.index(month) if month.is_a?(String)
      retry_block do
        # This is for a double-month datepicker
        current_month_element = flatpickr_container.all(".cur-month", wait: 0).first
        current_month = if current_month_element
                          Date::MONTHNAMES.index(current_month_element.text)
                        else
                          # This is for a single-month datepicker
                          flatpickr_container.first(".flatpickr-monthDropdown-months").value.to_i + 1
                        end

        if current_month < month
          month_difference = month - current_month
          month_difference.times { flatpickr_container.find(".flatpickr-next-month").click }
          flatpickr_container.first(".flatpickr-monthDropdown-months").value.to_i + 1
        elsif current_month > month
          month_difference = current_month - month
          month_difference.times { flatpickr_container.find(".flatpickr-prev-month").click }
          flatpickr_container.first(".flatpickr-monthDropdown-months").value.to_i + 1
        end
      end
    end
  end
end
