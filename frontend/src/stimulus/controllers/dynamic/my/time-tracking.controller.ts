import { Controller } from '@hotwired/stimulus';
import { Calendar } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import moment from 'moment';
import { renderStreamMessage } from '@hotwired/turbo';

export default class MyTimeTrackingController extends Controller {
  private turboRequests:TurboRequestsService;
  private pathHelper:PathHelperService;

  static targets = ['calendar'];

  static values = {
    mode: String,
    timeEntries: Array,
    initialDate: String,
    canCreate: Boolean,
    canEdit: Boolean,
  };

  declare readonly calendarTarget:HTMLElement;
  declare readonly modeValue:string;
  declare readonly timeEntriesValue:object[];
  declare readonly initialDateValue:string;
  declare readonly canCreateValue:boolean;
  declare readonly canEditValue:boolean;

  private calendar:Calendar;

  async connect() {
    const context = await window.OpenProject.getPluginContext();
    this.turboRequests = context.services.turboRequests;
    this.pathHelper = context.services.pathHelperService;

    // handle dialog close event
    document.addEventListener('dialog:close', (event:CustomEvent) => {
      const { detail: { dialog, submitted } } = event as { detail:{ dialog:HTMLDialogElement; submitted:boolean }; };
      if (dialog.id === 'time-entry-dialog' && submitted) {
        window.location.reload();
      }
    });

    const DEFAULT_TIMED_EVENT_DURATION = '01:00';

    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [timeGridPlugin, dayGridPlugin, interactionPlugin],
      initialView: this.calendarView(),
      firstDay: 1, // get from settings
      locale: 'de', // also get from settings
      events: this.timeEntriesValue,
      headerToolbar: false,
      initialDate: this.initialDateValue,
      height: 800,
      contentHeight: 780,
      aspectRatio: 3,
      selectable: this.canCreateValue,
      editable: this.canEditValue,
      eventResizableFromStart: true,
      defaultTimedEventDuration: DEFAULT_TIMED_EVENT_DURATION,
      allDayContent: I18n.t('js.myTimeTracking.noSpecificTime'),
      dayMaxEventRows: 4, // 3 + more link
      eventClassNames(arg) {
        return [
          'calendar-time-entry-event',
          `__hl_status_${arg.event.extendedProps.statusId}`,
          '__hl_border_top',
        ];
      },
      eventContent: (arg) => {
        let time = '';

        if (arg.event.allDay) {
          time = `${this.displayDuration(arg.event.extendedProps.hours as number)}`;
        } else {
          time = `${moment(arg.event.start).format('HH:mm')}-${moment(arg.event.end).format('HH:mm')} (${this.displayDuration(arg.event.extendedProps.hours as number)})`;
        }

        return ({
          html: `
            <div class="fc-event-main-frame">
              <div class="fc-event-time">${time}</div>
              <div class="fc-event-title-container">
                <div class="fc-event-title fc-sticky">
                  <a href="${this.pathHelper.workPackageShortPath(arg.event.extendedProps.workPackageId as string)}">${arg.event.extendedProps.workPackageSubject}</a>
                </div>
                <div class="text-muted">
                  <a href="${this.pathHelper.projectPath(arg.event.extendedProps.projectId as string)}">${arg.event.extendedProps.projectName}</a>
                </div>
              </div>
            </div>` });
      },
      select: (info) => {
        let dialogParams = 'onlyMe=true';

        if (info.allDay) {
          dialogParams = `${dialogParams}&date=${info.startStr}`;
        } else {
          dialogParams = `${dialogParams}&startTime=${info.start.toISOString()}&endTime=${info.end.toISOString()}`;
        }

        void this.turboRequests.request(
          `${this.pathHelper.timeEntryDialog()}?${dialogParams}`,
          { method: 'GET' },
        );
      },
      eventResize: (info) => {
        const startMoment = moment(info.event.startStr);
        const endMoment = moment(info.event.endStr);

        const newEventHours = info.event.allDay ? info.event.extendedProps.hours as number : moment.duration(endMoment.diff(startMoment)).asHours();

        info.event.setExtendedProp('hours', newEventHours);

        this.updateTimeEntry(
          info.event.id,
          startMoment.format('YYYY-MM-DD'),
          info.event.allDay ? null : startMoment.format('HH:mm'),
          newEventHours,
          info.revert,
        );
      },

      eventDragStart: (info) => {
        // When dragging from all day into the calendar set the defaultTimedEventDuration to the hours of the event so
        // that we display it correctly in the calendar. Will be reset in the drop event
        if (info.event.allDay) {
          this.calendar.setOption('defaultTimedEventDuration', moment.duration(info.event.extendedProps.hours as number, 'hours').asMilliseconds());
        }
      },

      eventDrop: (info) => {
        const startMoment = moment(info.event.startStr);

        this.updateTimeEntry(
          info.event.id,
          startMoment.format('YYYY-MM-DD'),
          info.event.allDay ? null : startMoment.format('HH:mm'),
          info.event.extendedProps.hours as number,
          info.revert,
        );

        if (!info.event.allDay) {
          info.event.setEnd(startMoment.add(info.event.extendedProps.hours as number, 'hours').toDate());
        }

        this.calendar.setOption('defaultTimedEventDuration', DEFAULT_TIMED_EVENT_DURATION);
      },
      eventClick: (info) => {
        // check if we clicked on a link tag, if so exit early as we don't want to show the modal
        if (info.jsEvent.target instanceof HTMLAnchorElement) { return; }

        void this.turboRequests.request(
          `${this.pathHelper.timeEntryEditDialog(info.event.id)}?onlyMe=true`,
          { method: 'GET' },
        );
      },
    });

    this.calendar.render();
  }

  updateTimeEntry(timeEntryId:string, spentOn:string, startTime:string | null, hours:number, revertFunction:() => void) {
    const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || '';
    fetch(
      this.pathHelper.timeEntryUpdate(timeEntryId),
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
        },
        body: JSON.stringify({
          time_entry: {
            spent_on: spentOn,
            start_time: startTime,
            hours,
          },
        }),
      },
    ).then((response) => {
      if (response.ok) {
        void response.text().then((html) => {
          renderStreamMessage(html);
        });
      } else if (revertFunction) { revertFunction(); }
    }).catch(() => {
      if (revertFunction) { revertFunction(); }
    });
  }

  displayDuration(duration:number):string {
    const hours = Math.floor(duration);
    const minutes = Math.round((duration - hours) * 60);

    if (minutes === 0) {
      return `${hours}h`;
    }
    return `${hours}h ${minutes}m`;
  }

  calendarView():string {
    switch (this.modeValue) {
      case 'week':
        return 'timeGridWeek';
      case 'month':
        return 'dayGridMonth';
      case 'day':
        return 'timeGridDay';
      default:
        return 'timeGridWeek';
    }
  }
}
