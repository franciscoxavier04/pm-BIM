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

# Update journal entries from this:
#
# {
#   "type" => "status_p_complete_changed",
#   "status_name" => status.name,
#   "status_id" => status.id,
#   "status_p_complete_change" => [20, 40]
# }
#
# to this:
#
# {
#   "type" => "status_changed",
#   "status_name" => status.name,
#   "status_id" => status.id,
#   "status_changes" => { "default_done_ratio" => [20, 40] }
# }
#
# structure needed to handle multiple changes in one cause
class FixStatusExcludedFromTotalsChangedJournalCause < ActiveRecord::Migration[7.1]
  def up
    # With Postgres version 16+, it could be written as:
    # json_object(
    #   'type': 'status_changed',
    #   'status_id': cause -> 'status_id',
    #   'status_name': cause -> 'status_name',
    #   'status_changes': json_object(
    #     'default_done_ratio': cause -> 'status_p_complete_change'
    #   )
    # )
    execute(<<~SQL.squish)
      UPDATE journals
      SET cause = jsonb_set(
        jsonb_set(
          cause,
          '{type}',
          '"status_changed"'
        ),
        '{status_changes}',
        jsonb_set(
          '{"default_done_ratio": ""}'::jsonb,
          '{default_done_ratio}',
          cause -> 'status_p_complete_change'
        )
      ) - 'status_p_complete_change'
      WHERE cause @> '{"type": "status_p_complete_changed"}';
    SQL
  end

  def down
    # With Postgres version 16+, it could be written as:
    # json_object(
    #   'type': 'status_p_complete_changed',
    #   'status_id': cause -> 'status_id',
    #   'status_name': cause -> 'status_name',
    #   'status_p_complete_change': cause #> '{status_changes,default_done_ratio}'
    # )
    execute(<<~SQL.squish)
      UPDATE journals
      SET cause = jsonb_set(
        jsonb_set(
          cause,
          '{type}',
          '"status_p_complete_changed"'
        ),
        '{status_p_complete_change}',
        cause #> '{status_changes,default_done_ratio}'
      ) - 'status_changes'
      WHERE cause @> '{"type": "status_changed", "status_changes":{"default_done_ratio":[]}}';
    SQL
  end
end
