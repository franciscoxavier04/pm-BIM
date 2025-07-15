# frozen_string_literal: true

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
module Projects
  module Settings
    class TypeForm < ApplicationForm
      form do |f|
        if model.new_record?
          # Hide the type field when creating a new project, as the type is determined via GET parameter.
          f.hidden(name: :project_type)
        else
          # Offer changing the type of existing projects when editing them. Otherwise, there would be no way
          # for users to change the type of project.
          f.select_list(
            name: :project_type,
            label: attribute_name(:project_type)
          ) do |list|
            Project.project_types.each_key do |label|
              list.option(label: I18n.t("activerecord.attributes.project.project_type_enum.#{label}"), value: label)
            end
          end
        end
      end
    end
  end
end
