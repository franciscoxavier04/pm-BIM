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

Rails.application.reloader.to_prepare do
  Principals::ReplaceReferencesService.add_replacement("AuthProvider", :creator_id)
  Principals::ReplaceReferencesService.add_replacement("Attachment", :author_id)
  Principals::ReplaceReferencesService.add_replacement("Budget", :author_id)
  Principals::ReplaceReferencesService.add_replacement("Changeset", :user_id)
  Principals::ReplaceReferencesService.add_replacement("Comment", :author_id)
  Principals::ReplaceReferencesService.add_replacement("CostEntry", :logged_by_id)
  Principals::ReplaceReferencesService.add_replacement("CostEntry", :user_id)
  Principals::ReplaceReferencesService.add_replacement("CostQuery", :user_id)
  Principals::ReplaceReferencesService.add_replacement("::Doorkeeper::Application", :owner_id)
  Principals::ReplaceReferencesService.add_replacement("MeetingAgenda", :author_id)
  Principals::ReplaceReferencesService.add_replacement("MeetingAgendaItem", :author_id)
  Principals::ReplaceReferencesService.add_replacement("MeetingAgendaItem", :presenter_id)
  Principals::ReplaceReferencesService.add_replacement("MeetingMinutes", :author_id)
  Principals::ReplaceReferencesService.add_replacement("MeetingParticipant", :user_id)
  Principals::ReplaceReferencesService.add_replacement("Message", :author_id)
  Principals::ReplaceReferencesService.add_replacement("News", :author_id)
  Principals::ReplaceReferencesService.add_replacement("::Notification", :actor_id)
  Principals::ReplaceReferencesService.add_replacement("::Query", :user_id)
  Principals::ReplaceReferencesService.add_replacement("TimeEntry", :logged_by_id)
  Principals::ReplaceReferencesService.add_replacement("TimeEntry", :user_id)
  Principals::ReplaceReferencesService.add_replacement("WikiPage", :author_id)
  Principals::ReplaceReferencesService.add_replacement("WorkPackage", :author_id)
  Principals::ReplaceReferencesService.add_replacement("WorkPackage", :assigned_to_id)
  Principals::ReplaceReferencesService.add_replacement("WorkPackage", :responsible_id)
end
