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

class Queries::Projects::Filters::LifeCycleStageFilter < Queries::Projects::Filters::Base
  include Queries::Projects::Filters::DynamicallyFromLifeCycle
  include Queries::Projects::Filters::FilterOnLifeCycle

  class << self
    def key
      /\Alcsd_stage_(\d+)\z/
    end

    private

    def name_for_step(stage)
      "lcsd_stage_#{stage.id}"
    end

    def step_subclass
      Project::StageDefinition
    end
  end

  def human_name
    I18n.t("project.filters.life_cycle_stage", stage: life_cycle_step_definition.name)
  end

  private

  def on_date
    stage_where_on(parsed_start)
  end

  def on_today
    stage_where_on(today)
  end

  def between_date
    stage_where_between(parsed_start, parsed_end)
  end

  def this_week
    stage_overlaps_this_week
  end

  def none
    stage_none
  end

  def life_cycle_scope_limit(scope)
    super
      .where(definition_id: life_cycle_step_definition.id)
  end
end
