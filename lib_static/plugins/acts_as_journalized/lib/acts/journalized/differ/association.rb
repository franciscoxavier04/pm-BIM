# frozen_string_literal: true

# -- copyright
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
# ++

module Acts::Journalized::Differ
  class Association
    def initialize(original, changed, association:, id_attribute:)
      @original_by_id = association_by_id(original, association, id_attribute)
      @changed_by_id = association_by_id(changed, association, id_attribute)
      @ids = (@changed_by_id.keys | @original_by_id.keys).compact
    end

    def attribute_changes(attribute, key_prefix:)
      single_attribute_changes(attribute)
        .transform_keys { |id| "#{key_prefix}_#{id}" }
    end

    def attributes_changes(attributes, key_prefix:, grouped: false)
      attributes.each_with_object({}) do |attribute, result|
        single_attribute_changes(attribute).each do |id, change|
          if grouped
            result["#{key_prefix}_#{id}"] ||= {}
            result["#{key_prefix}_#{id}"][attribute] = change
          else
            result["#{key_prefix}_#{id}_#{attribute}"] = change
          end
        end
      end
    end

    private

    def association_by_id(model, association, id_attribute)
      return {} unless model

      relation = if association.respond_to?(:call)
                   association.call(model)
                 else
                   model.send(association)
                 end

      relation.group_by(&id_attribute.to_sym)
    end

    def single_attribute_changes(attribute)
      attribute = attribute.to_sym

      pairs = @ids.index_with do |id|
        [
          combine_journals(@original_by_id[id], attribute),
          combine_journals(@changed_by_id[id], attribute)
        ]
      end

      pairs.reject { |_, (old_value, new_value)| old_value.to_s.strip == new_value.to_s.strip }
    end

    def combine_journals(journals, attribute)
      # TODO: is there real case where there will be more than one value?
      journals.map(&attribute).sort.join(",") if journals
    end
  end
end
