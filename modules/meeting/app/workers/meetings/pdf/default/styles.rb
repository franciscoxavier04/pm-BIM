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

module Meetings::PDF::Default::Styles
  class PDFStyles < Meetings::PDF::Common::Styles::Base
    def heading_hr
      {
        color: @styles.dig(:heading, :hr, :color),
        height: resolve_pt(@styles.dig(:heading, :hr, :height), 1)
      }
    end

    def heading_hr_margins
      resolve_margin(@styles.dig(:heading, :hr))
    end

    def agenda_item_hr
      {
        color: @styles.dig(:agenda_item, :hr, :color),
        height: resolve_pt(@styles.dig(:agenda_item, :hr, :height), 1)
      }
    end

    def agenda_item_hr_margins
      resolve_margin(@styles.dig(:agenda_item, :margins))
    end
  end

  def styles
    @styles ||= PDFStyles.new(styles_asset_path)
  end

  private

  def styles_asset_path
    File.dirname(File.expand_path(__FILE__))
  end
end
