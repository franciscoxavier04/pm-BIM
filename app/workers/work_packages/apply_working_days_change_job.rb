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

class WorkPackages::ApplyWorkingDaysChangeJob < ApplicationJob
  include JobConcurrency
  queue_with_priority :above_normal

  good_job_control_concurrency_with(
    total_limit: 1
  )

  attr_accessor :previous_working_days, :previous_non_working_days

  def perform(user_id:, previous_working_days:, previous_non_working_days:)
    self.previous_working_days = previous_working_days
    self.previous_non_working_days = previous_non_working_days

    user = User.find(user_id)

    User.execute_as user do
      for_each_work_package(applicable_work_packages) do |work_package|
        apply_change_to_work_package(work_package)
      end

      applicable_predecessors.find_each do |predecessor|
        apply_change_to_predecessor(predecessor)
      end
    end
  end

  private

  def journal_cause
    @journal_cause ||= Journal::CausedByWorkingDayChanges.new(
      working_days: changed_days,
      non_working_days: changed_non_working_dates
    )
  end

  def apply_change_to_work_package(work_package)
    WorkPackages::UpdateService
      .new(user: User.current, model: work_package, contract_class: EmptyContract, cause_of_rescheduling: journal_cause)
      .call(duration: work_package.duration, journal_cause:) # trigger a recomputation of start and due date
      .all_results
  end

  def apply_change_to_predecessor(predecessor)
    schedule_result = WorkPackages::SetScheduleService
                        .new(user: User.current, work_package: predecessor, initiated_by: journal_cause)
                        .call

    # The SetScheduleService does not save. It has to be done by the caller.
    schedule_result.dependent_results.map(&:result).each(&:save)
  end

  def applicable_work_packages
    days_of_week = changed_days.keys
    dates = changed_non_working_dates.keys
    WorkPackage
      .covering_dates_and_days_of_week(days_of_week:, dates:)
      .order(WorkPackage.arel_table[:start_date].asc.nulls_first,
             WorkPackage.arel_table[:due_date].asc)
  end

  def changed_days
    previous = Set.new(previous_working_days)
    current = Set.new(Setting.working_days)

    # `^` is a Set method returning a new set containing elements exclusive to
    # each other
    (previous ^ current).index_with { |day| current.include?(day) }
  end

  def changed_non_working_dates
    previous = Set.new(previous_non_working_days)
    current = Set.new(NonWorkingDay.pluck(:date))

    # `^` is a Set method returning a new set containing elements exclusive to
    # each other
    (previous ^ current).index_with { |day| current.exclude?(day) }
  end

  def applicable_predecessors
    days_of_week = changed_days.keys
    dates = changed_non_working_dates.keys

    WorkPackage
      .predecessors_needing_relations_rescheduling(days_of_week:, dates:)
      .where.not(id: already_processed_work_package_ids)
  end

  def for_each_work_package(scope)
    scope.pluck(:id).each do |id|
      next if already_processed_work_package_ids.include?(id)

      processed_work_packages = yield(WorkPackage.find(id))
      already_processed_work_package_ids.merge(processed_work_packages.pluck(:id))
    end
  end

  def already_processed_work_package_ids
    @already_processed_work_package_ids ||= Set.new
  end
end
