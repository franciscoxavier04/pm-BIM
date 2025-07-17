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

module Projects::Exports::PDFExport
  module Cover
    def render_cover
      write_cover_logo
      write_cover_image
      write_cover_rect
      write_cover_title
      pdf.start_new_page
    end

    def write_cover_logo
      image_obj, image_info = logo_image
      height = 60
      scale = [height / image_info.height.to_f, 1].min
      pdf.embed_image image_obj, image_info, { at: [0, pdf.bounds.height + 30], scale: }
      image_info.width.to_f * scale
    end

    def cover_image
      image_file = Rails.root.join("app/assets/images/pdf/20943511.jpg")
      image_obj, image_info = pdf.build_image_object(image_file)
      image_opts = { at: [55, pdf.bounds.height - 180], width: 500 }
      [image_obj, image_info, image_opts]
    end

    def write_cover_title # rubocop:disable Metrics/AbcSize
      page_height = pdf.page.dimensions[3]
      third_height = page_height / 3
      font_size = 26
      margin = 50
      text = heading.gsub(": ", ":\n")
      pdf.canvas do
        pdf.formatted_text_box(
          [{ text:, size: font_size, color: "FFFFFF", styles: [:bold] }],
          at: [margin, third_height],
          height: third_height - pdf.bounds.bottom - font_size,
          width: pdf.bounds.width - (margin * 2),
          overflow: :shrink_to_fit,
          align: :center,
          valign: :center
        )
      end
    end

    def write_cover_rect # rubocop:disable Metrics/AbcSize
      original_color = pdf.fill_color
      pdf.fill_color = "086F90"

      page_width = pdf.page.dimensions[2]
      page_height = pdf.page.dimensions[3]

      pdf.canvas do
        pdf.fill_rectangle([0, page_height / 3], page_width, page_height / 3)
      end

      pdf.fill_color = original_color
    end

    def write_cover_image
      pdf.canvas do
        image_obj, image_info, image_opts = cover_image
        pdf.embed_image image_obj, image_info, image_opts
      end
    end
  end
end
