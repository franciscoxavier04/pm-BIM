# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

module Admin
  module TimeEntryActivities
    class IndexComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      options :time_entry_activities

      private

      def max_activity_position
        time_entry_activities.map(&:position).max
      end

      def wrapper_data_attributes
        {
          controller: "generic-drag-and-drop",
          "application-target": "dynamic"
        }
      end

      def drop_target_config
        {
          "is-drag-and-drop-target": true,
          "target-container-accessor": "& > ul",
          "target-allowed-drag-type": "time-entry-activity"
        }
      end

      def draggable_item_config(activity)
        {
          "draggable-id": activity.id,
          "draggable-type": "time-entry-activity",
          "drop-url": move_admin_time_entry_activity_path(activity)
        }
      end
    end
  end
end
