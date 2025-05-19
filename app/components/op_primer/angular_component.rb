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
#
module OpPrimer
  class AngularComponent < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
    include AngularHelper

    ##
    # Creates a component element tag with the given attributes.
    #
    # @param tag [Symbol] the tag name of the Angular component.
    # @param inputs [Hash{String=>Object}] a hash of input properties.
    #   Keys will be converted to kebab-cased strings, prefixed with `data-`.
    #   Values will be serialized as JSON.
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(tag:, inputs: {}, **system_arguments)
      @system_arguments = system_arguments
      @system_arguments[:tag] = tag
      @system_arguments[:classes] = class_names(
        system_arguments[:classes],
        "op-angular-component"
      )
      @system_arguments[:data] = merge_data(
        system_arguments,
        data: angular_component_inputs(inputs)
      )

      super
    end

    def call
      render(Primer::BaseComponent.new(**@system_arguments))
    end
  end
end
