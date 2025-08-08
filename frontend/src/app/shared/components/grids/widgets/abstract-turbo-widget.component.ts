import { ChangeDetectionStrategy, Component, Directive } from "@angular/core";
import { AbstractWidgetComponent } from "./abstract-widget.component";

@Component({
  template: `<turbo-frame [attr.src]='src'></turbo-frame>`,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export abstract class TurboWidgetComponent extends AbstractWidgetComponent {
  abstract src:string;

  override get isEditable(): boolean {
    return false;
  }
}
