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

    # @!macro format_text_options
    #   @param [Hash] options a customizable set of options.
    #   @option options [Project] :project (@project, object#project)
    #     a Project context.
    #   @option options [Boolean] :only_path (true)
    #     whether to generate links with relative URLs.
    #   @option options [User] :current_user (User.current)
    #     the current user context.
    #   @option options [:plain, :rich] :format (:rich)
    #     the text format.
    #     `:plain` will return plain text.
    #     `:rich` will render raw Markdown as HTML.

    ##
    # Formats text according to system settings and provided options.
    #
    # @overload format_text(text, options = {})
    #   @param [String] text the raw text to be formatted, typically Markdown.
    #   @macro format_text_options
    #   @option options [Object] :object an object context.
    #
    #   @example Setting a project context explicitly
    #     format_text("## Hello world", project: current_project)
    #   @example Generating links with full URLs
    #     format_text("[Projects](/projects)", only_path: false)
    #
    # @overload format_text(object, attribute, options = {})
    #   @param [Object] object an object, typically a model
    #     (i.e. `ActiveRecord::Base` descendent).
    #   @param [Symbol] attribute the method on that object.
    #     `#to_s` will be called on the return value.
    #   @macro format_text_options
    #
    #   @example
    #     format_text(issue, :description, options)
    #
    # @return [String] the formatted text as an HTML-safe String.
    def format_text(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      case args.size
      when 1
        attribute = nil
        object = options[:object]
        text = args.shift
      when 2
        object = args.shift
        attribute = args.shift
        text = object.send(attribute).to_s
      else
        raise ArgumentError, "invalid arguments to format_text"
      end
      return "" if text.blank?

      project = options.delete(:project) { @project || object.try(:project) }
      only_path = options.delete(:only_path) != false
      current_user = options.delete(:current_user) { User.current }

      plain = ::OpenProject::TextFormatting::Formats.plain?(options.delete(:format))

      Renderer.format_text text,
                           options.merge(
                             plain:,
                             object:,
                             request: try(:request),
                             current_user:,
                             attribute:,
                             only_path:,
                             project:
                           )
    end
  end
end
