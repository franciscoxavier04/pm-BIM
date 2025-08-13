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
      Scimitar::Schema::Attribute.new(name: "familyName",
                                      caseExact: false,
                                      type: "string",
                                      required: true),
      Scimitar::Schema::Attribute.new(name: "givenName",
                                      caseExact: false,
                                      type: "string",
                                      required: true)
    ]
  end
end

class OpenProjectNameComplexType < Scimitar::ComplexTypes::Base
  set_schema OpenProjectNameSchema
end

module ScimitarSchemaExtension
  AUTHENTICATION_SCHEMES = [
    Scimitar::AuthenticationScheme.new(
      type: "oauth2",
      name: "OAuth2",
      description: OpenProject::Static::Links.links[:sysadmin_docs][:scim_static_access_token_authentication_method][:href]
    ),
    Scimitar::AuthenticationScheme.new(
      type: "oauthbearertoken",
      name: "OAuth Bearer Token",
      description: OpenProject::Static::Links.links[:sysadmin_docs][:scim_oauth2_client_credentials_authentication_method][:href]
    ),
    Scimitar::AuthenticationScheme.new(
      type: "oidcjwt",
      name: "OpenID Provider JWT",
      description: OpenProject::Static::Links.links[:sysadmin_docs][:scim_jwt_authetication_method][:href]
    )
  ].freeze

  class LimitedServiceProviderConfiguration
    include ActiveModel::Model

    attr_accessor(
      :authenticationSchemes,
      :meta,
      :schemas
    )

    def initialize(attributes = {})
      defaults = {
        meta: Scimitar::Meta.new(
          resourceType: "ServiceProviderConfig",
          created: Time.zone.now,
          lastModified: Time.zone.now,
          version: "1"
        ),
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"],
        authenticationSchemes: AUTHENTICATION_SCHEMES
      }

      super(defaults.merge(attributes))
    end
  end

  module Group
    def scim_attributes
      [
        Scimitar::Schema::Attribute.new(name: "displayName",
                                        type: "string",
                                        required: true),
        Scimitar::Schema::Attribute.new(name: "members",
                                        multiValued: true,
                                        complexType: Scimitar::ComplexTypes::ReferenceMember,
                                        mutability: "readWrite"),
        Scimitar::Schema::Attribute.new(name: "externalId",
                                        type: "string",
                                        uniqueness: "server",
                                        caseExact: true,
                                        required: true),
        Scimitar::Schema::Attribute.new(name: "id",
                                        caseExact: true,
                                        type: "string",
                                        uniqueness: "server",
                                        mutability: "readOnly")
      ]
    end
  end

  module User
    def scim_attributes
      [
        Scimitar::Schema::Attribute.new(name: "userName",
                                        type: "string",
                                        uniqueness: "server",
                                        required: true),
        Scimitar::Schema::Attribute.new(name: "name",
                                        complexType: OpenProjectNameComplexType,
                                        required: true),
        Scimitar::Schema::Attribute.new(name: "active",
                                        type: "boolean"),
        Scimitar::Schema::Attribute.new(name: "emails",
                                        multiValued: true,
                                        complexType: Scimitar::ComplexTypes::Email,
                                        required: true),
        Scimitar::Schema::Attribute.new(name: "groups",
                                        multiValued: true,
                                        complexType: Scimitar::ComplexTypes::ReferenceGroup,
                                        mutability: "readOnly"),
        Scimitar::Schema::Attribute.new(name: "externalId",
                                        type: "string",
                                        uniqueness: "server",
                                        caseExact: true,
                                        required: true),
        Scimitar::Schema::Attribute.new(name: "id",
                                        caseExact: true,
                                        type: "string",
                                        uniqueness: "server",
                                        mutability: "readOnly")
      ]
    end
  end
end
