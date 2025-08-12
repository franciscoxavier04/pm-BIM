import { ApplicationRef, ChangeDetectorRef, Component, ElementRef, Injector, OnInit, inject } from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { TimeEntriesCurrentUserConfigurationModalService } from 'core-app/shared/components/grids/widgets/time-entries/current-user/configuration-modal/services/configuration-modal/configuration-modal.service';

@Component({
  templateUrl: './configuration.modal.html',
  providers: [TimeEntriesCurrentUserConfigurationModalService],
  standalone: false,
})
export class TimeEntriesCurrentUserConfigurationModalComponent extends OpModalComponent implements OnInit {
  readonly I18n = inject(I18nService);
  readonly injector = inject(Injector);
  readonly appRef = inject(ApplicationRef);
  readonly loadingIndicator = inject(LoadingIndicatorService);
  readonly notificationService = inject(WorkPackageNotificationService);
  readonly configuration = inject(ConfigurationService);
  readonly timeEntriesCurrentUserConfigurationModalService = inject(TimeEntriesCurrentUserConfigurationModalService);

  public text = {
    displayedDays: this.I18n.t('js.grid.widgets.time_entries_current_user.displayed_days'),
    closePopup: this.I18n.t('js.close_popup_title'),
    applyButton: this.I18n.t('js.modals.button_apply'),
    cancelButton: this.I18n.t('js.modals.button_cancel'),
  };

  public firstDayOfWeek:number;

  // Checked value of all days of the week, starting from Monday.
  public options:{ days:boolean[] };

  public daysOriginalCheckedValues:boolean[];

  public days:IDayData[];

  ngOnInit() {
    const localDayOptions = this.locals.options.days;
    this.daysOriginalCheckedValues = localDayOptions.length > 0 ? localDayOptions : Array.from({ length: 7 }, () => true);
    this.days = this.timeEntriesCurrentUserConfigurationModalService.getOrderedDaysData(this.daysOriginalCheckedValues);
  }

  public saveChanges():void {
    const checkedValuesInOriginalOrder = this.timeEntriesCurrentUserConfigurationModalService.getCheckedValuesInOriginalOrder(this.days);

    this.options = { days: checkedValuesInOriginalOrder };
    this.service.close();
  }
}
