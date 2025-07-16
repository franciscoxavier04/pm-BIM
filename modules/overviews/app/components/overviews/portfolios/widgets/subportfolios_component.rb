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
      class SubportfoliosComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include ApplicationHelper

        attr_reader :subportfolios

        def initialize(model = nil, project:, **)
          super(model, **)

          @project = project
          @subportfolios = Project
                             .visible
                             .portfolio
                             .where(parent: project.id)
                             .sort_by do |project|
                               rank = rank_for(project)
                               [rank.nil? ? 1 : 0, rank]
                             end
        end

        def label_color_for(key)
          schemes = {
            on_track: :success,
            at_risk: :danger,
            not_set: :primary,
            off_track: :severe,
            not_started: :accent,
            finished: :done,
            discontinued: :warning
          }

          schemes[key.to_sym] || :secondary
        end

        def formatted_rank_for(project)
          helpers.safe_join ["Rang:", rank_for(project) || "k.A."], " "
        end

        def rank_for(project)
          project.public_send("custom_field_#{BmdsHackathon::References.rank_cf.id}")
        end
      end
    end
  end
end
