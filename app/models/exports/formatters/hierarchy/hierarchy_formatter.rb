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

module Exports
  module Formatters
    module Hierarchy
      class HierarchyFormatter
        def format(object, custom_field)
          cvs = object.custom_value_for(custom_field)
          case cvs
          when Array
            cvs.map { |item| format_hierarchy_item_for_export(item) }.join(", ")
          when CustomValue
            format_hierarchy_item_for_export(cvs)
          else
            cvs
          end
        end

        def format_hierarchy_item_for_export(item_value)
          item = ::CustomField::Hierarchy::Item.find_by(id: item_value.to_s)
          return "#{item_value} #{I18n.t(:label_not_found)}" if item.nil?

          item.ancestry_path
        end

        def hierarchy_item_service
          ::CustomFields::Hierarchy::HierarchicalItemService.new
        end
      end
    end
  end
end
