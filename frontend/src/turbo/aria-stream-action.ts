import { StreamActions, StreamElement } from '@hotwired/turbo';
import { announce } from '@primer/live-region-element';

export function registerAriaStreamAction() {
  StreamActions.aria = function ariaStreamAction(this:StreamElement) {
      const message = this.getAttribute('message') ?? '';
      const type = this.getAttribute('type') ?? 'polite';
      if (type === 'assertive') {
        void announce(message, {
          politeness: 'assertive',
        });
      } else {
        void announce(message, {
          politeness: 'polite',
          delayMs: 5000,
        });
      }
  };
}
