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

require "fileutils"

module OpenProject::Bim::BcfXml
  class Exporter < ::WorkPackage::Exports::QueryExporter
    def initialize(object, options = {})
      object.add_filter("bcf_issue_associated", "=", ["t"])
      super
    end

    def current_user
      User.current
    end

    def self.key
      :bcf
    end

    def export!
      Dir.mktmpdir do |dir|
        files = create_bcf! dir
        zip = zip_folder dir, files
        success(zip)
      end
    rescue StandardError => e
      Rails.logger.error "Failed to export work package list #{e} #{e.message}"
      raise e
    end

    def success(zip)
      Exports::Result
        .new format: :xls,
             content: zip,
             title: bcf_filename,
             mime_type: "application/octet-stream"
    end

    def bcf_filename
      # We often have an internal query name that is not meant
      # for public use or was given by a user.
      if query.name.present? && query.name != "_"
        return sane_filename("#{query.name}.bcf")
      end

      sane_filename(
        "#{Setting.app_title} #{I18n.t(:label_work_package_plural)} \
        #{format_time_as_date(Time.current, format: '%Y-%m-%d')}.bcf"
      )
    end

    def zip_folder(dir, files)
      zip_file = Tempfile.new bcf_filename

      Zip::OutputStream.open(zip_file.path) do |zos|
        files.each do |file|
          name = file.sub("#{dir}/", "")
          zos.put_next_entry(name)
          zos.print File.read(file)
        end
      end

      zip_file
    end

    def create_bcf!(bcf_folder)
      manifest_file = write_manifest(bcf_folder)
      files = [manifest_file]

      work_packages.find_each do |wp|
        # Update or create the BCF issue from the given work package
        issue = IssueWriter.update_from!(wp)

        # Create a folder for the issue
        issue_folder = topic_folder_for(bcf_folder, issue)

        # Append the markup itself
        files << topic_markup_file(issue_folder, issue)

        # Append any viewpoints
        files.concat viewpoints_for(issue_folder, issue)

        # TODO additional files such as BIM snippets
      end

      files
    end

    ##
    # Write the manifest file <dir>/bcf.version
    def write_manifest(dir)
      File.join(dir, "bcf.version").tap do |manifest_file|
        dump_file manifest_file, manifest_xml
      end
    end

    ##
    # Create and return the issue folder
    # /dir/<uuid>/
    def topic_folder_for(dir, issue)
      File.join(dir, issue.uuid).tap do |issue_dir|
        Dir.mkdir issue_dir
      end
    end

    ##
    # Write each work package BCF
    def topic_markup_file(issue_dir, issue)
      File.join(issue_dir, "markup.bcf").tap do |file|
        dump_file file, issue.markup
      end
    end

    ##
    # Write viewpoints
    def viewpoints_for(issue_dir, issue)
      [].tap do |files|
        issue.viewpoints.find_each do |vp|
          vp_file = File.join(issue_dir, "#{vp.uuid}.bcfv")
          snapshot_file = File.join(issue_dir, "#{vp.uuid}#{vp.snapshot.extension}")

          # Copy the files
          dump_file vp_file, ViewpointWriter.new(vp).to_xml
          FileUtils.cp vp.snapshot.local_path, snapshot_file

          files << vp_file << snapshot_file
        end
      end
    end

    def manifest_xml
      Nokogiri::XML::Builder.new do |xml|
        xml.comment created_by_comment
        xml.Version "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                    "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
                    "VersionId" => "2.1" do
          xml.DetailedVersion "2.1"
        end
      end.to_xml
    end

    def dump_file(path, content)
      File.write(path, content)
    end

    def created_by_comment
      " Created by #{Setting.app_title} #{OpenProject::VERSION} at #{Time.now} "
    end
  end
end
