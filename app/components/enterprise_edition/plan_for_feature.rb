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
    end

    def title
      I18n.t("ee.upsale.#{feature_key}.title", default: default_title)
    end

    def default_title
      I18n.t(feature_key, scope: :enterprise_features)
    end

    def description
      @description || begin
        if I18n.exists?(:"ee.upsale.#{feature_key}.description_html")
          I18n.t("ee.upsale.#{feature_key}.description_html").html_safe
        else
          I18n.t("ee.upsale.#{feature_key}.description")
        end
      end
    rescue I18n::MissingTranslationData => e
      raise e.exception(
        <<~TEXT.squish
          The expected '#{I18n.locale}.ee.upsale.#{feature_key}.description' nor '#{I18n.locale}.ee.upsale.#{feature_key}.description_html' key does not exist.
          Ideally, provide it in the locale file.
          If that isn't applicable, a description parameter needs to be provided.
        TEXT
      )
    end

    def features
      return @features if defined?(@features)

      @features = I18n.t("ee.upsale.#{feature_key}.features", default: nil)&.values
    end

    def plan
      @plan ||= OpenProject::Token.lowest_plan_for(feature_key)&.capitalize
    end

    def plan_text
      plan_name = render(Primer::Beta::Text.new(font_weight: :bold, classes: "upsale-colored")) do
        I18n.t("ee.upsale.plan_name", plan:)
      end

      I18n.t("ee.upsale.plan_text_html", plan_name:).html_safe
    end
  end
end
