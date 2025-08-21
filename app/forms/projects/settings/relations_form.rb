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
module Projects
  module Settings
    class RelationsForm < ApplicationForm
      delegate :parent, to: :model

      form do |f|
        f.project_autocompleter(
          name: :parent_id,
          label: attribute_name(:parent_id),
          autocomplete_options: {
            model: project_autocompleter_model,
            focusDirectly: false,
            dropdownPosition: "bottom",
            url: project_autocompleter_url,
            filters: [],
            data: { qa_field_name: "parent" }
          }
        )
      end

      private

      def render?
        model.project?
      end

      def project_autocompleter_model
        return nil unless parent
        return { id: parent.id, name: I18n.t(:"api_v3.undisclosed.parent") } unless parent.visible? || User.current.admin?

        { id: parent.id, name: parent.name }
      end

      def project_autocompleter_url
        url_str = ::API::V3::Utilities::PathHelper::ApiV3Path.projects_available_parents
        url_str << "?of=#{model.id}" unless model.new_record?
        url_str
      end
    end
  end
end
