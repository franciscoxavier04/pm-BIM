/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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
import ViewPortService from './services/view-port-service';

export default class BaseController extends Controller<HTMLElement> {
  static values = {
    updateStreamsPath: String,
    sorting: String,
    pollingIntervalInMs: Number,
    filter: String,
    userId: Number,
    workPackageId: Number,
    notificationCenterPathName: String,
    lastServerTimestamp: String,
    showConflictFlashMessageUrl: String,
    unsavedChangesConfirmationMessage: String,
  };

  declare updateStreamsPathValue:string;
  declare sortingValue:string;
  declare lastServerTimestampValue:string;
  declare intervallId:number;
  declare pollingIntervalInMsValue:number;
  declare notificationCenterPathNameValue:string;
  declare filterValue:string;
  declare userIdValue:number;
  declare workPackageIdValue:number;
  declare latestKnownChangesetUpdatedAtKey:string;
  declare showConflictFlashMessageUrlValue:string;
  declare unsavedChangesConfirmationMessageValue:string;

  static targets = ['journalsContainer'];
  declare readonly journalsContainerTarget:HTMLElement;

  viewPortService:ViewPortService;

  connect() {
    this.viewPortService = new ViewPortService(this.notificationCenterPathNameValue);
  }

  adjustJournalContainerMarginWith(marginBottomPx:string) {
    // don't do this on mobile screens
    if (this.viewPortService.isMobile()) { return; }
    this.journalsContainerTarget.style.marginBottom = marginBottomPx;
  }

  resetJournalsContainerMargins():void {
    if (!this.journalsContainerTarget) return;

    this.journalsContainerTarget.style.marginBottom = '';
    this.journalsContainerTarget.classList.add('work-packages-activities-tab-index-component--journals-container_with-initial-input-compensation');
  }

  setLastServerTimestampViaHeaders(headers:Headers) {
    if (headers.has('X-Server-Timestamp')) {
      this.lastServerTimestampValue = headers.get('X-Server-Timestamp') as string;
    }
  }
}
