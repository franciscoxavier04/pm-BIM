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

module Admin::ScimClients
  class FormComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    def self.wrapper_key = :scim_clients_form

    private

    def form_options
      form_target.merge(stimulus_controller_options)
                 .merge(model:)
    end

    def form_target
      if model.new_record?
        { method: :post, url: admin_scim_clients_path }
      else
        { method: :patch, url: admin_scim_client_path(model) }
      end
    end

    def stimulus_controller_options
      {
        data: {
          controller: "scim-clients--form-inputs",
          turbo_frame: "_top"
        }
      }
    end
  end
end
