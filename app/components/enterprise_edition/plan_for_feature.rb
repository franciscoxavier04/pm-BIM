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

module EnterpriseEdition
  module PlanForFeature
    extend ActiveSupport::Concern

    included do
      attr_accessor :feature_key
      attr_accessor :i18n_scope
    end

    def teaser?
      feature_key == :teaser
    end

    def token
      @token ||= EnterpriseToken.active_trial_tokens.last
    end

    def title
      I18n.t(:title, scope: i18n_scope, default: default_title)
    end

    def default_title
      teaser? ? teaser_title : I18n.t(feature_key, scope: :"ee.features")
    end

    def teaser_title
      I18n.t("ee.teaser.title", count: token.days_left, trial_plan: token.plan)
    end

    def description
      return teaser_description if teaser?

      @description || begin
        if I18n.exists?(:description_html, scope: i18n_scope)
          I18n.t(:description_html, scope: i18n_scope).html_safe
        else
          I18n.t(:description, scope: i18n_scope)
        end
      end
    rescue I18n::MissingTranslationData => e
      raise e.exception(
        <<~TEXT.squish
          The expected '#{I18n.locale}.#{i18n_scope}.description' nor '#{I18n.locale}.#{i18n_scope}.description_html' key does not exist.
          Ideally, provide it in the locale file.
          If that isn't applicable, a description parameter needs to be provided.
        TEXT
      )
    end

    def teaser_description
      I18n.t("ee.teaser.description", trial_plan: plan_name(token.plan)).html_safe
    end

    def features
      defined?(@features) || begin
        @features = I18n.t(:features, scope: i18n_scope, default: nil)&.values
      end

      @features = I18n.t(:features, scope: i18n_scope, default: nil)&.values
    end

    def plan
      defined?(@plan) || begin
        @plan = OpenProject::Token.lowest_plan_for(feature_key)
        raise ArgumentError, "#{feature_key} is not a valid feature, as no plan mapped to it." if @plan.nil?
      end

      @plan
    end

    def plan_text
      I18n.t("ee.upsell.plan_text_html", plan_name: plan_name(plan)).html_safe
    end

    def plan_name(plan)
      render(Primer::Beta::Text.new(font_weight: :bold, classes: "upsell-colored")) do
        I18n.t("ee.upsell.plan_name", plan: plan.capitalize)
      end
    end
  end
end
