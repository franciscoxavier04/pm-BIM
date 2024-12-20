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
  class PatternMapper
    TOKEN_REGEX = /{{[0-9A-Za-z_]+}}/

    MAPPING = {
      type: ->(wp) { wp.type.name },
      assignee: ->(wp) { wp.assigned_to&.name },
      created: ->(wp) { wp.created_at },
      author: ->(wp) { wp.author.name },
      parent_id: ->(wp) { wp.parent&.id },
      project_name: ->(wp) { wp.project.name }
    }.freeze

    private_constant :MAPPING

    def initialize(pattern)
      @pattern = pattern
      @tokens = pattern.scan(TOKEN_REGEX).map { |token| Patterns::Token.build(token) }
    end

    def valid?(work_package)
      @tokens.each { |token| get_value(work_package, token) }
    rescue NoMethodError
      false
    end

    def resolve(work_package)
      @tokens.inject(@pattern) do |pattern, token|
        pattern.gsub(token.pattern, get_value(work_package, token))
      end
    end

    private

    def get_value(work_package, token)
      raw_value = if token.custom_field? && token.context != work_package.context
                    fn(key).call(work_package.public_send(token.context))
                  else
                    fn(token.key).call(work_package)
                  end

      stringify(raw_value)
    end

    def fn(key)
      MAPPING.fetch(key) { ->(wp) { wp.public_send(key.to_sym) } }
    end

    def stringify(value)
      case value
      when Date, Time, DateTime
        value.strftime("%Y-%m-%d")
      when NilClass
        "N/A"
      else
        value.to_s
      end
    end
  end
end
