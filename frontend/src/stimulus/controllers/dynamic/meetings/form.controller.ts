import { ApplicationController } from 'stimulus-use';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export default class OpMeetingsFormController extends ApplicationController {
  private turboRequests:TurboRequestsService;
  private pathHelper:PathHelperService;

  static values = { structured: Boolean };

  declare structuredValue:boolean;

  async connect() {
    const context = await window.OpenProject.getPluginContext();
    this.turboRequests = context.services.turboRequests;
    this.pathHelper = context.services.pathHelperService;
  }

  updateTimezoneText():void {
    const data = new FormData(this.element as HTMLFormElement);
    const urlSearchParams = new URLSearchParams();
    let key:string;

    ['start_date', 'start_time_hour'].forEach((name) => {
      if (this.structuredValue === true) {
        key = `structured_meeting[${name}]`;
      } else {
        key = `meeting[${name}]`;
      }
      urlSearchParams.append(key, data.get(key) as string);
    });

    void this
      .turboRequests
      .request(
        `${this.pathHelper.staticBase}/meetings/fetch_timezone?${urlSearchParams.toString()}`,
        {
          headers: { Accept: 'text/vnd.turbo-stream.html' },
        },
      );
  }
}
