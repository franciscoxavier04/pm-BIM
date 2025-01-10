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

RSpec.describe AttributeHelpTextsController do
  let(:user) { build_stubbed(:user) }
  let(:model) { build(:work_package_help_text) }

  let(:find_expectation) do
    allow(AttributeHelpText)
      .to receive(:find)
      .with(1234.to_s)
      .and_return(model)
  end

  before do
    login_as user

    mock_permissions_for(user) do |mock|
      mock.allow_globally :edit_attribute_help_texts
    end
  end

  describe "#index" do
    before do
      allow(AttributeHelpText).to receive(:all).and_return [model]

      get :index
    end

    it "is successful" do
      expect(response).to be_successful
      expect(assigns(:texts_by_type)).to eql("WorkPackage" => [model])
    end
  end

  describe "#edit" do
    before do
      find_expectation

      get :edit, params: { id: 1234 }
    end

    context "when found" do
      it "is successful" do
        expect(response).to be_successful
        expect(assigns(:attribute_help_text)).to eql model
      end
    end

    context "when not found" do
      let(:find_expectation) do
        allow(AttributeHelpText)
          .to receive(:find)
          .with(1234.to_s)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#update" do
    let(:call) do
      put :update,
          params: {
            id: 1234,
            attribute_help_text: {
              help_text: "my new help text"
            }
          }
    end

    before do
      find_expectation
    end

    context "when save is success" do
      before do
        expect(model).to receive(:save).and_return(true)

        call
      end

      it "edits the announcement" do
        expect(response).to redirect_to action: :index, tab: "WorkPackage"
        expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)

        expect(model.help_text).to eq("my new help text")
      end
    end

    context "when save is failure" do
      before do
        expect(model).to receive(:save).and_return(false)

        call
      end

      it "fails to update the announcement" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template "edit"
      end
    end

    context "when not found" do
      let(:find_expectation) do
        allow(AttributeHelpText)
          .to receive(:find)
          .with(1234.to_s)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      before do
        call
      end

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end
end
