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

class WorkPackageRelationsTab::RelationsMediator
  RelationGroup = Data.define(:type, :visible_relations, :invisible_relations)

  attr_reader :work_package

  def initialize(work_package:)
    @work_package = work_package
  end

  def visible_relations
    @visible_relations ||= work_package.relations.includes(:to, :from).visible
  end

  def visible_children
    @visible_children ||= work_package.children.visible
  end

  def invisible_relations
    @invisible_relations = work_package.relations.includes(:to, :from).where.not(id: @visible_relations.select(:id))
  end

  def invisible_children
    @invisible_children ||= work_package.children.where.not(id: @visible_children.select(:id))
  end

  def directionally_aware_grouped_relations
    # Collect all unique relation types
    all_relation_types = collect_all_relation_types

    # Group visible and invisible relations by type
    all_relation_types.map do |type|
      RelationGroup.new(
        type: type,
        visible_relations: filter_relations_by_type(visible_relations, type),
        invisible_relations: filter_relations_by_type(invisible_relations, type)
      )
    end
  end

  def any_relations?
    visible_relations.any? || invisible_relations.any? || children.any?
  end

  def any_children?
    visible_children.any? || invisible_children.any?
  end

  private

  def collect_all_relation_types
    (visible_relations + invisible_relations).map do |relation|
      relation.relation_type_for(work_package)
    end.uniq
  end

  def filter_relations_by_type(relations, type)
    relations.select do |relation|
      relation.relation_type_for(work_package) == type
    end
  end
end
