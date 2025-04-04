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

module ProjectPhases
  class HoverCardController < ApplicationController
    no_authorization_required! :show

    def show
      permitted_params = hover_card_params

      unless valid_gate?(permitted_params[:gate])
        render json: { error: "Invalid gate parameter" }, status: :unprocessable_entity
      end

      id = permitted_params[:id]
      @phase = Project::Phase.eager_load(:definition).where(active: true).find_by(id:)
      @gate = permitted_params[:gate]

      render layout: nil
    end

    private

    def hover_card_params
      params.permit(:id, :gate)
    end

    def valid_gate?(gate)
      gate.present? && %w[start finish].include?(gate)
    end
  end
end
