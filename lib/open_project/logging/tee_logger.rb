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

module OpenProject
  module Logging
    class TeeLogger
      attr_reader :loggers,
                  :stdout,
                  :file

      ##
      # Initialize a stdout/stderr and file logger
      # with the file logger within <rails root>/log/<filename>
      def initialize(log_name, max_level = ::Logger::DEBUG)
        @stdout = ::ActiveSupport::Logger.new STDOUT
        @file = ::ActiveSupport::Logger.new Rails.root.join("log", "#{File.basename(log_name, '.log')}.log")

        stdout.level = max_level
        file.level = max_level

        @loggers = [stdout, file]
      end

      %w(log debug info warn error fatal unknown).each do |m|
        define_method(m) do |*args|
          @loggers.map { |t| t.send(m, *args) }
        end
      end
    end
  end
end
