/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

export interface MatchPreviewDialogSubmittedEvent {
  detail:{
    regularExpressions:string;
    previewGroups:string;
  }
}

export default class MatchPreviewDialogController extends Controller {
  static targets = [
    'regexpInput',
    'groupNamesInput',
  ];

  static values = {
    updateUrl: String,
  };

  declare readonly regexpInputTarget:HTMLInputElement;
  declare readonly groupNamesInputTarget:HTMLInputElement;

  declare dialog:HTMLDialogElement;
  declare turboRequests:TurboRequestsService;
  declare updateUrlValue:string;
  declare updateMatchTimeout:number;

  async connect() {
    this.dialog = this.element as HTMLDialogElement;
    const context = await window.OpenProject.getPluginContext();
    this.turboRequests = context.services.turboRequests;

    this.regexpInputTarget.addEventListener('input', () => { this.updateMatchPreview(); });
    this.groupNamesInputTarget.addEventListener('input', () => { this.updateMatchPreview(); });
  }

  updateRegexpValue(value:string) {
    this.regexpInputTarget.value = value;
    this.updateMatchPreview();
  }

  submitDialog() {
    const event:MatchPreviewDialogSubmittedEvent = { detail: {
      regularExpressions: this.regexpInputTarget.value,
      previewGroups: this.groupNamesInputTarget.value,
    }};
    this.dispatch('submitted', event);
    this.dialog.close();
  }

  updateMatchPreview() {
    if(this.updateMatchTimeout) clearTimeout(this.updateMatchTimeout);

    this.updateMatchTimeout = setTimeout(() => { this.doUpdateMatchPreview(); }, 500);
  }

  doUpdateMatchPreview() {
    void this.turboRequests.request(this.updateUrlValue, {
      method: 'POST',
      headers: {
        Accept: 'text/vnd.turbo-stream.html',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        preview_group_names: this.groupNamesInputTarget.value,
        preview_regular_expressions: this.regexpInputTarget.value
      }),
    });
  }
}
