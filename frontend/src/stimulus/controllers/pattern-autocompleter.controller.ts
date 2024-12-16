/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';

export default class PatternAutocompleterController extends Controller {
  static targets = [
    'tokenTemplate',
    'content',
    'formInput',
    'suggestions',
  ];

  declare readonly tokenTemplateTarget:HTMLTemplateElement;
  declare readonly contentTarget:HTMLElement;
  declare readonly formInputTarget:HTMLInputElement;
  declare readonly suggestionsTarget:HTMLElement;

  static values = { patternInitial: String };
  declare patternInitialValue:string;

  // internal state
  currentRange:Range|undefined = undefined;
  selectedSuggestion:{ element:HTMLElement|null, index:number } = { element: null, index: 0 };

  connect() {
    this.contentTarget.innerHTML = this.toHtml(this.patternInitialValue) || ' ';
  }

  // Input field events
  input_keydown(event:KeyboardEvent) {
    // insert the selected suggestion
    if (event.key === 'Enter') {
      // prevent entering new line characters
      event.preventDefault();

      const selectedItem = this.suggestionsTarget.querySelector('.selected') as HTMLElement;
      if (selectedItem) {
        this.insertToken(this.createToken(selectedItem.dataset.value!));
        this.clearSuggestionsFilter();
      }
    }

    // move up and down the suggestions selection
    if (event.key === 'ArrowUp') {
      event.preventDefault();
      this.selectSuggestionAt(this.selectedSuggestion.index - 1);
    }
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      this.selectSuggestionAt(this.selectedSuggestion.index + 1);
    }

    // close the suggestions
    if (event.key === 'Escape' || event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      this.clearSuggestionsFilter();
      this.hide(this.suggestionsTarget);
    }

