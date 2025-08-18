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

module Queries::ProjectPhaseDefinitions
  module DatabaseQueries
    # JOIN statement for project phase definitions. We ensure that only active project phases are considered.
    # Note that one project might have an active phase while another project has set the phase with the same definition
    # to inactive. Additionally, the permissions to view project phases are considered on a project level, too.
    def join_project_phase_definitions_based_on_permissions_and_active_phases
      # The project is joined here anew which should not be necessary for many use-cases but is.
      # The necessity comes from AR's behavior of automatically determining the alias for tables LEFT JOINed via includes.
      # To avoid conflicts, AR will search strings for occurrences of the table name and if found, an included table
      # will be aliased (potentially with a numbering). In this case, if the permission checks are part of the query,
      # it will include a reference to the projects table. Therefore, the include for projects, which happens in
      # the query itself, will be considered needing an alias. That assumption is wrong in this case as the reference
      # to projects is in a subquery but AR does not know that.
      <<~SQL.squish
        LEFT OUTER JOIN "projects" ON "projects"."id" = "work_packages"."project_id"
        LEFT OUTER JOIN (
          #{active_project_phases.to_sql}
        ) AS active_phases
        ON active_phases.active_phase_definition_id = work_packages.project_phase_definition_id
          AND active_phases.project_id = work_packages.project_id
      SQL
    end

    private

    def active_project_phases
      Project::Phase
        .active
        .where(project_id: projects_with_view_phases_permissions)
        .select(:id, :project_id, "definition_id AS active_phase_definition_id")
    end

    def projects_with_view_phases_permissions
      Project.allowed_to(User.current, :view_project_phases).select(:id)
    end
  end
end
