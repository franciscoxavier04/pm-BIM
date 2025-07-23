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
import { withIndexOutletMixin } from './mixins/with-index-outlet';

enum AnchorType {
  Comment = 'comment',
  Activity = 'activity',
}

interface CustomEventWithIdParam extends Event {
  params:{
    id:string;
    anchorName:AnchorType;
  };
}

export default class AutoScrollingController extends withIndexOutletMixin(Controller) {
  connect() {
    this.handleInitialScroll();
  }

  setAnchor(event:CustomEventWithIdParam) {
    // native anchor scroll is causing positioning issues
    event.preventDefault();

    const activityId = event.params.id;
    const anchorName = event.params.anchorName;

    // not using the scrollToActivity method here as it is causing flickering issues
    // in case of a setAnchor click, we can go for a direct scroll approach
    const scrollableContainer = this.scrollableContainer;
    const activityElement = this.getActivityAnchorElement(anchorName, activityId);

    if (scrollableContainer && activityElement) {
      scrollableContainer.scrollTo({
        top: activityElement.offsetTop - 90,
        behavior: 'smooth',
      });
    }

    window.location.hash = `#${anchorName}-${activityId}`;
  }

  performAutoScrollingOnStreamsUpdate(journalsContainerAtBottom:boolean = false) {
    if (this.indexOutlet.sortingValue === 'asc' && journalsContainerAtBottom) {
      // scroll to (new) bottom if sorting is ascending and journals container was already at bottom before a new activity was added
      if (this.isMobile()) {
        this.scrollInputContainerIntoView(300);
      } else {
        this.scrollJournalContainer(true, true);
      }
    }
  }

  performAutoScrollingOnFormSubmit() {
    if (this.isMobile() && !this.isWithinNotificationCenter()) {
      // wait for the keyboard to be fully down before scrolling further
      // timeout amount tested on mobile devices for best possible user experience
      this.scrollInputContainerIntoView(800);
    } else {
      this.scrollJournalContainer(this.indexOutlet.sortingValue === 'asc', true);
    }
  }

  scrollInputContainerIntoView(timeout:number = 0, behavior:ScrollBehavior = 'smooth') {
    const inputContainer = this.inputContainer;
    setTimeout(() => {
      if (inputContainer) {
        inputContainer.scrollIntoView({
          behavior,
          block: this.indexOutlet.sortingValue === 'desc' ? 'nearest' : 'start',
        });
      }
    }, timeout);
  }

  scrollJournalContainer(toBottom:boolean, smooth:boolean = false) {
    const scrollableContainer = this.scrollableContainer;
    if (scrollableContainer) {
      if (smooth) {
        scrollableContainer.scrollTo({
          top: toBottom ? scrollableContainer.scrollHeight : 0,
          behavior: 'smooth',
        });
      } else {
        scrollableContainer.scrollTop = toBottom ? scrollableContainer.scrollHeight : 0;
      }
    }
  }

  private handleInitialScroll() {
    const anchorTypeRegex = new RegExp(`#(${AnchorType.Comment}|${AnchorType.Activity})-(\\d+)`, 'i');
    const activityIdMatch = window.location.hash.match(anchorTypeRegex); // Ex. [ "#comment-80", "comment", "80" ]

    if (activityIdMatch && activityIdMatch.length === 3) {
      this.scrollToActivity(activityIdMatch[1] as AnchorType, activityIdMatch[2]);
    } else if (this.indexOutlet.sortingValue === 'asc' && (!this.isMobile() || this.isWithinNotificationCenter())) {
      this.scrollToBottom();
    }
  }

  private scrollToActivity(activityAnchorName:AnchorType, activityId:string) {
    const maxAttempts = 20; // wait max 20 seconds for the activity to be rendered
    this.tryScroll(activityAnchorName, activityId, 0, maxAttempts);
  }

  private scrollToBottom() {
    this.tryScrollToBottom(0, 20, 'auto');
  }

  private tryScroll(activityAnchorName:AnchorType, activityId:string, attempts:number, maxAttempts:number) {
    const scrollableContainer = this.scrollableContainer;
    const activityElement = this.getActivityAnchorElement(activityAnchorName, activityId);
    const topPadding = 70;

    if (activityElement && scrollableContainer) {
      scrollableContainer.scrollTop = 0;

      setTimeout(() => {
        const containerRect = scrollableContainer.getBoundingClientRect();
        const elementRect = activityElement.getBoundingClientRect();
        const relativeTop = elementRect.top - containerRect.top;

        scrollableContainer.scrollTop = relativeTop - topPadding;
      }, 50);
    } else if (attempts < maxAttempts) {
      setTimeout(() => this.tryScroll(activityAnchorName, activityId, attempts + 1, maxAttempts), 1000);
    }
  }

  private tryScrollToBottom(attempts:number = 0, maxAttempts:number = 20, behavior:ScrollBehavior = 'smooth') {
    const scrollableContainer = this.scrollableContainer;

    if (!scrollableContainer) {
      if (attempts < maxAttempts) {
        setTimeout(() => this.tryScrollToBottom(attempts + 1, maxAttempts), 1000);
      }
      return;
    }

    scrollableContainer.scrollTop = 0;

    let timeoutId:ReturnType<typeof setTimeout>;

    const observer = new MutationObserver(() => {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      clearTimeout(timeoutId);

      timeoutId = setTimeout(() => {
        observer.disconnect();
        scrollableContainer.scrollTo({
          top: scrollableContainer.scrollHeight,
          behavior,
        });
      }, 100);
    });

    observer.observe(scrollableContainer, {
      childList: true,
      subtree: true,
      attributes: true,
    });
  }

  private getActivityAnchorElement(activityAnchorName:AnchorType, activityId:string):HTMLElement | null {
    return document.querySelector(`[data-anchor-${activityAnchorName}-id="${activityId}"]`);
  }

  private get inputContainer():HTMLElement | null {
    return this.element.querySelector('.work-packages-activities-tab-journals-new-component');
  }

  isJournalsContainerScrolledToBottom():boolean {
    let atBottom = false;
    // we have to handle different scrollable containers for different viewports/pages in order to identify if the user is at the bottom of the journals
    // DOM structure different for notification center and workpackage detail view as well
    const scrollableContainer = this.scrollableContainer;
    if (scrollableContainer) {
      atBottom = (scrollableContainer.scrollTop + scrollableContainer.clientHeight + 10) >= scrollableContainer.scrollHeight;
    }

    return atBottom;
  }
}
