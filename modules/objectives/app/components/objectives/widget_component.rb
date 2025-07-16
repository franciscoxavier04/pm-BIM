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

module Objectives
  class WidgetComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper
    include PlaceholderUsersHelper
    include AvatarHelper

    attr_reader :collapsed

    def initialize(model = nil,
                   project:,
                   collapsed: false,
                   show_footer: true,
                   query: nil,
                   **system_arguments)
      super(model)

      @project = project
      @collapsed = collapsed
      @show_footer = show_footer
      @system_arguments = system_arguments
      @query = query || setup_query

      compute_results!
    end

    private

    def compute_results!
      @groups = @query.results.work_package_count_by_group
      @squares = prepare_squares_data(@groups)

      @work_packages = @query.results.work_packages
      @total_percentage = (@work_packages.pluck(:done_ratio).compact.sum.to_f / @work_packages.size).round

      closed_status = BmdsHackathon::Objectives.objective_statuses.find { |s| s.name == "Geschlossen" }
      @percentage_closed = (@groups[closed_status] || 0).to_f / @groups.values.sum * 100
    end

    def setup_query
      @query = Query.new(name: "_", project: @project)
      @query.include_subprojects = true
      @query.add_filter("type_id", "=", [BmdsHackathon::Objectives.objective_type.id])
      @query.add_filter("status_id", "=", BmdsHackathon::Objectives.objective_statuses.map(&:id))
      @query.group_by = "status"
    end

    def prepare_squares_data(groups)
      # Add squares for each defined status
      BmdsHackathon::Objectives.objective_statuses.map do |status|
        count = groups[status] || 0

        {
          count: count,
          label: status.name,
          color: BmdsHackathon::Objectives::COLOR_MAP[status.name],
          bgcolor: BmdsHackathon::Objectives::BGCOLOR_MAP[status.name]
        }
      end
    end
  end
end
