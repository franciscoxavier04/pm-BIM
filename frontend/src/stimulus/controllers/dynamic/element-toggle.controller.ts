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

/**
 * Stimulus controller for element visibility toggle functionality.
 */
export default class ElementToggleController extends Controller<HTMLElement> {
  static values = {
    targetSelector: String,
    showTarget: String,
    hideTarget: String,
  };

  declare readonly targetSelectorValue:string;
  declare readonly showTargetValue:string;
  declare readonly hideTargetValue:string;

  /**
   * Show the target element(s).
   */
  show(event:Event):void {
    event.preventDefault();

    const selector = this.showTargetValue || this.targetSelectorValue;
    if (!selector) return;

    document.querySelectorAll(selector).forEach((element) => {
      if (element instanceof HTMLElement) {
        element.style.display = '';
        element.hidden = false;
      }
    });
  }

  /**
   * Hide the target element(s).
   */
  hide(event:Event):void {
    event.preventDefault();

    const selector = this.hideTargetValue || this.targetSelectorValue;
    if (!selector) return;

    document.querySelectorAll(selector).forEach((element) => {
      if (element instanceof HTMLElement) {
        element.style.display = 'none';
        element.hidden = true;
      }
    });
  }

  /**
   * Toggle visibility of the target element(s).
   */
  toggle(event:Event):void {
    event.preventDefault();

    if (!this.targetSelectorValue) return;

    document.querySelectorAll(this.targetSelectorValue).forEach((element) => {
      if (element instanceof HTMLElement) {
        const isHidden = element.style.display === 'none' || element.hidden;
        if (isHidden) {
          element.style.display = '';
          element.hidden = false;
        } else {
          element.style.display = 'none';
          element.hidden = true;
        }
      }
    });
  }

  /**
   * Show one element and hide another (useful for edit/cancel patterns).
   */
  showAndHide(event:Event):void {
    event.preventDefault();

    if (this.showTargetValue) {
      document.querySelectorAll(this.showTargetValue).forEach((element) => {
        if (element instanceof HTMLElement) {
          element.style.display = '';
          element.hidden = false;
        }
      });
    }

    if (this.hideTargetValue) {
      document.querySelectorAll(this.hideTargetValue).forEach((element) => {
        if (element instanceof HTMLElement) {
          element.style.display = 'none';
          element.hidden = true;
        }
      });
    }
  }
}
