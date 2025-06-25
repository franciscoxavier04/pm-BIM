# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

require "rails_helper"

RSpec.describe EnterpriseEdition::TrialTeaserComponent, type: :component do
  let(:mock_token) do
    instance_double(
      EnterpriseToken,
      days_left: 7,
      plan: :mocked
    )
  end

  before do
    allow(EnterpriseToken).to receive(:active_trial_tokens).and_return([mock_token])
  end

  context "for an admin user" do
    before do
      admin_user = instance_double(User, admin?: true)
      allow(User).to receive(:current).and_return(admin_user)
    end

    it "renders the trial teaser" do
      render_inline(described_class.new)

      component = find_test_selector("op-enterprise-banner")

      within(component) do
        expect(page).to have_no_css(".op-enterprise-banner--close_icon")

        expect(page).to have_text("Buy now")
        expect(page).to have_text("7 days left of mocked trial token")
        expect(page).to have_text("You have access to all Mocked enterprise plan features.")

        expect(page).to have_no_text("Start free trial")
        expect(page).to have_no_text("Book now")
        expect(page).to have_no_text("Upgrade now")
        expect(page).to have_no_text("More information")
      end
    end
  end

  context "for a non-admin user" do
    before do
      admin_user = instance_double(User, admin?: false)
      allow(User).to receive(:current).and_return(admin_user)
    end

    it "nothing is rendered" do
      render_inline(described_class.new)

      expect(page).to have_no_css("[data-test-selector='op-enterprise-banner']")
    end
  end
end
