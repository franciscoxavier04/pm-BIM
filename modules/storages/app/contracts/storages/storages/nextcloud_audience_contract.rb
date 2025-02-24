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

module Storages::Storages
  class NextcloudAudienceContract < ::ModelContract
    attribute :nextcloud_audience
    validates :nextcloud_audience, presence: true, if: -> { nextcloud_storage_authenticate_via_idp? }

    # Adding this to allow writing the nextcloud_audience
    attribute :provider_fields

    private

    def nextcloud_storage_authenticate_via_idp?
      nextcloud_storage? && @model.authenticate_via_idp?
    end

    def nextcloud_storage?
      @model.is_a?(Storages::NextcloudStorage)
    end
  end
end
