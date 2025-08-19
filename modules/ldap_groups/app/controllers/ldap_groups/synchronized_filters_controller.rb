# frozen_string_literal: true

module LdapGroups
  class SynchronizedFiltersController < ::ApplicationController
    before_action :require_admin

    guard_enterprise_feature(:ldap_groups, except: %i[show destroy]) do
      redirect_to ldap_groups_synchronized_groups_path, status: :see_other
    end

    before_action :find_filter, except: %i[new create]

    layout "admin"
    menu_item :plugin_ldap_groups

    def new
      @filter = SynchronizedFilter.new
    end

    def show; end

    def end; end

    def destroy_info; end

    def create
      @filter = SynchronizedFilter.new permitted_params

      if @filter.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to ldap_groups_synchronized_groups_path
      else
        render action: :new, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def update
      if @filter.update permitted_params
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: :show
      else
        render action: :edit, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def destroy
      if @filter.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_can_not_delete_entry)
      end

      redirect_to ldap_groups_synchronized_groups_path
    end

    def synchronize
      call = ::LdapGroups::SynchronizeFilterService
                .new(@filter)
                .call

      call.on_success do
        count = call.result
        symbol = count > 0 ? :notice : :info
        flash[symbol] = I18n.t("ldap_groups.synchronized_filters.label_n_groups_found", count:)
      end

      call.on_failure do
        flash[:error] = call.message
      end

      redirect_to ldap_groups_synchronized_groups_path
    end

    private

    def find_filter
      @filter = SynchronizedFilter.find(params[:ldap_filter_id])
    end

    def permitted_params
      params
        .require(:synchronized_filter)
        .permit(:filter_string, :name, :ldap_auth_source_id, :group_name_attribute, :sync_users, :base_dn)
    end
  end
end
