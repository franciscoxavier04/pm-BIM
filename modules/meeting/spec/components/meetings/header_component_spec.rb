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

RSpec.describe Meetings::HeaderComponent, type: :component do
  let(:project) { build_stubbed(:project, name: "Top SECRET Project") }
  let(:meeting) { build_stubbed(:meeting, project:, title: "All Hands and All 🦶") }
  let(:current_project) { nil }
  let(:user) { build_stubbed(:user) }

  subject do
    render_inline(described_class.new(meeting:, project: current_project))
    page
  end

  before do
    login_as(user)
  end

  describe "breadcrumbs" do
    it "renders breadcrumb navigation" do
      expect(subject).to have_navigation "Breadcrumb"
    end

    context "with a one-off meeting" do
      context "without a current project" do
        it "renders global breadcrumbs" do
          expect(subject).to have_css ".breadcrumb-item", count: 3
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(1)", text: "OpenProject"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(2)", text: "Meetings"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(3)", text: "All Hands and All 🦶"
        end

        it "renders global links" do
          expect(subject).to have_no_link href: /\/projects\//
        end
      end

      context "with a current project" do
        let(:current_project) { project }

        it "renders project breadcrumbs" do
          expect(subject).to have_css ".breadcrumb-item", count: 3
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(1)", text: "Top SECRET Project"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(2)", text: "Meetings"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(3)", text: "All Hands and All 🦶"
        end

        it "renders project links" do
          expect(subject).to have_link href: /\/projects\//
        end
      end
    end

    context "with an associated recurring/templated meeting" do
      let(:series) { build_stubbed(:recurring_meeting, project:, title: "Coffee Chat") }
      let(:meeting) { build_stubbed(:structured_meeting_template, recurring_meeting: series, project:) }

      context "without a current project" do
        it "renders global breadcrumbs" do
          expect(subject).to have_css ".breadcrumb-item", count: 4
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(1)", text: "OpenProject"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(2)", text: "Meetings"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(3)", text: "Coffee Chat"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(4)", text: "Template"
        end

        it "renders global links" do
          expect(subject).to have_no_link href: /\/projects\//
        end
      end

      context "with a current project" do
        let(:current_project) { project }

        it "renders project breadcrumbs" do
          expect(subject).to have_css ".breadcrumb-item", count: 4
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(1)", text: "Top SECRET Project"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(2)", text: "Meetings"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(3)", text: "Coffee Chat"
          expect(subject).to have_css ".breadcrumb-item:nth-of-type(4)", text: "Template"
        end

        it "renders project links" do
          expect(subject).to have_link href: /\/projects\//
        end
      end
    end
  end

  describe "send mail invitation" do
    let(:current_project) { project }

    context "when allowed" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:send_meeting_agendas_notification, project:)
        end
      end

      context "when open" do
        let(:meeting) { build_stubbed(:meeting, project:, state: :open) }

        it "renders the mail invitation" do
          expect(subject).to have_text I18n.t("meeting.label_mail_all_participants")
        end
      end

      context "when closed" do
        let(:meeting) { build_stubbed(:meeting, project:, state: :closed) }

        it "does not render the mail invitation" do
          expect(subject).to have_no_text I18n.t("meeting.label_mail_all_participants")
        end
      end
    end

    context "when not allowed" do
      let(:meeting) { build_stubbed(:meeting, project:, state: :open) }

      it "does not render the mail invitation" do
        expect(subject).to have_no_text I18n.t("meeting.label_mail_all_participants")
      end
    end
  end
end
