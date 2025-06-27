/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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
import React from 'react';
import { createRoot, Root } from 'react-dom/client';
import OpBlockNoteContainer from 'react/OpBlockNoteContainer';

const styles = require('css-loader!../../node_modules/@blocknote/mantine/dist/style.css');

class BlockNoteElement extends HTMLElement {
  static observedAttributes = ['value'];

  private container:HTMLDivElement;
  private reactRoot:Root|null = null;

  private hiddenField:HTMLInputElement;

  constructor() {
    super();
    const shadowRoot = this.attachShadow({ mode: 'open' });
    this.container = document.createElement('div');
    shadowRoot.appendChild(this.container);
    const hiddenFieldSlot = document.createElement('slot');
    hiddenFieldSlot.name = 'hidden-field';
    shadowRoot.appendChild(hiddenFieldSlot);
    const style = document.createElement('style');
    style.textContent = styles;
    shadowRoot.appendChild(style);
  }

  get value():string {
    return this.getAttribute('value') || '';
  }

  set value(value) {
    this.setAttribute('value', value);
  }

  connectedCallback() {
    this.hiddenField = this.shadowRoot!.querySelector('input[type="hidden"][slot="hidden-field"')!;
    this.reactRoot = createRoot(this.container);
    this.reactRender();
  }

  disconnectedCallback() {
    this.reactRoot?.unmount();
  }

  reactRender() {
    this.reactRoot!.render(React.createElement(OpBlockNoteContainer, {
      inputField: this.hiddenField,
      inputText: this.value
    }));
  }

  attributeChangedCallback(name: string, oldValue: string|null, newValue: string|null) {
    if (oldValue !== newValue) {
      this.reactRender();
    }
  }
}

customElements.define('block-note', BlockNoteElement);
