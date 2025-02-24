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

module Admin
  module TimeEntryActivities
    class ReassignForm < ApplicationForm
      include OpenProject::StaticRouting::UrlHelpers

      attr_reader :other_activities

      def initialize(other_activities:)
        super()

        @other_activities = other_activities
      end

      form do |form|
        form.select_list(
          name: :reassign_to_id,
          label: I18n.t(:text_enumeration_category_reassign_to),
          required: true,
          input_width: :large
        ) do |select|
          other_activities.each do |activity|
            select.option(value: activity.id, label: activity.name)
          end
        end

        form.group(layout: :horizontal) do |button_group|
          button_group.button(name: :cancel,
                              tag: :a,
                              label: I18n.t(:button_cancel),
                              scheme: :default,
                              href: admin_time_entry_activities_path)
          button_group.submit(name: :submit, label: I18n.t(:button_apply), scheme: :primary)
        end
      end
    end
  end
end
