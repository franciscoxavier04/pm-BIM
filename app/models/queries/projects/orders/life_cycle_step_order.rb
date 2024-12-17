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

class Queries::Projects::Orders::LifeCycleStepOrder < Queries::Orders::Base
  self.model = Project

  validates :life_cycle_step_definition, presence: { message: I18n.t(:"activerecord.errors.messages.does_not_exist") }

  def self.key
    # FIXME: use RequestStore?
    valid_ids = Project::LifeCycleStepDefinition.pluck(:id)

    /\Alcsd_(#{valid_ids.join('|')})\z/
  end

  def life_cycle_step_definition
    return @life_cycle_step_definition if defined?(@life_cycle_step_definition)

    @life_cycle_step_definition = self.class.scope.find_by(id: attribute[/\Alcsd_(\d+)\z/, 1])
  end

  def available?
    life_cycle_step_definition.present?
  end

  def self.scope
    Project::LifeCycleStepDefinition
  end

  private

  def joins
    # LEFT JOIN project_life_cycle_steps
    # ON projects.id = project_life_cycle_steps.project_id
    # LEFT JOIN project_life_cycle_step_definitions
    # ON project_life_cycle_step_definitions.id = project_life_cycle_steps.definition_id
    # AND project_life_cycle_step_definitions.id = #{life_cycle_step_definition.id}

    # TODO: this breaks when sorting by multiple life cycle step columns as the subquery will be used
    # more than once and duplicate names are not allowed.
    <<~SQL.squish
      LEFT JOIN (
        SELECT steps.*, def.name, def.id as def_id
        FROM project_life_cycle_steps steps
        LEFT JOIN project_life_cycle_step_definitions def
          ON steps.definition_id = def.id
        WHERE
          1=1
          AND steps.active = true
          AND def.id = #{life_cycle_step_definition.id}
      ) steps ON steps.project_id = projects.id
    SQL
  end

  def order(scope)
    # -> scope coming in. need to enrich it with definitions and their active steps and then order by date?
    # look into joins and other base class methods -> they will be needed here
    # Parent implementation:
    # scope.order(name => direction)
    with_raise_on_invalid do
      scope.where("steps.def_id = :def_id OR steps.def_id IS NULL", def_id: life_cycle_step_definition.id)
           .order("steps.start_date #{direction}")
    end
  end
end
