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

# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 5.1 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.

# https://guides.rubyonrails.org/configuring.html#config-action-view-form-with-generates-remote-forms
# Make `form_with` generate non-remote forms. Previous versions had false.
# Rails 5.1, 5.2, and 6.0 default is true. Rails 6.1+ default is false.
# Let's keep it false as it is the definitive default
# Rails.application.config.action_view.form_with_generates_remote_forms = true

# https://guides.rubyonrails.org/configuring.html#config-assets-unknown-asset-fallback
# Unknown asset fallback will return the path passed in when the given
# asset is not present in the asset pipeline. Previous versions had true.
# Rails 5.1+ default is false.
# Rails.application.config.assets.unknown_asset_fallback = false
