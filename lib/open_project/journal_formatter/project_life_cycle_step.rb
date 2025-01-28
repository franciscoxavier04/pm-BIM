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

class OpenProject::JournalFormatter::ProjectLifeCycleStep < JournalFormatter::Base
  def render(key, values, options = { html: true })
    step = Project::LifeCycleStep.find(key[/\d+/])

    name = step.definition.name
    label = options[:html] ? content_tag(:strong, name) : name

    messages = [
      activation_message(values:),
      date_change_message(values:, step:, options:)
    ]

    "#{label} #{messages.compact.to_sentence}"
  end

  private

  def activation_message(values:)
    if values[:active]&.any?
      if values[:active][1]
        I18n.t("activity.project_life_cycle_step.activated")
      else
        I18n.t("activity.project_life_cycle_step.deactivated")
      end
    end
  end

  def date_change_message(values:, step:, options:)
    case step
    when Project::Gate
      if values[:date]
        from, to = values[:date].map { format_date(_1) }

        format_date_change(from:, to:, options:)
      end
    when Project::Stage
      if values[:date_range]
        from, to = values[:date_range].map { format_date_range(_1) }

        format_date_change(from:, to:, options:)
      end
    end
  end

  def format_date_range(date_range)
    "#{format_date(date_range.begin)} - #{format_date(date_range.end)}" if date_range
  end

  def format_date_change(from:, to:, options:)
    if from && to
      I18n.t("activity.project_life_cycle_step.changed_date", from:, to:)
    elsif to
      I18n.t("activity.project_life_cycle_step.added_date", date: to)
    elsif from
      date = options[:html] ? content_tag("del", from) : from

      I18n.t("activity.project_life_cycle_step.removed_date", date:)
    end
  end
end
