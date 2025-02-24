import { StreamActions, StreamElement } from '@hotwired/turbo';
import { announce } from '@primer/live-region-element';
export function registerAriaStreamAction() {
  StreamActions.aria = function dialogStreamAction(this:StreamElement) {
    document.addEventListener("turbo:before-stream-render", () => {
      const message = this.getAttribute('message')??'';
      const type = this.getAttribute('type')??'polite';
      if (type === 'assertive') {
        announce(message, {
          politeness: 'assertive',
        });
      } else {
        announce(message, {
          politeness: 'polite',
        });
      }
    });
  };
}
