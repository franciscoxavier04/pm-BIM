import { TestBed } from '@angular/core/testing';
import { AttributeHelpTextsService } from './attribute-help-text.service';
import { AttributeHelpTextModalService } from './attribute-help-text-modal.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ToastService } from '../toaster/toast.service';

describe('AttributeHelpTextModalService', () => {
  let fetchSpy:jasmine.Spy<Window['fetch']>;
  let modalService:AttributeHelpTextModalService;
  let dialog:HTMLDialogElement|null;

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

  const makeSuccessResponse = (dialogId:string, dialogContent:string) => {
    const body = `<turbo-stream action="dialog">
        <template>
          <dialog-helper>
            <dialog id="${dialogId}">${dialogContent}</dialog>
          </dialog-helper>
        </template>
      </turbo-stream>`;

    return new Response(body, { status: 200, headers: { 'Content-Type': 'text/vnd.turbo-stream.html' } });
  };

  afterEach(() => {
    dialog?.remove();
    dialog = null;
  });

  describe('with a successful request', () => {
    beforeEach(() => {
      fetchSpy
        .withArgs(jasmine.stringMatching('/1/show_dialog'), jasmine.any(Object))
        .and.resolveTo(makeSuccessResponse('test1', 'Hello Dialog'));
    });

    it('should handle Turbo Stream dialog response and open the dialog', async () => {
      expect(document.querySelector('dialog#test1')).toBeFalsy();

      await expectAsync(modalService.show('1')).toBeResolved();

      expect(fetchSpy).toHaveBeenCalledTimes(1);

      dialog = await waitForNativeElement<HTMLDialogElement>('dialog#test1');

      expect(dialog.textContent).toEqual('Hello Dialog');
      expect(dialog.open).toBeTrue();
      dialog.close();

      expect(dialog.open).toBeFalse();
    });
  });

  describe('with an aborted request followed by a successful request', () => {
    beforeEach(() => {
      fetchSpy
        .withArgs(jasmine.stringMatching('/2/show_dialog'), jasmine.any(Object))
        .and.returnValues(
          Promise.reject(new DOMException('message', 'AbortError')),
          Promise.resolve(makeSuccessResponse('test2', 'Noch mal ein Dialog')),
        );
    });

    it('should handle Turbo Stream dialog response and still open the dialog', async () => {
      expect(document.querySelector('dialog#test2')).toBeFalsy();

      await expectAsync(modalService.show('2')).toBeRejected();
      await expectAsync(modalService.show('2')).toBeResolved();

      expect(fetchSpy).toHaveBeenCalledTimes(2);

      dialog = await waitForNativeElement<HTMLDialogElement>('dialog#test2');

      expect(dialog.textContent).toEqual('Noch mal ein Dialog');
      expect(dialog.open).toBeTrue();
      dialog.close();

      expect(dialog.open).toBeFalse();
    });
  });

  describe('with 3 successful requests with the same dialog id', () => {
    beforeEach(() => {
      fetchSpy
        .withArgs(jasmine.stringMatching('/3/show_dialog'), jasmine.any(Object))
        .and.returnValues(
          Promise.resolve(makeSuccessResponse('test3', '<p>initial content</p>')),
          Promise.resolve(makeSuccessResponse('test3', '<p>updated content</p>')),
          Promise.resolve(makeSuccessResponse('test3', '<h3>new headline</h3>')),
        );
    });

    it('should handle Turbo Stream dialog response and update dialog', async () => {
      expect(document.querySelector('dialog#test3')).toBeFalsy();

      await expectAsync(modalService.show('3')).toBeResolved();

      expect(fetchSpy).toHaveBeenCalledTimes(1);

      dialog = await waitForNativeElement<HTMLDialogElement>('dialog#test3');

      expect(dialog.textContent).toEqual('initial content');
      expect(dialog.open).toBeTrue();

      await expectAsync(modalService.show('3')).toBeResolved();

      expect(fetchSpy).toHaveBeenCalledTimes(2);

      let mutation = await waitForElementMutation(dialog);

      expect(mutation.type).toEqual('characterData');
      expect(dialog.textContent).toEqual('updated content');
      expect(dialog.open).toBeTrue();

      await expectAsync(modalService.show('3')).toBeResolved();

      expect(fetchSpy).toHaveBeenCalledTimes(3);

      mutation = await waitForElementMutation(dialog);

      expect(mutation.type).toEqual('childList');
      expect(dialog.textContent).toEqual('new headline');
      expect(dialog.querySelector('h3')).toBeTruthy();
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

function waitForElementMutation<T extends Element>(
  element:T,
  predicate:(mutation:MutationRecord) => boolean = () => true,
):Promise<MutationRecord> {
  return new Promise((resolve) => {
    const observer = new MutationObserver((mutationList) => {
      const record = mutationList.find(predicate);
      if (record) {
        observer.disconnect();
        resolve(record);
      }
    });
    observer.observe(element, { childList: true, subtree: true, characterData: true });
  });
}
