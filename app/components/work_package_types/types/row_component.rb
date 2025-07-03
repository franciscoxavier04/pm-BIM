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

module WorkPackageTypes
  module Types
    class RowComponent < ::RowComponent
      with_collection_parameter :type

      include ApplicationHelper
      include TypesHelper

      attr_reader :type

      def initialize(type:, table:)
        super(row: type, table: table)
        @type = type
        @table = table
      end

      def name
        link_to type.name, edit_type_settings_path(type_id: type.id)
      end

      def workflow_warning
        return unless type.workflows.empty?

        safe_join([
                    op_icon("icon3 icon-warning"),
                    t(:text_type_no_workflow),
                    " (",
                    link_to(t(:button_edit), edit_workflows_path(type: type)),
                    ")"
                  ])
      end

      def color
        icon_for_type type
      end

      def default
        checked_image(type.is_default)
      end

      def milestone
        checked_image(type.is_milestone)
      end

      def sort
        helpers.reorder_links("type", { action: "move", id: type })
      end

      def model
        @type
      end

      def button_links
        [delete_link]
      end

      def delete_link
        return if type.is_standard?

        link_to(
          "",
          type,
          method: :delete,
          data: { confirm: t(:text_are_you_sure) },
          class: "icon icon-delete",
          title: t(:button_delete)
        )
      end
    end
  end
end
