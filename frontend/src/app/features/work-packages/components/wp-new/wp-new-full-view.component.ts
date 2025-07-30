//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { WorkPackageCreateComponent } from 'core-app/features/work-packages/components/wp-new/wp-create.component';
import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'wp-new-full-view',
  host: { class: 'work-packages-page--ui-view' },
  templateUrl: './wp-new-full-view.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageNewFullViewComponent extends WorkPackageCreateComponent {
  public successState = this.$state.current.data.successState as string;

  breadcrumbItems() {
    const items = [];
    items.push({
      href: this.pathHelper.homePath(),
      text: this.titleService.appTitle,
    });
    if (this.currentProjectService?.identifier) {
      items.push({
        href: this.pathHelper.projectPath(this.currentProjectService.identifier),
        text: this.currentProjectService.name,
      });
    }
    items.push({
      href: this.pathHelper.workPackagesPath(this.currentProjectService.identifier as string),
      text: this.I18n.t('js.label_work_package_plural'),
    });
    items.push(I18n.t('js.label_create_work_package'));

    return items;
  }
}
