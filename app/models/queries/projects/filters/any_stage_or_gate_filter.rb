# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

class Queries::Projects::Filters::AnyStageOrGateFilter < Queries::Projects::Filters::Base
  include Queries::Operators::DateRangeClauses

  def type
    :date
  end

  def available_operators
    [
      ::Queries::Operators::Today,
      ::Queries::Operators::OnDate,
      ::Queries::Operators::BetweenDate
    ]
  end

  def available?
    OpenProject::FeatureDecisions.stages_and_gates_active? &&
      User.current.allowed_in_any_project?(:view_project_stages_and_gates)
  end

  def human_name
    I18n.t("project.filters.any_stage_or_gate")
  end

  def where
    case operator
    when "=d"
      stage_where_on(parsed_start)
        .or(gate_where(parsed_end))
        .arel
        .exists
    when "t"
      stage_where_on(today)
        .or(gate_where(today, today))
        .arel
        .exists
    when "<>d"
      stage_where_between(parsed_start, parsed_end)
        .or(gate_where(parsed_start, parsed_end))
        .arel
        .exists
    else
      raise "Unknown operator #{operator}"
    end
  end

  def stage_where_on(start_date, end_date = start_date)
    Project::LifeCycleStep
      .where("project_id = #{Project.table_name}.id")
      .where(type: Project::Stage.name)
      .where(date_range_clause(Project::LifeCycleStep.table_name, "start_date", nil, start_date))
      .where(date_range_clause(Project::LifeCycleStep.table_name, "end_date", end_date, nil))
  end

  def stage_where_between(start_date, end_date)
    Project::LifeCycleStep
      .where("project_id = #{Project.table_name}.id")
      .where(type: Project::Stage.name)
      .where(date_range_clause(Project::LifeCycleStep.table_name, "start_date", start_date, nil))
      .where(date_range_clause(Project::LifeCycleStep.table_name, "end_date", nil, end_date))
  end

  def gate_where(start_date, end_date = start_date)
    # On gates, only the start_date is set.
    Project::LifeCycleStep
      .where("project_id = #{Project.table_name}.id")
      .where(type: Project::Gate.name)
      .where(date_range_clause(Project::LifeCycleStep.table_name, "start_date", start_date, end_date))
  end

  def parsed_start
    values.first.present? ? Date.parse(values.first) : nil
  end

  def parsed_end
    values.last.present? ? Date.parse(values.last) : nil
  end

  def today
    Time.zone.today
  end

  def connection
    ActiveRecord::Base.connection
  end
end
