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
require_module_spec_helper

module Storages
  module Adapters
    module Providers
      module SharePoint
        RSpec.describe SharePointContract, :storage_server_helpers, :webmock do
          let(:current_user) { create(:admin) }
          let(:storage) { build(:share_point_storage, host: "https://openproject.sharepoint.com ") }

          # As the SharePointContract is selected by the BaseContract to make writable attributes available,
          # the BaseContract needs to be instantiated here.
          subject(:contract) { Storages::BaseContract.new(storage, current_user) }

          it "is valid with all required attributes" do
            expect(subject).to be_valid
          end

          context "with missing name" do
            before do
              storage.name = nil
            end

            it "is not valid" do
              expect(subject).not_to be_valid
              expect(subject.errors[:name]).to be_present
            end
          end

          describe "host" do
            context "with valid host" do
              before do
                storage.host = "https://exmaple.com/"
              end

              it "must be valid" do
                expect(contract).to be_valid
              end
            end

            context "with invalid host" do
              before do
                storage.host = "not-a-url"
              end

              it "is not valid" do
                expect(subject).not_to be_valid
                expect(subject.errors[:host]).to be_present
              end
            end
          end

          context "with missing site_id" do
            before do
              storage.site_id = nil
            end

            it "is not valid" do
              expect(subject).not_to be_valid
              expect(subject.errors[:site_id]).to be_present
            end
          end

          context "with invalid site_id" do
            before do
              storage.site_id = "not-a-guid"
            end

            it "is not valid" do
              expect(subject).not_to be_valid
              expect(subject.errors[:site_id]).to be_present
            end
          end

          context "with missing library_id" do
            before do
              storage.library_id = nil
            end

            it "is not valid" do
              expect(subject).not_to be_valid
              expect(subject.errors[:library_id]).to be_present
            end
          end
        end
      end
    end
  end
end
