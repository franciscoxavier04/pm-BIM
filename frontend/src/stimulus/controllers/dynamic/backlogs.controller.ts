import { Controller } from '@hotwired/stimulus';

import 'core-vendor/jquery.flot/jquery.flot';
import 'core-vendor/jquery.flot/excanvas';
import 'core-vendor/jquery.jeditable.mini';
import 'core-vendor/jquery.cookie';
import 'core-vendor/jquery.colorcontrast';

import './backlogs/common';
import './backlogs/master_backlog';
import './backlogs/backlog';
import './backlogs/burndown';
import './backlogs/model';
import './backlogs/editable_inplace';
import './backlogs/sprint';
import './backlogs/work_package';
import './backlogs/story';
import './backlogs/task';
import './backlogs/impediment';
import './backlogs/taskboard';
import './backlogs/show_main';

export default class BacklogsController extends Controller {
}
