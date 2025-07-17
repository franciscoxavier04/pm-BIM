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

class DocumentsController < ApplicationController
  include AttachableServiceCall
  include OpTurbo::ComponentStream

  default_search_scope :documents
  model_object Document

  before_action :find_project_by_project_id, only: %i[index new create]
  before_action :find_model_object, except: %i[index new create]
  before_action :find_project_from_association, except: %i[index new create]
  before_action :authorize

  def index
    @group_by = %w(category date title author).include?(params[:group_by]) ? params[:group_by] : "category"
    documents = @project.documents
    @grouped =
      case @group_by
      when "date"
        documents.group_by { |d| d.updated_at.to_date }
      when "title"
        documents.group_by { |d| d.title.first.upcase }
      when "author"
        documents.with_attachments.group_by { |d| d.attachments.last.author }
      else
        documents.includes(:category).group_by(&:category)
      end

    render layout: false if request.xhr?
  end

  def show
    @attachments = @document.attachments.order(Arel.sql("created_at DESC"))
  end

  def new
    @document = @project.documents.build
    @document.attributes = document_params

    if OpenProject::FeatureDecisions.block_note_editor_active?
      respond_with_dialog Documents::FormModalComponent.new(@document, project: @project)
    else
      render action: :new
    end
  end

  def edit
    @categories = DocumentCategory.all

    if OpenProject::FeatureDecisions.block_note_editor_active?
      respond_with_dialog Documents::FormModalComponent.new(@document, project: @project)
    else
      render action: :edit
    end
  end

  def edit_title
    update_header_component_via_turbo_stream(state: :edit)

    respond_with_turbo_streams
  end

  def create
    call = attachable_create_call ::Documents::CreateService,
                                  args: document_params.merge(project: @project)

    call.on_success do
      flash[:notice] = I18n.t(:notice_successful_create)

      if OpenProject::FeatureDecisions.block_note_editor_active?
        redirect_to document_path(call.result)
      else
        redirect_to project_documents_path(@project)
      end
    end

    call.on_failure do
      if OpenProject::FeatureDecisions.block_note_editor_active?
        update_via_turbo_stream(component: Documents::FormModalBodyComponent.new(call.result, project: @project))
        respond_with_turbo_streams(status: :unprocessable_entity)
      else
        @document = call.result
        render action: :new, status: :unprocessable_entity
      end
    end
  end

  def cancel_edit
    update_header_component_via_turbo_stream(state: :show)

    respond_with_turbo_streams
  end

  def update
    call = attachable_update_call ::Documents::UpdateService,
                                  model: @document,
                                  args: document_params

    respond_to do |format|
      format.turbo_stream do
        respond_with_document_update_turbo_streams(call)
      end

      format.html do
        if call.success?
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to action: "show", id: @document
        else
          @document = call.result
          render action: :edit, status: :unprocessable_entity
        end
      end
    end
  end

  def update_title
    call = Documents::UpdateService
      .new(user: current_user, model: @document)
      .call(document_params.slice(:title))

    state = call.success? ? :show : :edit
    update_header_component_via_turbo_stream(state:)

    respond_with_turbo_streams
  end

  def delete_dialog
    respond_with_dialog Documents::DeleteDialogComponent.new(@document)
  end

  def destroy
    @document.destroy
    redirect_to controller: "/documents", action: "index", project_id: @project
  end

  private

  def document_params
    params.fetch(:document, {}).permit("category_id", "title", "description")
  end

  def update_header_component_via_turbo_stream(state: :show)
    update_via_turbo_stream(
      component: Documents::HeaderComponent.new(
        @document,
        project: @project,
        state:
      )
    )
  end

  def respond_with_document_update_turbo_streams(service_call)
    @document = service_call.result
    update_header_component_via_turbo_stream(state: :show)

    if service_call.success?
      render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
    else
      render_error_flash_message_via_turbo_stream(message: service_call.message)
    end

    respond_with_turbo_streams
  end
end
