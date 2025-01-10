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

module ToolbarHelper
  include ERB::Util
  include ActionView::Helpers::OutputSafetyHelper

  def toolbar(title:, title_extra: nil, title_class: nil, subtitle: "", link_to: nil, html: {})
    classes = ["toolbar-container", html[:class]].compact.join(" ")
    content_tag :div, class: classes do
      toolbar = content_tag :div, class: "toolbar" do
        dom_title(title, link_to, title_class:, title_extra:) + dom_toolbar do
          yield if block_given?
        end
      end
      next toolbar if subtitle.blank?

      toolbar + content_tag(:p, subtitle, class: "subtitle")
    end
  end

  def editable_toolbar(form:, field_name:, html: {})
    container_classes = ["toolbar-container -editable", html[:class]].compact.join(" ")
    content_tag :div, class: container_classes do
      content_tag :div, class: "toolbar" do
        concat(editable_toolbar_title(form, field_name))
        concat(dom_toolbar { yield if block_given? })
      end
    end
  end

  def breadcrumb_toolbar(*elements, subtitle: "", html: {}, &)
    toolbar(title: safe_join(elements, " &raquo ".html_safe), subtitle:, html:, &)
  end

  protected

  def editable_toolbar_title(form, field_name)
    new_element = form.object.new_record?

    content_tag :div, class: "title-container" do
      form.text_field field_name,
                      class: "toolbar--editable-toolbar -border-on-hover-only",
                      placeholder: t(:label_page_title),
                      "aria-label": t(:label_page_title),
                      autocomplete: "off",
                      required: true,
                      autofocus: new_element,
                      no_label: true
    end
  end

  def dom_title(raw_title, link_to = nil, title_class: nil, title_extra: nil)
    title = "".html_safe
    title << raw_title

    if link_to.present?
      title << ": "
      title << link_to
    end

    content_tag :div, class: "title-container" do
      opts = {}

      opts[:class] = title_class if title_class.present?

      content_tag(:h2, title, opts) + (
        title_extra.presence || ""
      )
    end
  end

  def dom_toolbar(&)
    return "" unless block_given?

    content_tag(:ul, class: "toolbar-items", &)
  end
end
