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
# along with this program; if not, write to the OpenProject GmbH.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Custom matcher to check if progress values are consistent using
# WorkPackages::SetAttributesService::ProgressValuesCalculations#consistent_progress_values?
#
# The helper helps at telling the acceptable range of values for the percent
# complete and/or remaining work when it fails.
#
# Usage:
#   expect(work: 10, remaining_work: 0, percent_complete: 100).to be_consistent_progress_values
#   expect(work: 10, remaining_work: 5, percent_complete: 50).to be_consistent_progress_values
RSpec::Matchers.define :be_consistent_progress_values do
  match do |progress_values|
    work, remaining_work, percent_complete = progress_values.values_at(:work, :remaining_work, :percent_complete)

    # Create a dummy class to access the ProgressValuesCalculations module
    dummy_class = Class.new { extend WorkPackages::SetAttributesService::ProgressValuesCalculations }

    dummy_class.consistent_progress_values?(work:, remaining_work:, percent_complete:)
  end

  failure_message do |progress_values|
    work, remaining_work, percent_complete = progress_values.values_at(:work, :remaining_work, :percent_complete)

    dummy_class = Class.new { extend WorkPackages::SetAttributesService::ProgressValuesCalculations }
    expected_percent_complete = dummy_class.derive_percent_complete(work:, remaining_work:)
    expected_remaining_work = dummy_class.derive_remaining_work(work:, percent_complete:)

    <<~MESSAGE
      expected progress values to be consistent:
        work: #{work}h
        remaining_work: #{remaining_work}h
        percent_complete: #{percent_complete}%

      but they are not consistent
        either derived percent_complete should be #{expected_percent_complete}% with work=#{work}h and remaining_work=#{remaining_work}h
        or derived remaining_work should be #{expected_remaining_work}h with work=#{work}h and percent_complete=#{percent_complete}%
    MESSAGE
  end

  failure_message_when_negated do |progress_values|
    work, remaining_work, percent_complete = progress_values.values_at(:work, :remaining_work, :percent_complete)

    dummy_class = Class.new { extend WorkPackages::SetAttributesService::ProgressValuesCalculations }
    expected_percent_complete = dummy_class.derive_percent_complete(work:, remaining_work:)
    expected_remaining_work = dummy_class.derive_remaining_work(work:, percent_complete:)

    <<~MESSAGE
      expected progress values to NOT be consistent:
        work: #{work}h
        remaining_work: #{remaining_work}h
        percent_complete: #{percent_complete}%

      but they are actually consistent:
        derived percent_complete is #{expected_percent_complete}% with work=#{work}h and remaining_work=#{remaining_work}h
        derived remaining_work is #{expected_remaining_work}h with work=#{work}h and percent_complete=#{percent_complete}%
    MESSAGE
  end

  description do
    "have consistent progress values"
  end
end
