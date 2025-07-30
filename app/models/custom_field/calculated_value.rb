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

# Methods for custom fields with a format of "calculated value".
# Should be included in the CustomField model.
module CustomField::CalculatedValue
  extend ActiveSupport::Concern

  # Mathematical operators that are allowed in the formula.
  MATH_OPERATORS_FOR_FORMULA = %w[+ - * / % ( )].freeze

  # Field formats that can be used within a formula.
  FIELD_FORMATS_FOR_FORMULA = %w[int float calculated_value].freeze

  included do
    validate :validate_formula, if: :field_format_calculated_value?
    validate :validate_referenced_custom_fields_allowed, if: :field_format_calculated_value?

    def validate_formula
      if formula_string.blank?
        errors.add(:formula, :blank)
        return
      end

      unless formula_contains_only_allowed_characters?
        errors.add(:formula, :invalid_characters)
        return
      end

      unless valid_formula_syntax?
        errors.add(:formula, :invalid)
      end
    end

    def formula=(value)
      if value.is_a?(String)
        super({ formula: value, referenced_custom_fields: cf_ids_used_in_formula(value) })
      else
        super
      end
    end

    # Returns the formula as a string. Will return an empty string if the formula is not set.
    def formula_string
      formula ? formula.fetch("formula", "") : ""
    end

    def usable_custom_field_references_for_formula
      self.class
        .where(field_format: FIELD_FORMATS_FOR_FORMULA)
        # Disallow the current custom field to avoid circular references
        .where.not(id: id)
        .visible
    end

    def validate_referenced_custom_fields_allowed
      # We can only validate used custom fields from a high-level perspective, since at this point in validation,
      # we do not have a project context to check against. So we cannot check if the custom fields are actually
      # enabled for a project and visible to a non-admin user.
      formula_cfs = cf_ids_used_in_formula(formula_string)
      allowed_cfs = usable_custom_field_references_for_formula.pluck(:id)

      surplus_cfs = formula_cfs - allowed_cfs

      if surplus_cfs.any?
        custom_field_names = CustomField.where(id: surplus_cfs).pluck(:name)
        errors.add(:formula, :invalid_custom_fields, custom_fields: custom_field_names.join(", "))
      end
    end

    private

    def calculator
      Dentaku::Calculator.new(case_sensitive: true)
    end

    def valid_formula_syntax?
      # Attempt to parse the formula. If no error is returned, the formula is syntactically valid.
      calculator.ast(formula_str_without_patterns)
      true
    rescue Dentaku::ParseError, Dentaku::TokenizerError
      false
    end

    def formula_contains_only_allowed_characters?
      # List of allowed characters in a formula. This only performs a very basic validation.
      # The allowed characters are:
      # Our mathematical operators, whitespace, digits and decimal points
      # Additionally, the formula may contain references to custom fields in the form of `{{cf_123}}`
      # where 123 is the ID of the custom field.
      # Once this basic validation passes, the formula will be parsed and validated by Dentaku, which builds an AST
      # and ensures that the formula is really valid. A welcome side effect of the basic validation done here is that
      # it prevents built-in functions from being used in the formula, which we do not want to allow.
      allowed_chars = MATH_OPERATORS_FOR_FORMULA + [" "]
      allowed_tokens = /\A(\{\{cf_\d+}}|\d+\.?\d*|\.\d+)\z/

      formula_string.split(Regexp.union(allowed_chars)).reject(&:empty?).all? do |token|
        token.match?(allowed_tokens)
      end
    end

    # Returns a list of custom field IDs used in the formula.
    # For a formula like `2 + {{cf_12}} + {{cf_4}}` it returns `[12, 4]`.
    def cf_ids_used_in_formula(formula_str)
      formula_str.scan(/\{\{cf_(\d+)}}/).flatten.compact.map(&:to_i)
    end

    # Returns `formula_string` with all custom field references detokenized so that they are parseable by Dentaku.
    # For example, for `2 + {{cf_12}} + {{cf_4}}` it returns `2 + cf_12 + cf_4`.
    def formula_str_without_patterns
      formula_string.gsub(/\{\{(cf_\d+)}}/, '\1')
    end
  end
end
