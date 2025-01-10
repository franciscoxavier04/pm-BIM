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

module Exports
  module Formatters
    class CustomFieldPdf < CustomField
      def self.apply?(attribute, export_format)
        export_format == :pdf && attribute.start_with?("cf_")
      end

      ##
      # Print the value meant for export.
      #
      # - For boolean values, use the Yes/No formatting for the PDF
      #   treat nil as false
      # - For long text values, output the plain value
      def format_for_export(object, custom_field)
        case custom_field.field_format
        when "bool"
          value = object.typed_custom_value_for(custom_field)
          value ? I18n.t(:general_text_Yes) : I18n.t(:general_text_No)
        when "text"
          object.typed_custom_value_for(custom_field)
        else
          object.formatted_custom_value_for(custom_field)
        end
      end
    end
  end
end
