

export const getNodeIndex = (element:Element) => [...element.parentNode!.children].indexOf(element);

export const showElement = (element:HTMLElement) => toggleElement(element, true);

export const hideElement = (element:HTMLElement) => toggleElement(element, false);

export const toggleElement = (element:HTMLElement, value = !element.hidden) => element.hidden = value;
