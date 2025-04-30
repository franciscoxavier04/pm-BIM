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

module Types
  module Patterns
    class TokenPropertyMapper
      # rubocop:disable Layout/LineLength
      BASE_ATTRIBUTE_TOKENS = [
        AttributeResolver.new(:id, WorkPackage.human_attribute_name(:id), ->(wp) { wp.id }),
        AttributeResolver.new(:accountable, WorkPackage.human_attribute_name(:responsible), ->(wp) { wp.responsible&.name }),
        AttributeResolver.new(:assignee, WorkPackage.human_attribute_name(:assigned_to), ->(wp) { wp.assigned_to&.name }),
        AttributeResolver.new(:author, WorkPackage.human_attribute_name(:author), ->(wp) { wp.author&.name }),
        AttributeResolver.new(:category, WorkPackage.human_attribute_name(:category), ->(wp) { wp.category&.name }),
        AttributeResolver.new(:creation_date, WorkPackage.human_attribute_name(:created_at), ->(wp) { wp.created_at }),
        AttributeResolver.new(:estimated_time, WorkPackage.human_attribute_name(:estimated_hours), ->(wp) { wp.estimated_hours }),
        AttributeResolver.new(:remaining_time, WorkPackage.human_attribute_name(:remaining_hours), ->(wp) { wp.remaining_hours }),
        AttributeResolver.new(:finish_date, WorkPackage.human_attribute_name(:due_date), ->(wp) { wp.due_date }),
        AttributeResolver.new(:parent_id, WorkPackage.human_attribute_name(:id), ->(parent) { parent.id }),
        AttributeResolver.new(:parent_assignee, WorkPackage.human_attribute_name(:assigned_to), ->(parent) { parent.assigned_to&.name }),
        AttributeResolver.new(:parent_author, WorkPackage.human_attribute_name(:author), ->(parent) { parent.author&.name }),
        AttributeResolver.new(:parent_category, WorkPackage.human_attribute_name(:category), ->(parent) { parent.category&.name }),
        AttributeResolver.new(:parent_creation_date, WorkPackage.human_attribute_name(:created_at), ->(parent) { parent.created_at }),
        AttributeResolver.new(:parent_estimated_time, WorkPackage.human_attribute_name(:estimated_hours), ->(parent) { parent.estimated_hours }),
        AttributeResolver.new(:parent_remaining_time, WorkPackage.human_attribute_name(:remaining_hours), ->(parent) { parent.remaining_hours }),
        AttributeResolver.new(:parent_finish_date, WorkPackage.human_attribute_name(:due_date), ->(parent) { parent.due_date }),
        AttributeResolver.new(:parent_priority, WorkPackage.human_attribute_name(:priority), ->(parent) { parent.priority }),
        AttributeResolver.new(:parent_subject, WorkPackage.human_attribute_name(:subject), ->(parent) { parent.subject }),
        AttributeResolver.new(:priority, WorkPackage.human_attribute_name(:priority), ->(wp) { wp.priority }),
        AttributeResolver.new(:project, WorkPackage.human_attribute_name(:project_id), ->(wp) { wp.project }),
        AttributeResolver.new(:project_active, Project.human_attribute_name(:active), ->(project) { project.active? }),
        AttributeResolver.new(:project_name, Project.human_attribute_name(:name), ->(project) { project.name }),
        AttributeResolver.new(:project_status, Project.human_attribute_name(:status_code), ->(project) { project.status_code }),
        AttributeResolver.new(:project_parent, Project.human_attribute_name(:parent), ->(project) { project.parent_id }),
        AttributeResolver.new(:project_public, Project.human_attribute_name(:public), ->(project) { project.public? }),
        AttributeResolver.new(:start_date, WorkPackage.human_attribute_name(:start_date), ->(wp) { wp.start_date }),
        AttributeResolver.new(:status, WorkPackage.human_attribute_name(:status), ->(wp) { wp.status&.name }),
        AttributeResolver.new(:type, WorkPackage.human_attribute_name(:type), ->(wp) { wp.type&.name })
      ].freeze
      # rubocop:enable Layout/LineLength

      def tokens_for_type(type)
        [
          *BASE_ATTRIBUTE_TOKENS,
          *tokenize(work_package_cfs_for(type)),
          *tokenize(project_attributes, "project_"),
          *tokenize(all_work_package_cfs, "parent_")
        ]
      end

      private

      def default_tokens
        BASE_ATTRIBUTE_TOKENS.each_with_object({ work_package: {}, project: {}, parent: {} }) do |token, obj|
          case token.key.to_s
          when /^project_/
            obj[:project][token.key] = token
          when /^parent_/
            obj[:parent][token.key] = token
          else
            obj[:work_package][token.key] = token
          end
        end
      end

      def prefixed_label(context, attribute_label)
        attribute_context = I18n.t("types.edit.subject_configuration.token.context.#{context}")
        I18n.t("types.edit.subject_configuration.token.label_with_context", attribute_context:, attribute_label:)
      end

      def tokenize(custom_field_scope, prefix = nil)
        custom_field_scope.pluck(:name, :id).map do |name, id|
          AttributeResolver.new(
            :"#{prefix}custom_field_#{id}",
            name,
            ->(context) do
              key = :"custom_field_#{id}"
              return :attribute_not_available unless context.respond_to?(key)

              context.public_send(key)
            end
          )
        end
      end

      def work_package_cfs_for(type)
        all_work_package_cfs.merge(type.custom_fields)
      end

      def all_work_package_cfs
        WorkPackageCustomField.where.not(field_format: %w[text bool link empty]).order(:name)
      end

      def project_attributes
        ProjectCustomField.where.not(field_format: %w[text bool link empty])
                          .where(admin_only: false, multi_value: false).order(:name)
      end
    end
  end
end
