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

module WorkPackages
  module Types
    class PdfExportTemplateController < ApplicationController
      include OpTurbo::ComponentStream
      before_action :require_admin
      before_action :find_type, only: %i[toggle drop enable_all disable_all]
      before_action :find_template, only: %i[toggle drop]

      def enable_all
        Rails.logger.debug "enable_all"

        respond_with_turbo_streams
      end

      def disable_all
        Rails.logger.debug "disable_all"

        respond_with_turbo_streams
      end

      def toggle
        return render_404 if @template.nil?

        Rails.logger.debug { "toggle #{@template.inspect}" }
        respond_with_turbo_streams
      end

      def drop
        return render_404 if @template.nil?

        Rails.logger.debug { "drop #{@template.inspect} #{params[:position]}" }
        respond_to_with_turbo_streams
      end

      protected

      def find_type
        @type = ::Type.find(params[:type_id])
      end

      def find_template
        @template = @type.pdf_export_templates_for_type.find { |t| t.id == params[:id] }
      end
    end
  end
end
