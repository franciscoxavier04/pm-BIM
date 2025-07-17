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

class Budget < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :project
  has_many :work_packages, dependent: :nullify
  has_many :material_budget_items, -> {
    includes(:cost_type).order(Arel.sql("material_budget_items.id ASC"))
  }, dependent: :destroy
  has_many :labor_budget_items, -> {
    includes(:user).order(Arel.sql("labor_budget_items.id ASC"))
  }, dependent: :destroy

  validates_associated :material_budget_items
  validates_associated :labor_budget_items

  after_update :save_material_budget_items
  after_update :save_labor_budget_items

  has_many :cost_entries, through: :work_packages
  has_many :time_entries, through: :work_packages

  has_many :parent_budget_relations, class_name: "BudgetRelation",
                                     foreign_key: "child_budget_id",
                                     dependent: :destroy,
                                     inverse_of: :child_budget

  has_many :child_budget_relations, class_name: "BudgetRelation",
                                    foreign_key: "parent_budget_id",
                                    dependent: :destroy,
                                    inverse_of: :parent_budget

  include ActiveModel::ForbiddenAttributesProtection

  acts_as_attachable
  acts_as_journalized

  acts_as_event type: "cost-objects",
                title: Proc.new { |o| "#{I18n.t(:label_budget)} ##{o.id}: #{o.subject}" },
                url: Proc.new { |o| { controller: "budgets", action: "show", id: o.id } }

  validates :subject, :project, :author, :fixed_date, presence: true
  validates :subject, length: { maximum: 255 }
  validates :subject, length: { minimum: 1 }

  enum :state, {
    planned: "planned",
    draft: "draft",
    submitted: "submitted",
    approved: "approved",
    rejected: "rejected"
  }, validate: { allow_nil: true }

  class << self
    def visible(user)
      includes(:project)
        .references(:projects)
        .merge(Project.allowed_to(user, :view_budgets))
    end

    # TODO: Extract into copy service
    def new_copy(source)
      copy = new(copy_attributes(source))

      copy_budget_items(source, copy, items: :labor_budget_items)
      copy_budget_items(source, copy, items: :material_budget_items)

      copy
    end

    protected

    def copy_attributes(source)
      source.attributes.slice("project_id", "subject", "description", "fixed_date", "state",
                              "supplementary_amount").merge("author" => User.current)
    end

    def copy_budget_items(source, sink, items:)
      raise ArgumentError unless %i(labor_budget_items material_budget_items).include? items

      source.send(items).each do |bi|
        to_slice = if items == :material_budget_items
                     %w(units cost_type_id comments amount)
                   else
                     %w(hours user_id comments amount)
                   end

        sink.send(items).build(bi.attributes.slice(*to_slice).merge("budget" => sink))
      end
    end
  end

  def budget
    supplementary_amount + material_budget + labor_budget + budget_added_by_children
  end

  def children_budgets_count
    # TODO: Efficient with query
    child_budget_relations.includes(:child_budget).sum { |rel| 1 + rel.child_budget.children_budgets_count }
  end

  def budget_added_by_children
    # TODO: Efficient with query
    @budget_added_by_children ||= child_budget_relations.add.includes(:child_budget).sum do |rel|
      rel.child_budget.budget
    end
  end

  def allocated_to_children
    # TODO: Efficient with query
    @allocated_to_children ||= child_budget_relations.includes(:child_budget).sum { |rel| rel.child_budget.budget }
  end

  def allocated_unused
    allocated_to_children - spent_on_children
  end

  def spent_with_children
    spent + spent_on_children
  end

  def spent_on_children
    # TODO: Efficient with query
    @spent_on_children ||= child_budget_relations.includes(:child_budget).sum do |rel|
      rel.child_budget.spent_with_children
    end
  end

  def type_label
    I18n.t(:label_budget)
  end

  def edit_allowed?
    User.current.allowed_in_project?(:edit_budgets, project)
  end

  # Amount of the budget spent.  Expressed as as a percentage whole number
  def budget_ratio
    return 0.0 if budget.nil? || budget == 0.0

    gone = spent + allocated_to_children

    ((gone / budget) * 100).round
  end

  def css_classes
    "budget"
  end

  def to_s
    subject
  end

  def name
    subject
  end

  def material_budget
    @material_budget ||= material_budget_items.visible_costs.inject(BigDecimal("0.0000")) { |sum, i| sum += i.costs }
  end

  def labor_budget
    @labor_budget ||= labor_budget_items.visible_costs.inject(BigDecimal("0.0000")) { |sum, i| sum += i.costs }
  end

  def spent
    spent_material + spent_labor
  end

  def spent_material
    @spent_material ||= if cost_entries.blank?
                          BigDecimal("0.0000")
                        else
                          cost_entries.visible_costs(User.current, project).sum("CASE
          WHEN #{CostEntry.table_name}.overridden_costs IS NULL THEN
            #{CostEntry.table_name}.costs
          ELSE
            #{CostEntry.table_name}.overridden_costs END").to_d
                        end
  end

  def spent_labor
    @spent_labor ||= if time_entries.blank?
                       BigDecimal("0.0000")
                     else
                       time_entries.visible_costs(User.current, project).sum("CASE
          WHEN #{TimeEntry.table_name}.overridden_costs IS NULL THEN
            #{TimeEntry.table_name}.costs
          ELSE
            #{TimeEntry.table_name}.overridden_costs END").to_d
                     end
  end

  def available
    budget - spent - allocated_to_children
  end

  def new_material_budget_item_attributes=(material_budget_item_attributes)
    material_budget_item_attributes.each do |_index, attributes|
      correct_material_attributes!(attributes)

      if valid_material_budget_attributes?(attributes)
        material_budget_items.build(attributes)
      end
    end
  end

  def existing_material_budget_item_attributes=(material_budget_item_attributes)
    update_budget_item_attributes(material_budget_item_attributes, type: "material")
  end

  def save_material_budget_items
    material_budget_items.each do |material_budget_item|
      material_budget_item.save(validate: false)
    end
  end

  def new_labor_budget_item_attributes=(labor_budget_item_attributes)
    labor_budget_item_attributes.each do |_index, attributes|
      correct_labor_attributes!(attributes)

      if valid_labor_budget_attributes?(attributes)
        item = labor_budget_items.build(attributes)
        item.budget = self # to please the labor_budget_item validation
      end
    end
  end

  def existing_labor_budget_item_attributes=(labor_budget_item_attributes)
    update_budget_item_attributes(labor_budget_item_attributes, type: "labor")
  end

  private

  def save_labor_budget_items
    labor_budget_items.each do |labor_budget_item|
      labor_budget_item.save(validate: false)
    end
  end

  def correct_labor_attributes!(attributes)
    return unless attributes

    attributes[:hours] = Rate.parse_number_string_to_number(attributes[:hours])
    attributes[:amount] = Rate.parse_number_string(attributes[:amount])
  end

  def correct_material_attributes!(attributes)
    return unless attributes

    attributes[:units] = Rate.parse_number_string_to_number(attributes[:units])
    attributes[:amount] = Rate.parse_number_string(attributes[:amount])
  end

  def update_budget_item_attributes(budget_item_attributes, type:)
    return unless edit_allowed?

    budget_items = send(:"#{type}_budget_items")

    budget_items.reject(&:new_record?).each do |budget_item|
      attributes = budget_item_attributes[budget_item.id.to_s.to_sym]
      send(:"correct_#{type}_attributes!", attributes)

      if send(:"valid_#{type}_budget_attributes?", attributes)
        budget_item.attributes = attributes
      else
        # This is surprising as it will delete right away compared to the
        # update of the attributes that requires a save afterwards to take effect.
        budget_items.delete(budget_item)
      end
    end
  end

  def valid_labor_budget_attributes?(attributes)
    attributes &&
      attributes[:hours].to_f.positive? &&
      attributes[:user_id].to_i.positive? &&
      Principal.possible_assignee(project).where(id: attributes[:user_id].to_i).exists?
  end

  def valid_material_budget_attributes?(attributes)
    attributes &&
      attributes[:units].to_f.positive?
  end
end
