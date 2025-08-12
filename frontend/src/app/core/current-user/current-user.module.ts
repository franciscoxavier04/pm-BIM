import { Injector, NgModule, inject } from '@angular/core';

import { CurrentUserService } from './current-user.service';
import { CurrentUserStore } from './current-user.store';
import { CurrentUserQuery } from './current-user.query';
import { firstValueFrom } from 'rxjs';

function loadUserMetadata(currentUserService:CurrentUserService) {
  const userMeta = document.querySelector<HTMLMetaElement>('meta[name=current_user]');
  currentUserService.setUser({
    id: userMeta?.dataset.id || null,
    name: userMeta?.dataset.name || null,
    loggedIn: userMeta?.dataset.loggedIn === 'true',
  });
}

export function bootstrapModule(injector:Injector):void {
  const currentUserService = injector.get(CurrentUserService);

  window.ErrorReporter
    .addHook(
      () => firstValueFrom(currentUserService.user$)
        .then(({ id }) => ({ user: id || 'anon' })),
    );

  loadUserMetadata(currentUserService);
  document.addEventListener('turbo:load', () => loadUserMetadata(currentUserService));
}

@NgModule({
  providers: [
    CurrentUserService,
    CurrentUserStore,
    CurrentUserQuery,
  ],
})
export class CurrentUserModule {
  constructor() {
    const injector = inject(Injector);

    bootstrapModule(injector);
  }
}
