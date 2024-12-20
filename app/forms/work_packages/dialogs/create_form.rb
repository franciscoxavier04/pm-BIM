# -- copyright
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
# ++

module WorkPackages::Dialogs
  class CreateForm < ApplicationForm
    attr_reader :work_package, :wrapper_id, :contract

    def initialize(work_package:, wrapper_id:)
      super()

      @work_package = work_package
      @wrapper_id = wrapper_id
      @contract = WorkPackages::CreateContract.new(work_package, User.current)
    end

    form do |f|
      f.autocompleter(
        name: :type_id,
        required: true,
        include_blank: false,
        input_width: :small,
        label: Type.model_name.human,
        visually_hide_label: true,
        autocomplete_options: {
          multiple: false,
          decorated: true,
          append_to: "##{wrapper_id}"
        }
      ) do |select|
        contract
          .assignable_types
          .pluck(:id, :name)
          .map { |value, label| select.option(label:, value:) }
      end

      f.text_field(
        name: :subject,
        label: WorkPackage.human_attribute_name(:subject),
        required: true,
        input_width: :large
      )

      f.rich_text_area(
        name: :description,
        label: MeetingAgendaItem.human_attribute_name(:description),
        rich_text_options: {
          resource: work_package,
          showAttachments: false
        }
      )

      work_package.changes.each do |attribute, value|
        f.hidden(name: attribute, value:)
      end
    end
  end
end
