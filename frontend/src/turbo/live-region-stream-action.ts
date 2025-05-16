import { StreamActions, StreamElement } from '@hotwired/turbo';
import { announce } from '@primer/live-region-element';

export function registerLiveRegionStreamAction() {
  StreamActions.liveRegion = function liveRegionStreamAction(this:StreamElement) {
    const message = this.getAttribute('message') || '';
    const politeness = this.getAttribute('politeness') || 'polite';
    const delayAttr = this.getAttribute('delay');
    const delay = delayAttr !== null && !Number.isNaN(Number(delayAttr)) ? Number(delayAttr) : 0;
    if (politeness === 'assertive') {
      void announce(message, {
        politeness: 'assertive',
      });
    } else {
      void announce(message, {
        politeness: 'polite',
        delayMs: delay,
      });
    }
  };
}
