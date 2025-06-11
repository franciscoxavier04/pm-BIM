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

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe ProjectPhases::ActivationContract do
  include_context "ModelContract shared context"

  let(:user) { build_stubbed(:user) }

  subject(:contract) { described_class.new(project, user) }

  context "with authorized user" do
    let(:project) { build_stubbed(:project) }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:select_project_phases, project:)
      end
    end

    it_behaves_like "contract is valid"
    it_behaves_like "contract reuses the model errors"

    context "when project is invalid" do
      let(:project) { build_stubbed(:project, name: "") }

      it_behaves_like "contract is valid"
    end
  end

  context "with unauthorized user" do
    let(:project) { build_stubbed(:project) }

    it_behaves_like "contract user is unauthorized"
  end
end
