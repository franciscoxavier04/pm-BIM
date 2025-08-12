import { Component, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Board } from 'core-app/features/boards/board/board';
import { Observable } from 'rxjs';

@Component({
  template: `
    <button title="{{ text.button_more }}"
            class="button last board--settings-dropdown toolbar-icon"
            boardsToolbarMenu
            [boardsToolbarMenu-resource]="board$ | async">
      <op-icon icon-classes="button--icon icon-show-more"></op-icon>
    </button>
  `,
  standalone: false,
})
export class BoardsMenuButtonComponent {
  readonly I18n = inject(I18nService);

  @Input() board$:Observable<Board>;

  text = {
    button_more: this.I18n.t('js.button_more'),
  };
}
