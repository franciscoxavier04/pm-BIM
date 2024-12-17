# frozen_string_literal: true

#-- copyright
#++

module Types
  class PatternMapper
    TOKEN_REGEX = /{{[A-z_]+}}/

    MAPPING = {
      assignee: ->(wp) { wp.assigned_to.name },
      created: ->(wp) { wp.created_at },
      author: ->(wp) { wp.author.name }
    }.freeze

    private_constant :MAPPING

    def initialize(pattern)
      @pattern = pattern
      @tokens = pattern.scan(TOKEN_REGEX).map { |token| Patterns::Token.new(token) }
    end

    def valid?(work_package)
      @tokens.each { |token| fn(token.key).call(work_package) }
    rescue NoMethodError
      false
    end

    def resolve(work_package)
      @tokens.inject(@pattern) do |pattern, token|
        value = fn(token.key).call(work_package)
        pattern.gsub(token.pattern, stringify(value))
      end
    end

    private

    def fn(key)
      MAPPING.fetch(key) { ->(wp) { wp.public_send(key.to_sym) } }
    end

    def stringify(value)
      case value
      when Date, Time, DateTime
        value.strftime("%Y-%m-%d")
      else
        value.to_s
      end
    end
  end
end
