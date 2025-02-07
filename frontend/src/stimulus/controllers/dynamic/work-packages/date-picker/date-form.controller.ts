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

export default class DateFormController extends Controller {
  static targets = [
    'startDateFieldContainer',
    'dueDateFieldContainer',
  ];

  declare readonly startDateFieldContainerTarget:HTMLElement;

  declare readonly dueDateFieldContainerTarget:HTMLElement;

  private toggled:boolean = false;

  startDateFieldContainerTargetConnected() {
    // When the complete turboFrame updates, we have to remember, whether the date field was already toggled.
    // In that case, we want to preserve that state
    this.setInitialVisibility();
  }

  dueDateFieldContainerTargetConnected() {
    // When the complete turboFrame updates, we have to remember, whether the date field was already toggled.
    // In that case, we want to preserve that state
    this.setInitialVisibility();
  }

  toggleStartDateFieldVisibility() {
    this.toggleFieldVisibility();
    this.startDateFieldContainerTarget.querySelector('input')?.focus();
  }

  toggleDueDateFieldVisibility() {
    this.toggleFieldVisibility();
    this.startDateFieldContainerTarget.querySelector('input')?.focus();
  }

  toggleFieldVisibility() {
    this.hideDateButtons();

    this.toggled = true;
  }

  private setInitialVisibility() {
    // If a date button has already been toggled once, it will not be shown again.
    if (this.toggled) {
      this.hideDateButtons();
    }
  }

  private hideDateButtons() {
    Array.from(document.getElementsByClassName('wp-datepicker-dialog-date-form--button-container_visible')).forEach((el) => {
      el.classList.remove('wp-datepicker-dialog-date-form--button-container_visible');
    });
  }
}
