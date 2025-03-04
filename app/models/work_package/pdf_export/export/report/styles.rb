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

module WorkPackage::PDFExport::Export::Report::Styles
  include MarkdownToPDF::StyleValidation

  class PDFStyles
    include MarkdownToPDF::Common
    include MarkdownToPDF::StyleHelper
    include WorkPackage::PDFExport::Common::Styles

    def overview_group_header
      resolve_font(@styles.dig(:overview, :group_heading))
    end

    def overview_group_header_margins
      resolve_margin(@styles.dig(:overview, :group_heading))
    end

    def overview_table_margins
      resolve_margin(@styles.dig(:overview, :table))
    end

    def overview_table_cell
      resolve_table_cell(@styles.dig(:overview, :table, :cell))
    end

    def overview_table_header_cell
      overview_table_cell.merge(
        resolve_table_cell(@styles.dig(:overview, :table, :cell_header))
      )
    end

    def overview_table_sums_cell
      overview_table_cell.merge(
        resolve_table_cell(@styles.dig(:overview, :table, :cell_sums))
      )
    end

    def overview_table_subject_indent
      resolve_pt(@styles.dig(:overview, :table, :subject_indent), 0)
    end

    def toc_max_depth
      @styles.dig(:toc, :max_depth) || 4
    end

    def toc_margins
      resolve_margin(@styles[:toc])
    end

    def toc_indent_mode
      @styles.dig(:toc, :indent_mode)
    end

    def toc_item(level)
      resolve_font(@styles.dig(:toc, :item)).merge(
        resolve_font(@styles.dig(:toc, :"item_level_#{level}"))
      )
    end

    def toc_item_subject_indent
      resolve_pt(@styles.dig(:toc, :subject_indent), 4)
    end

    def toc_item_margins(level)
      resolve_margin(@styles.dig(:toc, :item)).merge(
        resolve_margin(@styles.dig(:toc, :"item_level_#{level}"))
      )
    end

    def wp_margins
      resolve_margin(@styles[:work_package])
    end

    def wp_subject(level)
      resolve_font(@styles.dig(:work_package, :subject)).merge(
        resolve_font(@styles.dig(:work_package, :"subject_level_#{level}"))
      )
    end

    def wp_detail_subject_margins
      resolve_margin(@styles.dig(:work_package, :subject))
    end

    def wp_attributes_table_margins
      resolve_margin(@styles.dig(:work_package, :attributes_table))
    end

    def wp_attributes_table_cell
      resolve_table_cell(@styles.dig(:work_package, :attributes_table, :cell))
    end

    def wp_attributes_table_label_cell
      wp_attributes_table_cell.merge(
        resolve_table_cell(@styles.dig(:work_package, :attributes_table, :cell_label))
      )
    end

    def wp_markdown_label
      resolve_font(@styles.dig(:work_package, :markdown_label))
    end

    def wp_markdown_label_margins
      resolve_margin(@styles.dig(:work_package, :markdown_label))
    end

    def wp_markdown_margins
      resolve_margin(@styles.dig(:work_package, :markdown_margin))
    end

    def wp_markdown_styling_yml
      resolve_markdown_styling(@styles.dig(:work_package, :markdown) || {})
    end

    def cover_header
      resolve_font(@styles.dig(:cover, :header))
    end

    def cover_header_logo_height
      resolve_pt(@styles.dig(:cover, :header, :logo_height), 25)
    end

    def cover_header_border
      { color: @styles.dig(:cover, :header, :border, :color),
        height: resolve_pt(@styles.dig(:cover, :header, :border, :height), 1),
        offset: resolve_pt(@styles.dig(:cover, :header, :border, :offset), 0) }
    end

    def cover_footer
      resolve_font(@styles.dig(:cover, :footer))
    end

    def cover_footer_offset
      resolve_pt(@styles.dig(:cover, :footer, :offset), 0)
    end

    def cover_hero_padding
      resolve_padding(@styles.dig(:cover, :hero))
    end

    def cover_hero_title
      resolve_font(@styles.dig(:cover, :hero, :title))
    end

    def cover_hero_title_spacing
      resolve_pt(@styles.dig(:cover, :hero, :title, :spacing), 0)
    end

    def cover_hero_title_max_height
      resolve_pt(@styles.dig(:cover, :hero, :title, :max_height), 30)
    end

    def cover_hero_heading
      resolve_font(@styles.dig(:cover, :hero, :heading))
    end

    def cover_hero_heading_spacing
      resolve_pt(@styles.dig(:cover, :hero, :heading, :spacing), 0)
    end

    def cover_hero_dates
      resolve_font(@styles.dig(:cover, :hero, :dates))
    end

    def cover_hero_dates_spacing
      resolve_pt(@styles.dig(:cover, :hero, :dates, :spacing), 0)
    end

    def cover_hero_dates_max_height
      resolve_pt(@styles.dig(:cover, :hero, :dates, :max_height), 0)
    end

    def cover_hero_subheading
      resolve_font(@styles.dig(:cover, :hero, :subheading))
    end

    def cover_hero_subheading_max_height
      resolve_pt(@styles.dig(:cover, :hero, :subheading, :max_height), 30)
    end
  end

  def styles
    @styles ||= PDFStyles.new(load_style)
  end

  private

  def load_style
    yml = YAML::load_file(File.join(styles_asset_path, "standard.yml"))
    schema = JSON::load_file(File.join(styles_asset_path, "schema.json"))
    validate_schema!(yml, schema)
  end

  def styles_asset_path
    File.dirname(File.expand_path(__FILE__))
  end
end
