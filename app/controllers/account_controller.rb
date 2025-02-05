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

class AccountController < ApplicationController
  include CustomFieldsHelper
  include OmniauthHelper
  include Accounts::Registration
  include Accounts::UserConsent
  include Accounts::UserLimits
  include Accounts::UserLogin
  include Accounts::UserPasswordChange

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_action :check_if_login_required
  no_authorization_required! :login,
                             :internal_login,
                             :logout,
                             :lost_password,
                             :register,
                             :activate,
                             :consent,
                             :confirm_consent,
                             :decline_consent,
                             :stage_success,
                             :stage_failure,
                             :change_password,
                             :auth_source_sso_failed

  before_action :apply_csp_appends, only: %i[login]
  before_action :disable_api
  before_action :check_auth_source_sso_failure, only: :auth_source_sso_failed
  before_action :check_internal_login_enabled, only: :internal_login

  layout "no_menu"

  # Login request and validation
  def login
    user = User.current

    if user.logged?
      redirect_after_login(user)
    elsif request.get? && omniauth_direct_login?
      direct_login(user)
    elsif request.post?
      authenticate_user
    end
  end

  def internal_login
    render "account/login"
  end

  # Log out current user and redirect to welcome page
  def logout
    previous_session = session.to_h.with_indifferent_access
    previous_user = current_user

    logout_user

    perform_post_logout previous_session, previous_user
  end

  # Enable user to choose a new password
  def lost_password
    return redirect_to(home_url) unless allow_lost_password_recovery?

    if params[:token]
      @token = ::Token::Recovery.find_by_plaintext_value(params[:token])
      redirect_to(home_url) && return unless @token and !@token.expired?

      @user = @token.user
      if request.post?
        call = ::Users::ChangePasswordService.new(current_user: @user, session: session).call(params)
        call.apply_flash_message!(flash) if call.errors.empty?

        if call.success?
          @token.destroy
          redirect_to action: "login"
          return
        end
      end

      render template: "account/password_recovery"
    elsif request.post?
      mail = params[:mail]
      user = User.find_by_mail(mail) if mail.present?

      flash[:notice] = I18n.t(:notice_account_lost_email_sent)

      unless user
        Rails.logger.error "Lost password unknown email input: #{mail}"
        return
      end

      unless user.change_password_allowed?
        UserMailer.password_change_not_possible(user).deliver_later
        Rails.logger.warn "Password cannot be changed for user: #{mail}"
        return
      end

      token = Token::Recovery.new(user_id: user.id)
      if token.save
        UserMailer.password_lost(token).deliver_later
        flash[:notice] = I18n.t(:notice_account_lost_email_sent)
        # Use the safe URL here:
        redirect_to action: "login", back_url: valid_internal_url(home_url)
        nil
      end
    end
  end

  # Token based account activation
  def activate
    token = ::Token::Invitation.find_by_plaintext_value(params[:token])

    if token.nil? || token.user.nil?
      invalid_token_and_redirect
    elsif token.expired?
      handle_expired_token token
    elsif token.user.invited?
      activate_by_invite_token token
    elsif Setting::SelfRegistration.enabled?
      activate_self_registered token
    else
      invalid_token_and_redirect
    end
  end

  # Process account activation for self-registered users
  def activate_self_registered(token)
    return if enforce_activation_user_limit(user: token.user)

    user = token.user

    if user.registered?
      user.activate

      if user.save
        token.destroy
        flash[:notice] = I18n.t(:notice_account_activated)
      else
        flash[:error] = I18n.t(:notice_activation_failed)
      end
    elsif user.active?
      flash[:notice] = I18n.t(:notice_account_already_activated)
    else
      flash[:error] = I18n.t(:notice_activation_failed)
    end

    # Validate back_url before redirecting
    redirect_to signin_path(back_url: valid_internal_url(params[:back_url]))
  end

  def activate_by_invite_token(token)
    activate_invited token
  end

  def activate_invited(token)
    session[:invitation_token] = token.value
    session[:back_url] = valid_internal_url(params[:back_url])
    user = token.user

    if user.ldap_auth_source
      activate_through_ldap user
    else
      activate_user user
    end
  end

  def activate_user(user)
    if omniauth_direct_login?
      direct_login user
    elsif OpenProject::Configuration.disable_password_login?
      flash[:notice] = I18n.t("account.omniauth_login")
      redirect_to signin_path
    else
      redirect_to account_register_path
    end
  end

  def activate_through_ldap(user)
    session[:auth_source_registration] = {
      login: user.login,
      ldap_auth_source_id: user.ldap_auth_source_id
    }

    flash[:notice] = I18n.t("account.auth_source_login", login: user.login).html_safe

    redirect_to signin_path(username: user.login)
  end

  # Direct login with optional back_url redirection
  def direct_login(user)
    if flash.empty?
      ps = {}.tap do |p|
        p[:origin] = valid_internal_url(params[:back_url]) if params[:back_url]
      end

      redirect_to direct_login_provider_url(ps)
    elsif Setting.login_required?
      error = !user.anonymous? || flash[:error]
      instructions = error ? :after_error : :after_registration

      render :exit, locals: { instructions: instructions }
    end
  end

  def invalid_token_and_redirect
    flash[:error] = I18n.t(:notice_account_invalid_token)
    redirect_to signin_path
  end

  # ... other actions and methods remain unchanged ...

  private

  # Existing helper methods (e.g., handle_expired_token, send_activation_email!) remain unchanged

  # ---------------------------------------------------------------------------
  # Revised URL Validation Helper
  #
  # This method ensures that any URL provided (typically via params[:back_url])
  # is safe for internal redirection. It only allows relative URLs that:
  #  - Do not include a scheme (e.g., "http://")
  #  - Do not include a host
  #  - Begin with a single slash ('/')
  #  - Do not start with a double slash, which some browsers interpret as a protocol-relative URL
  # If the URL is missing or invalid, it defaults to home_url.
  # ---------------------------------------------------------------------------
  def valid_internal_url(url)
    return home_url unless url.present?

    uri = URI.parse(url) rescue nil
    if uri && uri.scheme.nil? && uri.host.nil? && uri.path.start_with?('/') && !url.start_with?('//')
      uri.to_s
    else
      home_url
    end
  end
end
