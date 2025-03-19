import { Controller } from '@hotwired/stimulus';
import { Calendar } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

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
      allDayContent: I18n.t('js.myTimeTracking.noSpecificTime'),
      eventClassNames(arg) {
        return [
          'calendar-time-entry-event',
          `__hl_status_${arg.event.extendedProps.statusId}`,
          '__hl_border_top',
        ];
      },
      eventDidMount(info) {
        //eslint-disable-next-line
        info.el.innerHTML = info.event.extendedProps.customEventView;
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
    });

    this.calendar.render();
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
