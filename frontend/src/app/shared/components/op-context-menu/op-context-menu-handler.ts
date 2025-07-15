import { computePosition, ComputePositionReturn, flip, offset, shift } from '@floating-ui/dom';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

/**
 * Interface passed to CM service to open a particular context menu.
 * This will often be a trigger component, but does not have to be.
 */
export abstract class OpContextMenuHandler extends UntilDestroyedMixin {
  protected element:HTMLElement;

  protected items:OpContextMenuItem[] = [];

  constructor(readonly opContextMenu:OPContextMenuService) {
    super();
  }

  /**
   * Called when the service closes this context menu
   *
   * @param focus Focus on the trigger again
   */
  public onClose(focus = false) {
    if (focus) {
      this.afterFocusOn.focus();
    }
  }

  public onOpen(menu:HTMLElement) {
    menu.querySelector<HTMLElement>('.menu-item')?.focus();
  }

  /**
   * Compute position for Floating UI.
   *
   * @param {Event} openerEvent
   */
  public computePosition(floating:HTMLElement, openerEvent:Event):Promise<ComputePositionReturn> {
    const reference = openerEvent.target as HTMLElement;
    return computePosition(reference, floating, {
      placement: 'bottom-start',
      middleware: [
        offset(0),
        flip(),
        shift({ padding: 5 }),
      ],
    });
  }

  /**
   * Get the locals passed to the op-context-menu component
   */
  public get locals():{ showAnchorRight?:boolean, contextMenuId?:string, items:OpContextMenuItem[] } {
    return {
      items: this.items,
    };
  }

  /**
   * Open this context menu
   */
  protected open(evt:Event):void {
    this.opContextMenu.show(this, evt);
  }

  protected get afterFocusOn():HTMLElement {
    return this.element;
  }
}
