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

require "spec_helper"

RSpec.describe "my access tokens", :js do
  let(:user_password) { "bob" * 4 }
  let!(:string_cf) { create(:user_custom_field, :string, name: "Hobbies", is_required: false) }
  let(:user) do
    create(:user,
           mail: "old@mail.com",
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  before do
    login_as user
  end

  describe "API tokens" do
    context "when API access is disabled via global settings", with_settings: { rest_api_enabled: false } do
      it "shows notice about disabled token" do
        visit my_access_tokens_path

        within "#api-token-component" do
          expect(page).to have_content("API tokens are not enabled by the administrator.")
          expect(page).not_to have_test_selector("api-token-add", text: "API token")
        end
      end
    end

    context "when API access is enabled via global settings", with_settings: { rest_api_enabled: true } do
      it "API tokens can be generated and revoked" do
        visit my_access_tokens_path

        expect(page).to have_no_content("API tokens are not enabled by the administrator.")

        within "#api-token-component" do
          expect(page).to have_test_selector("api-token-add", text: "API Token")
          find_test_selector("api-token-add").click
        end

        expect(page).to have_test_selector("new-access-token-dialog")

        # create API token
        fill_in "token_api[token_name]", with: "Testing Token"
        find_test_selector("create-api-token-button").click

        within("dialog#api-created-dialog") do
          expect(page).to have_content "The Access token token has been generated"
          click_on "Close"
        end
        expect(page).to have_content("Testing Token")

        User.current.reload
        visit my_access_tokens_path

        # multiple API tokens can be created
        within "#api-token-component" do
          expect(page).to have_test_selector("api-token-add", text: "API Token")
        end

        # revoke API token
        within "#api-token-component" do
          accept_confirm do
            find_test_selector("api-token-revoke").click
          end
        end

        expect(page).to have_content "The API token has been deleted."

        User.current.reload
        visit my_access_tokens_path

        # API token can be created again
        within "#api-token-component" do
          expect(page).to have_test_selector("api-token-add", text: "API Token")
        end
      end
    end
  end

  describe "RSS tokens" do
    context "when RSS access is disabled via global settings", with_settings: { feeds_enabled: false } do
      it "shows notice about disabled token" do
        visit my_access_tokens_path

        within "#rss-token-section" do
          expect(page).to have_content("RSS tokens are not enabled by the administrator.")
          expect(page).not_to have_test_selector("rss-token-add", text: "RSS token")
        end
      end
    end

    context "when RSS access is enabled via global settings", with_settings: { feeds_enabled: true } do
      it "in Access Tokens they can generate and revoke their RSS key" do
        visit my_access_tokens_path

        expect(page).to have_no_content("RSS tokens are not enabled by the administrator.")

        within "#rss-token-section" do
          expect(page).to have_test_selector("rss-token-add", text: "RSS token")
          find_test_selector("rss-token-add").click
        end

        expect(page).to have_content "A new RSS token has been generated. Your access token is"

        User.current.reload
        visit my_access_tokens_path

        # only one RSS token can be created
        within "#rss-token-section" do
          expect(page).not_to have_test_selector("rss-token-add", text: "RSS token")
        end

        # revoke RSS token
        within "#rss-token-section" do
          accept_confirm do
            find_test_selector("rss-token-revoke").click
          end
        end

        expect(page).to have_content "The RSS token has been deleted."

        User.current.reload
        visit my_access_tokens_path

        # RSS token can be created again
        within "#rss-token-section" do
          expect(page).to have_test_selector("rss-token-add", text: "RSS token")
        end
      end
    end
  end

  describe "iCalendar tokens" do
    context "when iCalendar access is disabled via global settings", with_settings: { ical_enabled: false } do
      it "shows notice about disabled token" do
        visit my_access_tokens_path

        within "#icalendar-token-section" do
          expect(page).to have_content("iCalendar subscriptions are not enabled by the administrator.")
        end
      end
    end

    context "when iCalendar access is enable via global settings", with_settings: { ical_enabled: true } do
      context "when no iCalendar token exists" do
        it "shows notice about how to use iCalendar tokens" do
          visit my_access_tokens_path

          within "#icalendar-token-section" do
            expect(page).to have_content("To add an iCalendar token") # ...
          end
        end
      end

      context "when multiple iCalendar tokens exist" do
        let!(:project) { create(:project) }
        let!(:query) { create(:query, project:) }
        let!(:another_query) { create(:query, project:) }
        let!(:ical_token_for_query) { create(:ical_token, user:, query:, name: "First Token Name") }
        let!(:ical_token_for_another_query) { create(:ical_token, user:, query: another_query, name: "Second Token Name") }
        let!(:second_ical_token_for_query) { create(:ical_token, user:, query:, name: "Third Token Name") }

        it "shows iCalendar tokens with their calender and project info" do
          visit my_access_tokens_path

          expect(page).to have_no_content("To add an iCalendar token") # ...

          within "#icalendar-token-section" do
            [
              ical_token_for_query,
              ical_token_for_another_query,
              second_ical_token_for_query
            ].each do |ical_token|
              token_name = ical_token.ical_token_query_assignment.name
              query = ical_token.ical_token_query_assignment.query

              expect(page).to have_test_selector("ical-token-row-#{ical_token.id}-name", text: token_name)
              expect(page).to have_test_selector("ical-token-row-#{ical_token.id}-query-name", text: query.name)
              expect(page).to have_test_selector("ical-token-row-#{ical_token.id}-project-name",
                                                 text: query.project.name)
            end
          end
        end

        it "single iCalendar tokens can be deleted" do
          visit my_access_tokens_path

          within "#icalendar-token-section" do
            accept_confirm do
              find_test_selector("ical-token-row-#{ical_token_for_query.id}-revoke").click
            end
          end

          expect(page).to have_content "The iCalendar URL with this token is now invalid."

          User.current.reload
          visit my_access_tokens_path

          within "#icalendar-token-section" do
            expect(page).not_to have_test_selector("ical-token-row-#{ical_token_for_query.id}-revoke")
          end
        end
      end
    end
  end

  describe "OAuth tokens" do
    context "when no OAuth access is configured" do
      it "shows notice about no existing tokens" do
        visit my_access_tokens_path

        within "#oauth-token-section" do
          expect(page).to have_content("There is no third-party application access configured and active for you")
        end
      end
    end

    context "when OAuth access is configured" do
      let!(:app) do
        create(:oauth_application,
               name: "Some App",
               confidential: false)
      end
      let!(:token_for_app) do
        create(:oauth_access_token,
               application: app,
               resource_owner: user)
      end
      let!(:second_app) do
        create(:oauth_application,
               name: "Some Second App",
               uid: "56789",
               confidential: false)
      end
      let!(:token_for_second_app) do
        create(:oauth_access_token,
               application: second_app,
               resource_owner: user)
      end

      context "when single OAuth token per app is configured" do
        it "shows token for granted applications" do
          visit my_access_tokens_path

          [app, second_app].each do |app|
            within "#oauth-token-section" do
              expect(page).to have_test_selector("oauth-token-row-#{app.id}-name", text: app.name)
              expect(page).to have_test_selector("oauth-token-row-#{app.id}-name", text: "(one active token)")
            end
          end
        end

        it "can revoke tokens" do
          visit my_access_tokens_path

          [app, second_app].each do |app|
            within "#oauth-token-section" do
              accept_confirm do
                find_test_selector("oauth-token-row-#{app.id}-revoke").click
              end
            end
          end

          User.current.reload
          visit my_access_tokens_path

          [app, second_app].each do |app|
            within "#oauth-token-section" do
              expect(page).not_to have_test_selector("oauth-token-row-#{app.id}-revoke")
            end
          end
        end
      end

      context "when multiple OAuth tokens per app are configured" do
        let!(:second_token_for_app) do
          create(:oauth_access_token,
                 application: app,
                 resource_owner: user)
        end
        let!(:second_token_for_second_app) do
          create(:oauth_access_token,
                 application: second_app,
                 resource_owner: user)
        end

        it "shows token for granted applications" do
          visit my_access_tokens_path

          [app, second_app].each do |app|
            within "#oauth-token-section" do
              expect(page).to have_test_selector("oauth-token-row-#{app.id}-name", text: app.name)
              expect(page).to have_test_selector("oauth-token-row-#{app.id}-name", text: "(2 active token)")
            end
          end
        end

        it "can revoke mutliple tokens per app" do
          visit my_access_tokens_path

          within "#oauth-token-section" do
            accept_confirm do
              find_test_selector("oauth-token-row-#{app.id}-revoke").click
            end
          end

          User.current.reload
          visit my_access_tokens_path

          within "#oauth-token-section" do
            expect(page).not_to have_test_selector("oauth-token-row-#{app.id}-revoke")
          end
        end
      end
    end
  end
end
