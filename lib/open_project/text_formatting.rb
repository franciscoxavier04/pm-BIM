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

module OpenProject
  # This module provides high-level text formatting functionality.
  #
  # @!method request
  #   Expected to be defined in the including class.
  #   @return [ActionDispatch::Request] the current request context.
  #
  # @note
  #   The including class should implement {#request} if {#format_text} is
  #   called within a request cycle.
  module TextFormatting
    include ::OpenProject::TextFormatting::Truncation

    # @!macro format_text_params
    #   @param [Project] project a Project context.
    #   @param [Boolean] only_path whether to generate links with relative URLs.
    #   @param [User] current_user the current user context.
    #   @param [:plain, :rich] format the text format.
    #     `:plain` will return plain text.
    #     `:rich` will render raw Markdown as HTML.
    #   @param ** [Hash] additional context to pass to the underlying rendering
    #      pipeline.

    # rubocop:disable Layout/LineLength

    ##
    # Formats text according to system settings and provided params.
    #
    # @overload format_text(text, object: nil, project: @project || object.try(:project), only_path: true, current_user: User.current, format: :rich, **)
    #
    #   @param [String] text the raw text to be formatted, typically Markdown.
    #   @param [Object] object an object context.
    #   @macro format_text_params
    #
    #   @example Setting a project context explicitly
    #     format_text("## Hello world", project: current_project)
    #   @example Generating links with full URLs
    #     format_text("[Projects](/projects)", only_path: false)
    #
    # @overload format_text(object, attribute, project: @project || object.try(:project), only_path: true, current_user: User.current, format: :rich, **)
    #
    #   @param [Object] object an object, typically a model
    #     (i.e. `ActiveRecord::Base` descendent).
    #   @param [Symbol] attribute the method on that object.
    #     `#to_s` will be called on the return value.
    #   @macro format_text_params
    #
    #   @example
    #     format_text(issue, :description, options)
    #
    # @return [String] the formatted text as an HTML-safe String.
    def format_text(*args, object: nil, project: nil, only_path: true, current_user: User.current, format: :rich, **)
      case args.size
      when 1
        attribute = nil
        text = args.first
      when 2
        object, attribute = args
        text = object.public_send(attribute).to_s
      else
        raise ArgumentError, "invalid arguments to format_text"
      end
      return "" if text.blank?

      project ||= @project || object.try(:project)
      plain = Formats.plain?(format)

      Renderer.format_text(
        text,
        **,
        plain:,
        object:,
        request: try(:request),
        current_user:,
        attribute:,
        only_path:,
        project:
      )
    end
    # rubocop:enable Layout/LineLength
  end
end
