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

module WorkPackageTypes
  class SetAttributesService < ::BaseServices::SetAttributes
    def initialize(user:, model:, contract_class:, contract_options: nil)
      super
      @valid_pattern = true
    end

    private

    def set_attributes(params)
      permitted = params.except(:copy_workflow_from)
      @valid_pattern = check_patterns(permitted)

      if @valid_pattern
        super(permitted)
      else
        super(permitted.except(:patterns))
      end
    end

    def validate_and_result
      success, errors = validate(model, user, options: {})

      if @valid_pattern
        ServiceResult.new(success:, errors:, result: model)
      else
        errors.add(:patterns, :is_invalid)
        ServiceResult.failure(errors:, result: model)
      end
    end

    def check_patterns(params)
      return true unless params.key?(:patterns)
      return true if params.key?(:patterns) && params[:patterns].blank?

      Types::Patterns::CollectionContract.new.call(params[:patterns]).success?
    rescue ArgumentError
      false
    end
  end
end
