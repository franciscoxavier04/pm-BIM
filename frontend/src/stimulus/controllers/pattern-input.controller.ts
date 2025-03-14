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

// internal type used to filter suggestions
type FilteredSuggestions = Array<{
  key:string;
  values:Array<{ prop:string; value:string; }>;
}>;

type TokenElement = HTMLElement&{ dataset:{ role:'token', prop:string } };

const COMPLETION_CHARACTER = '/';

export default class PatternInputController extends Controller {
  static targets = [
    'tokenTemplate',
    'content',
    'formInput',

    'suggestions',
    'suggestionsHeadingTemplate',
    'suggestionsDividerTemplate',
    'suggestionsItemTemplate',

    'insertAsTextTemplate',
  ];

  declare readonly tokenTemplateTarget:HTMLTemplateElement;
  declare readonly contentTarget:HTMLElement;
  declare readonly formInputTarget:HTMLInputElement;

  declare readonly suggestionsTarget:HTMLElement;
  declare readonly suggestionsHeadingTemplateTarget:HTMLTemplateElement;
  declare readonly suggestionsDividerTemplateTarget:HTMLTemplateElement;
  declare readonly suggestionsItemTemplateTarget:HTMLTemplateElement;

  declare readonly insertAsTextTemplateTarget:HTMLTemplateElement;

  static values = {
    patternInitial: String,
    suggestionsInitial: Object,
    insertAsTextTemplate: String,
  };

  declare readonly patternInitialValue:string;
  declare readonly suggestionsInitialValue:Record<string, Record<string, string>>;
  declare readonly insertAsTextTemplateValue:string;

  validTokenMap:Record<string, string> = {};
  currentRange:Range|undefined = undefined;

  connect() {
    this.validTokenMap = Object.values(this.suggestionsInitialValue)
      .reduce((acc, val) => ({ ...acc, ...val }), {});

    this.contentTarget.innerHTML = this.toHtml(this.patternInitialValue) || ' ';
    this.tagInvalidTokens();
    this.clearSuggestionsFilter();
  }

  // Input field events
  input_keydown(event:KeyboardEvent) {
    if (event.key === 'Enter') {
      event.preventDefault();
    }

    if (event.key === 'ArrowDown') {
      const firstSuggestion = this.suggestionsTarget.querySelector('[role="menuitem"]') as HTMLElement;
      firstSuggestion?.focus();
      event.preventDefault();
    }
    if (event.key === 'ArrowLeft') {
      if (this.startsWithToken()) {
        this.insertSpaceIfFirstCharacter();
      }
    }
    if (event.key === 'ArrowRight') {
      if (this.endsWithToken()) {
        this.insertSpaceIfLastCharacter();
      }
    }

    // close the suggestions
    if (['Escape', 'ArrowLeft', 'ArrowRight', 'End', 'Home'].includes(event.key)) {
      this.clearSuggestionsFilter();
    }

    // update cursor
    this.setRange();
  }

  input_change():void {
    // clean up empty tags from the input
    this.contentTarget.querySelectorAll('span').forEach((element) => element.textContent?.trim() === '' && element.remove());
    this.contentTarget.querySelectorAll('br').forEach((element) => element.remove());

    // show suggestions for the current word
    const word = this.currentWord();
    if (word === null) {
      this.clearSuggestionsFilter();
    } else {
      this.filterSuggestions(word);
    }

    this.tagInvalidTokens();

    // This resets the cursor position without changing it.
    // It is necessary because chromium based browsers try to
    // retain styling and adds an unwanted <font> tag,
    // breaking the behaviour of this component
    const selection = document.getSelection();
    if (selection && selection.rangeCount) {
      const range = selection.getRangeAt(0);
      selection.removeAllRanges();
      selection.addRange(range);
    }
    this.setRange();
  }

  input_mouseup() {
    const selection = document.getSelection();
    if (selection?.type === 'Caret' && selection?.anchorOffset === 0 && this.startsWithToken()) {
      this.insertSpaceIfFirstCharacter();
    }

    if (selection?.type === 'Caret' && this.endsWithToken()) {
      this.insertSpaceIfLastCharacter();
    }

    this.setRange();
  }

  input_focus() {
    this.setRange();
  }

  input_blur() {
    this.updateFormInputValue();
  }

  // Autocomplete events
  suggestions_select(event:PointerEvent):void {
    const target = event.currentTarget as HTMLElement;
    const token = this.createToken(target.dataset.prop!);

    if (!this.currentRange) {
      this.contentTarget.appendChild(token);
      this.clearSuggestionsFilter();
      return;
    }

    const parentNode = this.currentRange.startContainer.parentNode;
    if (parentNode !== null && this.isToken(parentNode)) {
      this.replaceToken(token, parentNode);
    } else {
      this.insertToken(token);
    }

    this.clearSuggestionsFilter();
  }

