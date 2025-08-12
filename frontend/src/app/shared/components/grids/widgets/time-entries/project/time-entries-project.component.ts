import { ChangeDetectorRef, Component, Injector, OnInit, inject } from '@angular/core';
import { WidgetTimeEntriesListComponent } from 'core-app/shared/components/grids/widgets/time-entries/list/time-entries-list.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { TimeEntryEditService } from 'core-app/shared/components/time_entries/edit/edit.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';

@Component({
  templateUrl: '../list/time-entries-list.component.html',
  providers: [
    HalResourceEditingService,
    TimeEntryEditService,
  ],
  standalone: false,
})
export class WidgetTimeEntriesProjectComponent extends WidgetTimeEntriesListComponent implements OnInit {
  protected readonly currentProject = inject(CurrentProjectService);

  protected dmFilters():Array<[string, FilterOperator, [string]]> {
    return [['spentOn', '>t-', ['7']] as [string, FilterOperator, [string]],
      ['project_id', '=', [this.currentProject.id]] as [string, FilterOperator, [string]]];
  }
}
