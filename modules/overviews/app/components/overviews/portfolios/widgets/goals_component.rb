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

module Overviews
  module Portfolios
    module Widgets
      class GoalsComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include ApplicationHelper
        include PlaceholderUsersHelper
        include AvatarHelper

        def initialize(model = nil, project:, **)
          super(model, **)

          @project = project

          @query = Query.new(name: "_", project:)
          @query.include_subprojects = true
          @query.add_filter("type_id", "=", [BmdsHackathon::Objectives.key_result_type.id])
          @query.add_filter("status_id", "=", BmdsHackathon::Objectives.key_result_statuses.map(&:id))
          @query.group_by = :status

          @groups = @query.results.work_package_count_by_group
          @squares = prepare_squares_data(@groups)

          closed_status = BmdsHackathon::Objectives.key_result_statuses.find { |s| s.name == "Geschlossen" }
          @percentage_closed = (@groups[closed_status] || 0).to_f / @groups.values.sum * 100
        end

        private

        def prepare_squares_data(groups)
          # Add squares for each defined status
          BmdsHackathon::Objectives.key_result_statuses.map do |status|
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
  end
end
