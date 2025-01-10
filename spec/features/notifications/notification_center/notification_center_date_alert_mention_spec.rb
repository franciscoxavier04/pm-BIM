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

require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "Notification center date alert and mention",
               :js,
               :with_cuprite,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project) }
  shared_let(:actor) { create(:user, firstname: "Actor", lastname: "User") }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project:, due_date: 1.day.ago) }

  shared_let(:notification_mention) do
    create(:notification,
           reason: :mentioned,
           recipient: user,
           resource: work_package,
           actor:)
  end

  shared_let(:notification_date_alert) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: work_package)
  end

  let(:center) { Pages::Notifications::Center.new }

  before do
    login_as user
    visit notifications_center_path
    wait_for_reload
  end

  context "with date alerts ee", with_ee: %i[date_alerts] do
    it "shows only the date alert time, not the mentioned author" do
      center.within_item(notification_date_alert) do
        expect(page).to have_text("Date alert, Mentioned")
        expect(page).to have_no_text("Actor user")
      end
    end
  end
end
