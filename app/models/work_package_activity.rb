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

class WorkPackageActivity < ApplicationRecord
  COMMENT_KINDS = %w[Journal Comment].freeze
  REVISION_KINDS = %w[Revision].freeze

  def self.compatible_kinds = [COMMENT_KINDS, REVISION_KINDS].flatten
  include ViewBasedModel

  belongs_to :work_package
  belongs_to :user

  scope :comments, -> { where(kind: COMMENT_KINDS) }
  scope :revisions, -> { where(kind: REVISION_KINDS) }

  alias_attribute :notes, :comments

  ##
  # Checks if a Journal is the initial version of a WorkPackage.
  #
  # See Journal#initial? for more details.
  #
  def initial?
    journal? && (version < 2)
  end

  def journal?
    kind == "Journal"
  end
end
