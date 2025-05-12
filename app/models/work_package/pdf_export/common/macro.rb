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
    return markdown if markdown.blank?

    apply_macros(markdown, context)
  end

  def macros
    [
      WorkPackage::Exports::Macros::Links,
      WorkPackage::Exports::Macros::Attributes
    ]
  end

  private

  def apply_macros(markdown, context)
    return markdown unless macros.any? { |macro| macro.applicable?(markdown) }

    document = Markly.parse(markdown)
    document.walk { |node| apply_macros_node(node, context) }
    document.to_markdown
  end

  def apply_macros_node(node, context)
    if %i[html inline_html].include?(node.type)
      apply_macros_node_html(node, context)
    elsif node.type == :text
      apply_macros_node_text(node, context)
    end
  end

  def apply_macros_node_text(node, context)
    formatted = apply_macro_text(node.string_content, context)
    if formatted != node.string_content
      if formatted.include?("<")
        fragment = Markly::Node.new(:inline_html)
        fragment.string_content = formatted
        node.insert_before(fragment)
        node.delete
      else
        node.string_content = formatted
      end
    end
  end

  def apply_macros_node_html(node, context)
    formatted = apply_macro_html(node.string_content, context)
    node.string_content = formatted if formatted != node.string_content
  end

  def applicable?(content)
    macros.any? { |macro| macro.applicable?(content) }
  end

  def apply_macro_text(text, context)
    applicable_macros = macros.select { |macro| macro.applicable?(text) }
    return text if applicable_macros.empty?

    applicable_macros.each do |macro|
      text = text.gsub(macro.regexp) do |matched_string|
        macro.process_match(Regexp.last_match, matched_string, context)
      end
    end
    text
  end

  def apply_macro_html(html, context)
    return html unless applicable?(html)

    doc = Nokogiri::HTML.fragment(html)
    apply_macro_html_node(doc, context)
    doc.to_html
  end

  def apply_macro_html_node(node, context)
    if node.text?
      formatted = apply_macro_text(node.content, context)
      node.content = formatted if formatted != node.content
    elsif PREFORMATTED_BLOCKS.exclude?(node.name)
      node.children.each { |child| apply_macro_html_node(child, context) }
    end
  end
end
