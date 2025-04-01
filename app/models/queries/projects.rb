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

module Queries::Projects
  ::Queries::Register.register(ProjectQuery) do
    filter Filters::ActiveFilter
    filter Filters::AncestorFilter
    filter Filters::AvailableCustomFieldsProjectsFilter
    filter Filters::AvailableProjectAttributesFilter
    filter Filters::CreatedAtFilter
    filter Filters::CustomFieldFilter
    filter Filters::FavoredFilter
    filter Filters::IdFilter
    filter Filters::LatestActivityAtFilter
    filter Filters::ProjectPhaseAnyFilter
    filter Filters::ProjectPhaseGateFilter
    filter Filters::ProjectPhaseFilter
    filter Filters::MemberOfFilter
    filter Filters::NameAndIdentifierFilter
    filter Filters::NameFilter
    filter Filters::ParentFilter
    filter Filters::PrincipalFilter
    filter Filters::ProjectStatusFilter
    filter Filters::PublicFilter
    filter Filters::TemplatedFilter
    filter Filters::TypeFilter
    filter Filters::TypeaheadFilter
    filter Filters::UserActionFilter
    filter Filters::VisibleFilter

    order Orders::CustomFieldOrder
    order Orders::DefaultOrder
    order Orders::LatestActivityAtOrder
    order Orders::ProjectPhaseOrder
    order Orders::NameOrder
    order Orders::ProjectStatusOrder
    order Orders::RequiredDiskSpaceOrder
    order Orders::TypeaheadOrder

    select Selects::CreatedAt
    select Selects::CustomField
    select Selects::Default
    select Selects::Favored
    select Selects::LatestActivityAt
    select Selects::ProjectPhase
    select Selects::RequiredDiskSpace
    select Selects::Status
  end
end
