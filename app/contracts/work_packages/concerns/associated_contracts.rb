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

module WorkPackages
  module Concerns
    module AssociatedContracts
      extend ActiveSupport::Concern

      included do
        class_attribute :associated_contract_classes, default: []
      end

      class_methods do
        def register_associated_contract(contract_class)
          associated_contract_classes << contract_class
        end
      end

      def valid?(context = nil)
        associated_valid = associated_contracts_valid?
        super && associated_valid
      end

      def writable_attributes
        super + associated_writable_attributes
      end

      protected

      def associated_contracts
        @associated_contracts ||= self
          .class
          .associated_contract_classes
          .select { |contract_class| contract_class.applicable?(model) }
          .map { |contract_class| contract_class.new(model, user) }
      end

      def associated_contracts_valid?
        associated_contracts.empty? || associated_contracts.all?(&:valid?)
      end

      def associated_writable_attributes
        @associated_writable_attributes ||= associated_contracts.flat_map(&:writable_attributes)
      end
    end
  end
end
