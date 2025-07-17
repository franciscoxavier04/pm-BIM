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

module Meetings
  module Reporting
    def generate_report(meeting)
      if params[:report_portfolio]
        portfolio_changes(meeting)
      end

      if params[:report_budget]
        report_budget(meeting)
      end

      if params[:report_milestones]
        report_milestones(meeting)
      end

      if params[:report_goals]
        report_goals(meeting)
      end

      if params[:report_risks]
        report_risks(meeting)
      end
    rescue => e
      Rails.logger.error("Failed to setup report #{e.message}")
    end

    def base_query(meeting)
      Query.new(name: "_", project: meeting.project).tap do |query|
        query.include_subprojects = params[:report_subprojects] == "true"
        query.timestamps = [baseline_value, "PT0S"]
      end
    end

    def baseline_value
      case params[:baseline].to_s
      when "last_week"
        Time.zone.now.last_week
      when "last_month"
        Time.zone.now.last_month
      when "last_quarter"
        Time.zone.now.last_quarter
      else
        Time.zone.now.yesterday
      end
    end

    def portfolio_changes(meeting)
      MeetingSection.create!(title: "Änderungen am Portfolio", meeting:)
    end

    def report_budget(meeting)
      project = meeting.project
      budgets = project.budgets
      return if budgets.empty?

      meeting_section = meeting.sections.find_or_create_by(title: "Budget")
      budgets.find_each do |budget|
        MeetingAgendaItem.create!(
          author: User.system,
          position: 1,
          meeting_section:,
          meeting:,
          title: budget.subject,
          notes: <<~STR
            **Status**: #{budget.state}
            **Budget**: #{helpers.number_to_currency(budget.supplementary_amount)}
          STR
        )
      end
    end

    def report_milestones(meeting)
      query = base_query(meeting)
      query.add_filter(:type_id, "=", [Type.find_by!(name: "Milestone").id])
      baseline = query.timestamps.first

      section = MeetingSection.create!(title: "Änderungen an Meilensteinen", meeting:)

      query
        .results
        .work_packages
        .select { |work_package| work_package.at_timestamp(baseline).nil? }
        .each do |wp|
          MeetingAgendaItem.create!(
            meeting:,
            meeting_section: section,
            title: nil,
            item_type: 1,
            work_package: wp,
            author: User.system,
            notes: "Neues Meilensteinen seit Vergleichsbasis"
          )
        end
    end

    def report_goals(meeting)
      query = base_query(meeting)
      query.add_filter(:type_id, "=", [BmdsHackathon::Objectives.objective_type.id])
      baseline = query.timestamps.first

      meeting_section = meeting.sections.find_or_create_by(title: "Ziele und Metriken")

      query
        .results
        .work_packages
        .select { |work_package| work_package.at_timestamp(baseline).nil? }
        .each do |work_package|
        agenda_item = MeetingAgendaItem.create!(
          author: User.system,
          position: 1,
          meeting_section:,
          meeting:,
          work_package:,
          title: work_package.subject,
          notes: "Neues Ziel seit Vergleichsbasis"
        )
      end
    end

    def report_risks(meeting)
    end
  end
end
