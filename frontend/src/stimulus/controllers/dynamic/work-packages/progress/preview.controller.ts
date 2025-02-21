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

import { debounce, DebouncedFunc } from 'lodash';
import { DialogPreviewController } from '../dialog/preview.controller';

export default class PreviewController extends DialogPreviewController {
  private debouncedPreview:DebouncedFunc<(event:Event) => void>;

  connect() {
    this.debouncedPreview = debounce((event:Event) => {
      let field:HTMLInputElement;
      if (event.type === 'blur') {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        field = (event as FocusEvent).relatedTarget as HTMLInputElement;
      } else {
        field = event.target as HTMLInputElement;
      }

      void this.preview(field);
    }, 100);

    super.connect();
  }

  disconnect() {
    this.debouncedPreview.cancel();
    super.disconnect();
  }

  registerFieldInputListeners() {
    this.fieldInputTargets.forEach((target) => {
      if (target.tagName.toLowerCase() === 'select') {
        target.addEventListener('change', this.debouncedPreview);
      } else {
        target.addEventListener('input', this.debouncedPreview);
      }
      target.addEventListener('blur', this.debouncedPreview);

      if (target.dataset.focus === 'true') {
        this.focusAndSetCursorPositionToEndOfInput(target);
      }
    });
  }

  unregisterFieldInputListeners() {
    this.fieldInputTargets.forEach((target) => {
      if (target.tagName.toLowerCase() === 'select') {
        target.removeEventListener('change', this.debouncedPreview);
      } else {
        target.removeEventListener('input', this.debouncedPreview);
      }
      target.removeEventListener('blur', this.debouncedPreview);
    });
  }

  afterRendering():void {
    // Do nothing;
  }

  // Ensures that on create forms, there is an "id" for the un-persisted
  // work package when sending requests to the edit action for previews.
  ensureValidPathname(formAction:string):string {
    const wpPath = new URL(formAction);

    if (wpPath.pathname.endsWith('/work_packages/progress')) {
      // Replace /work_packages/progress with /work_packages/new/progress
      wpPath.pathname = wpPath.pathname.replace('/work_packages/progress', '/work_packages/new/progress');
    }

    return wpPath.toString();
  }

  ensureValidWpAction(wpPath:string):string {
    return wpPath.endsWith('/work_packages/new/progress') ? 'new' : 'edit';
  }

  markFieldAsTouched(event:{ target:HTMLInputElement }) {
    this.targetFieldName = event.target.name.replace(/^work_package\[([^\]]+)\]$/, '$1');
    this.markTouched(this.targetFieldName);

    if (this.isWorkBasedMode()) {
      this.keepFieldValueWithPriority('estimated_hours', 'remaining_hours', 'done_ratio');
    }
  }

  private isWorkBasedMode() {
    return this.findValueInput('done_ratio') !== undefined;
  }
}
