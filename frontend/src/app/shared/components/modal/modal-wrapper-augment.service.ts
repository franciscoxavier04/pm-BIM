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

import { Inject, Injectable, Injector } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { DynamicContentModalComponent } from 'core-app/shared/components/modals/modal-wrapper/dynamic-content.modal';

const iframeSelector = '.iframe-target-wrapper';

/**
 * This service takes modals that are rendered by the rails backend,
 * and re-renders them with the angular op-modal service
 */
@Injectable({ providedIn: 'root' })
export class OpModalWrapperAugmentService {
  constructor(
    @Inject(DOCUMENT) protected documentElement:Document,
    protected injector:Injector,
    protected opModalService:OpModalService,
  ) {
    documentElement.addEventListener('turbo:before-render', () => opModalService.close());
  }

  /**
   * Create initial listeners for Rails-rendered modals
   */
  public setupListener() {
    const matches = this.documentElement.querySelectorAll('[data-augmented-model-wrapper]');
    for (let i = 0; i < matches.length; ++i) {
      this.wrapElement(matches[i] as HTMLElement);
    }
  }

  /**
   * Wrap a section[data-augmented-modal-wrapper] element
   */
  public wrapElement(element:HTMLElement) {
    // Find activation link
    const activationSelector = element.dataset.activationSelector || '.modal-delivery-element--activation-link';
    const activationLink = document.querySelector(activationSelector)!;
    const initializeNow = element.dataset.modalInitializeNow;

    if (initializeNow) {
      this.show(element);
    } else {
      activationLink.addEventListener('click', (evt) => {
        this.show(element);
        evt.preventDefault();
      });
    }
  }

  private show(element:HTMLElement) {
    // Set modal class name
    const modalClassName = element.dataset.modalClassName;
    // Append CSP-whitelisted IFrame for onboarding
    const iframeUrl = element.dataset.modalIframeUrl;

    // Set template from wrapped element
    const wrappedElement = element.querySelector<HTMLElement>('.modal-delivery-element')!;
    let modalBody = wrappedElement.innerHTML;

    if (iframeUrl) {
      modalBody = this.appendIframe(wrappedElement, iframeUrl);
    }

    this.opModalService.show(
      DynamicContentModalComponent,
      this.injector,
      {
        modalBody,
        modalClassName,
      },
    );
  }

  private appendIframe(body:HTMLElement, url:string) {
    const iframe = document.createElement('iframe');
    iframe.frameBorder = "0";
    iframe.height = "350";
    iframe.allowFullscreen = true;
    iframe.setAttribute('src', url);

    const iframeParent = body.querySelector(iframeSelector)!;
    if (iframeParent.querySelector('iframe')) {
      // Make sure we don't initialize the iframe multiple times
      return body.innerHTML;
    }

    iframeParent.append(iframe);

    return body.innerHTML;
  }
}
