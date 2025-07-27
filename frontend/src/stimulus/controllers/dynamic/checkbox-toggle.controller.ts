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
 * Stimulus controller for checkbox toggle functionality.
 */
export default class CheckboxToggleController extends Controller<HTMLElement> {
  static values = {
    selector: String,
    formName: String,
    checked: Boolean,
  };

  declare readonly selectorValue:string;
  declare readonly formNameValue:string;
  declare readonly checkedValue:boolean;

  /**
   * Toggle all checkboxes matching the selector.
   * Used for workflows, roles permissions, etc.
   */
  toggle(event:Event):void {
    event.preventDefault();

    const checkboxes = Array.from(document.querySelectorAll<HTMLInputElement>(this.selectorValue));
    if (checkboxes.length === 0) return;

    const allChecked = checkboxes.every((checkbox) => checkbox.checked);
    checkboxes.forEach((checkbox) => {
      if (!checkbox.disabled) {
        checkbox.checked = !allChecked;
      }
    });
  }

  /**
   * Check or uncheck all checkboxes in a form.
   * Used for check_all_links helper.
   */
  checkAll(event:Event):void {
    event.preventDefault();

    const selector = this.formNameValue
      ? `#${this.formNameValue} input[type="checkbox"]:not([disabled])`
      : `${this.selectorValue} input[type="checkbox"]:not([disabled])`;

    document
      .querySelectorAll<HTMLInputElement>(selector)
      .forEach((checkbox) => {
        checkbox.checked = this.checkedValue;
      });
  }
}
