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

# An alternative to the `be_html_eql` matcher that wraps Rails DOM testing assertions.
# Adapted from rails-dom-testing.
# See https://github.com/rails/rails-dom-testing/blob/main/lib/rails/dom/testing/assertions/dom_assertions.rb
#
RSpec::Matchers.define :be_dom_eql do |expected, **kwargs|
  include Rails::Dom::Testing::Assertions

  description { "be equivalent HTML" }
  failure_message { rescued_exception.message }
  failure_message_when_negated { "expected not to be equivalent HTML, but it was equivalent." }

  match_unless_raises do |actual|
    assert_dom_equal(expected, actual, **kwargs)
  end
end
