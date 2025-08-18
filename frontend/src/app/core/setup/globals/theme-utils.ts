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

export type OpColorMode = 'light' | 'dark';

export type OpTheme = OpColorMode | `${OpColorMode}_high_contrast`;

export class ThemeUtils {
  public applySystemThemeImmediately():void {
    const colorMode = this.detectSystemColorMode();
    this.applyThemeToBody(colorMode);
  }

  public detectOpColorMode():OpColorMode {
    return document.body.getAttribute('data-color-mode') as OpColorMode;
  }

  public detectSystemColorMode():OpColorMode {
    return this.prefersSystemLightMode() ? 'light' : 'dark';
  }

  public prefersSystemLightHighContrast():boolean {
    return this.prefersSystemLightMode() && this.prefersSystemHighContrast();
  }

  public prefersSystemLightMode():boolean {
    return window.matchMedia('(prefers-color-scheme: light)').matches;
  }

  public prefersSystemHighContrast():boolean {
    return window.matchMedia('(prefers-contrast: more)').matches;
  }

  public applyThemeToBody(colorMode:OpColorMode):void {
    const body = document.body;
    const increaseContrast = this.prefersSystemHighContrast();
    const otherColorMode = (colorMode === 'light' ? 'dark' : 'light');

    body.setAttribute('data-color-mode', colorMode);
    body.setAttribute(`data-${colorMode}-theme`, increaseContrast ? `${colorMode}_high_contrast` : colorMode);
    body.removeAttribute(`data-${otherColorMode}-theme`);
  }
}
