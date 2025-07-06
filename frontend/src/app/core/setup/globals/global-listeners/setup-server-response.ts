// Legacy code ported from app/assets/javascripts/application.js.erb

import { delegateEvent } from "core-app/shared/helpers/delegate-event";

// Do not add stuff here, but ideally remove into components whenever changes are necessary
export function setupServerResponse() {
  // show/hide the files table
  document.querySelectorAll('.attachments h4').forEach((heading) => {
    heading.addEventListener('click', () => {
      heading.classList.toggle('closed'); //FIXME .next().slideToggle(100);
    })
  });

  let resizeTo:any = null;
  window.addEventListener('resize', () => {
    // wait 200 milliseconds for no further resize event
    // then readjust breadcrumb

    if (resizeTo) {
      clearTimeout(resizeTo);
    }
    resizeTo = setTimeout(() => {
      window.dispatchEvent(new CustomEvent('resizeEnd')); // FIXME
    }, 200);
  });

  // Do not close the login window when using it
  document.querySelector('#nav-login-content')?.addEventListener('click', (event) => {
    event.stopPropagation();
  });

  // Set focus on first error message
  const error_focus = document.querySelector<HTMLAnchorElement>('a.afocus');
  const input_focus = document.querySelector<HTMLElement>('.autofocus');
  if (error_focus) {
    error_focus.focus();
  } else if (input_focus) {
    input_focus.focus();
    if (input_focus instanceof HTMLInputElement) {
      input_focus.select();
    }
  }
  // Focus on field with error
  addClickEventToAllErrorMessages();

  // Click handler for formatting help
  delegateEvent('click', '.formatting-help-link-button', () => {
    window.open(`${window.appBasePath}/help/wiki_syntax`,
      '',
      'resizable=yes, location=no, width=600, height=640, menubar=no, status=no, scrollbars=yes');
    return false;
  }, document.body);
}

function addClickEventToAllErrorMessages() {
  document.querySelectorAll('a.afocus').forEach((target) => {
    target.addEventListener('click', (evt) => {
      let field = document.querySelector(`#${target.getAttribute('href')!.substr(1)}`);
      if (field === null) {
        // Cut off '_id' (necessary for select boxes)
        field = document.querySelector(`#${target.getAttribute('href')!.substr(1).concat('_id')}`);
      }
      return false;
    }, {once: true});
  });
}

export function initMainMenuExpandStatus() {
  const wrapper = document.querySelector('#wrapper');
  const upToggle = document.querySelector<HTMLAnchorElement>('ul.menu_root.closed li.open a.arrow-left-to-project');

  if (upToggle && wrapper?.classList.contains('hidden-navigation')) {
    upToggle.click();
  }
}

function activateFlash(selector:string) {
  const flashMessages = document.querySelectorAll<HTMLElement>(selector);

  flashMessages.forEach((flashMessage) => {
    flashMessage.style.display = "block";
  });
}

export function activateFlashNotice() {
  activateFlash('.op-toast[role="alert"]');
}

export function activateFlashError() {
  activateFlash('.errorExplanation[role="alert"]');
}

export function focusFirstErroneousField() {
  const firstErrorSpan = document.querySelector('span.errorSpan')!;
  const erroneousInput = firstErrorSpan.querySelector<HTMLElement>(':input');

  erroneousInput?.focus();
}
