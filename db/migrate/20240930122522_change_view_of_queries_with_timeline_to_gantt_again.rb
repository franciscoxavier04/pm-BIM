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

require_relative "20231201085450_change_view_of_queries_with_timeline_to_gantt"

# Inherit from the original migration `ChangeViewOfQueriesWithTimelineToGantt`
# to avoid duplicating it.
#
# The original migration was fine, but it was applied too early: in OpenProject
# 13.2.0 the migration would already have been run and it was still possible to
# create Gantt queries inside the work packages module. Such queries were not
# migrated.
#
# This was registered as bug #56769.
#
# This migration runs the original migration again to ensure all queries
# displayed as Gantt charts are displayed in the right module.
class ChangeViewOfQueriesWithTimelineToGanttAgain < ChangeViewOfQueriesWithTimelineToGantt
end
