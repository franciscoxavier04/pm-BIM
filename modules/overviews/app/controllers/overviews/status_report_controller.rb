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
  class StatusReportController < ::ApplicationController
    before_action :authorize
    before_action :find_project_by_project_id

    def create
      result = if Setting.ai_enabled && Setting.haystack_base_url.present?
                 Overviews::HaystackReportRequest.new(user: current_user).call(@project)
               else
                 ServiceResult.success(result: "")
               end

      # TODO: Maybe both (success & error) should redirect to new_document_path, just prefilling a lot
      #       or the whole LLM-interaction is part of new_document_path and happens there
      result.each do |content|
        document = persist_report(content).result
        redirect_to document_path(document)
      end
      result.on_failure do
        flash[:error] = result.errors
        redirect_to project_overview_path(@project)
      end
    end

    private

    def persist_report(content)
      Documents::CreateService.new(user: current_user).call(
        project: @project,
        category: DocumentCategory.project_status_report,
        title: "Report erstellt am #{helpers.format_time(Time.zone.now)}",
        description: content
      )
    end
  end
end
