# frozen_string_literal: true

# -- copyright
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
# ++

class Queries::Projects::Filters::LifeCycleGateFilter < Queries::Projects::Filters::Base
  include Queries::Projects::Filters::DynamicallyFromLifeCycle
  include Queries::Projects::Filters::FilterOnLifeCycle

  class << self
    def key
      /\Alcsd_gate_(\d+)\z/
    end

    private

    def name_for_step(gate)
      "lcsd_gate_#{gate.id}"
    end

    def step_subclass
      Project::GateDefinition
    end
  end

  def human_name
    I18n.t("project.filters.life_cycle_gate", gate: life_cycle_step_definition.name)
  end

  private

  def on_date
    gate_where(parsed_end)
  end

  def on_today
    gate_where(today, today)
  end

  def between_date
    gate_where(parsed_start, parsed_end)
  end

  def this_week
    gate_where(beginning_of_week.to_date, end_of_week.to_date)
  end

  def none
    gate_none
  end

  def life_cycle_scope_limit(scope)
    super
      .where(definition_id: life_cycle_step_definition.id)
  end
end
