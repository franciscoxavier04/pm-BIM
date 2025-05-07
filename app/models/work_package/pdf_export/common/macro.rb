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

module WorkPackage::PDFExport::Common::Macro
  PREFORMATTED_BLOCKS = %w(pre code).freeze

  def apply_markdown_field_macros(markdown, context)
    apply_macros(markdown, context, WorkPackage::Exports::Macros::Attributes)
  end

  private

  def apply_macros(markdown, context, formatter)
    return markdown unless formatter.applicable?(markdown)

    document = Markly.parse(markdown)
    document.walk do |node|
      if node.type == :html
        node.string_content = apply_macro_html(node.string_content, context, formatter) || node.string_content
      elsif node.type == :text
        node.string_content = apply_macro_text(node.string_content, context, formatter) || node.string_content
      end
    end
    document.to_markdown
  end

  def apply_macro_text(text, context, formatter)
    return text unless formatter.applicable?(text)

    text.gsub!(formatter.regexp) do |matched_string|
      matchdata = Regexp.last_match
      formatter.process_match(matchdata, matched_string, context)
    end
  end

  def apply_macro_html(html, context, formatter)
    return html unless formatter.applicable?(html)

    doc = Nokogiri::HTML.fragment(html)
    apply_macro_html_node(doc, context, formatter)
    doc.to_html
  end

  def apply_macro_html_node(node, context, formatter)
    if node.text?
      node.content = apply_macro_text(node.content, context, formatter)
    elsif PREFORMATTED_BLOCKS.exclude?(node.name)
      node.children.each { |child| apply_macro_html_node(child, context, formatter) }
    end
  end
end
