import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['section', 'select'];

  declare readonly sectionTargets:HTMLElement[];

  declare readonly selectTarget:HTMLSelectElement;

  add(event:Event) {
    const selectedValue = (event.target as HTMLSelectElement).value;
    if (!selectedValue) {
      return;
    }

    const section = this.sectionTargets.find((s) => s.dataset.sectionName === selectedValue);
    if (section) {
      section.hidden = false;
    }

    this.toggleOption(selectedValue);
  }

  hide(event:MouseEvent) {
    const section = (event.target as HTMLElement).closest('.hide-section') as HTMLElement;
    if (section) {
      section.hidden = true;
    }

    const name = section.dataset.name as string;
    this.toggleOption(name);
  }

  toggleOption(name:string) {
    const option = Array
      .from(this.selectTarget.options)
      .find((opt:HTMLOptionElement) => opt.value === name);

    if (!option) {
      return;
    }

    option.disabled = !option.disabled;
  }
}
