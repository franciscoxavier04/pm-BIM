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

module Comments
  class CreateContract < BaseContract
    validate :validate_author
    validate :allowed_to_comment?

    private

    def validate_author
      errors.add :author, :invalid unless model.author_id == user.id
    end

    def allowed_to_comment?
      errors.add(:base, :error_unauthorized) unless can_comment?
    end

    def can_comment?
      case model.commented
      when WorkPackage
        can_comment_on_work_package?
      when News
        can_comment_on_news?
      else
        false
      end
    end

    def can_comment_on_work_package?
      if model.internal?
        can_add_internal_comment?
      else
        user.allowed_in_work_package?(:add_work_package_comments, model.commented)
      end
    end

    def can_comment_on_news?
      user.allowed_in_project?(:comment_news, model.commented.project)
    end

    def can_add_internal_comment?
      EnterpriseToken.allows_to?(:internal_comments) &&
        model.commented.project.enabled_internal_comments &&
        user.allowed_in_project?(:add_internal_comments, model.commented.project)
    end
  end
end
