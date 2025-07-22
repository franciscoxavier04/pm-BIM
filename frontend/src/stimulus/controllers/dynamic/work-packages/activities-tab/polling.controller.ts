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

import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { useMeta } from 'stimulus-use';
import type AutoScrollingController from './auto-scrolling.controller';
import BaseController from './base.controller';
import StemsController from './stems.controller';

export default class PollingController extends BaseController {
  static outlets = ['work-packages--activities-tab--auto-scrolling', 'work-packages--activities-tab--stems'];
  declare readonly workPackagesActivitiesTabAutoScrollingOutlet:AutoScrollingController;
  declare readonly workPackagesActivitiesTabStemsOutlet:StemsController;

  static targets = ['editForm', 'reactionButton'];
  declare readonly editFormTargets:HTMLFormElement[];
  declare readonly reactionButtonTargets:HTMLElement[];

  static metaNames = ['csrf-token'];
  declare readonly csrfToken:string;

  private updateInProgress:boolean = false;
  private turboRequests:TurboRequestsService;
  private apiV3Service:ApiV3Service;
  private abortController = new AbortController();

  async connect() {
    super.connect();
    useMeta(this, { suffix: false });

    const context = await window.OpenProject.getPluginContext();
    this.turboRequests = context.services.turboRequests;
    this.apiV3Service = context.services.apiV3Service;

    this.setupEventListeners();
    this.markAsConnected();
    this.safeUpdateWorkPackageFormsWithStateChecks();
    this.setLatestKnownChangesetUpdatedAt();
    this.startPolling();
  }

  disconnect() {
    this.removeEventListeners();
    this.stopPolling();
    this.markAsDisconnected();
  }

  handleWorkPackageUpdate(_event?:Event):void {
    // wait statically as the events triggering this, fire when an async request was started, not ended
    // I don't see a way to detect the end of the async requests reliably, thus the static wait
    setTimeout(() => this.updateActivitiesList(), 2000);
  }

  async updateActivitiesList() {
    if (this.updateInProgress) return;

    this.updateInProgress = true;
    const editingJournals = this.captureEditingJournals();
    // Unfocus any reaction buttons that may have been focused
    // otherwise the browser will perform an auto scroll to the before focused button after the stream update was applied
    this.unfocusReactionButtons();

    void this.performUpdateStreamsRequest(this.prepareUpdateStreamsUrl(editingJournals))
      .then(({ html, headers }) => {
        this.handleUpdateStreamsResponse(html, headers);
      }).catch((error) => {
        console.error('Error updating activities list:', error);
      }).finally(() => {
        this.updateInProgress = false;
      });
  }

  // used in specs for timing
  private markAsConnected() { this.element.dataset.stimulusControllerConnected = 'true'; }
  private markAsDisconnected() { this.element.dataset.stimulusControllerConnected = 'false'; }

  private startPolling() {
    if (this.intervallId) {
      this.stopPolling();
    }

    this.intervallId = window.setInterval(() => this.updateActivitiesList(), this.pollingIntervalInMsValue);
  }

  private stopPolling() {
    window.clearInterval(this.intervallId);
  }

  private setLatestKnownChangesetUpdatedAt() {
    const latestKnownChangesetUpdatedAtKey = `work-package-${this.workPackageIdValue}-latest-known-changeset-updated-at-${this.userIdValue}`;
    const latestChangesetUpdatedAt = this.parseLatestChangesetUpdatedAtFromDom();

    if (latestChangesetUpdatedAt) {
      localStorage.setItem(latestKnownChangesetUpdatedAtKey, latestChangesetUpdatedAt.toString());
    }
  }

  private getLatestKnownChangesetUpdatedAt():Date | null {
    const latestKnownChangesetUpdatedAt = localStorage.getItem(this.latestKnownChangesetUpdatedAtKey);
    return latestKnownChangesetUpdatedAt ? new Date(latestKnownChangesetUpdatedAt) : null;
  }

  private setupEventListeners() {
    const { signal } = this.abortController;

    const handlers = {
      workPackageUpdated: () => { void this.handleWorkPackageUpdate(); },
      workPackageNotificationsUpdated: () => { void this.handleWorkPackageUpdate(); },
      visibilityChange: () => { void this.handleVisibilityChange(); },
    };

    document.addEventListener('work-package-updated', handlers.workPackageUpdated, { signal });
    document.addEventListener('work-package-notifications-updated', handlers.workPackageNotificationsUpdated, { signal });
    document.addEventListener('visibilitychange', handlers.visibilityChange, { signal });
  }

  private removeEventListeners() {
    this.abortController.abort();
  }

  private handleVisibilityChange() {
    if (document.hidden) {
      this.stopPolling();
    } else {
      void this.updateActivitiesList();
      this.startPolling();
    }
  }

  private unfocusReactionButtons() {
    this.reactionButtonTargets.forEach((button) => button.blur());
  }

  private performUpdateStreamsRequest(url:string):Promise<{ html:string, headers:Headers }> {
    return this.turboRequests.request(url, {
      method: 'GET',
      headers: { 'X-CSRF-Token': this.csrfToken },
    }, true); // suppress error toast in polling to avoid spamming the user when having e.g. network issues
  }

