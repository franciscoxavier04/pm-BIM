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

RSpec.describe Projects::StatusButtonComponent, type: :component do
  let(:project) { build_stubbed(:project, status_code:) }
  let(:status_code) { nil }

  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject do
    render_inline(described_class.new(project:, user:))
    page
  end

  shared_examples "component wrapper" do |id|
    it "renders component wrapper" do
      expect(subject).to have_xpath "//*[@id='#{id}']", count: 1
    end
  end

  it_behaves_like "component wrapper", "projects-status-button-component"

  context "when the user has no project edit permissions" do
    context "when status code is not set" do
      it "renders a disabled button" do
        expect(subject).to have_button "Not set", disabled: true
      end
    end

    context "when status code is set" do
      let(:status_code) { :off_track }

      it "renders a disabled button" do
        expect(subject).to have_button "Off track", disabled: true
      end
    end

    it "does not render a Primer ActionMenu" do
      expect(subject).not_to have_element "action-menu"
    end
  end

  context "when the user has project edit permissions" do
    let(:user) { build_stubbed(:admin) }

    context "when status code is not set" do
      it "renders an enabled button" do
        expect(subject).to have_button "Not set", disabled: false, aria: { label: "Edit project status" }
      end

      it "renders a Primer ActionMenu (single variant)" do
        expect(subject).to have_element "action-menu", "data-select-variant": "none"
        expect(subject).to have_element "action-menu", class: "op-status-button"
      end

      it "renders project status options" do
        subject

        expect(page).to have_menu do
          expect(page).to have_selector :menuitem, count: 7
          expect(page).to (have_selector :menuitem, text: "Not set", aria: { current: true } do |link|
            expect(link[:"data-turbo-method"]).to eq "delete"
          end)
          expect(page).to have_selector :menuitem, text: "On track"
          expect(page).to have_selector :menuitem, text: "At risk"
          expect(page).to have_selector :menuitem, text: "Not started"
          expect(page).to have_selector :menuitem, text: "Finished"
          expect(page).to have_selector :menuitem, text: "Discontinued"
          expect(page).to have_selector :menuitem, text: "Off track"
        end
      end
    end

    context "when status code is set" do
      let(:status_code) { :on_track }

      it "renders an enabled button" do
        expect(subject).to have_button "On track", disabled: false, aria: { label: "Edit project status" }
      end

      it "renders a Primer ActionMenu (single variant)" do
        expect(subject).to have_element "action-menu", "data-select-variant": "none"
        expect(subject).to have_element "action-menu", class: "op-status-button"
      end

      it "renders project status options" do
        subject

        expect(page).to have_menu do
          expect(page).to have_selector :menuitem, count: 7
          expect(page).to have_selector :menuitem, text: "Not set"
          expect(page).to (have_selector :menuitem, text: "On track", aria: { current: true } do |link|
            expect(link[:"data-turbo-method"]).to eq "put"
          end)
          expect(page).to have_selector :menuitem, text: "At risk"
          expect(page).to have_selector :menuitem, text: "Not started"
          expect(page).to have_selector :menuitem, text: "Finished"
          expect(page).to have_selector :menuitem, text: "Discontinued"
          expect(page).to have_selector :menuitem, text: "Off track"
        end
      end
    end
  end
end
