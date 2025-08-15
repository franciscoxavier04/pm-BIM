import { environment } from '../environments/environment';
import { OpApplicationController } from './controllers/op-application.controller';
import MainMenuController from './controllers/dynamic/menus/main.controller';
import OpDisableWhenCheckedController from './controllers/disable-when-checked.controller';
import PrintController from './controllers/print.controller';
import RefreshOnFormChangesController from './controllers/refresh-on-form-changes.controller';
import FormPreviewController from './controllers/form-preview.controller';
import AsyncDialogController from './controllers/async-dialog.controller';
import PollForChangesController from './controllers/poll-for-changes.controller';
import TableHighlightingController from './controllers/table-highlighting.controller';
import OpShowWhenCheckedController from './controllers/show-when-checked.controller';
import OpShowWhenValueSelectedController from './controllers/show-when-value-selected.controller';
import FlashController from './controllers/flash.controller';
import OpProjectsZenModeController from './controllers/dynamic/projects/zen-mode.controller';
import PasswordConfirmationDialogController from './controllers/password-confirmation-dialog.controller';
import PreviewController from './controllers/dynamic/work-packages/date-picker/preview.controller';
import KeepScrollPositionController from './controllers/keep-scroll-position.controller';
import PatternInputController from './controllers/pattern-input.controller';
import HoverCardTriggerController from './controllers/hover-card-trigger.controller';
import ScrollIntoViewController from './controllers/scroll-into-view.controller';
import CkeditorFocusController from './controllers/ckeditor-focus.controller';
import IndexController from './controllers/dynamic/work-packages/activities-tab/index.controller';
import AutoScrollingController from './controllers/dynamic/work-packages/activities-tab/auto-scrolling.controller';
import PollingController from './controllers/dynamic/work-packages/activities-tab/polling.controller';
import StemsController from './controllers/dynamic/work-packages/activities-tab/stems.controller';
import EditorController from './controllers/dynamic/work-packages/activities-tab/editor.controller';

import AutoSubmit from '@stimulus-components/auto-submit';
import AutoThemeSwitcher from './controllers/auto-theme-switcher.controller';
import { OpenProjectStimulusApplication } from 'core-stimulus/openproject-stimulus-application';
import { Application } from '@hotwired/stimulus';
import { BeforeunloadController } from './controllers/beforeunload.controller';
import DisableWhenClickedController from 'core-stimulus/controllers/disable-when-clicked.controller';

declare global {
  interface Window {
    Stimulus:Application;
  }
}

OpenProjectStimulusApplication.preregister('application', OpApplicationController);
OpenProjectStimulusApplication.preregister('async-dialog', AsyncDialogController);
OpenProjectStimulusApplication.preregister('disable-when-checked', OpDisableWhenCheckedController);
OpenProjectStimulusApplication.preregister('disable-when-clicked', DisableWhenClickedController);
OpenProjectStimulusApplication.preregister('flash', FlashController);
OpenProjectStimulusApplication.preregister('menus--main', MainMenuController);
OpenProjectStimulusApplication.preregister('password-confirmation-dialog', PasswordConfirmationDialogController);
OpenProjectStimulusApplication.preregister('poll-for-changes', PollForChangesController);
OpenProjectStimulusApplication.preregister('print', PrintController);
OpenProjectStimulusApplication.preregister('refresh-on-form-changes', RefreshOnFormChangesController);
OpenProjectStimulusApplication.preregister('form-preview', FormPreviewController);
OpenProjectStimulusApplication.preregister('hover-card-trigger', HoverCardTriggerController);
OpenProjectStimulusApplication.preregister('show-when-checked', OpShowWhenCheckedController);
OpenProjectStimulusApplication.preregister('show-when-value-selected', OpShowWhenValueSelectedController);
OpenProjectStimulusApplication.preregister('table-highlighting', TableHighlightingController);
OpenProjectStimulusApplication.preregister('projects-zen-mode', OpProjectsZenModeController);
OpenProjectStimulusApplication.preregister('work-packages--date-picker--preview', PreviewController);
OpenProjectStimulusApplication.preregister('keep-scroll-position', KeepScrollPositionController);
OpenProjectStimulusApplication.preregister('pattern-input', PatternInputController);
OpenProjectStimulusApplication.preregister('scroll-into-view', ScrollIntoViewController);
OpenProjectStimulusApplication.preregister('ckeditor-focus', CkeditorFocusController);
OpenProjectStimulusApplication.preregister('auto-submit', AutoSubmit);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--index', IndexController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--auto-scrolling', AutoScrollingController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--polling', PollingController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--stems', StemsController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--editor', EditorController);
OpenProjectStimulusApplication.preregister('beforeunload', BeforeunloadController);
OpenProjectStimulusApplication.preregister('auto-theme-switcher', AutoThemeSwitcher);

const instance = OpenProjectStimulusApplication.start();
window.Stimulus = instance;

instance.debug = !environment.production;
instance.handleError = (error, message, detail) => {
  console.warn(error, message, detail);
};
