import { Controller } from '@hotwired/stimulus';
import { Calendar } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import dayGridPlugin from '@fullcalendar/daygrid';

export default class MyTimeTrackingController extends Controller {
  static targets = ['calendar'];

  static values = {
    mode: String,
    timeEntries: Array,
    initialDate: String,
  };

  declare readonly calendarTarget:HTMLElement;
  declare readonly modeValue:string;
  declare readonly timeEntriesValue:object[];
  declare readonly initialDateValue:string;

  private calendar:Calendar;

  connect() {
    // styling for the calendar entries can be stolen from the team planner

    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [timeGridPlugin, dayGridPlugin],
      initialView: this.calendarView(),
      firstDay: 1, // get from settings
      locale: 'de', // also get from settings
      events: this.timeEntriesValue,
      headerToolbar: false,
      initialDate: this.initialDateValue,
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
