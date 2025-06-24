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

import { Injectable } from '@angular/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DateTime, Duration, DurationUnit, Settings } from 'luxon';
import { outputChronicDuration } from '../../shared/helpers/chronic_duration';
import { toDateTime } from 'core-app/shared/helpers/date-time-helpers';

@Injectable({ providedIn: 'root' })
export class TimezoneService {
  constructor(
    readonly configurationService:ConfigurationService,
    readonly I18n:I18nService,
  ) { }

  /**
   * Returns the user's configured timezone or guesses it through moment
   */
  public userTimezone():string {
    return this.configurationService.isTimezoneSet() ? this.configurationService.timezone() : Settings.defaultZone.name;
  }

  /**
   * Takes a utc date time string and turns it into
   * a local date time moment object.
   */
  public parseDatetime(datetime:string):DateTime {
    return DateTime.fromISO(datetime).setZone(this.userTimezone());
  }

  public parseDate(date:DateTime|Date|string):DateTime {
    return toDateTime(date);
  }

  /**
   * Parses the specified datetime and applies the user's configured timezone, if any.
   *
   * This will effectfully transform the [server] provided datetime object to the user's configured local timezone.
   *
   * @param {String} datetime in 'YYYY-MM-DDTHH:mm:ssZ' format
   * @returns {DateTime}
   */
  public parseISODatetime(datetime:string):DateTime {
    return this.parseDatetime(datetime);
  }

  public parseISODate(date:string):DateTime {
    return DateTime.fromISO(date);
  }

  public formattedDate(date:string, format = this.getDateFormat()):string {
    return DateTime.fromISO(date).toLocaleString(format);
  }

  /**
   * Returns the number of days from today the given dateString is apart.
   * Negative means the date lies in the past.
   * @param dateString
   */
  public daysFromToday(dateString:string):number {
    const dt = DateTime.fromISO(dateString);
    const today = DateTime.now().startOf('day');

    return dt.diff(today, 'days').days;
  }

  public formattedTime(datetimeString:string, format = this.getTimeFormat()):string {
    return this.parseDatetime(datetimeString).toLocaleString(format);
  }

  public formattedDatetime(datetimeString:string):string {
    const c = this.formattedDatetimeComponents(datetimeString);
    return `${c[0]} ${c[1]}`;
  }

  public formattedRelativeDateTime(datetimeString:string):string {
    const dt = this.parseDatetime(datetimeString);
    return dt.toRelative() || '';
  }

  public formattedDatetimeComponents(datetimeString:string):[string, string] {
    const dt = this.parseDatetime(datetimeString);
    return [
      dt.toLocaleString(this.getDateFormat()),
      dt.toLocaleString(this.getTimeFormat()),
    ];
  }

  public toSeconds(durationString:string):number {
    return Number(Duration.fromISO(durationString).seconds.toFixed(2));
  }

  public toHours(durationString:string):number {
    return Number(Duration.fromISO(durationString).hours.toFixed(2));
  }

  public toDays(durationString:string):number {
    return Number(Duration.fromISO(durationString).days.toFixed(2));
  }

  public toISODuration(input:string|number, unit:DurationUnit):string {
    return Duration.fromObject({ [unit]: input }).toISO();
  }

  public utcDateToLocalDate(date:Date):Date {
    return new Date(date.getTime() + date.getTimezoneOffset() * 60 * 1000);
  }

  public utcDateToISODateString(date:Date):string {
    return DateTime.fromJSDate(date).toUTC().toISODate() || '';
  }

  public utcDatesToISODateStrings(dates:Date[]):string[] {
    return dates.map((date) => this.utcDateToISODateString(date));
  }

  public formattedDuration(durationString:string, unit:'hour'|'days' = 'hour'):string {
    switch (unit) {
      case 'hour':
        return this.I18n.t('js.units.hour', {
          count: this.toHours(durationString),
        });
      case 'days':
        return this.I18n.t('js.units.day', {
          count: this.toDays(durationString),
        });
      default:
        // Case fallthrough for eslint
        return '';
    }
  }

  public formattedChronicDuration(durationString:string, opts = {
    format: this.configurationService.durationFormat(),
    hoursPerDay: this.configurationService.hoursPerDay(),
    daysPerMonth: this.configurationService.daysPerMonth(),
  }):string {
    // Keep in sync with app/services/duration_converter#output
    const seconds = this.toSeconds(durationString);

    return outputChronicDuration(seconds, opts) || '0h';
  }

  public formattedISODate(date:DateTime|Date|string):string {
    return this.parseDate(date).toISODate() || '';
  }

  public formattedISODateTime(datetime:DateTime):string {
    return datetime.toISO() || '';
  }

  public isValidISODate(date:string):boolean {
    return DateTime.fromISO(date).isValid;
  }

  public isValidISODateTime(dateTime:string):boolean {
    return DateTime.fromISO(dateTime).isValid;
  }

  public getDateFormat():Intl.DateTimeFormatOptions {
    //return this.configurationService.dateFormatPresent() ? this.configurationService.dateFormat() :
    return DateTime.DATE_SHORT;
  }

  public getTimeFormat():Intl.DateTimeFormatOptions {
    //return this.configurationService.timeFormatPresent() ? this.configurationService.timeFormat() :
    return DateTime.TIME_SIMPLE;
  }
}
