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

##
# Intended to be used by the ApplicationController to provide authorization helpers
module Accounts::EnterpriseGuard
  extend ActiveSupport::Concern

  class_methods do
    ##
    # Adds a before_action check to test enterprise status of the feature
    # @param feature_key [String] the name of the enterprise feature to check
    #
    # If a block is passed, it will be executed if the feature is not available.
    def guard_enterprise_feature(feature_key, **action_args, &)
      before_action(**action_args) do
        perform_enterprise_feature_guard(feature_key, &)
      end
    end
  end

  private

  ##
  # Checks if the current action is covered by any authorization method.
  # @param feature_key [String] the name of the enterprise feature to check
  # If a block is passed, it will be executed if the feature is not available.
  def perform_enterprise_feature_guard(feature_key, &)
    return if EnterpriseToken.allows_to?(feature_key)

    plan = OpenProject::Token.lowest_plan_for(feature_key)
    if block_given?
      flash[:error] = I18n.t("error_enterprise_plan_needed", plan:)
      instance_eval(&)
    else
      render_403 message: I18n.t("error_enterprise_plan_needed", plan:)
    end
  end
end
