import { Injectable } from '@angular/core';
import { renderStreamMessage } from '@hotwired/turbo';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { debugLog } from 'core-app/shared/helpers/debug_output';

@Injectable({ providedIn: 'root' })
export class TurboRequestsService {
  #controllers = new Map<string, AbortController>();

  constructor(
    private toast:ToastService,
  ) {

  }

  public request(
    url:string,
    init:RequestInit = {},
    suppressErrorToast = false,
    requestId?:string,
  ):Promise<{
    html:string,
    headers:Headers
  }> {
    if (requestId) {
      this.abortRequest(requestId);

      const controller = new AbortController();
      this.#controllers.set(requestId, controller);
      init.signal = controller.signal;
    }

    const defaultHeaders = {
      'X-Authentication-Scheme': 'Session',
    };

    init.headers = {
      ...defaultHeaders,
      ...init.headers,
    };

    return fetch(url, init)
      .then((response) => {
        return response.text().then((html) => ({
          html,
          headers: response.headers,
          response,
        }));
      })
      .then((result) => {
        const contentType = result.response.headers.get('Content-Type') || '';
        const isTurboStream = contentType.includes('text/vnd.turbo-stream.html');

        // only render the stream message if we are in a turbo stream response
        if (isTurboStream) {
          renderStreamMessage(result.html);
        }

        if (!result.response.ok) {
          throw new Error(result.response.statusText);
        } else {
          // enable further processing of the html and headers in the calling function
          return { html: result.html, headers: result.headers };
        }
      })
      .catch((error) => {
        if (requestId && error instanceof DOMException && error.name === 'AbortError') {
          debugLog(`Request "${requestId}" was aborted.`);

        // this should only catch errors happening in the client side parsing in the above .then() calls
        } else if (!suppressErrorToast) {
          this.toast.addError(error as string);
        } else {
          console.error(error);
        }

        throw error;
      })
      .finally(() => {
        if (requestId) {
          this.#controllers.delete(requestId);
        }
      });
  }

  public submitForm(
    form:HTMLFormElement,
    params:URLSearchParams|null = null,
    url = form.action,
    requestId?:string,
  ):Promise<{ html:string, headers:Headers }> {
    const formData = new FormData(form);
    const requestParams = params ? `?${params.toString()}` : '';
    const requestUrlWithParams = `${url}${requestParams}`;
    return this.request(
      requestUrlWithParams,
      {
        method: form.method,
        body: formData,
        headers: {
          'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content,
        },
      },
      true,
      requestId || requestUrlWithParams,
    );
  }

  public requestStream(
    url:string,
    requestId = url,
  ):Promise<{ html:string, headers:Headers }> {
    return this.request(
      url,
      {
        method: 'GET',
        headers: {
          Accept: 'text/vnd.turbo-stream.html',
        },
        credentials: 'same-origin',
      },
      false,
      requestId,
    );
  }

  public abortRequest(requestId:string):void {
    const controller = this.#controllers.get(requestId);
    if (controller) {
      controller.abort();
      this.#controllers.delete(requestId);
    }
  }

  public abortAll():void {
    this.#controllers.forEach((controller) => controller.abort());
    this.#controllers.clear();
  }
}
