import { AfterViewInit, Directive, ElementRef } from '@angular/core';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import Mousetrap from 'mousetrap';
import { computePosition, ComputePositionReturn, flip, offset, shift } from '@floating-ui/dom';

@Directive({
  selector: '[opContextMenuTrigger]',
})
export class OpContextMenuTrigger extends OpContextMenuHandler implements AfterViewInit {
  protected element:HTMLElement;

  protected items:OpContextMenuItem[] = [];

  constructor(
    readonly elementRef:ElementRef,
    readonly opContextMenu:OPContextMenuService,
  ) {
    super(opContextMenu);
  }

  ngAfterViewInit():void {
    this.element = this.elementRef.nativeElement;

    // Open by clicking the element
    this.element.addEventListener('click', (evt) => {
      evt.preventDefault();

      // When clicking the same trigger twice, close the element instead.
      if (this.opContextMenu.isActive(this)) {
        this.opContextMenu.close();
      } else {
        this.open(evt);
      }
    });

    // Open with keyboard combination as well
    Mousetrap(this.element).bind('shift+alt+f10', (evt:any) => {
      this.open(evt);
    });
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
      ],
    });
  }
}
