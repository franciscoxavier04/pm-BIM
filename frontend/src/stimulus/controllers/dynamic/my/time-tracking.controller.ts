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
      allDayContent: I18n.t('js.myTimeTracking.noSpecificTime'),
      eventClassNames(arg) {
        return [
          'calendar-time-entry-event',
          `__hl_status_${arg.event.extendedProps.statusId}`,
          '__hl_border_top',
        ];
      },
      eventDidMount(_info) {
        // console.log(info.event);
        //eslint-disable-next-line
        // info.el.innerHTML = info.event.extendedProps.customEventView;
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

        this.updateTimeEntry(
          info.event.id,
          startMoment.format('YYYY-MM-DD'),
          info.event.allDay ? null : startMoment.format('HH:mm'),
          info.event.allDay ? info.event.extendedProps.hours as number : moment.duration(endMoment.diff(startMoment)).asHours(),
          info.revert,
        );
      },

      // TODO: When dragging from all day to the calendar, we need to set the hours

      eventDrop: (info) => {
        const startMoment = moment(info.event.startStr);
        const endMoment = moment(info.event.endStr);

        this.updateTimeEntry(
          info.event.id,
          startMoment.format('YYYY-MM-DD'),
          info.event.allDay ? null : startMoment.format('HH:mm'),
          info.event.allDay ? info.event.extendedProps.hours as number : moment.duration(endMoment.diff(startMoment)).asHours(),
          info.revert,
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
      } else if (!response.ok && revertFunction) { revertFunction(); }
    }).catch(() => {
      if (revertFunction) { revertFunction(); }
    });
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
