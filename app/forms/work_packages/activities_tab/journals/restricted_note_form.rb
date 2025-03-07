# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
module WorkPackages::ActivitiesTab::Journals
  class RestrictedNoteForm < ApplicationForm
    form do |notes_form|
      notes_form.check_box(
        name: :restricted,
        label: I18n.t("activities.work_packages.activity_tab.restricted_visibility"),
        checked: false,
        label_arguments: { class: "no-wrap" },
        data: {
          "work-packages--activities-tab--restricted-comment-target": "restrictedCheckbox",
          action: "input->work-packages--activities-tab--restricted-comment#toggleBackgroundColor"
        },
        caption:
      )
    end

    private

    def caption
      href = ::OpenProject::Static::Links.url_for(:user_guides_work_package_activity)
      I18n.t("activities.work_packages.activity_tab.restricted_visibility_explainer",
             who_link_text: render(Primer::Beta::Link.new(href:, target: "_blank")) do
               I18n.t("activities.work_packages.activity_tab.label_who")
             end).html_safe
    end
  end
end
