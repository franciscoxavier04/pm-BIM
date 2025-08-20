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

module ::Webhooks
  module Outgoing
    module Webhooks
      class RowComponent < ::RowComponent
        property :description

        def webhook
          model
        end

        def name
          link_to webhook.name,
                  { controller: table.target_controller, action: :show, webhook_id: webhook.id }
        end

        def enabled
          if webhook.enabled?
            helpers.op_icon "icon-yes"
          end
        end

        def events
          selected_events =
            webhook
              .events
              .pluck(:name)
              .map(&method(:lookup_event_name))
              .compact
              .uniq

          count = selected_events.count
          if count <= 3
            selected_events.join(", ")
          else
            content_tag("span", count, class: "badge")
          end
        end

        def lookup_event_name(name)
          OpenProject::Webhooks::EventResources.lookup_resource_name(name)
        end

        def selected_projects
          if webhook.all_projects?
            return "(#{I18n.t(:label_all)})"
          end

          selected = webhook.projects.map(&:name)

          if selected.empty?
            "(#{I18n.t(:label_all)})"
          elsif selected.size <= 3
            webhook.projects.pluck(:name).join(", ")
          else
            content_tag("span", selected, class: "badge")
          end
        end

        def row_css_class
          [
            "webhooks--outgoing-webhook-row",
            "webhooks--outgoing-webhook-row-#{model.id}"
          ].join(" ")
        end

        ###

        def button_links
          [edit_link, delete_link]
        end

        def edit_link
          link_to(
            helpers.op_icon("icon icon-edit button--link"),
            { controller: table.target_controller, action: :edit, webhook_id: webhook.id },
            title: t(:button_edit)
          )
        end

        def delete_link
          link_to(
            helpers.op_icon("icon icon-delete button--link"),
            { controller: table.target_controller, action: :destroy, webhook_id: webhook.id },
            method: :delete,
            data: { confirm: I18n.t(:text_are_you_sure) },
            title: t(:button_delete)
          )
        end
      end
    end
  end
end
