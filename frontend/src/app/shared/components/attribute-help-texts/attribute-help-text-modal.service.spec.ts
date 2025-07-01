import { TestBed } from '@angular/core/testing';
import { AttributeHelpTextsService } from './attribute-help-text.service';
import { AttributeHelpTextModalService } from './attribute-help-text-modal.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ToastService } from '../toaster/toast.service';

describe('AttributeHelpTextModalService', () => {
  let fetchSpy:jasmine.Spy<Window['fetch']>;
  let modalService:AttributeHelpTextModalService;
  let response:Response;

  beforeEach(() => {
    fetchSpy = spyOn(window, 'fetch');
  });

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [],
      providers: [
        { provide: ToastService, useValue: {} },
        { provide: AttributeHelpTextsService, useValue: {} },
        PathHelperService,
        TurboRequestsService,
      ],
    }).compileComponents();

    modalService = TestBed.inject(AttributeHelpTextModalService);
  });

  it('should be created', () => {
    expect(modalService).toBeTruthy();
  });

  describe('with a successful request', () => {
    beforeEach(() => {
      response = new Response(`
        <turbo-stream action="dialog" target="">
          <template>
            <dialog>Hello Dialog</dialog>
          </template>
        </turbo-stream>`,
        {
          status: 200,
          headers: { 'Content-Type': 'text/vnd.turbo-stream.html' }
        }
      );
      fetchSpy.and.resolveTo(response);
    });

    it('should make a request and handle Turbo Stream dialog response', async () => {
      expect(document.querySelector('dialog')).toBeFalsy();

      modalService.show('1');

      expect(fetchSpy).toHaveBeenCalledTimes(1);

      const dialog = await waitForNativeElement<HTMLDialogElement>('dialog');

      expect(dialog.textContent).toEqual('Hello Dialog');
      expect(dialog.open).toBeTrue();
      dialog.close();

      expect(dialog.open).toBeFalse();
    });
  });
});

function waitForNativeElement<T extends Element>(selector:string):Promise<T> {
  let element = document.querySelector<T>(selector);
  if (element) {
    return Promise.resolve(element);
  }

  return new Promise<T>((resolve) => {
    const observer = new MutationObserver(() => {
      element = document.querySelector<T>(selector);
      if (element) {
        observer.disconnect();
        resolve(element);
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });
  });
}
