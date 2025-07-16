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

module BmdsHackathon
  module Objectives
    BGCOLOR_MAP = {
      "Im Plan" => "--bgColor-accent-muted",
      "Außer Plan" => "--bgColor-attention-muted",
      "Kritisch" => "--bgColor-closed-muted",
      "Geschlossen" => "--bgColor-neutral-muted"
    }.freeze

    COLOR_MAP = {
      "Im Plan" => "--bgColor-accent-emphasis",
      "Außer Plan" => "--bgColor-attention-emphasis",
      "Kritisch" => "--bgColor-closed-emphasis",
      "Geschlossen" => "--bgColor-neutral-emphasis"
    }.freeze

    module_function

    def objective_type
      @objective_type ||= Type.find_by!(name: "Objective")
    end

    def key_result_type
      @key_result_type ||= Type.find_by!(name: "Key Result")
    end

    def key_result_statuses
      @key_result_statuses ||= begin
        statuses = Status.where(name: ["Im Plan", "Außer Plan", "Kritisch", "Geschlossen"]).to_a

        [
          statuses.detect { |s| s.name == "Im Plan" },
          statuses.detect { |s| s.name == "Außer Plan" },
          statuses.detect { |s| s.name == "Kritisch" },
          statuses.detect { |s| s.name == "Geschlossen" }
        ].compact.freeze
      end
    end

    def target_cf
      @target_cf ||= CustomField.find_by!(name: "Zielwert")
    end

    def current_cf
      @current_cf ||= CustomField.find_by!(name: "Istwert")
    end
  end
end
