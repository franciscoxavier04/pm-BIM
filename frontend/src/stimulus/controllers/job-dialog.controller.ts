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

import { ApplicationController } from 'stimulus-use';
import { renderStreamMessage } from '@hotwired/turbo';
import { HttpErrorResponse } from '@angular/common/http';
import { TurboHelpers } from 'turbo/helpers';

export default class AsyncJobDialogController extends ApplicationController {
    static values = {
        closeDialogId: String,
    };

    declare closeDialogIdValue:string;

    connect() {
        this.element.addEventListener('click', (e) => {
            e.preventDefault();
            TurboHelpers.showProgressBar();
            this.closePreviousDialog();
            this.requestJob().then((job_id) => {
                if (job_id) {
                    return this.showJobModal(job_id);
                }
                return this.handleError('No job ID returned from server.');
            })
                .catch((error:HttpErrorResponse|string) => this.handleError(error))
                .finally(() => {
                    TurboHelpers.hideProgressBar();
                });
        });
    }

    closePreviousDialog() {
      if (!this.closeDialogIdValue) {
        return; // No dialog ID specified, nothing to close
      }
      const dialog = document.getElementById(this.closeDialogIdValue) as HTMLDialogElement;
      if (dialog) {
        dialog.close();
      }
    }

    async requestJob():Promise<string> {
        const response = await fetch(this.href, {
            method: this.method,
            headers: { Accept: 'application/json' },
            credentials: 'same-origin',
        });
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const result = await response.json() as { job_id:string };
        if (!result.job_id) {
            throw new Error('Invalid response from server');
        }
        return result.job_id;
    }

    async showJobModal(job_id:string) {
        const response = await fetch(`/job_statuses/${job_id}/dialog`, {
            method: 'GET',
            headers: { Accept: 'text/vnd.turbo-stream.html' },
        });
        if (response.ok) {
            renderStreamMessage(await response.text());
        } else {
            throw new Error(response.statusText || 'Invalid response from server');
        }
    }

    async handleError(error:HttpErrorResponse|string):Promise<void> {
        void window.OpenProject.getPluginContext().then((pluginContext) => {
            pluginContext.services.notifications.addError(error);
        });
    }

    get href() {
        return (this.element as HTMLLinkElement).href;
    }

    get method() {
        return (this.element as HTMLLinkElement).dataset.jobHrefMethod || 'GET';
    }
}
