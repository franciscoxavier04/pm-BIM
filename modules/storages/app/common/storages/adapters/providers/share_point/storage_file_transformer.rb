# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Adapters
    module Providers
      module SharePoint
        class StorageFileTransformer
          attr_reader :site_name

          def initialize(site_name)
            @site_name = site_name
          end

          def transform(json)
            Results::StorageFile.build(
              id: compose_id(json),
              name: json[:name],
              size: json[:size],
              mime_type: mime_type(json),
              location: extract_location(json),
              created_at: Time.zone.parse(json.dig(:fileSystemInfo, :createdDateTime)),
              last_modified_at: Time.zone.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
              created_by_name: json.dig(:createdBy, :user, :displayName),
              last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
              permissions: %i[readable writeable]
            )
          end

          def parent_transform(json)
            Results::StorageFile.new(
              name: json.dig(:parentReference, :name),
              id: compose_parent_id(json[:parentReference]),
              location: extract_parent_location(json),
              permissions: %i[readable writeable]
            )
          end

          private

          def mime_type(entry)
            return "application/x-op-directory" if entry.key? :folder

            entry.dig(:file, :mimeType)
          end

          def extract_location(json)
            json[:webUrl].gsub(/.*#{site_name}/, "")
          end

          def extract_parent_location(json)
            rindex = UrlBuilder.path(json[:name]).length * -1
            extract_location(json)[0...rindex]
          end

          def compose_id(json)
            "#{json.dig(:parentReference, :driveId)}#{SharePointStorage::IDENTIFIER_SEPARATOR}#{json[:id]}"
          end

          def compose_parent_id(parent)
            item_id = parent[:path].ends_with?("root:") ? nil : parent[:id]

            "#{parent[:driveId]}#{SharePointStorage::IDENTIFIER_SEPARATOR}#{item_id}"
          end
        end
      end
    end
  end
end
