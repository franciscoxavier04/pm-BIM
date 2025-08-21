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
      module Sharepoint
        module Commands
          RSpec.describe CreateFolderCommand, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }
            let(:auth_strategy) { Registry.resolve("sharepoint.authentication.userless").call(false) }
            let(:base_drive) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW" }
            let(:input_data) { Input::CreateFolder.build(folder_name:, parent_location:).value! }

            it_behaves_like "adapter create_folder_command: basic command setup"

            context "when creating a folder in the root", vcr: "sharepoint/create_folder_root" do
              let(:folder_name) { "Földer CreatedBy Çommand" }
              let(:parent_location) { composite_identifier(nil) }
              let(:path) { "/Marcello%20VCR/F%C3%B6lder%20CreatedBy%20%C3%87ommand" }

              it_behaves_like "adapter create_folder_command: successful folder creation"
            end

            context "when creating a folder in a parent folder", vcr: "sharepoint/create_folder_parent" do
              let(:folder_name) { "Földer CreatedBy Çommand" }
              let(:parent_location) { composite_identifier("01ANJ53W7TITEF4WCHRBDKR7VMNUWZ33WD") }
              let(:path) { "/Marcello%20VCR/Folder%20with%20spaces/F%C3%B6lder%20CreatedBy%20%C3%87ommand" }

              it_behaves_like "adapter create_folder_command: successful folder creation"
            end

            context "when creating a folder in a non-existing parent folder", vcr: "sharepoint/create_folder_parent_not_found" do
              let(:folder_name) { "Földer CreatedBy Çommand" }
              let(:parent_location) { composite_identifier("01AZJL5PKU2WV3U3RKKFF4A7ZCWVBXRTEU") }

              it_behaves_like "adapter create_folder_command: parent not found"
            end

            context "when folder already exists", vcr: "sharepoint/create_folder_already_exists" do
              let(:folder_name) { "data" }
              let(:parent_location) { composite_identifier(nil) }

              it_behaves_like "adapter create_folder_command: folder already exists"
            end

            context "when trying to create a folder under the root of the site",
                    vcr: "sharepoint/create_folder_invalid_request" do
              let(:folder_name) { "cant_do_that_folder" }
              let(:parent_location) { "/" }

              it "returns a failure" do
                result = described_class.call(storage:, auth_strategy:, input_data:)

                expect(result).to be_failure

                error = result.failure
                expect(error.code).to eq(:invalid_request)
                expect(error.source).to eq(described_class)
              end
            end

            private

            def composite_identifier(item_id) = "#{base_drive}#{SharepointStorage::IDENTIFIER_SEPARATOR}#{item_id}"

            def delete_created_folder(folder)
              Input::DeleteFolder.build(location: folder.id).bind do |input_data|
                Registry.resolve("sharepoint.commands.delete_folder").call(storage:, auth_strategy:, input_data:)
              end
            end
          end
        end
      end
    end
  end
end
