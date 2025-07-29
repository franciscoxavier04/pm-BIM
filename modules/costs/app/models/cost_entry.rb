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

class CostEntry < ApplicationRecord
  ALLOWED_ENTITY_TYPES = %w[WorkPackage].freeze

  belongs_to :project
  belongs_to :entity, polymorphic: true
  belongs_to :user
  belongs_to :logged_by, class_name: "User"
  include ::Costs::DeletedUserFallback
  belongs_to :cost_type
  belongs_to :budget
  belongs_to :rate, class_name: "CostRate"

  include ActiveModel::ForbiddenAttributesProtection

  after_initialize :after_initialize
  before_validation :before_validation
  before_save :before_save
  validate :validate

  validates :entity, :project_id, :user_id, :logged_by_id, :cost_type_id, :units, :spent_on, presence: true
  validates :units, numericality: { allow_nil: false, message: :invalid }
  validates :comments, length: { maximum: 255, allow_nil: true }
  validates :entity_type,
            inclusion: { in: ALLOWED_ENTITY_TYPES },
            allow_blank: true

  scope :on_work_packages, ->(work_packages) { where(entity: work_packages) }

  extend CostEntryScopes
  include Entry::Costs
  include Entry::SplashedDates
  include Entry::DeprecatedAssociation

  def after_initialize
    return unless new_record?

    # This belongs in a SetAttributesService, but cost_entries are not yet created as such
    self.logged_by = User.current

    if cost_type.nil? && default_cost_type = CostType.default
      self.cost_type_id = default_cost_type.id
    end
  end

  def before_validation
    self.project = entity.project if entity && project.nil?
  end

  def validate # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    errors.add :units, :invalid if units&.negative?
    errors.add :project_id, :invalid if project.nil?
    errors.add :entity, :invalid if entity.nil? || (project != entity.project)
    errors.add :cost_type_id, :invalid if cost_type.present? && cost_type.deleted_at.present?
    errors.add :user_id, :invalid if project.present? && project.users.exclude?(user) && user_id_changed?

    begin
      spent_on.to_date
    rescue StandardError
      errors.add :spent_on, :invalid
    end
  end

  def before_save
    self.spent_on &&= spent_on.to_date
    update_costs
  end

  def entity=(value)
    if value.is_a?(String) && value.starts_with?("gid://")
      super(GlobalID::Locator.locate(value, only: ALLOWED_ENTITY_TYPES.map(&:safe_constantize)))
    else
      super
    end
  end

  def entity_gid
    entity&.to_gid.to_s
  end

  def overwritten_costs=(costs)
    write_attribute(:overwritten_costs, CostRate.parse_number_string_to_number(costs))
  end

  def units=(units)
    write_attribute(:units, CostRate.parse_number_string(units))
  end

  def current_rate
    cost_type.rate_at(self.spent_on)
  end

  # Returns true if the cost entry can be edited by usr, otherwise false
  def editable_by?(usr)
    usr.allowed_in_project?(:edit_cost_entries, project) ||
      (usr.allowed_in_project?(:edit_own_cost_entries, project) && user_id == usr.id)
  end

  def creatable_by?(usr)
    usr.allowed_in_project?(:log_costs, project) ||
      (usr.allowed_in_project?(:log_own_costs, project) && user_id == usr.id)
  end

  def costs_visible_by?(usr)
    usr.allowed_in_project?(:view_cost_rates, project) ||
      (usr.id == user_id && !overridden_costs.nil?)
  end

  private

  def cost_attribute
    units
  end
end
