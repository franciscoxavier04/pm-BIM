import { Component, Input, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { OpInviteUserModalService } from 'core-app/features/invite-user-modal/invite-user-modal.service';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';

@Component({
  selector: 'op-invite-user-button',
  templateUrl: './invite-user-button.component.html',
  styleUrls: ['./invite-user-button.component.sass'],
  standalone: false,
})
export class InviteUserButtonComponent {
  readonly I18n = inject(I18nService);
  readonly opInviteUserModalService = inject(OpInviteUserModalService);
  readonly currentProjectService = inject(CurrentProjectService);
  readonly currentUserService = inject(CurrentUserService);
  readonly autocompleter = inject(OpAutocompleterComponent);

  @Input() projectId:string|null;

  /** This component does not provide an output, because both primary usecases were in places where the button was
   * destroyed before the modal closed, causing the data from the modal to never arrive at the parent.
   * If you want to do something with the output from the modal that is opened, use the OpInviteUserModalService
   * and subscribe to the `close` event there.
   */
  text = {
    button: this.I18n.t('js.invite_user_modal.invite'),
  };

  canInviteUsersToProject$:Observable<boolean>;

  public ngOnInit():void {
    this.projectId = this.projectId || this.currentProjectService.id;
    this.canInviteUsersToProject$ = this
      .currentUserService
      .hasCapabilities$(
        'memberships/create',
        this.projectId || null,
      );
  }

  public onAddNewClick($event:Event):void {
    $event.stopPropagation();
    this.opInviteUserModalService.open(this.projectId);
    this.autocompleter.closeSelect();
  }
}
