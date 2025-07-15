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

import { Component, ElementRef, OnInit } from '@angular/core';
import { slideDown, slideUp } from 'es6-slide-up-down';


@Component({
  selector: 'opce-persistent-toggle',
  template: '',
})
export class PersistentToggleComponent implements OnInit {
  /** Unique identifier of the toggle */
  private identifier:string;

  /** Is hidden */
  private isHidden = false;

  /** Element reference */
  private element:HTMLElement;

  private targetNotification:HTMLElement;

  constructor(private elementRef:ElementRef) {
  }

  ngOnInit():void {
    this.element = this.elementRef.nativeElement;
    this.targetNotification = this.getTargetNotification();

    this.identifier = this.element.dataset.identifier!;
    this.isHidden = window.OpenProject.guardedLocalStorage(this.identifier) === 'true';

    // Set initial state
    this.targetNotification.hidden = !!this.isHidden;

    // Register click handler
    this.element
      .parentElement
      ?.querySelector('.persistent-toggle--click-handler')
      ?.addEventListener('click', () => this.toggle(!this.isHidden));

    // Register target toaster close icon
    this.targetNotification
      .querySelector('.op-toast--close')
      ?.addEventListener('click', () => this.toggle(true));
  }

  private getTargetNotification() {
    return this.element
      .parentElement!
      .querySelector<HTMLElement>('.persistent-toggle--toaster')!;
  }

  private toggle(isNowHidden:boolean) {
    this.isHidden = isNowHidden;
    window.OpenProject.guardedLocalStorage(this.identifier, (!!isNowHidden).toString());

    if (isNowHidden) {
      slideUp(this.targetNotification, 400);
      window.requestAnimationFrame(() => this.targetNotification.hidden = true);
    } else {
      slideDown(this.targetNotification, 400);
      window.requestAnimationFrame(() => this.targetNotification.hidden = false);
    }
  }
}
