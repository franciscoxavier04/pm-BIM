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

import {
  AfterViewInit,
  ChangeDetectorRef,
  Directive,
  ElementRef,
  EventEmitter,
  Input,
  OnDestroy,
  Output,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';

@Directive({
  selector: '[opModalWithTurboContent]',
})
export class ModalWithTurboContentDirective implements AfterViewInit, OnDestroy {
  @Input() resource:HalResource;
  @Input() change:ResourceChangeset<HalResource>;

  @Output() successfulCreate= new EventEmitter<unknown>();
  @Output() successfulUpdate= new EventEmitter();
  @Output() cancel= new EventEmitter();

  private contextBasedListenerBound = this.contextBasedListener.bind(this);
  private cancelListenerBound = this.cancelListener.bind(this);

  constructor(
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    readonly halEvents:HalEventsService,
    readonly apiV3Service:ApiV3Service,
    readonly toastService:ToastService,
    readonly I18n:I18nService,
  ) {

  }

  ngAfterViewInit() {
    this
      .elementRef
      .nativeElement
      .addEventListener('turbo:submit-end', this.contextBasedListenerBound);

    document
      .addEventListener('cancelModalWithTurboContent', this.cancelListenerBound);
  }

  ngOnDestroy() {
    this
      .elementRef
      .nativeElement
      .removeEventListener('turbo:submit-end', this.contextBasedListenerBound);

    document
      .removeEventListener('cancelModalWithTurboContent', this.cancelListenerBound);
  }

  private contextBasedListener(event:CustomEvent) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    if (this.resource.id === 'new') {
      void this.propagateSuccessfulCreate(event);
    } else {
      this.propagateSuccessfulUpdate(event);
    }
  }

  private cancelListener():void {
    this.cancel.emit();
  }

  private async propagateSuccessfulCreate(event:CustomEvent) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const { fetchResponse } = event.detail;

    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    if (fetchResponse.succeeded) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-assignment,@typescript-eslint/no-unsafe-member-access
      const JSONresponse:unknown = await this.extractJSONFromResponse(fetchResponse.response.body);

      this.successfulCreate.emit(JSONresponse);

      this.change.push();
      this.cdRef.detectChanges();
    }
  }

  private propagateSuccessfulUpdate(event:CustomEvent) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const { fetchResponse } = event.detail;

    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    if (fetchResponse.succeeded) {
      this.halEvents.push(
        this.resource as WorkPackageResource,
        { eventType: 'updated' },
      );

      void this.apiV3Service.work_packages.id(this.resource as WorkPackageResource).refresh();

      this.successfulUpdate.emit();

      this.toastService.addSuccess(this.I18n.t('js.notice_successful_update'));
    }
  }

  private async extractJSONFromResponse(response:ReadableStream) {
    const readStream = await response.getReader().read();

    // eslint-disable-next-line @typescript-eslint/no-unsafe-return
    return JSON.parse(new TextDecoder('utf-8').decode(new Uint8Array(readStream.value as ArrayBufferLike)));
  }
}
