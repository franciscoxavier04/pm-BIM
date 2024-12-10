import { ApplicationController } from 'stimulus-use';

export default class OpRecurringMeetingsFormController extends ApplicationController {
  static targets = [
    'frequency',
    'interval',
  ];

  declare readonly frequencyTarget:HTMLSelectElement;
  declare readonly intervalTarget:HTMLInputElement;

  updateFrequencyText():void {
    const frequency = this.frequencyTarget.value;
    const interval = this.intervalTarget.value;
    this.intervalTarget.placeholder = `Every ${frequency}`;
  }
}
