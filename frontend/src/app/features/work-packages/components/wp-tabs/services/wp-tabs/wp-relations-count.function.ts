import { Injector } from '@angular/core';
import { Observable, combineLatest, from, Subject } from 'rxjs';
import { map, switchMap, startWith } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';

export function workPackageRelationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const pathHelper = injector.get(PathHelperService);
  const turboRequests = injector.get(TurboRequestsService);
  const wpRelations = injector.get(WorkPackageRelationsService);
  const wpId = workPackage.id!.toString();

  const url = pathHelper.workPackageGetRelationsCounterPath(wpId.toString());
  const updateTrigger$ = new Subject<void>();

  // Listen for relation state changes
  const relationsState$ = wpRelations.state(wpId).values$().pipe(startWith(null));

  // Trigger Turbo request whenever the state changes or manually triggered
  return combineLatest([relationsState$, updateTrigger$.pipe(startWith(null))]).pipe(
    switchMap(() => from(turboRequests.request(url))),
    map((response) => parseInt(response.html, 10)),
  );
}
