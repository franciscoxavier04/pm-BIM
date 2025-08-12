import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TypeGroup } from 'core-app/features/admin/types/type-form-configuration.component';

@Component({
  selector: 'op-type-form-query-group',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './query-group.component.html',
  standalone: false,
})
export class TypeFormQueryGroupComponent {
  private I18n = inject(I18nService);
  private cdRef = inject(ChangeDetectorRef);

  text = {
    edit_query: this.I18n.t('js.admin.type_form.edit_query'),
  };

  @Input() public group:TypeGroup;

  @Output() public editQuery = new EventEmitter<void>();

  @Output() public deleteGroup = new EventEmitter<void>();

  rename(newValue:string):void {
    this.group.name = newValue;
    this.cdRef.detectChanges();
  }
}
