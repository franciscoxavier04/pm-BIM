import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import {
  UntypedFormArray,
  UntypedFormControl,
  FormGroupDirective,
} from '@angular/forms';
import moment from 'moment';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'op-workdays-settings',
  templateUrl: './workdays-settings.component.html',
  styleUrls: ['./workdays-settings.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkdaysSettingsComponent implements OnInit {
  private I18n = inject(I18nService);
  readonly formGroup = inject(FormGroupDirective);

  control:UntypedFormArray;

  /**
   * The locale might render workdays in a different order, which is what moment return with localeSorted
   * and used for rendering the component.
   */
  localeWorkdays:string[] = moment.weekdays(true);

  /**
   * Almost* ISO workdays with localized strings.
   * ISO workdays are 1=Monday, ... 7=Sunday which is what we persist
   *
   * Working with the FormArray however, we use 0=Monday, 6=Sunday and add one before saving
   * @private
   */
  private isoWorkdays:string[] = WorkdaysSettingsComponent.buildISOWeekdays();

  text = {
    title: this.I18n.t('js.reminders.settings.workdays.title'),
  };

  ngOnInit():void {
    this.control = this.formGroup.control.get('workdays') as UntypedFormArray;
  }

  indexOfLocalWorkday(day:string):number {
    return this.isoWorkdays.indexOf(day);
  }

  controlForLocalWorkday(day:string):UntypedFormControl {
    const index = this.indexOfLocalWorkday(day);
    return this.control.at(index) as UntypedFormControl;
  }

  /** Workdays from moment.js are in non-ISO order, that means Sunday=0, Saturday=6 */
  static buildISOWeekdays():string[] {
    const days = moment.weekdays(false);

    days.push(days.shift() as string);

    return days;
  }
}