  private prepareUpdateStreamsUrl(editingJournals:Set<string>):string {
    const baseUrl = window.location.origin;
    const url = new URL(this.updateStreamsPathValue, baseUrl);

    url.searchParams.set('sortBy', this.sortingValue);
    url.searchParams.set('filter', this.filterValue);
    url.searchParams.set('last_update_timestamp', this.lastServerTimestampValue);

    if (editingJournals.size > 0) {
      url.searchParams.set('editing_journals', Array.from(editingJournals).join(','));
    }

    return url.toString();
  }

  private handleUpdateStreamsResponse(html:string, headers:Headers) {
    // the timeout is require in order to give the Turb.renderStream method enough time to render the new journals
    // the methods below partially rely on the DOM to be updated
    // a specific signal would be way better than a static timeout, but I couldn't find a suitable one
    setTimeout(() => {
      this.workPackagesActivitiesTabStemsOutlet.handleStemVisibility();
      this.setLastServerTimestampViaHeaders(headers);
      this.checkForAndHandleWorkPackageUpdate(html);
      this.checkForNewNotifications(html);
      this.performAutoScrolling(html);
      this.setLatestKnownChangesetUpdatedAt();
    }, 100);
  }

  private checkForAndHandleWorkPackageUpdate(html:string) {
    if (html.includes('work-packages-activities-tab-journals-item-component-details--journal-detail-container')) {
      if (this.latestChangesetFromOtherUser()) {
        this.safeUpdateWorkPackageForms();
      }
    }
  }

  private safeUpdateWorkPackageFormsWithStateChecks() {
    const latestKnownChangesetIsOutdated = this.latestKnownChangesetOutdated();
    const latestChangesetIsFromOtherUser = this.latestChangesetFromOtherUser();

    if (latestKnownChangesetIsOutdated && latestChangesetIsFromOtherUser) {
      this.safeUpdateWorkPackageForms();
    }
  }

  private safeUpdateWorkPackageForms() {
    if (this.anyInlineEditActiveInWpSingleView()) {
      this.showConflictFlashMessage();
    } else {
      this.updateWorkPackageForms();
    }
  }

  private checkForNewNotifications(html:string) {
    if (html.includes('data-op-ian-center-update-immediate')) {
      this.updateNotificationCenter();
    }
  }

  private latestKnownChangesetOutdated():boolean {
    const latestKnownChangesetUpdatedAt = this.getLatestKnownChangesetUpdatedAt();
    const latestChangesetUpdatedAt = this.parseLatestChangesetUpdatedAtFromDom();

    return !!(latestKnownChangesetUpdatedAt && latestChangesetUpdatedAt && (latestKnownChangesetUpdatedAt < latestChangesetUpdatedAt));
  }

  private latestChangesetFromOtherUser():boolean {
    const latestChangesetUserId = this.parseLatestChangesetUserIdFromDom();

    return !!(latestChangesetUserId && (latestChangesetUserId !== this.userIdValue));
  }

  private anyInlineEditActiveInWpSingleView():boolean {
    const wpSingleViewElement = document.querySelector('wp-single-view');
    if (wpSingleViewElement) {
      return wpSingleViewElement.querySelector('.inline-edit--active-field') !== null;
    }
    return false;
  }

  private showConflictFlashMessage() {
    // currently we do not have a programmatic way to show the primer flash messages
    // so we just do a request to the server to show it
    // should be refactored once we have a programmatic way to show the primer flash messages!
    void this.turboRequests.request(`${this.showConflictFlashMessageUrlValue}?scheme=warning`, {
      method: 'GET',
    });
  }

  private updateWorkPackageForms() {
    const wp = this.apiV3Service.work_packages.id(this.workPackageIdValue);
    void wp.refresh();
  }

  private updateNotificationCenter() {
    document.dispatchEvent(new Event('ian-update-immediate'));
  }

  private parseLatestChangesetUserIdFromDom():number | null {
    const latestChangesetUpdatedAt = this.parseLatestChangesetUpdatedAtFromDom();
    if (!latestChangesetUpdatedAt) return null;

    const railsTimestamp = latestChangesetUpdatedAt.getTime() / 1000;
    const userId = this.element
      .querySelector(`[data-journal-with-changeset-updated-at="${railsTimestamp}"]`)
      ?.getAttribute('data-journal-with-changeset-user-id');

    return userId ? parseInt(userId, 10) : null;
  }

  private parseLatestChangesetUpdatedAtFromDom():Date | null {
    const elements = this.element.querySelectorAll('[data-journal-with-changeset-updated-at]');

    const dates = Array.from(elements)
      .map((element) => element.getAttribute('data-journal-with-changeset-updated-at'))
      .filter((dateStr):dateStr is string => dateStr !== null)
      .map((dateStr) => new Date(parseInt(dateStr, 10) * 1000))
      .filter((date) => !Number.isNaN(date.getTime())); // filter out invalid dates

    if (dates.length === 0) return null;

    // find the latest date
    return new Date(Math.max(...dates.map((date) => date.getTime())));
  }

  private captureEditingJournals():Set<string> {
    const editingJournals = new Set<string>();

    const editForms = this.editFormTargets;
    editForms.forEach((form) => {
      const journalId = form.dataset.journalId;
      if (journalId) { editingJournals.add(journalId); }
    });

    return editingJournals;
  }

  private performAutoScrolling(html:string) {
    // only process append, prepend and update actions
    if (!(html.includes('action="append"') || html.includes('action="prepend"') || html.includes('action="update"'))) {
      return;
    }

    this.workPackagesActivitiesTabAutoScrollingOutlet.performAutoScrollingOnStreamsUpdate();
  }
}
