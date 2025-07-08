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

require "will_paginate"

module PaginationHelper
  SHOW_MORE_DEFAULT_LIMIT = 5
  SHOW_MORE_DEFAULT_INCREMENT = 20
  SHOW_MORE_MAX_LIMIT = 1000

  def pagination_links_full(paginator, params: {}, allowed_params: nil, per_page_links: true, **)
    return unless paginator.total_entries > 0

    content_tag(:div, class: "op-pagination") do
      concat pagination_pages_section(paginator, renderer: LinkRenderer, params:, allowed_params:, **)
      concat pagination_options_section(paginator, params:, allowed_params:) if per_page_links
    end
  end

  # Returns page option used for pagination
  # based on:
  #  * offset
  #  * limit
  #  * page
  #  parameters.
  #  Prefers page over the other two and
  #  calculates page in its absence based on limit and offset.
  #  Return 1 if all else fails.
  def page_param(options = params)
    page = if options[:page]
             options[:page].to_i
           elsif options[:offset] && options[:limit]
             begin
               # + 1 as page is not 0 but 1 based
               (options[:offset].to_i / per_page_param(options)) + 1
             rescue ZeroDivisionError
               1
             end
           else
             1
           end

    if page > 0
      page
    else
      1
    end
  end

  # Returns per_page option used for pagination
  # based on:
  #  * per_page options value
  #  * per_page session value
  #  * limit options value
  #  in that order
  #  Return smallest possible setting if all else fails.
  def per_page_param(options = params)
    per_page_candidates = [options[:per_page].to_i, session[:per_page].to_i, options[:limit].to_i]

    if (union = per_page_candidates & Setting.per_page_options_array).empty?
      Setting.per_page_options_array.min
    else
      session[:per_page] = union.first

      union.first
    end
  end

  ##
  # For "Show more" paginated links, we want to load an initial number of items (defaulting to 5)
  # unless a higher number is provided. These values do not correspond to the per_page_options
  def show_more_limit_param(options = params, initial_limit: SHOW_MORE_DEFAULT_LIMIT)
    limit = options[:limit].to_i
    if limit.zero?
      initial_limit
    else
      [limit, SHOW_MORE_MAX_LIMIT].min
    end
  end

  ##
  # Paginate an AR relation for the "show more" pagination functionality
  def show_more_pagination(paginator, options = params)
    paginator.paginate(page: 1, per_page: show_more_limit_param(options))
  end

  class LinkRenderer < ::WillPaginate::ActionView::LinkRenderer
    def to_html
      pagination.inject("") do |html, item|
        html + (item.is_a?(Integer) ? page_number(item) : send(item))
      end.html_safe
    end

    protected

    def merge_get_params(url_params)
      params = super
      allowed_params ? params.slice(*allowed_params) : params
    end

    def page_number(page)
      label = I18n.t("js.pagination.pages.page_number", number: page)
      if page == current_page
        tag(:li,
            tag(:em, page, "aria-label": label, "aria-current": "page", tabindex: 0),
            class: "op-pagination--item op-pagination--item_current")
      else
        tag(:li,
            link(page, page, class: "op-pagination--item-link", "aria-label": label),
            class: "op-pagination--item")
      end
    end

    def gap
      tag(:li, "&#x2026;", class: "op-pagination--space", role: "separator")
    end

    def previous_page
      num = @collection.current_page > 1 && (@collection.current_page - 1)
      previous_or_next_page(num, I18n.t(:label_previous), "prev")
    end

    def next_page
      num = @collection.current_page < total_pages && (@collection.current_page + 1)
      previous_or_next_page(num, I18n.t(:label_next), "next")
    end

    def previous_or_next_page(page, text, class_suffix)
      if page
        tag(:li,
            link(text, page, { class: "op-pagination--item-link op-pagination--item-link_#{class_suffix}" }),
            class: "op-pagination--item op-pagination--item_#{class_suffix}")
      else
        ""
      end
    end

    private

    def link(text, target, attributes)
      new_attributes = attributes.dup
      new_attributes["data-turbo-stream"] = true if turbo?
      new_attributes["data-turbo-action"] = turbo_action if turbo_action.present?

      super(text, target, new_attributes)
    end

    def allowed_params
      @options[:allowed_params] # rubocop:disable Rails/HelperInstanceVariable
    end

    # Customize the Turbo visit action for pagination links. Can be set to "advance" or "replace".
    #  "advance" - push a new entry onto the history stack.
    #  "replace" - replace the current history entry.
    # See: https://turbo.hotwired.dev/reference/attributes
    #
    # Example: Promoting a Frame Navigation to a Page Visit
    #   By default navigation within a turbo frame does not change the rest of the browser's state,
    #   but you can promote a frame navigation a "Visit" by setting the turbo-action attribute to "advance".
    #   See: https://turbo.hotwired.dev/handbook/frames#promoting-a-frame-navigation-to-a-page-visit
    #
    def turbo_action
      @options[:turbo_action] # rubocop:disable Rails/HelperInstanceVariable
    end

    def turbo?
      @options[:turbo] # rubocop:disable Rails/HelperInstanceVariable
    end
  end

  private

  def pagination_pages_section(paginator, **)
    content_tag(:nav, class: "op-pagination--pages", aria: { label: I18n.t(:"js.pagination.page_navigation") }) do
      pagination_entries(paginator, **)
    end
  end

  def pagination_options_section(paginator, params:, allowed_params:)
    per_page_options = Setting.per_page_options_array
    return "".html_safe if per_page_options.empty?

    allowed_params ||= %w[filters sortBy]
    content_tag(:div, class: "op-pagination--options") do
      content_tag(:nav, aria: { label: I18n.t(:"js.pagination.per_page_navigation") }) do
        pagination_options_list(
          per_page_options,
          current_per_page: paginator.per_page,
          **params.merge(safe_query_params(allowed_params))
        )
      end
    end
  end

  ##
  # Builds the pagination nav with pages and range
  def pagination_entries(paginator, **)
    page_first = paginator.offset + 1
    page_last = paginator.offset + paginator.length
    total = paginator.total_entries

    content_tag(:ul, class: "op-pagination--items op-pagination--items_start", role: "presentation") do
      concat will_paginate(paginator, **)
      concat content_tag(:li, "(#{page_first} - #{page_last}/#{total})", class: "op-pagination--range")
    end
  end

  def pagination_options_list(per_pages, current_per_page:, **)
    content_tag(:ul, class: "op-pagination--items op-pagination--items_end", role: "presentation") do
      safe_join [
        content_tag(:li, I18n.t(:label_per_page), class: "op-pagination--label"),
        per_pages.map { |per_page| pagination_options_item(per_page, current: per_page == current_per_page, **) }
      ]
    end
  end

  ##
  # Constructs the 'n items per page' entries
  # determined from available options in the settings.
  def pagination_options_item(per_page, current:, **options)
    label = I18n.t("js.pagination.pages.show_per_page", number: per_page)
    content_tag(:li, class: ["op-pagination--item", { "op-pagination--item_current": current }]) do
      link_to_unless(
        current,
        per_page,
        options.merge(page: 1, per_page:),
        class: "op-pagination--item-link", aria: { label: }, target: "_top"
      ) do
        content_tag(:span, per_page, aria: { label:, current: "page" }, tabindex: 0)
      end
    end
  end
end
