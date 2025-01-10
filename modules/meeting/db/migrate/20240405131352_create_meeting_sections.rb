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

class CreateMeetingSections < ActiveRecord::Migration[7.1]
  def up
    create_table :meeting_sections do |t|
      t.integer :position
      t.string :title
      t.references :meeting, null: false, foreign_key: true

      t.timestamps
    end

    add_reference :meeting_agenda_items, :meeting_section

    create_and_assign_default_section
  end

  def down
    remove_reference :meeting_agenda_items, :meeting_section
    drop_table :meeting_sections
    # TODO: positions of agenda items are now not valid anymore as they have been scoped to sections
    # Do we need to catch this?
  end

  private

  def create_and_assign_default_section
    StructuredMeeting.includes(:agenda_items).find_each do |meeting|
      section = MeetingSection.create!(
        meeting:,
        title: "Untitled"
      )
      meeting.agenda_items.update_all(meeting_section_id: section.id)
    end
  end
end
