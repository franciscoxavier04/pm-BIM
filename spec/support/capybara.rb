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

require "socket"
require "capybara/rspec"
require "capybara-screenshot"
require "capybara-screenshot/rspec"
require "rack_session_access/capybara"
require "action_dispatch"

RSpec.shared_context "with default_url_options and host name set to Capybara test server" do
  around do |example|
    original_host = default_url_options[:host]
    original_port = default_url_options[:port]
    original_host_setting = Setting.host_name
    default_url_options[:host] = Capybara.server_host
    default_url_options[:port] = Capybara.server_port
    Setting.host_name = "#{Capybara.server_host}:#{Capybara.server_port}"
    example.run
  ensure
    default_url_options[:host] = original_host
    default_url_options[:port] = original_port
    Setting.host_name = original_host_setting
  end
end

RSpec.shared_context "with host name set to test.host" do
  around do |example|
    original_host_setting = Setting.host_name
    Setting.host_name = "test.host"
    example.run
  ensure
    Setting.host_name = original_host_setting
  end
end

RSpec.configure do |config|
  Capybara.default_max_wait_time = 4
  Capybara.javascript_driver = :chrome_en

  port = ENV.fetch("CAPYBARA_SERVER_PORT", ParallelHelper.port_for_app).to_i
  if port > 0
    Capybara.server_port = port
  end
  Capybara.always_include_port = true

  hostname =
    if ENV["CAPYBARA_DYNAMIC_BIND_IP"]
      ip_address = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
      Capybara.server_host = ip_address

      ENV.fetch("CAPYBARA_APP_HOSTNAME", ip_address)
    else
      ENV.fetch("CAPYBARA_APP_HOSTNAME", "localhost")
    end

  Capybara.server_host = hostname
  Capybara.app_host = "http://#{hostname}:#{Capybara.server_port}"
  Capybara.default_host = Capybara.app_host

  # Set the default options
  config.include_context "with default_url_options and host name set to Capybara test server", type: :feature
  config.include_context "with host name set to test.host", type: :controller

  # Fix the host name for rails_request specs
  %i[request rails_request].each do |type|
    config.include_context("with host name set to test.host", type:)
    config.before(:each, type:) do
      host! "test.host"

      # Rack::Test uses a respond_to?(:default_host) to check for overwritten host
      # and there appears to be no other option
      def default_host
        "test.host"
      end
    end
  end

  # Make it possible to match on value attribute.
  #
  # For instance:
  #
  #     expect(page).to have_selector(".date input", value: "2022-11-17")
  #
  Capybara.modify_selector(:css) do
    filter(:value) { |node, v| node.value == v }
  end
end

# silence puma if we're using it
puma_options = { Silent: true }
# use `CAPYBARA_PUMA_THREADS=1:1` to use only 1 puma thread, which is useful
# when using irb/pry in server code.
puma_options[:Threads] = ENV["CAPYBARA_PUMA_THREADS"] if ENV.key?("CAPYBARA_PUMA_THREADS")
Capybara.server = :puma, puma_options

Rails.application.config do
  config.middleware.use RackSessionAccess::Middleware
end
