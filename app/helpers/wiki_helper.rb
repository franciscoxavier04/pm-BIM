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

module WikiHelper
  def wiki_page_options_for_select(pages,
                                   ids: true,
                                   placeholder: true)
    s = if placeholder
          [["-- #{t('label_no_parent_page')} --", ""]]
        else
          []
        end

    s + wiki_page_options_for_select_of_level(pages.group_by(&:parent),
                                              ids:)
  end

  def breadcrumb_for_page(page, action = nil)
    project = page.project

    breadcrumbs = []

    # First breadcrumb: Project overview
    breadcrumbs << { href: project_overview_path(project.id), text: project.name }

    # Add ancestors
    breadcrumbs += page.ancestors.reverse.map do |parent|
      {
        href: url_for(controller: "wiki", action: "show", project_id: parent.project, id: parent.title),
        text: parent.breadcrumb_title
      }
    end

    # Optional action
    breadcrumbs << action if action

    # Final page title (just a string)
    breadcrumbs << h(page.breadcrumb_title) unless action

    breadcrumbs
  end

  private

  def wiki_page_options_for_select_of_level(pages,
                                            parent: nil,
                                            level: 0,
                                            ids: true)
    return [] unless pages[parent]

    pages[parent].inject([]) do |s, page|
      s << wiki_page_option(page, level, ids)
      s += wiki_page_options_for_select_of_level(pages, parent: page, level: level + 1, ids:)
      s
    end
  end

  def wiki_page_option(page, level, ids)
    indent = level.positive? ? (("&nbsp;" * level * 2) + "&#187; ") : ""
    id = ids ? page.id : page.title
    [(indent + h(page.title)).html_safe, id]
  end
end
