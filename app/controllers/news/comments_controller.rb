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

class News::CommentsController < ApplicationController
  default_search_scope :news
  model_object Comment, scope: [News => :commented]

  before_action :find_object_and_scope
  before_action :authorize

  def create
    comment_result = Comments::CreateService
      .new(user: current_user)
      .call(comment_params)

    if comment_result.success?
      flash[:notice] = I18n.t(:label_comment_added)
    else
      flash[:error] = comment_result.message
    end

    redirect_to news_path(@news)
  end

  def destroy
    @comment.destroy
    redirect_to news_path(@news)
  end

  private

  def comment_params
    params.expect(comment: %i[comments])
          .merge(commented: @news, author: current_user)
  end
end
