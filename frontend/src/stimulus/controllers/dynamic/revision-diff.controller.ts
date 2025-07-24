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
 * Stimulus controller for revision diff selection functionality.
 * Handles the complex logic for selecting revisions to compare in repository views.
 */
export default class RevisionDiffController extends Controller<HTMLElement> {
  static values = {
    targetSelector: String,
  };

  declare readonly targetSelectorValue:string;

  /**
   * Handle "from" radio button selection.
   * When selecting a "from" revision, automatically select the next revision as "to".
   */
  selectFrom(event:Event):void {
    const radio = event.target as HTMLInputElement;
    if (!radio.matches('input[type="radio"]')) return;

    // Extract line number from the radio button ID (format: cb-{line_num})
    const match = radio.id.match(/cb-(\d+)/);
    if (!match) return;

    const lineNum = parseInt(match[1], 10);
    const toRadio = document.querySelector<HTMLInputElement>(`#cbto-${lineNum + 1}`);

    if (toRadio) {
      toRadio.checked = true;
    }
  }

  /**
   * Handle "to" radio button selection.
   * When selecting a "to" revision, ensure the "from" revision is properly set.
   */
  selectTo(event:Event):void {
    const radio = event.target as HTMLInputElement;
    if (!radio.matches('input[type="radio"]')) return;

    // Extract line number from the radio button ID (format: cbto-{line_num})
    const match = radio.id.match(/cbto-(\d+)/);
    if (!match) return;

    const lineNum = parseInt(match[1], 10);
    const fromRadio = document.querySelector<HTMLInputElement>(`#cb-${lineNum}`);

    // If the corresponding "from" radio is checked, select the previous "from" radio instead
    if (fromRadio && fromRadio.checked) {
      const prevFromRadio = document.querySelector<HTMLInputElement>(`#cb-${lineNum - 1}`);
      if (prevFromRadio) {
        prevFromRadio.checked = true;
      }
    }
  }
}
