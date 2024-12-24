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

module Types
  module Patterns
    class TokenPropertyMapper
      MAPPING = {
        accountable: ->(wp) { wp.responsible&.name },
        assignee: ->(wp) { wp.assigned_to&.name },
        author: ->(wp) { wp.author&.name },
        category: ->(wp) { wp.category&.name },
        creation_date: ->(wp) { wp.created_at },
        estimated_time: ->(wp) { wp.estimated_hours },
        finish_date: ->(wp) { wp.due_date },
        parent: ->(wp) { wp.parent&.id },
        parent_author: ->(wp) { wp.parent&.author&.name },
        parent_category: ->(wp) { wp.parent&.category&.name },
        parent_creation_date: ->(wp) { wp.parent&.created_at },
        parent_estimated_time: ->(wp) { wp.parent&.estimated_hours },
        parent_finish_date: ->(wp) { wp.parent&.due_date },
        parent_priority: ->(wp) { wp.parent&.priority },
        priority: ->(wp) { wp.priority },
        project: ->(wp) { wp.project_id },
        project_active: ->(wp) { wp.project&.active? },
        project_name: ->(wp) { wp.project&.name },
        project_status: ->(wp) { wp.project&.status_code },
        project_parent: ->(wp) { wp.project&.parent_id },
        project_public: ->(wp) { wp.project&.public? },
        start_date: ->(wp) { wp.start_date },
        status: ->(wp) { wp.status&.name },
        type: ->(wp) { wp.type&.name }
      }.freeze

      def fetch(key)
        MAPPING.fetch(key) { ->(context) { context.public_send(key.to_sym) } }
      end

      alias :[] :fetch

      def tokens_for_type(_type)
        []
        # Fetch all CustomFields for type
        # Fetch all customFields prefixed as parent
        # fetch all project attributes prefixed as project
      end
    end
  end
end
