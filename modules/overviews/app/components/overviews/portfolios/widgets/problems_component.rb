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
      class ProblemsComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include ApplicationHelper
        include PlaceholderUsersHelper
        include AvatarHelper

        attr_reader :wps

        def initialize(model = nil, project:, **)
          super(model, **)

          @project = project
          @cutoff_limit = 5
          @level_cf = BmdsHackathon::References.risk_level_cf
          @wps = WorkPackage
                    .visible
                    .where(type: Type.where(name: ["Risiko", "Problem"]))
                    .where(project_id: @project.self_and_descendants.select(:id))
                    .includes(:custom_values)
                    .sort_by { |wp| wp.send("custom_field_#{@level_cf.id}").to_i }
                    .reverse
        end

        def risk_level_for(work_package)
          work_package.send("custom_field_#{@level_cf.id}")
        end
      end
    end
  end
end
