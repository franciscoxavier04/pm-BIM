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

require_relative "../../spec_helper"

RSpec.describe My::TimeTrackingController do
  let(:user) { create(:user) }

  before do
    login_as user
  end

  describe "GET /my/time-tracking" do
    context "when requesting on a non mobile device" do
      before do
        allow(controller).to receive(:mobile?).and_return(false)
      end

      context "and tracking start and end times is enabled" do
        before do
          allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(true)
        end

        it "redirects to the week calendar view" do
          get :calendar
          expect(response).to redirect_to(action: :week, view_mode: "calendar")
        end
      end

      context "and tracking start and end times is disabled" do
        before do
          allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(false)
        end

        it "redirects to the week list view" do
          get :calendar
          expect(response).to redirect_to(action: :week, view_mode: "list")
        end
      end
    end

    context "when requesting on a mobile device" do
      before do
        allow(controller).to receive(:mobile?).and_return(true)
      end

      context "and tracking start and end times is enabled" do
        before do
          allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(true)
        end

        it "redirects to the day calendar view" do
          get :calendar
          expect(response).to redirect_to(action: :day, view_mode: "calendar")
        end
      end

      context "and tracking start and end times is disabled" do
        before do
          allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(false)
        end

        it "redirects to the day list view" do
          get :calendar
          expect(response).to redirect_to(action: :day, view_mode: "list")
        end
      end
    end
  end
end
