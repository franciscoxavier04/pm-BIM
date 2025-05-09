import { StreamActions, StreamElement } from '@hotwired/turbo';
import { announce } from '@primer/live-region-element';

export function registerAriaStreamAction() {
  StreamActions.aria = function ariaStreamAction(this:StreamElement) {
      const message = this.getAttribute('message') || '';
      const politeness = this.getAttribute('politeness') || 'polite';
      if (politeness === 'assertive') {
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
