
export function delegateEvent(type:string, selector:string, listener:(ev:Event) => void, elementScope?: HTMLElement) {
  (elementScope || document).addEventListener(type, (ev) => {
    const element = (ev.target as HTMLElement).closest(selector);
    if (element) {
      listener.call(element, ev);
    }
  });
}

export function delegateEvents(type:string, selector:string, listener:(ev:Event) => void, elementsScope:HTMLElement[]|NodeListOf<HTMLElement>) {
  elementsScope.forEach((elementScope) => delegateEvent(type, selector, listener, elementScope));
}
