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

import type IndexController from './index.controller';
import type RestrictedCommentController from './restricted-comment.controller';

type QuoteParams = {
  userId:string;
  userName:string;
  textWrote:string;
  content:string;
  isRestricted:boolean;
};

export default class QuoteCommentController extends Controller {
  static outlets = ['work-packages--activities-tab--index', 'work-packages--activities-tab--restricted-comment'];

  declare readonly workPackagesActivitiesTabIndexOutlet:IndexController;
  declare readonly workPackagesActivitiesTabRestrictedCommentOutlet:RestrictedCommentController;

  quote({ params: { userId, userName, textWrote, content, isRestricted } }:{ params:QuoteParams }) {
    const quotedText = this.quotedText(content, userId, userName, textWrote);

    if (this.isFormVisible) {
      this.insertQuoteOnExistingEditor(quotedText);
    } else {
      this.openEditorWithInitialData(quotedText);
    }

    this.setCommentRestriction(isRestricted);
  }

  private quotedText(rawComment:string, userId:string, userName:string, textWrote:string) {
    const quoted = rawComment.split('\n')
      .map((line:string) => `\n> ${line}`)
      .join('');

    // if we ever change CKEditor or how @mentions work this will break
    return `<mention class="mention" data-id="${userId}" data-type="user" data-text="@${userName}">@${userName}</mention> ${textWrote}:\n\n${quoted}`;
  }

  private insertQuoteOnExistingEditor(quotedText:string) {
    if (this.ckEditorInstance) {
      const editorData = this.ckEditorInstance.getData({ trim: false });

      if (editorData.endsWith('<br>') || editorData.endsWith('\n')) {
        this.ckEditorInstance.setData(`${editorData}${quotedText}`);
      } else {
        this.ckEditorInstance.setData(`${editorData}\n\n${quotedText}`);
      }
    }
  }

  private setCommentRestriction(isRestricted:boolean) {
    if (isRestricted && !this.workPackagesActivitiesTabRestrictedCommentOutlet.restrictedCheckboxTarget.checked) {
      this.workPackagesActivitiesTabRestrictedCommentOutlet.restrictedCheckboxTarget.checked = isRestricted;
      this.workPackagesActivitiesTabRestrictedCommentOutlet.toggleBackgroundColor();
    }
  }

  private openEditorWithInitialData(quotedText:string) {
    this.workPackagesActivitiesTabIndexOutlet.openEditorWithInitialData(quotedText);
  }

  private get ckEditorInstance() {
    return this.workPackagesActivitiesTabIndexOutlet.getCkEditorInstance();
  }

  private get isFormVisible():boolean {
    return !this.workPackagesActivitiesTabIndexOutlet.formRowTarget.classList.contains('d-none');
  }
}
