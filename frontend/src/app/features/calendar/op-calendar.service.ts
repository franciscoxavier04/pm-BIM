import {
  ElementRef,
  Injectable,
} from '@angular/core';
import { Subject } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import * as moment from 'moment-timezone';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Injectable()
export class OpCalendarService extends UntilDestroyedMixin {
  resize$ = new Subject<void>();

  resizeObs:ResizeObserver;

  constructor(
    readonly weekdayService:WeekdayService,
    readonly dayService:DayResourceService,
    readonly configurationService:ConfigurationService,
  ) {
    super();
  }

  resizeObserver(v:ElementRef|undefined):void {
    if (!v) {
      return;
    }

    if (!this.resizeObs) {
      this.resizeObs = new ResizeObserver(() => this.resize$.next());
    }

    this.resizeObs.observe(v.nativeElement as Element);
  }

  applyNonWorkingDay({ date }:{ date?:Date }, nonWorkingDays:IDay[]):string[] {
    const utcDate = moment(date).utc();
    const formatted = utcDate.format('YYYY-MM-DD');
    if (date && (this.weekdayService.isNonWorkingDay(utcDate) || nonWorkingDays.find((el) => el.date === formatted))) {
      return ['fc-non-working-day'];
    }
    return [];
  }

  dayHeaderContent({ date }:{ date?:Date }):string {
    const utcDate = moment(date).utc();

    // If no date format is configured, use a very unambiguous one as default
    const configuredDateFormat = this.configurationService.dateFormatPresent()
      ? this.configurationService.dateFormat() : 'YYYY-MM-DD';

    return utcDate.format(`ddd ${configuredDateFormat}`);
  }
}
