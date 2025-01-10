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

module OpenProject::Users
  # @logical_path OpenProject/Users
  class AvatarComponentPreview < Lookbook::Preview
    # Renders a user avatar using the OpenProject opce-principal web component. Note that the hover card options
    # have no effect in this lookbook.
    # @param size select { choices: [default, medium, mini] }
    # @param link toggle
    # @param show_name toggle
    # @param hover_card toggle
    # @param hover_card_target select { choices: [default, custom] }
    def default(size: :default, link: true, show_name: true, hover_card: true, hover_card_target: :default)
      user = FactoryBot.build_stubbed(:user)
      render(Users::AvatarComponent.new(user:, size:, link:, show_name:,
                                        hover_card: { active: hover_card, target: hover_card_target }))
    end

    def sizes
      user = FactoryBot.build_stubbed(:user)
      render_with_template(locals: { user: })
    end
  end
end
