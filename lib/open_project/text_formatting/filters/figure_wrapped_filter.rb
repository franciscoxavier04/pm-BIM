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

module OpenProject::TextFormatting
  module Filters
    class FigureWrappedFilter < HTMLPipeline::NodeFilter
      include ActionView::Context
      include ActionView::Helpers::TagHelper

      SELECTOR = Selma::Selector.new(match_element: %(table,img))

      def selector
        SELECTOR
      end

      def handle_element(element)
        p "HGTM"
        p @doc
        p @html
        wrap_element(element)
        p "after"
        p @doc
        p @html
      end

      def call(*)
        super
        p "HTML"
        p @html
        doc.to_html
      end

      private

      # Wrap img elements like this
      # <figure>
      #   <div class="op-uc-figure--content">
      #     <img></img>
      #   </div>
      # <figure>
      #
      # and
      #
      # <figure>
      #   <div class="op-uc-figure--content">
      #     <table></table>
      #   </div>
      # <figure>

      # The figure and img/table element later on get css classes applied to them so it does
      # not have to happen here.
      def wrap_element(element)
        wrap_in_figure(element) # unless has_ancestor?(element, "figure")
        wrap_in_div(element) # unless has_ancestor?(element, "div")
      end

      def wrap_in_figure(element)
        element.before("<figure>", as: :html)
        element.after("</figure>", as: :html)
      end

      def wrap_in_div(element)
        foo = element.before(%(<div class="op-uc-figure--content">), as: :html)
        element.after("</div>", as: :html)
      end
    end
  end
end
