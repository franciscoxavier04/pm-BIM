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

import { Injectable, Injector, NgZone } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { HoverCardComponent } from 'core-app/shared/components/modals/preview-modal/hover-card-modal/hover-card.modal';
import { PortalOutletTarget } from 'core-app/shared/components/modal/portal-outlet-target.enum';

@Injectable({ providedIn: 'root' })
export class HoverCardTriggerService {
  private modalElement:HTMLElement;

  private mouseInModal = false;
  private hoverTimeout:number|null = null;
  private closeTimeout:number|null = null;
  // Set to custom when opening the hover card on top of another modal
  private modalTarget:PortalOutletTarget = PortalOutletTarget.Default;
  private previousTarget:HTMLElement|null = null;

  // Track whether we currently show a hover card or not. It is important not to open multiple hover cards at
  // the same time, and refrain from closing the wrong kind of modal overlay.
  private isShowingHoverCard:boolean = false;

  // The time you need to keep hovering over a trigger before the hover card is shown
  OPEN_DELAY_IN_MS = 1000;
  // The time you need to keep away from trigger/hover card before an opened card is closed
  CLOSE_DELAY_IN_MS = 250;

  constructor(
    readonly opModalService:OpModalService,
    readonly ngZone:NgZone,
    readonly injector:Injector,
  ) {
  }

  setupListener() {
    jQuery(document.body).on('mouseover', '.op-hover-card--preview-trigger', (e) => {
      e.preventDefault();
      e.stopPropagation();

      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const el = e.target as HTMLElement;
      if (!el) { return; }

      // For some elements, the hover card data is on another element. We need to find that element.
      const dataSource = this.getDataSource(el);

      if (this.previousTarget && this.previousTarget === el) {
        // Re-entering the trigger counts as hovering over the card:
        this.mouseInModal = true;
        // But we will not re-render the same card, abort here
        return;
      }

      // Hovering over a new target. Close the old one (if any).
      this.close(true);
      this.previousTarget = el;

      const turboFrameUrl = this.parseHoverCardUrl(dataSource);
      if (!turboFrameUrl) { return; }

      // Reset close timer for when hovering over multiple triggers in quick succession.
      // A timer from a previous hover card might still be running. We do not want it to
      // close the new (i.e. this) hover card.
      if (this.closeTimeout) {
        clearTimeout(this.closeTimeout);
        this.closeTimeout = null;
      }

      // Set a delay before showing the hover card
      this.hoverTimeout = window.setTimeout(() => {
        this.showHoverCard(dataSource, turboFrameUrl, e);
      }, this.OPEN_DELAY_IN_MS);
    });

    jQuery(document.body).on('mouseleave', '.op-hover-card--preview-trigger', () => {
      this.clearHoverTimer();
      this.mouseInModal = false;
      this.closeAfterTimeout();
    });

    jQuery(document.body).on('mouseleave', '.op-hover-card', () => {
      this.clearHoverTimer();
      this.mouseInModal = false;
      this.closeAfterTimeout();
    });

    jQuery(document.body).on('mouseenter', '.op-hover-card', () => {
      this.mouseInModal = true;
    });
  }

  private showHoverCard(el:HTMLElement, turboFrameUrl:string, e:JQuery.MouseOverEvent) {
    // Abort if the element is no longer present in the DOM. This can happen when this method is called after a delay.
    if (!document.body.contains(el)) { return; }
    // Do not try to show two hover cards at the same time.
    if (this.isShowingHoverCard) { return; }

    this.parseHoverCardOptions(el);

    // There is only one possible slot to insert a modal. If that slot is taken, we assume the other modal
    // to be more important than a hover card and give up.
    const modal = this.opModalService.showIfNotActive(
      HoverCardComponent,
      this.injector,
      { turboFrameSrc: turboFrameUrl, event: e },
      true,
      false,
      this.modalTarget,
    );

    modal?.subscribe((previewModal) => {
      this.isShowingHoverCard = true;
      this.modalElement = previewModal.elementRef.nativeElement as HTMLElement;
      previewModal.alignment = 'top';

      void previewModal.reposition(this.modalElement, el);
    });
  }

  // Should be called when the mouse leaves the hover-zone so that we no longer attempt ot display the hover card.
  private clearHoverTimer() {
    if (this.hoverTimeout) {
      clearTimeout(this.hoverTimeout);
      this.hoverTimeout = null;
    }
  }

  private closeAfterTimeout() {
    this.ngZone.runOutsideAngular(() => {
      this.closeTimeout = window.setTimeout(() => {
        this.close();
      }, this.CLOSE_DELAY_IN_MS);
    });
  }

  private close(forceClose=false) {
    if (forceClose) {
      this.mouseInModal = false;
    }

    // It is important to check if we are currently showing a hover card. If we closed the modal service without
    // doing so, we might accidentally close another modal (e.g. share dialog).
    if (this.isShowingHoverCard && !this.mouseInModal) {
      this.opModalService.close();
      this.isShowingHoverCard = false;
      // Allow opening this target once more, since it has been orderly closed
      this.previousTarget = null;
    }
  }

  /*
   * Some elements do not carry the hover data arguments on themselves, but rely on nearby elements to provide them.
   * For example in the auto completer.
   *
   * This method will return the element that actually carries the hover card data.
   */
  private getDataSource(el:HTMLElement) {
    if (el.className.includes('op-hover-card--data-on-sibling-principal')) {
      const candidate = this.findSiblingElementWithHoverCardData(el);
      if (candidate) {
        return candidate as HTMLElement;
      }
    }

    return el;
  }

  private findSiblingElementWithHoverCardData(el:HTMLElement) {
    const sibling = jQuery(el).siblings('.op-principal').get(0);
    if (sibling) {
      return this.childElementWithHoverCardTrigger(sibling);
    }

    return null;
  }

  private childElementWithHoverCardTrigger(principal:Element) {
    return principal.querySelector('.op-hover-card--preview-trigger');
  }

  private parseHoverCardUrl(el:HTMLElement) {
    return el.getAttribute('data-hover-card-url');
  }

  private parseHoverCardOptions(el:HTMLElement) {
    const modalTarget = el.getAttribute('data-hover-card-target');
    if (modalTarget) {
      this.modalTarget = parseInt(modalTarget, 10);
    }
  }
}
