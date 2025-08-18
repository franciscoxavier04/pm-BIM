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

class WorkPackages::SetAttributesService
  module ProgressValuesCalculations
    # Calculate work from remaining work and percent complete without checking for consistency.
    # It returns unexpected results when `percent_complete` is 100.
    def calculate_work(remaining_work:, percent_complete:)
      remaining_percent_complete = 1.0 - (percent_complete / 100.0)
      (remaining_work / remaining_percent_complete).round(2)
    end

    # Calculate remaining work from work and percent complete without checking for consistency.
    def calculate_remaining_work(work:, percent_complete:)
      completed_work = work * percent_complete / 100.0
      remaining_work = (work - completed_work).round(2)
      remaining_work.clamp(0.0, work)
    end

    # Calculate percent complete from work and remaining work without checking for consistency.
    # Raises `FloatDomainError` if work is 0.
    def calculate_percent_complete(work:, remaining_work:)
      # round to 2 decimal places because that's how we store work and remaining
      # work in database
      rounded_work = work.round(2)
      rounded_remaining_work = remaining_work.round(2)
      completed_work = rounded_work - rounded_remaining_work
      completion_ratio = completed_work.to_f / rounded_work

      percentage = (completion_ratio * 100)
      case percentage
      in 0 then 0
      in 0..1 then 1
      in 99...100 then 99
      else
        percentage.round
      end
    end

    def consistent_progress_values?(work:, remaining_work:, percent_complete:)
      # Check if one of provided remaining_work or percent_complete matches the calculated one
      percent_complete == calculate_percent_complete(work:, remaining_work:) \
        || remaining_work == calculate_remaining_work(work:, percent_complete:)
    end
  end
end
