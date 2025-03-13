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

module ColorsHelper
  include Primer::JoinStyleArgumentsHelper

  def options_for_colors(colored_thing)
    colors = []
    Color.find_each do |c|
      options = {}
      options[:name] = c.name
      options[:value] = c.id
      options[:selected] = true if c.id == colored_thing.color_id

      colors.push(options)
    end
    colors.to_json
  end

  def selected_color(colored_thing)
    colored_thing.color_id
  end

  #
  # Styles to display the color of attributes (type, status etc.) for example in the WP view
  ##
  def resource_color_css(name, scope)
    if scope != Color
      scope = scope.includes(:color)
    end

    scope.all.map do |entry|
      color = entry.is_a?(::Color) ? entry : entry.color

      if color.nil?
        ".#{hl_color_class(name, entry)} { display: none }"
      else

        ".#{hl_color_class(name, entry)} { #{default_color_styles(color.hexcode)} #{theme_variables} }"
      end
    end.join("\n")
  end

  def theme_variables
    mode = User.current.pref.theme.split("_", 2)[0]
    if mode == "dark"
      default_variables_dark
    else
      default_variables_light
    end
  end

  def background_color_css
    mode = User.current.pref.theme.split("_", 2)[0]

    if mode == "dark"
      ".__hl_background { #{highlighted_background_dark} }"
    else
      ".__hl_background { #{highlighted_background_light} }"
    end

    set_background_colors_for(class_name: ".#{hl_background_class(name, entry)}", color:)
  end

  def foreground_color_css
    mode = User.current.pref.theme.split("_", 2)[0]

    if mode == "dark"
      ".__hl_foreground { #{highlighted_foreground_dark} }"
    else
      ".__hl_foreground { #{highlighted_foreground_light} }"
    end
  end

  def hl_color_class(name, model)
    "__hl_#{name}_#{model.id}"
  end

  def icon_for_color(color, options = {})
    return unless color
    return if color.hexcode.blank?

    style = join_style_arguments(
      "background-color: #{color.hexcode}",
      "border-color: #{color.darken(0.5)}50",
      options[:style]
    )

    options.merge!(class: "color--preview #{options[:class]}",
                   title: color.name,
                   style:)

    content_tag(:span, " ", options)
  end

  def color_by_variable(variable)
    DesignColor.find_by(variable:)&.hexcode
  end

  def default_color_styles(hex)
    color = ColorConversion::Color.new(hex)
    rgb = color.rgb
    hsl = color.hsl

    <<~CSS.squish
      --color-r: #{rgb[:r]};
      --color-g: #{rgb[:g]};
      --color-b: #{rgb[:b]};
      --color-h: #{hsl[:h]};
      --color-s: #{hsl[:s]};
      --color-l: #{hsl[:l]};
      --perceived-lightness: calc( ((var(--color-r) * 0.2126) + (var(--color-g) * 0.7152) + (var(--color-b) * 0.0722)) / 255 );
      --lightness-switch: max(0, min(calc((1/(var(--lightness-threshold) - var(--perceived-lightness)))), 1));
    CSS
  end

  def default_variables_dark
    <<~CSS.squish
      --lightness-threshold: 0.6;
      --background-alpha: 0.18;
      --lighten-by: calc(((var(--lightness-threshold) - var(--perceived-lightness)) * 100) * var(--lightness-switch));
    CSS
  end

  def default_variables_light
    <<~CSS.squish
      --lightness-threshold: 0.453;
    CSS
  end

  def highlighted_background_dark
    <<~CSS.squish
      color: hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%)) !important;
      background: rgba(var(--color-r), var(--color-g), var(--color-b), var(--background-alpha)) !important;
      border: 1px solid hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%)) !important;
    CSS
  end

  def highlighted_background_light
    mode = User.current.pref.theme
    border_adjustment_factor = (mode == "light_high_contrast" ? 75 : 15)

    <<~CSS.squish
      color: hsl(0deg, 0%, calc(var(--lightness-switch) * 100%)) !important;
      background: rgb(var(--color-r), var(--color-g), var(--color-b)) !important;
      border: 1px solid hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - #{border_adjustment_factor}) * 1%)) !important;
    CSS
  end

  def highlighted_foreground_dark
    <<~CSS.squish
      color: hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%), 1) !important;
    CSS
  end

  def highlighted_foreground_light
    mode = User.current.pref.theme
    color_adjustment_factor = (mode == "light_high_contrast" ? 0.5 : 0.22)

    <<~CSS.squish
      color: hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - (var(--color-l) * #{color_adjustment_factor})) * 1%), 1) !important;
    CSS
  end
end
