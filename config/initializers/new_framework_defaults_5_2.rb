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
# This file contains migration options to ease your Rails 5.2 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.

# https://guides.rubyonrails.org/configuring.html#config-active-record-cache-versioning
# Make Active Record use stable #cache_key alongside new #cache_version method.
# This is needed for recyclable cache keys. Previous versions had false.
# Rails 5.2+ default is true.
# Rails.application.config.active_record.cache_versioning = true

# https://guides.rubyonrails.org/configuring.html#config-action-dispatch-use-authenticated-cookie-encryption
# Use AES-256-GCM authenticated encryption for encrypted cookies.
# Also, embed cookie expiry in signed or encrypted cookies for increased security.
#
# This option is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 5.2.
#
# Existing cookies will be converted on read then written with the new scheme.
# Previous versions had false. Rails 5.2+ default is true.
# Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = true

# https://guides.rubyonrails.org/configuring.html#config-active-support-use-authenticated-message-encryption
# Use AES-256-GCM authenticated encryption as default cipher for encrypting messages
# instead of AES-256-CBC, when use_authenticated_message_encryption is set to true.
# Previous versions had false. Rails 5.2+ default is true.
# Rails.application.config.active_support.use_authenticated_message_encryption = true

# https://guides.rubyonrails.org/configuring.html#config-action-controller-default-protect-from-forgery
# Add default protection from forgery to ActionController::Base instead of in
# ApplicationController.
# Previous versions had false. Rails 5.2+ default is true.
# Rails.application.config.action_controller.default_protect_from_forgery = true

# https://guides.rubyonrails.org/configuring.html#config-active-support-hash-digest-class
# Use SHA-1 instead of MD5 to generate non-sensitive digests, such as the ETag header.
# Previous versions had false (OpenSSL::Digest::MD5).
# Rails 5.2 to 6.1 default is true (OpenSSL::Digest::SHA1).
# Rails 7.0 started using `config.active_support.hash_digest_class = OpenSSL::Digest::SHA256` instead
# and removed `Rails.application.config.active_support.use_sha1_digests` setting
# Rails.application.config.active_support.use_sha1_digests = true

# https://guides.rubyonrails.org/configuring.html#config-action-view-form-with-generates-ids
# Make `form_with` generate id attributes for any generated HTML tags.
# Previous versions had false. Rails 5.2+ default is true.
# Rails.application.config.action_view.form_with_generates_ids = true
