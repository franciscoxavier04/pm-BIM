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

module My
  class AccessTokensController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_login

    before_action :set_current_user
    before_action :set_grouped_ical_tokens, only: %i[index]
    before_action :set_ical_token, only: %i[revoke_ical_token]
    before_action :set_api_token, only: %i[revoke_api_key]

    menu_item :access_tokens

    layout "my"

    no_authorization_required! :index,
                               :dialog,
                               :generate_rss_key,
                               :revoke_rss_key,
                               :generate_api_key,
                               :revoke_api_key,
                               :revoke_ical_token,
                               :delete_storage_token

    def dialog
      @token_type = params[:token_type] || "api"
    end

    def index
      @ical_meeting_tokens = current_user.ical_meeting_tokens

      @storage_tokens = OAuthClientToken
                          .preload(:oauth_client)
                          .joins(:oauth_client)
                          .where(user: @user, oauth_client: { integration_type: "Storages::Storage" })
    end

    def revoke_storage_token
      token = OAuthClientToken
                .preload(:oauth_client)
                .joins(:oauth_client)
                .where(user: @user, oauth_client: { integration_type: "Storages::Storage" }).find_by(id: params[:access_token_id])

      if token&.destroy
        flash[:info] = I18n.t("my_account.access_tokens.storages.removed")
      else
        flash[:error] = I18n.t("my_account.access_tokens.storages.failed")
      end
      redirect_to action: :index
    end

    def generate_rss_key # rubocop:disable Metrics/AbcSize
      token = Token::RSS.create!(user: current_user)
      flash[:info] = [
        t("my.access_token.notice_reset_token", type: "RSS").html_safe,
        helpers.content_tag(:strong, helpers.content_tag(:code, token.plain_value)),
        t("my.access_token.token_value_warning")
      ]
    rescue StandardError => e
      Rails.logger.error "Failed to reset user ##{current_user.id} RSS key: #{e}"
      flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
    ensure
      redirect_to action: :index
    end

    def revoke_rss_key
      current_user.rss_token.destroy
      flash[:info] = t("my.access_token.notice_rss_token_revoked")
    rescue StandardError => e
      Rails.logger.error "Failed to revoke rss token ##{current_user.id}: #{e}"
      flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
    ensure
      redirect_to action: :index
    end

    def generate_api_key
      result = call_generate_token_service

      result.on_success do |r|
        update_via_turbo_stream(component: section_to_render(r.result))

        dialog = My::AccessToken::AccessTokenCreatedDialogComponent.new(token: r.result)
        modify_via_turbo_stream(component: dialog, action: :dialog, status: :ok)
      end

      result.on_failure do |r|
        update_via_turbo_stream(
          component: My::AccessToken::NewAccessTokenFormComponent.new(token: r.result),
          status: :bad_request
        )
      end

      respond_with_turbo_streams
    end

    def revoke_api_key # rubocop:disable Metrics/AbcSize
      result = APITokens::DeleteService.new(user: current_user, model: @api_token).call

      # rubocop:disable Rails/ActionControllerFlashBeforeRender
      result.on_success do
        flash[:notice] = t("my.access_token.notice_api_token_revoked")
      end

      result.on_failure do |r|
        error = r.errors.map(&:message).join("; ")
        Rails.logger.error("Failed to revoke api token ##{current_user.id}: #{error}")
        flash[:error] = t("my.access_token.failed_to_revoke_token", error:)
      end
      # rubocop:enable Rails/ActionControllerFlashBeforeRender

      redirect_to action: :index
    end

    def revoke_ical_token
      message = ical_destroy_info_message
      @ical_token.destroy
      flash[:info] = message
    rescue StandardError => e
      Rails.logger.error "Failed to revoke all ical tokens for ##{current_user.id}: #{e}"
      flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
    ensure
      redirect_to action: :index
    end

    private

    def set_current_user
      @user = User.current
    end

    helper_method :has_tokens?

    def has_tokens?
      Setting.feeds_enabled? || Setting.rest_api_enabled? || current_user.ical_tokens.any?
    end

    def set_api_token
      @api_token = current_user.api_tokens.find(params[:access_token_id])
    end

    def set_ical_token
      @ical_token = current_user.ical_tokens.find(params[:access_token_id])
    end

    def set_grouped_ical_tokens
      @ical_tokens_grouped_by_query = current_user.ical_tokens
                                                  .joins(ical_token_query_assignment: { query: :project })
                                                  .select("tokens.*, ical_token_query_assignments.query_id")
                                                  .group_by(&:query_id)
    end

    def ical_destroy_info_message
      t(
        "my.access_token.notice_ical_token_revoked",
        token_name: @ical_token.ical_token_query_assignment.name,
        calendar_name: @ical_token.query.name,
        project_name: @ical_token.query.project.name
      )
    end

    def section_to_render(token)
      case token
      when Token::API
        My::AccessToken::APITokensSectionComponent.new(tokens: current_user.api_tokens, token_type: Token::API)
      when Token::ICalMeeting
        My::AccessToken::APITokensSectionComponent.new(tokens: current_user.ical_meeting_tokens, token_type: Token::ICalMeeting)
      else
        raise ArgumentError, "Unknown token type: #{token.class}"
      end
    end

    def call_generate_token_service # rubocop:disable Metrics/AbcSize
      if params[:token_api]
        APITokens::CreateService
        .new(user: current_user, model: Token::API.new)
        .call(token_name: params[:token_api][:token_name])
      elsif params[:token_ical_meeting]
        APITokens::CreateService
        .new(user: current_user, model: Token::ICalMeeting.new)
        .call(token_name: params[:token_ical_meeting][:token_name])
      else
        raise ArgumentError, "Unknown token type"
      end
    end
  end
end
