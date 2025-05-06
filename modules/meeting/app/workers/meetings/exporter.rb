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

module Meetings
  class Exporter < Exports::Exporter
    include WorkPackage::PDFExport::Common::Common
    include WorkPackage::PDFExport::Common::Logo
    include WorkPackage::PDFExport::Export::Page
    include WorkPackage::PDFExport::Export::Cover
    include WorkPackage::PDFExport::Export::Meetings::Styles
    include WorkPackage::PDFExport::Export::Markdown
    include WorkPackage::PDFExport::Common::Attachments
    include WorkPackage::PDFExport::Common::Badge
    include Meetings::PDF::PageHead
    include Meetings::PDF::Participants
    include Meetings::PDF::Agenda

    attr_accessor :pdf

    self.model = Meeting

    alias :meeting :object

    def self.key
      :pdf
    end

    def initialize(meeting, _options = {})
      super

      setup_page!
    end

    def setup_page!
      self.pdf = get_pdf
      configure_page_size!(:portrait)
    end

    def export!
      render_doc
      success(pdf.render)
    rescue StandardError => e
      Rails.logger.error "Failed to generate PDF export:  #{e.message}:\n#{e.backtrace.join("\n")}"
      error(I18n.t(:error_pdf_failed_to_export, error: e.message))
    end

    def render_doc
      pdf.title = heading
      write_cover_page! if with_cover?
      render_meeting!
    end

    def render_meeting!
      write_page_head
      write_hr
      write_participants
      write_hr
      write_agenda
    end

    def write_hr
      write_horizontal_line(pdf.cursor, 1, "6E7781")
      pdf.move_down(10)
    end

    def with_cover?
      false# true
    end

    def cover_page_title
      ""
    end

    def cover_page_heading
      meeting.title
    end

    def cover_page_dates
      "#{meeting.start_date} #{meeting.start_time_hour}".strip
    end

    def cover_page_subheading
      meeting.location
    end

    def heading
      meeting.title
    end

    def footer_title
      "Footer title"
    end

    def title_datetime
      meeting.start_time.strftime("%Y-%m-%d")
    end

    def title
      build_pdf_filename(meeting.title)
    end

    def with_images?
      true
    end
  end
end
