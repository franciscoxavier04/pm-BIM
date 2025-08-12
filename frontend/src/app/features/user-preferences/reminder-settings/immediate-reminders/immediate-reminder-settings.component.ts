import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import {
  UntypedFormGroup,
  FormGroupDirective,
} from '@angular/forms';

@Component({
  selector: 'op-immediate-reminder-settings',
  templateUrl: './immediate-reminder-settings.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class ImmediateReminderSettingsComponent implements OnInit {
  private I18n = inject(I18nService);
  private storeService = inject(UserPreferencesService);
  private rootFormGroup = inject(FormGroupDirective);

  form:UntypedFormGroup;

  text = {
    title: this.I18n.t('js.reminders.settings.immediate.title'),
    explanation: this.I18n.t('js.reminders.settings.immediate.explanation'),
    mentioned: this.I18n.t('js.reminders.settings.immediate.mentioned'),
    personalReminder: this.I18n.t('js.reminders.settings.immediate.personal_reminder'),
  };

  ngOnInit():void {
    this.form = this.rootFormGroup.control.get('immediateReminders') as UntypedFormGroup;
  }
}
