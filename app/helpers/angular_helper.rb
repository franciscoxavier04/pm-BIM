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

module AngularHelper
  ##
  # Create a component element tag with the given attributes
  #
  # Allow setting dynamic inputs for components with the populateInputsFromDataset functionality
  # by using inputs: { inputName: value }
  def angular_component_tag(component, options = {})
    inputs = angular_component_inputs(options.delete(:inputs) || {})

    options[:data] = options.fetch(:data, {}).merge(inputs)
    options[:class] ||= "op-angular-component"

    content_tag(component, nil, options)
  end

  ##
  # Transforms inputs to interop with the `populateInputsFromDataset`.
  #
  # @param inputs [Hash{String=>Object}] a hash of input properties.
  #   Keys will be converted to kebab-cased strings, prefixed with `data-`.
  #   Values will be serialized as JSON.
  # @return [Hash{String=>String}] a new hash with transformed properties.
  def angular_component_inputs(inputs)
    inputs.each_with_object({}) { |(k, v), h| h[k.to_s.underscore.dasherize] = v.to_json }
  end
end
