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

import { delegateEvents } from "core-app/shared/helpers/delegate-event";
import { hideElement, toggleElement } from "core-app/shared/helpers/dom-helpers";
import invariant from "tiny-invariant";

function createFieldsetToggleStateLabel(legend:HTMLLegendElement, text:string) {
  const labelClass = 'fieldset-toggle-state-label';
  let toggleLabel = legend.querySelector<HTMLSpanElement>(`a span.${labelClass}`);

  if (!toggleLabel) {
    toggleLabel = document.createElement('span')
    toggleLabel.classList.add(labelClass);
    toggleLabel.classList.add('hidden-for-sighted');

    legend.querySelector('a')?.append(toggleLabel);
  }

  toggleLabel.textContent = ` ${text}`;
}

function setFieldsetToggleState(fieldset:HTMLFieldSetElement) {
  const legend = fieldset.querySelector('legend')!;

  if (fieldset.classList.contains('collapsed')) {
    createFieldsetToggleStateLabel(legend, I18n.t('js.label_collapsed'));
  } else {
    createFieldsetToggleStateLabel(legend, I18n.t('js.label_expanded'));
  }
}

function getFieldset(element:HTMLElement):HTMLFieldSetElement {
  const fieldset = element.closest('fieldset');
  invariant(fieldset, 'Cannot derive fieldset from element!');

  return fieldset;
}

function toggleFieldset(element:HTMLElement) {
  const fieldset = getFieldset(element);
  // Mark the fieldset that the user has touched it at least once
  fieldset.dataset.touched = 'true';
  fieldset.classList.toggle('collapsed');

  const contentArea = fieldset.querySelector<HTMLElement>('> div:not(.form--toolbar')!;
  toggleElement(contentArea); // TODO: jQuery Porting - add slide effect
  setFieldsetToggleState(fieldset);
}

export function setupToggableFieldsets() {
  const fieldsets = document.querySelectorAll<HTMLFieldSetElement>('fieldset.form--fieldset.-collapsible');

  // Toggle on click
  delegateEvents('click', '.form--fieldset-legend', (event) => {
    const legend = event.target as HTMLLegendElement;
    toggleFieldset(legend);
    event.preventDefault();
    event.stopPropagation();
    return false;
  }, fieldsets);

  // Set initial state
  fieldsets
    .forEach((fieldset) => {
      const contentArea = fieldset.querySelector<HTMLElement>('> div')!;
      if (fieldset.classList.contains('collapsed')) {
        hideElement(contentArea);
      }

      setFieldsetToggleState(fieldset);
    });
}
