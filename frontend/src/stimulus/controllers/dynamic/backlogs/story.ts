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

import { Backlog } from './backlog';
import { WorkPackage } from './work_package';

/**************************************
  STORY
***************************************/
class Story extends WorkPackage {
  constructor(el:HTMLElement) {
    super(el);

    // Associate this object with the element for later retrieval
    this.$.data('this', this);
    this.$.on('click', '.editable', this.handleClick);
  }

  /**
   * Callbacks from model.ts
   **/
  beforeSave() {
    this.refreshStory();
  }

  afterCreate(data:any, textStatus:any, xhr:any) {
    this.refreshStory();
  }

  afterUpdate(data:any, textStatus:any, xhr:any) {
    this.refreshStory();
  }

  refreshed() {
    this.refreshStory();
  }

  editDialogTitle() {
    return `Story #${this.getID()}`;
  }

  editorDisplayed(editor:JQuery<HTMLElement>) {
  }

  getPoints() {
    const points = parseInt(this.$.find('.story_points').first().text(), 10);
    return isNaN(points) ? 0 : points;
  }

  getType() {
    return 'Story';
  }

  markIfClosed() {
    // Do nothing
  }

  newDialogTitle() {
    return 'New Story';
  }

  refreshStory() {
    this.recalcVelocity();
  }

  recalcVelocity() {
    (this.$.parents('.backlog').first().data('this') as Backlog).refresh();
  }

  saveDirectives() {
    let url;
    const prev = this.$.prev();
    const backlog = this.$.parents('.backlog').data('this') as Backlog;
    const sprintId = backlog.isSprintBacklog()
      ? backlog.getSprint().getID()
      : '';
    let data = `prev=${
      prev.length === 1 ? prev.data('this').getID() : ''
    }&version_id=${sprintId}`;

    if (this.$.find('.editor').length > 0) {
      data += `&${this.$.find('.editor').serialize()}`;
    }

    //TODO: this might be unsave in case the parent of this story is not the
    //      sprint backlog, then we dont have a sprintId an cannot generate a
    //      valid url - one option might be to take RB.constants.sprint_id
    //      hoping it exists
    if (this.isNew()) {
      // @ts-expect-error TS(2304): Cannot find name 'RB'.
      url = RB.urlFor('create_story', { sprint_id: sprintId });
    } else {
      // @ts-expect-error TS(2304): Cannot find name 'RB'.
      url = RB.urlFor('update_story', { id: this.getID(), sprint_id: sprintId });
      data += '&_method=put';
    }

    return {
      url,
      data,
    };
  }

  beforeSaveDragResult() {
    // Do nothing
  }
}

export const EditableStory = EditableInplace(Story);
export type EditableStoryType = typeof EditableStory & Story; // FIXME
