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

import {
  ChangeDetectorRef, Directive, ElementRef, Injector,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { BoardListComponent } from 'core-app/features/boards/board/board-list/board-list.component';
import { computePosition, flip, offset, shift } from '@floating-ui/dom';

@Directive({
  selector: '[op-addCardDropdown]',
})
export class AddCardDropdownMenuDirective extends OpContextMenuTrigger {
  constructor(readonly elementRef:ElementRef,
    readonly opContextMenu:OPContextMenuService,
    readonly opModalService:OpModalService,
    readonly authorisationService:AuthorisationService,
    readonly wpInlineCreate:WorkPackageInlineCreateService,
    readonly boardList:BoardListComponent,
    readonly injector:Injector,
    readonly querySpace:IsolatedQuerySpace,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService) {
    super(elementRef, opContextMenu);
  }

  protected open(evt:Event) {
    this.items = this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  /**
   * Compute position for Floating UI.
   *
   * @param {Event} openerEvent
   */
  public computePosition(floating:HTMLElement, openerEvent:Event) {
    return computePosition(this.element, floating, {
      placement: 'bottom-start',
      middleware: [
        offset(0),
        flip(),
        shift({ padding: 5 }),
      ]
    });
  }

  private buildItems() {
    return [
      {
        disabled: !this.wpInlineCreate.canAdd,
        linkText: this.I18n.t('js.card.add_new'),
        onClick: () => {
          this.boardList.addNewCard();
          return true;
        },
      },
      {
        disabled: !this.wpInlineCreate.canReference,
        linkText: this.I18n.t('js.relation_buttons.add_existing'),
        onClick: () => {
          this.boardList.addReferenceCard();
          return true;
        },
      },
    ];
  }
}
