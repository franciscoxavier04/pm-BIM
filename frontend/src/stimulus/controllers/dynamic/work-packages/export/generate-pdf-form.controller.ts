import { Controller } from '@hotwired/stimulus';

export default class GeneratePdfController extends Controller {
  static targets = ['templates'];

  templatesChanged(event:Event) {
    const target = event.target as HTMLSelectElement;
    const data = target.options[target.selectedIndex].dataset;

    const formControl = target.closest('.FormControl') as HTMLElement;
    const captionElement = formControl.querySelector('.FormControl-caption') as HTMLElement;
    if (captionElement) {
      captionElement.innerText = (data.caption || '');
    }
  }
}
