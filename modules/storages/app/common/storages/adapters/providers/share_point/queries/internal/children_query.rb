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

module Storages
  module Adapters
    module Providers
      module SharePoint
        module Queries
          module Internal
            class ChildrenQuery < Base
              FIELDS = "?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder,parentReference"

              def self.call(storage:, http:, drive_id:, location:)
                new(storage).call(drive_id:, http:, location:)
              end

              def initialize(storage)
                super
                @transformer = StorageFileTransformer.new(site_name)
              end

              def call(http:, drive_id:, location:)
                handle_response(http.get(request_uri(drive_id, location) + FIELDS)).bind do |json|
                  files = json.fetch(:value, [])
                  return empty_response(http, drive_id, location) if files.empty?

                  parse_response(files)
                end
              end

              private

              def request_uri(drive_id, location)
                if location.root?
                  UrlBuilder.url(base_uri, "/v1.0/drives/#{drive_id}/root/children")
                else
                  UrlBuilder.url(base_uri, "/v1.0/drives/#{drive_id}/root:#{UrlBuilder.path(location.path)}:/children")
                end
              end

              def folder_uri(drive_id, folder)
                base_url = UrlBuilder.url(base_uri, "/v1.0/drives/#{drive_id}/root")
                return base_url if folder.root?

                "#{base_url}:#{UrlBuilder.path(folder.path)}"
              end

              def handle_response(response)
                error = Results::Error.new(source: self.class, payload: response)

                case response
                in { status: 200..299 }
                  Success(response.json(symbolize_keys: true))
                in { status: 400 }
                  Failure(error.with(code: :request_error))
                in { status: 404 }
                  Failure(error.with(code: :not_found))
                in { status: 403 }
                  Failure(error.with(code: :forbidden))
                in { status: 401 }
                  Failure(error.with(code: :unauthorized))
                else
                  Failure(error.with(code: :error))
                end
              end

              def parse_response(json)
                files = json.filter_map { @transformer.transform(it).value_or(nil) }
                entry = json.first

                Results::StorageFileCollection.build(
                  files:,
                  parent: @transformer.parent_transform(entry),
                  ancestors: build_ancestors(entry[:parentReference], entry[:webUrl])
                )
              end

              def empty_response(http, drive_id, folder)
                handle_response(http.get(folder_uri(drive_id, folder) + FIELDS)).bind do |json|
                  Results::StorageFileCollection.build(
                    files: [],
                    parent: @transformer.bare_transform(json),
                    ancestors: build_empty_ancestors(json)
                  )
                end
              end

              def build_ancestors(parent_reference, web_url)
                drive_name = CGI.unescape(web_url.gsub(/.*#{site_name}\//, "").split("/").first)
                list = parent_reference[:path].gsub(/.*root:/, "").split("/")[0..-2] # Last item is the parent
                forge_ancestors(list, drive_name)
              end

              def build_empty_ancestors(json)
                parent_reference = json[:parentReference]

                drive_name = CGI.unescape(json[:webUrl].gsub(/.*#{site_name}\//, "").split("/").first)
                list = parent_reference[:path].gsub(/.*root:/, "").split("/")
                return [site_root, drive_root(drive_name)] if list.empty?

                forge_ancestors(list, drive_name)
              end

              def forge_ancestors(component_list, drive_name)
                component_list.each_with_object([site_root]) do |component, ancestors|
                  if component.blank?
                    ancestors.push(drive_root(drive_name))
                  else
                    ancestors.push(
                      @transformer.build_ancestor(component, "#{CGI.unescape(ancestors.last.location)}/#{component}")
                    )
                  end
                end
              end

              def drive_root(name)
                @transformer.build_ancestor(name, "/#{name}")
              end

              def site_root
                @transformer.build_ancestor(site_name, "/")
              end
            end
          end
        end
      end
    end
  end
end
