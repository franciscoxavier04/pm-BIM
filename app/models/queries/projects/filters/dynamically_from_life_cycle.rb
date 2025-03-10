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

module Queries::Projects::Filters::DynamicallyFromLifeCycle
  extend ActiveSupport::Concern

  included do
    def initialize(name, options = {})
      @life_cycle_step_definition = options[:life_cycle_step_definition]

      super
    end

    private

    attr_accessor :life_cycle_step_definition
  end

  class_methods do
    def all_for(context = nil)
      all_step_definitions
        .map do |step|
        create!(name: name_for_step(step), context:)
      rescue ::Queries::Filters::InvalidError
        Rails.logger.error "Failed to map life cycle step definition filter for #{step.name} (CF##{step.id})."
        nil
      end
    end

    def create!(name:, **options)
      life_cycle_step_definition = find_by_accessor(name)
      raise ::Queries::Filters::InvalidError if life_cycle_step_definition.nil?

      new(name, options.merge(life_cycle_step_definition:))
    end

    def key
      raise NotImplementedError
    end

    def all_step_definitions
      key = %w[Queries::Projects::Filters::LifeCycleStepFilter all_step_definitions]

      RequestStore
        .fetch(key) { Project::LifeCycleStepDefinition.all.to_a }
        .select { |lcsd| lcsd.is_a?(step_subclass) }
    end

    def find_by_accessor(name)
      match = name.match key

      if match.present? && match[1].to_i > 0
        all_step_definitions
          .detect { |lcsd| lcsd.id == match[1].to_i }
      end
    end

    def name_for_step(_step)
      raise NotImplementedError
    end

    def step_subclass
      raise NotImplementedError
    end
  end
end
