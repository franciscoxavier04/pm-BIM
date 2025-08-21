# frozen_string_literal: true

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

class CreateActiveProjectPhaseView < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      CREATE OR REPLACE VIEW active_project_phases AS
      SELECT active_phases.active_phase_definition_id AS id,
             project_phase_definitions.name AS name,
             work_packages.id               AS work_package_id,
             project_phase_definition_id,
             projects.id                    AS project_id,
             CASE
                 WHEN project_phase_definitions.position IS NULL THEN -1
                 ELSE project_phase_definitions.position
                 END                        AS phase_position
      FROM work_packages
               LEFT OUTER JOIN project_phase_definitions
                               ON project_phase_definitions.id = work_packages.project_phase_definition_id
               LEFT OUTER JOIN projects
                               ON projects.id = work_packages.project_id
               LEFT OUTER JOIN (SELECT project_phases.id,
                                       project_phases.project_id,
                                       definition_id AS active_phase_definition_id
                                FROM project_phases
                                WHERE project_phases.active = TRUE
                                  AND project_phases.project_id IN (SELECT projects.id
                                                                    FROM projects
                                                                    WHERE projects.active = TRUE)) AS active_phases
                               ON active_phases.active_phase_definition_id = work_packages.project_phase_definition_id
                                   AND active_phases.project_id = work_packages.project_id;
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS active_project_phases;"
  end
end
