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

require "spec_helper"

RSpec.describe Queries::Projects::Filters::TypeFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :project_type }
    let(:type) { :list }
    let(:model) { Project }
    let(:attribute) { :project_type }
    let(:values) { ["program"] }
    let(:admin) { build_stubbed(:admin) }
    let(:user) { build_stubbed(:user) }

    before do
      allow(Project).to receive(:project_types).and_return({
                                                             "project" => "project",
                                                             "program" => "program",
                                                             "portfolio" => "portfolio"
                                                           })
      allow(I18n).to receive(:t).with("label_project_type").and_return("Organizational entity type")
      allow(I18n).to receive(:t).with("activerecord.attributes.project.project_type_enum.project").and_return("Project")
      allow(I18n).to receive(:t).with("activerecord.attributes.project.project_type_enum.program").and_return("Program")
      allow(I18n).to receive(:t).with("activerecord.attributes.project.project_type_enum.portfolio").and_return("Portfolio")
    end

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expect(instance.allowed_values.map(&:second)).to contain_exactly("portfolio", "program", "project")
      end
    end
  end
end
