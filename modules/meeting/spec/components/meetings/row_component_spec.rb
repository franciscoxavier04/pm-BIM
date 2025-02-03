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

require "rails_helper"

RSpec.describe Meetings::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project) }
  let(:table) do
    instance_double(Meetings::TableComponent, columns: [:title], mobile_columns: [:title], mobile_labels: [],
                                              grid_class: "test",
                                              main_column?: false,
                                              has_actions?: true,
                                              current_project:)
  end
  let(:current_project) { nil }
  let(:user) { build_stubbed(:user) }

  subject do
    render_inline(described_class.new(row: meeting, table:))
    page
  end

  before do
    login_as(user)
  end

  describe "title column" do
    context "with a one-off meeting" do
      let(:meeting) { build_stubbed(:structured_meeting, project:, title: "One-time fun!") }

      it "is shows the meeting title" do
        expect(subject).to have_text "One-time fun!"
      end

      context "without a current project" do
        it "links to the meeting" do
          expect(subject).to have_link "One-time fun!", href: meeting_path(meeting)
        end
      end

      context "with a current project" do
        let(:current_project) { project }

        it "links to the meeting" do
          expect(subject).to have_link "One-time fun!", href: project_meeting_path(project, meeting)
        end
      end
    end

    context "with an associated recurring/templated meeting" do
      let(:series) { build_stubbed(:recurring_meeting, project:) }
      let(:meeting) do
        build_stubbed(:structured_meeting_template, recurring_meeting: series, project:, title: "Regular catch ups :)")
      end

      it "is shows the meeting template title" do
        expect(subject).to have_text "Regular catch ups :)"
      end

      context "without a current project" do
        it "links to the meeting occurrence" do
          expect(subject).to have_link "Regular catch ups :)", href: meeting_path(meeting)
        end

        it "links to the meeting series" do
          expect(subject).to have_link "Weekly", href: recurring_meeting_path(series)
        end
      end

      context "with a current project" do
        let(:current_project) { project }

        it "links to the meeting occurrence" do
          expect(subject).to have_link "Regular catch ups :)", href: project_meeting_path(project, meeting)
        end

        it "links to the meeting series" do
          expect(subject).to have_link "Weekly", href: project_recurring_meeting_path(project, series)
        end
      end
    end
  end

  describe "actions" do
    context "with default permissions" do
      context "with a one-off meeting" do
        let(:meeting) { build_stubbed(:structured_meeting, project:) }

        it "shows default menu items" do
          expect(subject).to have_link "Download iCalendar event"
        end
      end

      context "with an associated recurring/templated meeting" do
        let(:series) { build_stubbed(:recurring_meeting, project:) }
        let(:meeting) { build_stubbed(:structured_meeting_template, recurring_meeting: series, project:) }

        it "shows download iCal menu item" do
          expect(subject).to have_link "Download iCalendar event"
        end

        context "without a current project" do
          it "shows view meeting series menu item" do
            expect(subject).to have_link "View meeting series", href: recurring_meeting_path(series)
          end
        end

        context "with a current project" do
          let(:current_project) { project }

          it "shows view meeting series menu item" do
            expect(subject).to have_link "View meeting series", href: project_recurring_meeting_path(project, series)
          end
        end
      end
    end

    context "with project delete meetings permissions" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:delete_meetings, project:)
        end
      end

      context "with a one-off meeting" do
        let(:meeting) { build_stubbed(:structured_meeting, project:) }

        context "without a current project" do
          it "shows delete menu item" do
            expect(subject).to have_link "Delete meeting", href: delete_dialog_meeting_path(meeting)
          end
        end

        context "with a current project" do
          let(:current_project) { project }

          it "shows delete menu item" do
            expect(subject).to have_link "Delete meeting", href: delete_dialog_project_meeting_path(project, meeting)
          end
        end
      end

      context "with an associated recurring/templated meeting" do
        let(:series) { build_stubbed(:recurring_meeting, project:) }
        let(:meeting) { build_stubbed(:structured_meeting_template, recurring_meeting: series, project:) }

        context "without a current project" do
          it "shows delete menu item" do
            expect(subject).to have_link "Delete occurrence", href: delete_dialog_meeting_path(meeting)
          end
        end

        context "with a current project" do
          let(:current_project) { project }

          it "shows delete menu item" do
            expect(subject).to have_link "Delete occurrence", href: delete_dialog_project_meeting_path(project, meeting)
          end
        end
      end
    end

    context "with project create meetings permissions" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:create_meetings, project:)
        end
      end

      context "with a one-off meeting" do
        let(:meeting) { build_stubbed(:structured_meeting, project:) }

        it "shows copy menu item" do
          expect(subject).to have_link "Copy meeting"
        end
      end
    end
  end
end
