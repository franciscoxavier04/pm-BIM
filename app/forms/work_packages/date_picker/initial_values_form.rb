# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

module WorkPackages
  module DatePicker
    class InitialValuesForm < ApplicationForm
      attr_reader :work_package

      def initialize(work_package:)
        super()

        @work_package = work_package
      end

      form do |form|
        hidden_initial_field(form, name: :start_date)
        hidden_initial_field(form, name: :due_date)
        hidden_initial_field(form, name: :duration)
        hidden_initial_field(form, name: :ignore_non_working_days)
      end

      private

      def hidden_initial_field(form, name:)
        form.hidden(name:,
                    value: work_package.public_send(:"#{name}_was"),
                    data: { "work-packages--date-pick--preview-target": "initialValueInput",
                            "referrer-field": name })
      end
    end
  end
end
