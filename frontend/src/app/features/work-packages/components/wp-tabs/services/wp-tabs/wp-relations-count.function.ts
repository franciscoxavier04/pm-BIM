import { Injector } from '@angular/core';
import { Observable, from } from 'rxjs';
import { map } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export function workPackageRelationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const PathHelper = injector.get(PathHelperService);
  const turboRequests= injector.get(TurboRequestsService);
  const wpId = workPackage.id!.toString();

  const url = PathHelper.workPackageGetCounterPath(wpId.toString());
  const turbo= turboRequests.request(url);
  const observable = from(turbo);
  return observable.pipe(
    map((response) => {
      return parseInt(response.html, 10);
    }),
  );
}
