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

RSpec.describe Recaptcha::AdminController do
  let(:user) { build_stubbed(:admin) }

  before do
    login_as user
  end

  describe "as non admin" do
    let(:user) { build_stubbed(:user) }

    it "does not allow access" do
      get :show
      expect(response).to have_http_status :forbidden

      post :update
      expect(response).to have_http_status :forbidden
    end
  end

  describe "show" do
    it "renders show" do
      get :show
      expect(response).to be_successful
      expect(response).to render_template "recaptcha/admin/show"
    end
  end

  describe "#update" do
    it "fails if invalid param" do
      post :update, params: { recaptcha_type: :unknown }
      expect(response).to be_redirect
      expect(flash[:error]).to be_present
    end

    it "succeeds" do
      expected = { recaptcha_type: "v2", website_key: "B", secret_key: "A" }

      expect(Setting)
        .to receive(:plugin_openproject_recaptcha=)
        .with(expected)

      post :update, params: expected
      expect(response).to be_redirect
      expect(flash[:error]).to be_nil
      expect(flash[:notice]).to be_present
    end
  end
end
