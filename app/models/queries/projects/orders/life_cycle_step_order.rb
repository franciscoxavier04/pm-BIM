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
    <<~SQL.squish
      LEFT JOIN #{cte_name} ON #{cte_name}.project_id = projects.id
    SQL
  end

  def cte_name
    definition_id = life_cycle_step_definition.id

    :"life_cycle_steps_cte_#{definition_id}"
  end

  def cte_statement
    Project::LifeCycleStep.select("*, def.name, def.id as def_id")
                          .joins("LEFT JOIN project_life_cycle_step_definitions def ON definition_id = def.id")
                          .where(active: true, definition_id: life_cycle_step_definition.id)
  end

  def order(scope)
    with_raise_on_invalid do
      # Note that a gate does not define an end_date. This code still works.
      direction_clause = Arel.sql("#{cte_name}.start_date #{direction}, #{cte_name}.end_date #{direction}")

      scope.where("#{cte_name}.def_id = :def_id OR #{cte_name}.def_id IS NULL", def_id: life_cycle_step_definition.id)
           .order(direction_clause)
    end
  end
end
