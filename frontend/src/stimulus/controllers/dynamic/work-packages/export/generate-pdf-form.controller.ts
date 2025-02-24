import { Controller } from '@hotwired/stimulus';

export default class GeneratePdfController extends Controller {
  static targets = ['templates', 'inputGroups'];

  declare inputGroupsTargets:Array<HTMLElement>;

  templatesChanged(event:Event) {
    const target = event.target as HTMLSelectElement;
    const data = target.options[target.selectedIndex].dataset;
    const template = target.options[target.selectedIndex].value;

    const formControl = target.closest('.FormControl') as HTMLElement;
    const captionElement = formControl.querySelector('.FormControl-caption') as HTMLElement;
    if (captionElement) {
      captionElement.innerText = (data.caption || '');
    }
    this.inputGroupsTargets.forEach((inputGroup:HTMLElement) => {
      if (inputGroup.dataset.template === template) {
        inputGroup.classList.remove('d-none');
      } else {
        inputGroup.classList.add('d-none');
      }
    });
  }
}
