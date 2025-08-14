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
        module Queries
          RSpec.describe FilesQuery, :webmock do
            let(:user) { create(:admin) }
            let(:storage) { create(:share_point_storage, :sandbox, oauth_client_token_user: user) }

            let(:auth_strategy) { Registry["share_point.authentication.userless"].call(false) }
            let(:input_data) { Input::Files.build(folder:).value! }

            it_behaves_like "adapter files_query: basic query setup"

            # rubocop:disable Layout/LineLength
            context "when parent folder is root", vcr: "share_point/files_query_root" do
              let(:folder) { "/" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK",
                      name: "OpenProject",
                      mime_type: "application/x-op-drive",
                      location: "/OpenProject",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw",
                      name: "Shared Documents",
                      mime_type: "application/x-op-drive",
                      location: "/Shared%20Documents",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Pmdpc8mQ1QJkyIbbWQJol",
                      name: "Selected Permissions",
                      mime_type: "application/x-op-drive",
                      location: "/Selected%20Permissions",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY_YoKf1JPvYSJeFRsyx4zF_",
                      name: "Chris document library",
                      mime_type: "application/x-op-drive",
                      location: "/Chris%20document%20library",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8CfNaHr_0ERYs5kgmEWFrX",
                      name: "Marcello AMPF",
                      mime_type: "application/x-op-drive",
                      location: "/Marcello%20AMPF",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8opHtYeMANTahXlS54FgHn",
                      name: "Dominic",
                      mime_type: "application/x-op-drive",
                      location: "/Dominic",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY93AQ5rgPKoR7tMwpspgj95",
                      name: "Markus",
                      mime_type: "application/x-op-drive",
                      location: "/Markus",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW",
                      name: "Marcello VCR",
                      mime_type: "application/x-op-drive",
                      location: "/Marcello%20VCR",
                      permissions: %i[readable writeable]
                    )
                  ],
                  parent: Results::StorageFile.new(id: "1269877d26360587caf07834bc72ee3ad3c3698f1651bf85d8562e7fda19aa0f",
                                                   name: "OPTest",
                                                   location: "/",
                                                   permissions: %i[readable writeable]),
                  ancestors: []
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "when requesting a drive", vcr: "share_point/files_query_drive" do
              let(:folder) { "/Marcello VCR" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W5P3SUY3ZCDTRA3KLXRGA5A2M3S",
                      name: "data",
                      size: 12605,
                      mime_type: "application/x-op-directory",
                      created_at: Time.zone.parse("2025-04-07 12:02:26Z"),
                      last_modified_at: Time.zone.parse("2025-04-07 12:02:26Z"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      location: "/Marcello%20VCR/data",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W2MWJ6SKEZPHFGIAAB325KYYMPE",
                      name: "empty",
                      size: 0,
                      mime_type: "application/x-op-directory",
                      created_at: Time.zone.parse("2025-07-28 08:46:36Z"),
                      last_modified_at: Time.zone.parse("2025-07-28 08:46:36Z"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      location: "/Marcello%20VCR/empty",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W7TITEF4WCHRBDKR7VMNUWZ33WD",
                      name: "Folder with spaces",
                      size: 0,
                      mime_type: "application/x-op-directory",
                      created_at: Time.zone.parse("2025-08-05 15:20:12Z"),
                      last_modified_at: Time.zone.parse("2025-08-05 15:20:13Z"),
                      created_by_name: "OP Owner",
                      last_modified_by_name: "OP Owner",
                      location: "/Marcello%20VCR/Folder%20with%20spaces",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53WZVLAWJSVFKOFF3HLYZPMPUK6HI",
                      name: "simply_oidc.jpg",
                      size: 56483,
                      mime_type: "image/jpeg",
                      created_at: Time.zone.parse("2025-04-07 12:02:42Z"),
                      last_modified_at: Time.zone.parse("2025-04-07 12:02:42Z"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      location: "/Marcello%20VCR/simply_oidc.jpg",
                      permissions: %i[readable writeable]
                    )
                  ],
                  parent: Results::StorageFile.new(
                    id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||",
                    name: "Marcello VCR",
                    location: "/Marcello%20VCR",
                    permissions: %i[readable writeable]
                  ),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "OPTest", location: "/")
                  ]
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "when requesting an folder", vcr: "share_point/files_query_folder" do
              let(:folder) { "/Marcello VCR/data" }

              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W6DBDYX553L4REYNOMUI6XVMTO6",
                      name: "subfolder",
                      size: 11845,
                      mime_type: "application/x-op-directory",
                      location: "/Marcello%20VCR/data/subfolder",
                      created_at: Time.zone.parse("2025-07-28 15:03:27.000000000 UTC +00:00"),
                      last_modified_at: Time.zone.parse("2025-07-28 15:03:27.000000000 UTC +00:00"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W26P5RNXU7V2JBKCVQQAGGTO46A",
                      name: "edge one_drive_health_report_2025-07-22T16_03_25Z.txt",
                      size: 760,
                      mime_type: "text/plain",
                      location: "/Marcello%20VCR/data/edge%20one_drive_health_report_2025-07-22T16_03_25Z.txt",
                      created_at: Time.zone.parse("2025-07-28 08:45:30.000000000 UTC +00:00"),
                      last_modified_at: Time.zone.parse("2025-07-28 08:45:30.000000000 UTC +00:00"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      permissions: %i[readable writeable]
                    )
                  ],
                  parent: Results::StorageFile.new(
                    id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W5P3SUY3ZCDTRA3KLXRGA5A2M3S",
                    name: "data",
                    location: "/Marcello%20VCR/data",
                    permissions: %i[readable writeable]
                  ),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "OPTest", location: "/"),
                    Results::StorageFileAncestor.new(name: "Marcello VCR", location: "/Marcello VCR")
                  ]
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "when requesting a sub folder", vcr: "share_point/files_query_sub_folder" do
              let(:folder) { "/Marcello VCR/data/subfolder" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W7MUYDYQAA3WVEYDJQNZVSKNPGD",
                      name: "fw13-easy-effects.json",
                      size: 11845,
                      mime_type: "application/json",
                      created_at: Time.zone.parse("2025-07-28 15:06:31.000000000 UTC +00:00"),
                      last_modified_at: Time.zone.parse("2025-07-28 15:06:31.000000000 UTC +00:00"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      location: "/Marcello%20VCR/data/subfolder/fw13-easy-effects.json",
                      permissions: %i[readable writeable]
                    )
                  ],
                  parent: Results::StorageFile.new(
                    id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W6DBDYX553L4REYNOMUI6XVMTO6",
                    name: "subfolder",
                    location: "/Marcello%20VCR/data/subfolder",
                    permissions: %i[readable writeable]
                  ),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "OPTest", location: "/"),
                    Results::StorageFileAncestor.new(name: "Marcello VCR", location: "/Marcello VCR"),
                    Results::StorageFileAncestor.new(name: "data", location: "/Marcello VCR/data")
                  ]
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "when requesting an empty folder", vcr: "share_point/files_query_empty_folder" do
              let(:folder) { "/Marcello VCR/empty" }

              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [],
                  parent: Results::StorageFile.new(
                    id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W2MWJ6SKEZPHFGIAAB325KYYMPE",
                    name: "empty",
                    location: "/Marcello%20VCR/empty",
                    permissions: %i[readable writeable]
                  ),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "OPTest", location: "/"),
                    Results::StorageFileAncestor.new(name: "Marcello VCR", location: "/Marcello VCR")
                  ]
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "when requesting an empty library", vcr: "share_point/files_query_empty_drive" do
              let(:folder) { "/Selected Permissions" }

              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [],
                  parent: Results::StorageFile.new(
                    id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Pmdpc8mQ1QJkyIbbWQJol",
                    name: "Selected Permissions",
                    location: "/Selected%20Permissions",
                    permissions: %i[readable writeable]
                  ),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "OPTest", location: "/")
                  ]
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "when requesting an unknown file", vcr: "share_point/files_query_file_not_found" do
              let(:folder) { "/Marcello VCR/POTATO" }

              it_behaves_like "adapter files_query: not found", Internal::ChildrenQuery
            end

            context "when requestion an unknown drive", vcr: "share_point/files_query_drive_not_found" do
              let(:folder) { "/That is no moon" }

              it_behaves_like "adapter files_query: not found"
            end
            # rubocop:enable Layout/LineLength
          end
        end
      end
    end
  end
end
