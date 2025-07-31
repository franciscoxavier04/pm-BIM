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
      include ApplicationHelper
      include TypesHelper

      def column_css_classes
        super.merge(
          name: "timelines-pet-name",
          color: "timelines-pet-color",
          default: "timelines-pet-is_default",
          milestone: "timelines-pet-is_milestone",
          sort: "timelines-pet-reorder"
        )
      end

      def name
        link_to model.name, edit_type_settings_path(type_id: model.id)
      end

      def workflow_warning
        return unless model.workflows.empty?

        safe_join([
                    op_icon("icon3 icon-warning"),
                    t(:text_type_no_workflow),
                    " (",
                    link_to(t(:button_edit), edit_workflows_path(type: model)),
                    ")"
                  ])
      end

      def color
        icon_for_type model
      end

      def default
        checked_image model.is_default
      end

      def milestone
        checked_image model.is_milestone
      end

      def sort
        helpers.reorder_links("type", { action: "move", id: model })
      end

      def button_links
        [delete_link]
      end

      def delete_link
        return if model.is_standard?

        link_to(
          "",
          model,
          turbo_method: :delete,
          data: { turbo_confirm: t(:text_are_you_sure) },
          class: "icon icon-delete",
          title: t(:button_delete)
        )
      end
    end
  end
end
