/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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

export default class RestrictedCommentController extends Controller {
  static targets = ['checkbox', 'formContainer'];

  declare readonly checkboxTarget:HTMLInputElement;
  declare readonly formContainerTarget:HTMLElement;

  onCheckboxChange():void {
    const restrictedCommentBgColorClass = 'work-packages-activities-tab-journals-new-component__journal-notes-body--restricted-comment';
    // FIXME: This is not ideal as primer can change class names. Awaiting redesign of the form...
    // This should NOT make it to production.
    const primerBgColorClass = 'color-bg-subtle';

    if (this.checkboxTarget.checked) {
      this.formContainerTarget.classList.remove(primerBgColorClass);
      this.formContainerTarget.classList.add(restrictedCommentBgColorClass);
    } else {
      this.formContainerTarget.classList.remove(restrictedCommentBgColorClass);
      this.formContainerTarget.classList.add(primerBgColorClass);
    }
  }
}
