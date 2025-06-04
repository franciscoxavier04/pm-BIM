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

require "work_packages/create_contract"

module WorkPackages
  class CopyContract < CreateContract
    # As % Complete can be set while Work and Remaining work are not, copying is
    # a scenario where this field must be writable
    attribute :done_ratio,
              writable: true

    # Overriding the definition in the CreateContract to allow copying based on the default
    # permission of :add_work_packages.
    attribute :project_phase_definition_id,
              writable: ->(*) {
                OpenProject::FeatureDecisions.stages_and_gates_active?
              },
              permission: :add_work_packages

    # Do not validate predecessors or children presence when copying: when
    # copying, it's possible to create a work package in automatic scheduling
    # mode even if it has no predecessors or children yet. They will be added
    # later in the process.
    def validate_has_predecessors_or_children; end

    # No validation happening on whether the phase is active in the project.
    # When copying a work package, e.g. from a project template, the phase
    # might not be active in the project yet. But when it is activated later,
    # the value should then be present.
    def validate_phase_active_in_project; end
  end
end
