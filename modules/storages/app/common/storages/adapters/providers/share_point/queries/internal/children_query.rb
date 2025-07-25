# frozen_string_literal: true

#-- copyright
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
                handle_response(http.get(request_uri(drive_id, location) + FIELDS)).bind { parse_response(it) }
              end

              private

              def request_uri(drive_id, location)
                if location.root?
                  UrlBuilder.url(base_uri, "/v1.0/drives/#{drive_id}/root/children")
                else
                  UrlBuilder.url(base_uri, "/v1.0/drives/#{drive_id}/items/#{location.path}/children")
                end
              end

              def handle_response(response)
                error = Results::Error.new(source: self.class, payload: response)

                case response
                in { status: 200..299 }
                  Success(response.json(symbolize_keys: true)[:value])
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
                  ancestors: forge_ancestors(entry[:parentReference], entry[:webUrl])
                )
              end

              def forge_ancestors(parent_reference, web_url)
                # 1. This is a query on a drive, so we will always have the site root.
                # 2. Then this can be a drive root or a folder query
                #   a. Drive Root we need to add it to the ancestors.
                drive_name = CGI.unescape(web_url.gsub(/.*#{site_name}\//, "").split("/").first)
                list = parent_reference[:path].gsub(/.*root:/, "").split("/")[0..-2] # Last item is the parent

                list.each_with_object([site_root]) do |component, ancestors|
                  if component.blank?
                    ancestors.unshift drive_root(parent_reference[:driveId], drive_name)
                  end
                end
              end

              def drive_root(drive_id, name)
                Results::StorageFile.new(
                  name:,
                  location: UrlBuilder.path("/#{name}"),
                  id: "#{drive_id}||",
                  permissions: %i[readable writeable]
                )
              end

              def site_root
                Results::StorageFile.new(
                  name: site_name,
                  location: "/",
                  id: Digest::SHA256.hexdigest("i_am_root"),
                  permissions: %i[readable writeable]
                )
              end
            end
          end
        end
      end
    end
  end
end
