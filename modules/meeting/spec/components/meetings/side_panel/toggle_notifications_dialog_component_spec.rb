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

RSpec.describe Meetings::SidePanel::ToggleNotificationsDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }

  before do
    login_as(user)
  end

  subject do
    render_inline(described_class.new(meeting))
    page
  end

  context "when notifications are enabled" do
    let(:meeting) { build_stubbed(:meeting, project:, notify: true) }

    it "renders the dialog with strings for disabling" do
      expect(subject).to have_text I18n.t("meeting.notifications.dialog.title.disable")
      expect(subject).to have_text I18n.t("meeting.notifications.dialog.message.disable")
      expect(subject).to have_button I18n.t("meeting.notifications.dialog.confirm_label.disable")
    end

    it "renders the correct form action" do
      expect(subject).to have_element "form", action: toggle_notifications_project_meeting_path(project, meeting)
    end
  end

  context "when notifications are disabled" do
    let(:meeting) { build_stubbed(:meeting, project:, notify: false) }

    it "renders the dialog with strings for enabling" do
      expect(subject).to have_text I18n.t("meeting.notifications.dialog.title.enable")
      expect(subject).to have_text I18n.t("meeting.notifications.dialog.message.enable")
      expect(subject).to have_button I18n.t("meeting.notifications.dialog.confirm_label.enable")
    end

    it "renders the correct form action" do
      expect(subject).to have_element "form", action: toggle_notifications_project_meeting_path(project, meeting)
    end
  end
end
