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

module LdapGroups
  class SynchronizationService
    def self.synchronize!
      User.system.run_given do
        new.call
      end
    end

    def call
      LdapAuthSource.find_each do |ldap|
        Rails.logger.info { "[LDAP groups] Retrieving groups from filters for ldap auth source #{ldap.name}" }
        LdapGroups::SynchronizedFilter
          .where(ldap_auth_source_id: ldap.id)
          .find_each do |filter|
          LdapGroups::SynchronizeFilterService
            .new(filter)
            .call
        end

        Rails.logger.info { "[LDAP groups] Start group synchronization for ldap auth source #{ldap.name}" }
        LdapGroups::SynchronizeGroupsService.new(ldap).call
      end
    rescue StandardError => e
      msg = "[LDAP groups] Failed to run LDAP group synchronization. #{e.class.name}: #{e.message}"
      Rails.logger.error msg
    end
  end
end
