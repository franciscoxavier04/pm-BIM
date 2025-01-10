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

class WorkPackages::StatusButtonComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(work_package:, user:, readonly: false, button_arguments: {}, menu_arguments: {})
    super

    @work_package = work_package
    @user = user
    @status = work_package.status
    @project = work_package.project

    @readonly = readonly
    @menu_arguments = menu_arguments
    @button_arguments = button_arguments.merge({ classes: "__hl_background_status_#{@status.id}" })

    @items = available_statusses
  end

  def button_title
    I18n.t("js.label_edit_status")
  end

  def disabled?
    !@user.allowed_in_project?(:edit_work_packages, @project)
  end

  def readonly?
    @status.is_readonly?
  end

  def button_arguments
    { title: button_title,
      disabled: disabled?,
      aria: {
        label: button_title
      } }.deep_merge(@button_arguments)
  end

  def available_statusses
    WorkPackages::UpdateContract.new(@work_package, @user)
                                .assignable_statuses
  end
end
