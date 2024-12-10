import { Controller } from '@hotwired/stimulus';

export default class ScrollController extends Controller {
  connect() {
    this.waitForRenderAndAct();
  }

  waitForRenderAndAct() {
    const element = document.querySelector('[data-scroll-active="true"]');

    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'center' });
    } else {
      requestAnimationFrame(this.waitForRenderAndAct.bind(this));
    }
  }
}
