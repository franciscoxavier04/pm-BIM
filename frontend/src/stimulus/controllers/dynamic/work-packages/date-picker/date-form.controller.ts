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
    'startDateField',
    'dueDateField',
    'durationField',
  ];

  declare readonly startDateFieldContainerTarget:HTMLElement;

  declare readonly dueDateFieldContainerTarget:HTMLElement;

  declare readonly startDateFieldTarget:HTMLInputElement;

  declare readonly dueDateFieldTarget:HTMLInputElement;

  declare readonly durationFieldTarget:HTMLInputElement;

  private toggled:boolean = false;

  private handleFlatpickrDatesChangedBound = this.handleFlatpickrDatesChanged.bind(this);

  connect() {
   document.addEventListener('date-picker:flatpickr-dates-changed', this.handleFlatpickrDatesChangedBound);
  }

  disconnect() {
    document.removeEventListener('date-picker:flatpickr-dates-changed', this.handleFlatpickrDatesChangedBound);
    super.disconnect();
  }

  handleFlatpickrDatesChanged() {
    this.checkForToggling();
  }

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
    this.dueDateFieldContainerTarget.querySelector('input')?.focus();
  }

  checkForToggling() {
    const activeField:HTMLInputElement = document.getElementsByClassName('op-datepicker-modal--date-field_current')[0] as HTMLInputElement;

    if (!this.areOtherFieldsEmpty(activeField)) {
      // When one of the other fields is filled, a value change will result in the missing field being calculated
      // Thus we have to make sure, that it is visible.
      this.toggleFieldVisibility();
    }
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
    document.removeEventListener('date-picker:flatpickr-dates-changed', this.handleFlatpickrDatesChangedBound);
  }

  private areOtherFieldsEmpty(activeField:HTMLInputElement) {
    const inputs = [this.startDateFieldTarget, this.dueDateFieldTarget, this.durationFieldTarget];

    const selectedIndex = inputs.indexOf(activeField);

    return inputs.every((input, index) => index === selectedIndex || input.value.trim() === '');
  }
}