  close_suggestions() {
    this.clearSuggestionsFilter();
  }

  private updateFormInputValue():void {
    this.formInputTarget.value = this.toBlueprint();
  }

  /**
   * Sets an internal representation of the cursor position by persisting the current `Range`
   */
  private setRange():void {
    const selection = document.getSelection();
    if (selection?.rangeCount) {
      this.currentRange = selection.getRangeAt(0);
    }
  }

  private insertSpaceIfFirstCharacter() {
    const selection = document.getSelection();
    if (selection && selection.rangeCount) {
      const range = selection.getRangeAt(0);
      // create a test range
      // select the whole content of the input
      // then set the "end" position to the current actual selection position (the caret)
      const testRange = document.createRange();
      testRange.selectNodeContents(this.contentTarget);
      testRange.setEnd(range.startContainer, range.startOffset);

      // if the resulting range is empty it is at the start of the input
      if (testRange.toString() === '') {
        // add a space
        const beforeToken = document.createTextNode(' ');
        const firstContent = this.contentTarget.firstChild as HTMLElement;
        this.contentTarget.insertBefore(beforeToken, firstContent);

        this.setRealCaretPositionAtNode(beforeToken, 'before');
      }
    }
  }

  private insertSpaceIfLastCharacter():void {
    const selection = document.getSelection();
    if (selection && selection.rangeCount) {
      const range = selection.getRangeAt(0);
      // create a test range
      // select the whole content of the input
      // then set the "start" position to the current actual selection position (the caret)
      const testRange = document.createRange();
      testRange.selectNodeContents(this.contentTarget);
      testRange.setStart(range.endContainer, range.endOffset);

      // if the resulting range is empty it is at the end of the input
      if (testRange.toString() === '') {
        // add a space
        const afterToken = document.createTextNode(' ');
        this.contentTarget.appendChild(afterToken);

        this.setRealCaretPositionAtNode(afterToken);
      }
    }
  }

  private setRealCaretPositionAtNode(target:Node, position:'before'|'after' = 'after'):void {
    const selection = document.getSelection();
    if (selection === null) { return; }

    const postRange = document.createRange();
    if (position === 'after') {
      postRange.setStartAfter(target);
    } else {
      postRange.setStartBefore(target);
    }
    selection.removeAllRanges();
    selection.addRange(postRange);
  }

  private endsWithToken():boolean {
    return this.contentTarget.innerHTML.endsWith('>');
  }

  private startsWithToken():boolean {
    return this.contentTarget.innerHTML.startsWith('<');
  }

  private replaceToken(newToken:TokenElement, oldToken:TokenElement):void {
    oldToken.replaceWith(newToken);
    this.setRealCaretPositionAtNode(newToken);
    this.updateFormInputValue();
    this.setRange();
  }

  private insertToken(token:TokenElement) {
    if (!this.currentRange) { return; }

    const targetNode = this.currentRange.startContainer;
    const targetOffset = this.currentRange.startOffset;
    const textContent = targetNode.textContent;

    if (textContent === null) { return; }

    let pos = targetOffset - 1;
    while (pos > -1 && textContent.charAt(pos) !== COMPLETION_CHARACTER) { pos -= 1; }

    const wordRange = document.createRange();
    wordRange.setStart(targetNode, pos);
    wordRange.setEnd(targetNode, targetOffset);

    wordRange.deleteContents();
    wordRange.insertNode(token);

    this.setRealCaretPositionAtNode(token);
    this.updateFormInputValue();
    this.setRange();
  }

  private currentWord():string|null {
    const selection = document.getSelection();
    if (selection === null) { return null; }

    const anchor = selection.anchorNode;
    if (anchor === null) { return null; }

    const parent = anchor.parentNode;
    if (parent === null) { return null; }

    const textContent = anchor.textContent;
    if (textContent === null) { return null; }

    if (this.isToken(parent)) {
      return textContent.slice(0, selection.anchorOffset);
    }

    const posKey = textContent.lastIndexOf(COMPLETION_CHARACTER);
    if (posKey === -1) { return null; }

    // key character is only considered valid, if directly followed by a non-whitespace character
    const textAfterKey = textContent.slice(posKey + 1, selection.anchorOffset);
    return textAfterKey.startsWith(' ') ? null : textAfterKey;
  }