    // update cursor
    this.setRange();
  }

  input_change() {
    // browsers insert a `<br>` tag on empty contenteditable elements so we need to cleanup
    if (this.contentTarget.innerHTML === '<br>') {
      this.contentTarget.innerHTML = ' ';
    }

    this.ensureSpacesAround();

    // show suggestions for the current word
    const word = this.currentWord();
    if (word && word.length > 0) {
      this.filterSuggestions(word);
      this.selectSuggestionAt(0);
      this.show(this.suggestionsTarget);
    } else {
      this.clearSuggestionsFilter();
      this.hide(this.suggestionsTarget);
    }

    // update cursor
    this.setRange();
  }

  input_mouseup() {
    this.setRange();
  }

  input_focus() {
    this.setRange();
  }

  input_blur() {
    this.updateFormInputValue();
    this.hide(this.suggestionsTarget);
  }

  // Autocomplete events
  suggestions_select(event:PointerEvent) {
    const target = event.currentTarget as HTMLElement;

    if (target) {
      this.insertToken(this.createToken(target.dataset.value!));
      this.clearSuggestionsFilter();
    }
  }

  suggestions_toggle() {
    this.clearSuggestionsFilter();
    if (this.suggestionsTarget.getAttribute('hidden')) {
      this.show(this.suggestionsTarget);
    } else {
      this.hide(this.suggestionsTarget);
    }
  }

  // Token events
  remove_token(event:PointerEvent) {
    const target = event.currentTarget as HTMLElement;

    if (target) {
      const tokenElement = target.closest('[data-role="token"]');
      if (tokenElement) {
        tokenElement.remove();
      }

      this.updateFormInputValue();
    }
  }

  // internal methods
  private updateFormInputValue():void {
    this.formInputTarget.value = this.toBlueprint();
  }

  private ensureSpacesAround():void {
    if (this.contentTarget.innerHTML.startsWith('<')) {
      this.contentTarget.insertBefore(document.createTextNode(' '), this.contentTarget.children[0]);
    }
    if (this.contentTarget.innerHTML.endsWith('>')) {
      this.contentTarget.appendChild(document.createTextNode(' '));
    }
  }

  private setRange():void {
    const selection = document.getSelection();
    if (selection?.rangeCount) {
      const range = selection.getRangeAt(0);
      if (range.startContainer.parentNode === this.contentTarget) {
        this.currentRange = range;
      }
    }
  }

  private insertToken(tokenElement:HTMLElement) {
    if (this.currentRange) {
      const targetNode = this.currentRange.startContainer;
      const targetOffset = this.currentRange.startOffset;

      let pos = targetOffset - 1;
      while (pos > -1 && targetNode.textContent?.charAt(pos) !== ' ') { pos-=1; }

      const wordRange = document.createRange();
      wordRange.setStart(targetNode, pos + 1);
      wordRange.setEnd(targetNode, targetOffset);

      wordRange.deleteContents();
      wordRange.insertNode(tokenElement);

      const postRange = document.createRange();
      postRange.setStartAfter(tokenElement);

      const selection = document.getSelection();
      selection?.removeAllRanges();
      selection?.addRange(postRange);

      this.updateFormInputValue();
      this.setRange();

      // clear suggestions
      this.clearSuggestionsFilter();
      this.hide(this.suggestionsTarget);
    } else {
      this.contentTarget.appendChild(tokenElement);
    }
  }

  private currentWord():string|null {
    const selection = document.getSelection();
    if (selection) {
      return (selection.anchorNode?.textContent?.slice(0, selection.anchorOffset)
        .split(' ')
        .pop() as string)
        .toLowerCase();
    }

    return null;
  }

  private clearSuggestionsFilter():void {
    const suggestionElements = this.suggestionsTarget.children;
    for (let i = 0; i < suggestionElements.length; i+=1) {
      this.show(suggestionElements[i] as HTMLElement);
    }
  }

  private filterSuggestions(word:string):void {
    const suggestionElements = this.suggestionsTarget.children;
    for (let i = 0; i < suggestionElements.length; i+=1) {
      const suggestionElement = suggestionElements[i] as HTMLElement;
      if (!suggestionElement.dataset.value) { continue; }

      if (suggestionElement.textContent?.trim().toLowerCase().includes(word) || suggestionElement.dataset.value.includes(word)) {
        this.show(suggestionElement);
      } else {
        this.hide(suggestionElement);
      }
    }

    // show autocomplete
    this.show(this.suggestionsTarget);
  }

  private selectSuggestionAt(index:number):void {
    if (this.selectedSuggestion.element) {
      this.selectedSuggestion.element.classList.remove('selected');
      this.selectedSuggestion.element = null;
    }

    const possibleTargets = this.suggestionsTarget.querySelectorAll('[data-role="suggestion-item"]:not([hidden])');
    if (possibleTargets.length > 0) {
      if (index < 0) { index += possibleTargets.length; }
      index %= possibleTargets.length;
      const element = possibleTargets[index];
      element.classList.add('selected');
      this.selectedSuggestion.element = element as HTMLElement;
      this.selectedSuggestion.index = index;
    }
  }

  private hide(el:HTMLElement):void {
    el.setAttribute('hidden', 'hidden');
  }

  private show(el:HTMLElement):void {
    el.removeAttribute('hidden');
  }

  private createToken(value:string):HTMLElement {
    const target = this.tokenTemplateTarget.content?.cloneNode(true) as HTMLElement;
    const contentElement = target.firstElementChild as HTMLElement;
    (contentElement.querySelector('[data-role="token-text"]') as HTMLElement).innerText = value;
    return contentElement;
  }

  private toHtml(blueprint:string):string {
    let htmlValue = blueprint.replace(/{{([0-9A-Za-z_]+)}}/g, (_, token:string) => this.createToken(token).outerHTML);
    if (htmlValue.startsWith('<')) { htmlValue = ` ${htmlValue}`; }
    if (htmlValue.endsWith('>')) { htmlValue = `${htmlValue} `; }
    return htmlValue;
  }

  private toBlueprint():string {
    let result = '';
    this.contentTarget.childNodes.forEach((node:Element) => {
      if (node.nodeType === Node.TEXT_NODE) {
        // Plain text node
        result += node.textContent;
      } else if (node.nodeType === Node.ELEMENT_NODE && (node as HTMLElement).dataset.role === 'token') {
        // Token element
        const tokenText = node.querySelector('[data-role="token-text"]');
        if (tokenText) {
            result += `{{${tokenText.textContent?.trim()}}}`;
        }
      }
    });
    return result.trim();
  }
}
