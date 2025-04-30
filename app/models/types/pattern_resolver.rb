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
  class PatternResolver
    TOKEN_REGEX = /{{[0-9A-Za-z_]+}}/
    ATTRIBUTE_PLACEHOLDER = "N/A"

    def initialize(pattern)
      @mapper = Patterns::TokenPropertyMapper.new
      @pattern = pattern
      @tokens = pattern.scan(TOKEN_REGEX).map { |token| Patterns::Token.build(token) }
    end

    def resolve(work_package)
      @token_resolver = @mapper.tokens_for_type(work_package.type)

      @tokens.inject(@pattern) do |pattern, token|
        pattern.gsub(token.pattern, get_value(work_package, token))
      end
    end

    private

    def get_value(work_package, token)
      context = token.context == :work_package ? work_package : work_package.public_send(token.context)
      return ATTRIBUTE_PLACEHOLDER if context.nil?

      attribute_resolver = @token_resolver.detect { |t| t.key == token.key }
      return ATTRIBUTE_PLACEHOLDER if attribute_resolver.nil?

      stringify(attribute_resolver.call(context), nil_replacement(attribute_resolver))
    end

    def nil_replacement(attribute_resolver)
      if attribute_resolver.context == :work_package
        "[#{attribute_resolver.label}]"
      else
        "[#{attribute_resolver.label_with_context}]"
      end
    end

    def stringify(value, nil_fallback)
      case value
      when Date, Time, DateTime
        value.strftime("%Y-%m-%d")
      when Array
        compact = value.compact
        compact.empty? ? nil_fallback : compact.join(", ")
      when NilClass
        nil_fallback
      when :attribute_not_available
        ATTRIBUTE_PLACEHOLDER
      else
        value.to_s
      end
    end
  end
end
