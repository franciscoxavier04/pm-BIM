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

module Overviews
  module ProjectPhases
    class ItemComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers

      private

      def not_set?
        model.not_set?
      end

      def icon
        :"op-phase"
      end

      def icon_color_class
        helpers.hl_inline_class("project_phase_definition", model.definition)
      end

      def text
        model.name
      end

      def authorized_edit_link
        if allowed_to_edit?
          Primer::Beta::Link.new(
            href: edit_project_phase_path(model),
            data: { controller: "async-dialog" },
            aria: { label: I18n.t(:label_edit) },
            test_selector: "project-life-cycle-edit-button-#{model.id}",
            underline: false
          )
        else
          Primer::Content.new
        end
      end

      def allowed_to_edit?
        User.current.allowed_in_project?(:edit_project_phases, model.project)
      end
    end
  end
end
