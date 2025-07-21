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

class Meeting::ReportForm < ApplicationForm
  def initialize(project:)
    super()

    @project = project
  end

  form do |meeting_form|
    meeting_form.hidden(name: :report, scope_name_to_model: false, value: "1")

    meeting_form.radio_button_group(
      name: :report_subprojects,
      scope_name_to_model: false,
      label: "Bericht für",
      visually_hide_label: true
    ) do |radio_group|
      radio_group.radio_button(
        value: "false",
        checked: true,
        label: "Für dieses #{@project.human_project_type}"
      )
      radio_group.radio_button(
        value: "true",
        label: "Für dieses #{@project.human_project_type_with_hierarchy}"
      )
    end

    meeting_form.select_list(
      name: "baseline",
      scope_name_to_model: false,
      label: "Vergleichsbasis"
    ) do |list|
      list.option(label: "Gestern", value: :yesterday)
      list.option(label: "Letzte Woche", value: :last_week)
      list.option(label: "Letzter Monat", value: :last_month)
      list.option(label: "Letztes Quartal", value: :last_quarter)
    end


    meeting_form.check_box(
      label: "Änderungen am #{@project.human_project_type}",
      scope_name_to_model: false,
      name: :report_portfolio
    )
    meeting_form.check_box(
      label: "Änderungen am Budget",
      scope_name_to_model: false,
      name: :report_budget
    )
    meeting_form.check_box(
      label: "Änderungen an Meilensteinen",
      scope_name_to_model: false,
      name: :report_milestones
    )
    meeting_form.check_box(
      label: "Änderungen an Zielen und Metriken",
      scope_name_to_model: false,
      name: :report_goals
    )
    meeting_form.check_box(
      label: "Neu identifizierte Risiken und Probleme",
      scope_name_to_model: false,
      name: :report_risks
    )
  end
end
