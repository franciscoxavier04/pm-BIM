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

RSpec.describe "I18n human_attribute_name", type: :helper do
  let(:test_model) do
    # Also tests that the application controller has the model included
    Class.new(ApplicationRecord) do
      def self.name
        "TestModel"
      end
    end
  end

  it "returns a valid translation for basic attribute" do
    # looks up "activerecord.attributes.test_model.name", "attributes.name",
    # and "activerecord.models.name" i18n keys
    # "activerecord.attributes.test_model.name" i18n key does not exist
    # "attributes.name" i18n key exists and translates to "Name"
    expect(test_model.human_attribute_name("name")).to eq "Name"
  end

  it "raises an error if the translation is missing" do
    expect { test_model.human_attribute_name("weird_attribute_that_does_not_exist") }
      .to raise_error(/I18n translation missing for attribute weird/)
  end

  it "returns a valid translation for a model name if corresponding i18n key activerecord.models.<attribute> exists" do
    # looks up "activerecord.models.project" i18n key
    expect(test_model.human_attribute_name("project")).to eq "Project"
  end
end
