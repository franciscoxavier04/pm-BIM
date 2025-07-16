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

module Risks
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    delegate :current_project, to: :table

    def work_package
      model
    end

    def risk
      render(Primer::OpenProject::FlexLayout.new(justify_content: :space_between, align_items: :center)) do |flex|
        flex.with_column(flex_layout: true) do |wp_flex|
          wp_flex.with_row do
            render(WorkPackages::InfoLineComponent.new(work_package:))
          end
          wp_flex.with_row do
            render(Primer::Beta::Text.new(font_weight: :bold)) { work_package.subject }
          end
        end
      end
    end

    def probability
      work_package.typed_custom_value_for(BmdsHackathon::References.risk_likelihood_cf)
    end

    def impact
      work_package.typed_custom_value_for(BmdsHackathon::References.risk_impact_cf)
    end

    def level
      level = work_package.typed_custom_value_for(BmdsHackathon::References.risk_level_cf)
      render(Primer::Beta::Text.new(classes: derive_color(level.to_i))) { level }
    end

    def derive_color(level)
      if level.between?(1, 6)
        "green"
      elsif level.between?(7, 15)
        "yellow"
      else
        "red"
      end
    end
  end
end
