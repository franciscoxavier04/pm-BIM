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
          passed_hints = hints.count { |h| h.fetch(:checked) }
          if passed_hints == hints.count
            "Das Projekt erfüllt alle Anforderungen der automatisierten Prüfungen."
          elsif passed_hints == 0
            "Das Projekt erfüllt derzeit keine der unten genannten Anforderungen."
          else
            "Das Projekt ist auf dem richtigen Weg, aber bestimmte Elemente können noch optimiert werden."
          end
        end

        def hints
          # TODO: The idea might be that we don't hardcode specific checks here but let an LLM come up with proposals magically
          # In that case it would need to be able to fill the three basic values "checked", "title" and "description" for all of
          # the checks that it performed
          [
            status_report_hint,
            test_hint
          ]
        end

        def status_report_hint
          title = "Statusbericht aktualisieren"
          report = @project.documents.where(category: DocumentCategory.project_status_report).order(:created_at).last
          if report && report.created_at > 1.month.ago
            { checked: true, title:, description: "Der Statusbericht ist aktuell." }
          else
            { checked: false, title:, description: "Der neueste Statusbericht wurde vor mehr als einem Monat erzeugt." }
          end
        end

        def test_hint
          { checked: false, title: "Dieses Element ist nur ein Test", description: "Und er wurde nicht bestanden." }
        end
      end
    end
  end
end
