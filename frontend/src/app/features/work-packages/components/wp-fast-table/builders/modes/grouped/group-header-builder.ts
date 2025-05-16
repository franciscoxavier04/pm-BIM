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

import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { rowGroupClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-classes.constants';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import { groupName } from './grouped-rows-helpers';
import { ProjectPhaseDisplayField } from 'core-app/shared/components/fields/display/field-types/project-phase-display-field.module';

export function groupClassNameFor(group:GroupObject) {
  return `group-${group.identifier}`;
}

export class GroupHeaderBuilder {
  @InjectField() public I18n:I18nService;

  public text:{ collapse:string, expand:string };

  constructor(public readonly injector:Injector) {
    this.text = {
      collapse: this.I18n.t('js.label_collapse'),
      expand: this.I18n.t('js.label_expand'),
    };
  }

  public buildGroupRow(group:GroupObject, colspan:number) {
    const row = document.createElement('tr');
    let togglerIconClass;
    let text;

    if (group.collapsed) {
      text = this.text.expand;
      togglerIconClass = 'icon-plus';
    } else {
      text = this.text.collapse;
      togglerIconClass = 'icon-minus2';
    }

    const leadingIcon = this.leadingIcon(group);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
    const groupTitle = _.escape((groupName(group)));

    row.classList.add(rowGroupClassName, groupClassNameFor(group));
    row.id = `wp-table-rowgroup-${group.index}`;
    row.dataset.groupIndex = (group.index).toString();
    row.dataset.groupIdentifier = group.identifier;
    row.innerHTML = `
      <td colspan="${colspan}" class="-no-highlighting">
        <div class="expander icon-context ${togglerIconClass}">
          <span class="hidden-for-sighted">${_.escape(text)}</span>
        </div>
        <div class="group--value" data-test-selector="op-group--value">
          ${leadingIcon ? leadingIcon.outerHTML : ''}
          ${groupTitle}
          <span class="count">
            (${group.count})
          </span>
        </div>
      </td>
    `;

    return row;
  }

  private leadingIcon(group:GroupObject) {
    if (group.leadingIcon === 'projectPhaseDefinition') {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      return ProjectPhaseDisplayField.phaseIconByName(groupName(group), false);
    }

    return null;
  }
}
