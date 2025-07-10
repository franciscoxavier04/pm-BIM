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

class OpenProjectNameSchema < Scimitar::Schema::Base
  def self.scim_attributes
    @scim_attributes ||= [
      Scimitar::Schema::Attribute.new(name: "familyName", caseExact: true, type: "string", required: true),
      Scimitar::Schema::Attribute.new(name: "givenName",  caseExact: true, type: "string", required: true)
    ]
  end
end

class OpenProjectNameComplexType < Scimitar::ComplexTypes::Base
  set_schema OpenProjectNameSchema
end

module ScimitarSchemaExtension
  module Group
    def scim_attributes
      [
        Scimitar::Schema::Attribute.new(name: "displayName", caseExact: true, type: "string", required: true),
        Scimitar::Schema::Attribute.new(name: "members", multiValued: true, complexType: Scimitar::ComplexTypes::ReferenceMember,
                                        mutability: "readWrite"),
        Scimitar::Schema::Attribute.new(name: "externalId", type: "string", caseExact: true, required: true)
      ]
    end
  end

  module User
    def scim_attributes
      [
        Scimitar::Schema::Attribute.new(name: "userName", caseExact: true, type: "string", uniqueness: "server", required: true),
        Scimitar::Schema::Attribute.new(name: "name", caseExact: true, complexType: OpenProjectNameComplexType, required: true),
        Scimitar::Schema::Attribute.new(name: "active", type: "boolean"),
        Scimitar::Schema::Attribute.new(name: "emails", multiValued: true, complexType: Scimitar::ComplexTypes::Email,
                                        required: true),
        Scimitar::Schema::Attribute.new(name: "groups", multiValued: true, complexType: Scimitar::ComplexTypes::ReferenceGroup,
                                        mutability: "readOnly"),
        Scimitar::Schema::Attribute.new(name: "externalId", type: "string", caseExact: true, required: true)
      ]
    end
  end
end
