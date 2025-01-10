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

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class Autocompleter < Primer::Forms::BaseComponent
        include AngularHelper
        prepend WrappedInput

        delegate :builder, :form, to: :@input

        def initialize(input:, autocomplete_options:, wrapper_data_attributes: {})
          super()
          @input = input
          @with_search_icon = autocomplete_options.delete(:with_search_icon) { false }
          @autocomplete_component = autocomplete_options.delete(:component) { "opce-autocompleter" }
          @autocomplete_data = autocomplete_options.delete(:data) { {} }
          @autocomplete_inputs = extend_autocomplete_inputs(autocomplete_options)
          @wrapper_data_attributes = wrapper_data_attributes
        end

        def extend_autocomplete_inputs(inputs) # rubocop:disable Metrics/AbcSize
          inputs[:classes] = "ng-select--primerized #{@input.invalid? ? '-error' : ''}"
          inputs[:inputName] ||= builder.field_name(@input.name)
          inputs[:labelForId] ||= builder.field_id(@input.name)
          inputs[:defaultData] = true unless inputs.key?(:defaultData)

          if inputs.delete(:decorated)
            inputs[:items] = @input.select_options.map(&:to_h)
            selected = @input.select_options.filter_map { |option| option.to_h if option.selected }
            inputs[:model] = inputs[:multiple] ? selected : selected.first
            inputs[:defaultData] = false
            inputs[:bindLabel] = "name"
          elsif builder.object
            inputs[:inputValue] ||= builder.object.send(@input.name)
          end

          inputs
        end
      end
    end
  end
end
