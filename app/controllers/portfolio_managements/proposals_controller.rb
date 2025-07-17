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

class PortfolioManagements::ProposalsController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :find_project_by_project_id
  before_action :authorize
  before_action :ensure_portfolio
  before_action :find_proposal, only: %i[show edit update destroy change_state]

  menu_item :portfolio

  def index
    @proposals = @project.portfolio_proposals

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @proposal = @project.portfolio_proposals.build
    if params[:add_project].present? && @proposal.project_ids.exclude?(params[:add_project])
      @proposal.project_ids << params[:add_project]
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def edit
    if params[:add_project].present? && @proposal.project_ids.exclude?(params[:add_project])
      @proposal.project_ids << params[:add_project]
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @proposal = @project.portfolio_proposals.build(proposal_params)

    if @proposal.save
      flash[:notice] = t(:notice_successful_create)
      redirect_to project_portfolio_management_proposal_path(@project, @proposal)
    else
      respond_to do |format|
        format.html { render :new }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash-messages", helpers.render_flash_messages)
        end
      end
    end
  end

  def update
    if @proposal.update(proposal_params)
      flash[:notice] = t(:notice_successful_update)
      redirect_to project_portfolio_management_proposal_path(@project, @proposal)
    else
      respond_to do |format|
        format.html { render :edit }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash-messages", helpers.render_flash_messages)
        end
      end
    end
  end

  def destroy
    if @proposal.destroy
      flash[:notice] = t(:notice_successful_delete)
    else
      flash[:error] = t(:error_unable_delete_proposal)
    end

    redirect_to project_portfolio_management_proposals_path(@project)
  end

  def change_state
    new_state = params[:state]

    if @proposal.update(state: new_state)
      flash[:notice] = t(:notice_proposal_state_changed, state: @proposal.state)
    else
      flash[:error] = @proposal.errors.full_messages.join(", ")
    end

    redirect_to project_portfolio_management_path(@project)
  end

  private

  def ensure_portfolio
    unless @project.portfolio?
      flash[:error] = t(:error_must_be_portfolio)
      redirect_to project_path(@project)
    end
  end

  def find_proposal
    @proposal = @project.portfolio_proposals.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def proposal_params
    params.require(:portfolio_proposal).permit(:name, :description, :state, project_ids: [])
  end
end
