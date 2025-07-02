# frozen_string_literal: true

# --copyright
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

module InternalVisibleExtension
  # AR Association Extension that filters internal comments based on the project's feature setting
  # and the user's permissions.
  #
  # @example
  #   class WorkPackage < ApplicationRecord
  #     has_many :activities, class_name: "WorkPackageActivity", extension: InternalVisibleExtension
  #   end
  #
  #   work_package = WorkPackage.first
  #   work_package.activities.internal_visible
  #   # => #<ActiveRecord::Relation [#<WorkPackageActivity id: 1, ...>]>
  #
  # @see https://guides.rubyonrails.org/association_basics.html#extensions
  #
  # @return [ActiveRecord::Relation] The relation with the internal comments filtered.
  #
  def internal_visible
    if proxy_association.owner.project.enabled_internal_comments &&
        User.current.allowed_in_project?(:view_internal_comments, proxy_association.owner.project)
      all
    else
      where(internal: false)
    end
  end
end
