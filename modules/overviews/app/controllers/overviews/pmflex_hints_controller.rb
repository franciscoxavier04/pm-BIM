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

module ::Overviews
  class PmflexHintsController < ::ApplicationController
    before_action :authorize
    before_action :find_project_by_project_id

    def create
      result = if Setting.ai_enabled && Setting.haystack_base_url.present?
                 Overviews::HaystackPmflexHintsRequest.new(user: current_user).call(@project)
               else
                 ServiceResult.success(result: [])
               end

      result.each do |hints|
        persist_hints(hints)
      end
      result.on_failure do
        flash[:error] = result.errors
      end

      redirect_to project_overview_path(@project)
    end

    private

    def persist_hints(hints)
      ActiveRecord::Base.transaction do
        @project.pmflex_hints.destroy_all
        hints.each do |hint|
          @project.pmflex_hints.create!(
            checked: hint.fetch("checked"),
            title: hint.fetch("title"),
            description: hint.fetch("description")
          )
        end
      end
    end
  end
end
