//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

// 'Global' dependencies
//
// dependencies required by classic (Rails) and Angular application.

// jQuery
import 'jquery-ujs';

// Jquery UI
// import 'jquery-ui/ui/position';
// import 'jquery-ui/ui/disable-selection';
// import 'jquery-ui/ui/widgets/sortable';
// import 'jquery-ui/ui/widgets/dialog';
// import 'jquery-ui/ui/widgets/tooltip';
import 'core-vendor/jquery-ui-1.14.1/jquery-ui';

import moment from 'moment';
import './init-moment-locales';

import 'jquery.caret';
// Text highlight for autocompleter
import 'mark.js/dist/jquery.mark.min';

import 'moment-timezone/builds/moment-timezone-with-data.min';
// eslint-disable-next-line import/extensions,import/no-extraneous-dependencies
import '@openproject/primer-view-components/app/assets/javascripts/primer_view_components.js';

import URI from 'urijs';
import 'urijs/src/URITemplate';

window.moment = moment;
window.URI = URI;
