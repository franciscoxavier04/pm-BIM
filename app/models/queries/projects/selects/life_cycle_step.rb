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

class Queries::Projects::Selects::LifeCycleStep < Queries::Selects::Base
  KEY = /\Alcsd_(\d+)\z/

  def self.key
    KEY
  end

  def self.all_available
    return [] unless available?

    Project::LifeCycleStepDefinition
      .pluck(:id)
      .map { |id| new(:"lcsd_#{id}") }
  end

  def caption
    life_cycle_step.name
  end

  def life_cycle_step
    return @life_cycle_step if defined?(@life_cycle_step)

    @life_cycle_step = Project::LifeCycleStepDefinition
                         .find_by(id: attribute[KEY, 1])
  end

  def available?
    life_cycle_step.present?
  end

  def action_menu_header(button)
    # Show the proper icon for the definition with the correct color.
    icon = life_cycle_step.is_a?(Project::StageDefinition) ? :"git-commit" : :diamond
    button.with_leading_visual_icon(icon:, classes: helpers.hl_inline_class("life_cycle_step_definition", life_cycle_step))

    # As all other action menu headers, we will show an action icon and the caption:
    button.with_trailing_action_icon(icon: :"triangle-down")

    caption.to_s
  end

  private

  def helpers
    @helpers ||= Object.new.extend(ColorsHelper)
  end
end
