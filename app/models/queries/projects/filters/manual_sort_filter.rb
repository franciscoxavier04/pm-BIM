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

class Queries::Projects::Filters::ManualSortFilter < Queries::Projects::Filters::Base
  include ::Queries::Projects::Common::ManualSorting

  def available_operators
    [Queries::Operators::PortfolioProposalProjects]
  end

  def available?
    true
  end

  def type
    :empty_value
  end

  def where
    Project
      .arel_table[:id]
      .in(context.portfolio_proposal_projects.pluck(:project_id))
      .to_sql
  end

  def self.key
    :manual_sort
  end

  def human_name
    I18n.t("activerecord.attributes.project_query.manual_sorting")
  end

  def ar_object_filter?
    true
  end

  private

  def operator_strategy
    Queries::Operators::PortfolioProposalProjects
  end
end
