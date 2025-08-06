# frozen_string_literal: true

#
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# rubocop:disable Gemspec/RequireMFA
Gem::Specification.new do |s|
  s.name        = "openproject-beyond_documents"
  s.version     = "0.0.1"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.org"
  s.summary     = "OpenProject Beyond Documents"
  s.description = "Allows working with long-lived documents that involve multiple steps and/or people."
  s.license     = "GPLv3"
  s.files       = Dir["{app,config,db,lib}/**/*"]
end
# rubocop:enable Gemspec/RequireMFA
