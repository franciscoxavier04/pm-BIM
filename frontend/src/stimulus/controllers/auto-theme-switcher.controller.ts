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
import { useMatchMedia } from 'stimulus-use';

export type OpTheme = 'light' | 'dark';

export default class AutoThemeSwitcher extends Controller {
  static values = {
    mode: String,
  };

  declare readonly modeValue:string;

  connect() {
    if (this.modeValue !== 'sync_with_os') return;

    useMatchMedia(this, {
      mediaQueries: {
        lightMode: '(prefers-color-scheme: light)',
      },
    });
  }

  isLightMode():void {
    this.applyTheme('light');
  }

  notLightMode():void {
    this.applyTheme('dark');
  }

  private applyTheme(theme:OpTheme):void {
    const body = document.body;

    switch (theme) {
      case 'dark':
        body.setAttribute('data-color-mode', 'dark');
        body.setAttribute('data-dark-theme', 'dark');
        body.removeAttribute('data-light-theme');
        break;
      case 'light':
        body.setAttribute('data-color-mode', 'light');
        body.setAttribute('data-light-theme', 'light');
        body.removeAttribute('data-dark-theme');
        break;
      default: // Do nothing
        break;
    }
  }
}
