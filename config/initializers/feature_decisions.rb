# frozen_string_literal: true

# --copyright
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
# ++

require_relative "../../lib_static/open_project/feature_decisions"

# Add feature flags here via e.g.
#
#   OpenProject::FeatureDecisions.add :some_flag
#
# If the feature to be flag-guarded stems from a module, add an initializer
# to that module's engine:
#
#   initializer 'the_engine.feature_decisions' do
#     OpenProject::FeatureDecisions.add :some_flag
#   end

OpenProject::FeatureDecisions.add :built_in_oauth_applications,
                                  description: "Allows the display and use of built-in OAuth applications."

OpenProject::FeatureDecisions.add :calculated_value_project_attribute,
                                  description: "Allows the use of calculated values as a project attribute."

OpenProject::FeatureDecisions.add :oidc_group_sync,
                                  description: "Allows to synchronize groups from OpenID Connect providers"

OpenProject::FeatureDecisions.add :scim_api,
                                  description: "Enables SCIM API.",
                                  force_active: true

OpenProject::FeatureDecisions.add :block_note_editor,
                                  description: "Enables the block note editor for rich text fields where available."

OpenProject::FeatureDecisions.add :minutes_styling_meeting_pdf,
                                  description: "Allow exporting a meeting with FITKO styling." \
                                    "See #65124 for details."