  private clearSuggestionsFilter():void {
    this.suggestionsTarget.innerHTML = '';
    this.suggestionsTarget.classList.add('d-none');
  }

  private filterSuggestions(word:string):void {
    this.clearSuggestionsFilter();
    this.suggestionsTarget.classList.remove('d-none');

    const filtered = this.getFilteredSuggestionsData(word.toLowerCase());

    // insert the HTML
    filtered.forEach((group, idx) => {
      const groupHeader = this.suggestionsHeadingTemplateTarget.content?.cloneNode(true) as HTMLElement;
      if (groupHeader) {
        const headerElement = groupHeader.querySelector('h2');
        if (headerElement) {
          headerElement.innerText = group.key;
        }

        this.suggestionsTarget.appendChild(groupHeader);
      }

      group.values.forEach((suggestion) => {
        const suggestionTemplate = this.suggestionsItemTemplateTarget.content?.cloneNode(true) as HTMLElement;
        const suggestionItem = suggestionTemplate.firstElementChild as HTMLElement;
        if (suggestionTemplate && suggestionItem) {
          suggestionItem.dataset.prop = suggestion.prop;
          this.setSuggestionText(suggestionItem, suggestion.value);
          this.suggestionsTarget.appendChild(suggestionItem);
        }
      });

      const groupDivider = this.suggestionsDividerTemplateTarget.content?.cloneNode(true) as HTMLElement;
      if (idx < filtered.length - 1) {
        this.suggestionsTarget.appendChild(groupDivider);
      }
    });

    if (this.suggestionsTarget.childNodes.length === 0) {
      this.appendInsertAsTextElement(word);
    }
  }

  private appendInsertAsTextElement(word:string):void {
    const template = this.insertAsTextTemplateTarget.content.cloneNode(true) as DocumentFragment;
    const item = template.firstElementChild;
    if (item === null) { return; }

    const textElement = item.querySelector('span');
    if (textElement === null) { return; }

    textElement.innerText = this.insertAsTextTemplateValue.replace('%{word}', word);
    this.suggestionsTarget.appendChild(item);
  }

  private setSuggestionText(suggestionItem:HTMLElement, value:string) {
    const textContainer = suggestionItem.querySelector('span');
    if (textContainer) {
      textContainer.innerText = value;
    } else {
      throw new Error('suggestion template does not have a span to hold the suggestion value');
    }
  }

  private getFilteredSuggestionsData(word:string):FilteredSuggestions {
    return Object.keys(this.suggestionsInitialValue).map((key) => {
      const group = this.suggestionsInitialValue[key];
      return {
        key,
        values: Object.entries(group).filter(([prop, value]) => {
          return value.toLowerCase().includes(word.toLowerCase()) || prop.toLowerCase().includes(word.toLowerCase()) || word === '*';
        }).map(([prop, value]) => ({ prop, value })),
      };
    }).filter((group) => group.values.length > 0);
  }

  private tagInvalidTokens():void {
    this.contentTarget.querySelectorAll('[data-role="token"]').forEach((element:HTMLElement) => {
      const exists = Object.keys(this.validTokenMap).some((key) => key === element.dataset.prop);

      if (exists) {
        element.classList.remove('Label--danger');
      } else {
        element.classList.add('Label--danger');
      }
    });
  }

  private createToken(value:string):TokenElement {
    const templateTarget = this.tokenTemplateTarget.content?.cloneNode(true) as DocumentFragment;
    const contentElement = templateTarget.firstElementChild as TokenElement;
    contentElement.dataset.prop = value;
    contentElement.innerText = this.validTokenMap[value] || value;
    return contentElement;
  }

  private toHtml(blueprint:string):string {
    return blueprint
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/{{([0-9A-Za-z_]+)}}/g, (_, token:string) => this.createToken(token).outerHTML);
  }

  private toBlueprint():string {
    let result = '';
    this.contentTarget.childNodes.forEach((node:ChildNode) => {
      if (this.isText(node)) {
        result += node.textContent;
      } else if (this.isToken(node)) {
        result += `{{${node.dataset.prop}}}`;
      }
    });
    return result.trim();
  }

  private isToken(node:Node):node is TokenElement {
    return this.isElement(node) && node.dataset.role === 'token';
  }

  private isText(node:Node):node is Text {
    return node.nodeType === Node.TEXT_NODE;
  }

  private isElement(node:Node):node is HTMLElement {
    return node.nodeType === Node.ELEMENT_NODE;
  }

  private isWhitespace(value:string):boolean {
    return /\s/.test(value);
  }
}
