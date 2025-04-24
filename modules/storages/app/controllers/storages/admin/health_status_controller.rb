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

module Storages
  module Admin
    class HealthStatusController < ApplicationController
      include OpTurbo::ComponentStream

      layout :admin_or_frame_layout

      model_object Storage

      before_action :require_admin
      before_action :find_model_object

      def admin_or_frame_layout
        return "turbo_rails/frame" if turbo_frame_request?

        "admin"
      end

      def show
        @report = Rails.cache.read(validator.report_cache_key)

        respond_to do |format|
          format.html
          format.text do
            timestamp = (@report&.latest_timestamp || Time.zone.now).iso8601
            filename = "#{@storage.name.underscore}_health_report_#{timestamp}.txt"
            send_data text_report(timestamp), filename:, type: "text/plain", disposition: :attachment
          end
        end
      end

      def create
        create_and_cache_report

        redirect_to admin_settings_storage_health_status_report_path(@storage), status: :see_other
      end

      def create_health_status_report
        report = create_and_cache_report

        update_via_turbo_stream(component: SidePanel::ValidationResultComponent.new(storage: @storage, result: report))
        respond_to_with_turbo_streams
      end

      private

      def text_report(timestamp)
        {
          storage: @storage.name,
          storage_type: @storage.to_s,
          ran_at: timestamp
        }.merge(@report.to_h).to_yaml(stringify_names: true)
      end

      def find_model_object(object_id = :storage_id)
        super
        @storage = @object
      end

      def create_and_cache_report
        report = validator.call
        Rails.cache.write(validator.report_cache_key, report, expires_in: 6.hours)

        report
      end

      def validator
        @validator ||= Peripherals::Registry.resolve("#{@storage}.validators.connection").new(@storage)
      end
    end
  end
end
