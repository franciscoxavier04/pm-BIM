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

class Meeting::Participant < ApplicationForm
  form do |participant_form|
    participant_form.autocompleter(
      name: :user_id,
      label: MeetingParticipant.model_name.human,
      visually_hide_label: true,
      autocomplete_options: {
        defaultData: true,
        component: "opce-user-autocompleter",
        url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
        filters:,
        searchKey: "any_name_attribute",
        resource: "principals",
        focusDirectly: true,
        multiple: false,
        isOpenedInModal: true,
        hoverCards: true,
        placeholder: I18n.t("meeting.participants.text.search_for_members"),
        data: {
          "test-selector": "participants-dialog-autocomplete"
        }
      }
    )
  end

  private

  def excluded_ids
    @excluded_ids ||= @builder.object.meeting.participants.filter_map(&:user_id)
  end

  def filters
    list = [
      { name: "type", operator: "=", values: %w[User] },
      { name: "member", operator: "=", values: [@builder.object.meeting.project_id] },
      { name: "status", operator: "=", values: [Principal.statuses[:active], Principal.statuses[:invited]] }
    ]

    list << { name: "id", operator: "!", values: excluded_ids } if excluded_ids.any?

    list
  end
end
