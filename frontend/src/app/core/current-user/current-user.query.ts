import { Injectable, inject } from '@angular/core';
import { Query } from '@datorama/akita';
import { CurrentUserState, CurrentUserStore } from './current-user.store';

@Injectable()
export class CurrentUserQuery extends Query<CurrentUserState> {
  protected store = inject(CurrentUserStore);

  isLoggedIn$ = this.select((state) => !!state.loggedIn);

  user$ = this.select((user) => user);
}
