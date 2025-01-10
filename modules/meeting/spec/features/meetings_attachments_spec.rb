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
require "features/page_objects/notification"

RSpec.describe "Add an attachment to a meeting (agenda)", :js, with_cuprite: false do
  let(:role) do
    create(:project_role, permissions: %i[view_meetings edit_meetings create_meeting_agendas])
  end

  let(:dev) do
    create(:user, member_with_roles: { project => role })
  end

  let(:project) { create(:project) }

  let(:meeting) do
    create(
      :meeting,
      project:,
      title: "Versammlung",
      agenda: create(:meeting_agenda, text: "Versammlung")
    )
  end

  let(:attachments) { Components::Attachments.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new }
  let(:attachments_list) { Components::AttachmentsList.new }

  before do
    login_as(dev)

    visit "/meetings/#{meeting.id}"

    within "#tab-content-agenda .toolbar" do
      click_on "Edit"
    end
  end

  describe "wysiwyg editor" do
    context "if on an existing page" do
      it "can upload an image via drag & drop" do
        find(".ck-content")

        editor.expect_button "Upload image from computer"

        editor.drag_attachment image_fixture.path, "Some image caption"

        click_on "Save"

        content = find_test_selector("op-meeting--meeting_agenda")

        expect(content).to have_css("img")
        expect(content).to have_content("Some image caption")
      end
    end
  end

  describe "attachment dropzone" do
    it "can upload an image via attaching and drag & drop" do
      editor.wait_until_loaded
      attachments_list.wait_until_visible

      ##
      # Attach file manually
      editor.attachments_list.expect_empty
      attachments.attach_file_on_input(image_fixture.path)
      editor.wait_until_upload_progress_toaster_cleared
      editor.attachments_list.expect_attached("image.png")

      ##
      # and via drag & drop
      editor.attachments_list.drag_enter
      editor.attachments_list.drop(image_fixture)
      editor.wait_until_upload_progress_toaster_cleared
      editor.attachments_list.expect_attached("image.png", count: 2)
    end
  end
end
