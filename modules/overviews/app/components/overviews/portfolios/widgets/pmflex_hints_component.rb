# frozen_string_literal: true

# -- copyright
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
# ++

module Overviews
  module Portfolios
    module Widgets
      class PmflexHintsComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include ApplicationHelper

        def initialize(model = nil, project:, **)
          super(model, **)

          @project = project
        end

        def summary
          passed_hints = hints.count(&:checked?)
          if hints.empty?
            "Das #{project_noun} wurde bisher nicht automatisch geprüft"
          elsif passed_hints == hints.count
            "Das #{project_noun} erfüllt alle Anforderungen der automatisierten Prüfungen."
          elsif passed_hints == 0
            "Das #{project_noun} erfüllt derzeit keine der unten genannten Anforderungen."
          else
            "Das #{project_noun} ist auf dem richtigen Weg, aber bestimmte Elemente können noch optimiert werden."
          end
        end

        def hints
          @project.pmflex_hints.to_a
        end

        def project_noun
          case @project.project_type
          when :portfolio
            "Portfolio"
          when :program
            "Programm"
          else
            "Projekt"
          end
        end

        def hints_updated_at
          hints.first&.created_at
        end
      end
    end
  end
end
