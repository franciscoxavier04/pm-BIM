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

module Settings
  module ProjectWorkPackages
    class HeaderComponent < ApplicationComponent
      def initialize(project, selected:)
        super
        @project = project
        @selected = selected
      end

      def breadcrumbs_items
        [{ href: project_overview_path(@project.id), text: @project.name },
         { href: project_settings_general_path(@project.id), text: I18n.t("label_project_settings") },
         t(:label_work_package_plural)]
      end

      def selected?(key)
        @selected == key
      end

      def show_types?
        User.current.allowed_in_project?(:manage_types, @project)
      end

      def show_categories?
        User.current.allowed_in_project?(:manage_categories, @project)
      end

      def show_custom_fields?
        User.current.allowed_in_project?(:select_custom_fields, @project)
      end
    end
  end
end
