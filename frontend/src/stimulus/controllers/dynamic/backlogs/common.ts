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

// @ts-expect-error TS(2339): Property 'RB' does not exist on type 'Window & typ... Remove this comment to see the full error message
if (window.RB === null || window.RB === undefined) {
  // @ts-expect-error TS(2339): Property 'RB' does not exist on type 'Window & typ... Remove this comment to see the full error message
  window.RB = {};
}

interface SaveDirectives {
  url:string;
  data:string;
}

interface Editable {
  $:JQuery<HTMLElement>;
  displayEditor(editor:JQuery<HTMLElement>):void;
  getEditor():JQuery<HTMLElement>;
}

// Utilities
class Dialog {
  msg(msg:any) {
    let dialog;
    let baseClasses;

    baseClasses = 'ui-button ui-widget ui-state-default ui-corner-all';

    if ($('#msgBox').length === 0) {
      dialog = $('<div id="msgBox"></div>').appendTo('body');
    } else {
      dialog = $('#msgBox');
    }

    dialog.html(msg);
    dialog.dialog({
      title: 'Backlogs Plugin',
      buttons: [
        {
          text: 'OK',
          class: 'button -primary',
          click() {
            $(this).dialog('close');
          },
        }],
      modal: true,
    });
    $('.button').removeClass(baseClasses);
    $('.ui-icon-closethick').prop('title', 'close');
  }
}

function ajax() {
  let ajaxQueue:any;
  let ajaxOngoing:any;
  let processAjaxQueue:any;

  ajaxQueue = [];
  ajaxOngoing = false;

  processAjaxQueue = function () {
    const options = ajaxQueue.shift();

    if (options !== null && options !== undefined) {
      ajaxOngoing = true;
      $.ajax(options);
    }
  };

  // Process outstanding entries in the ajax queue whenever a ajax request
  // finishes.
  $(document).ajaxComplete((event, xhr, settings) => {
    ajaxOngoing = false;
    processAjaxQueue();
  });

  return function (options:any) {
    ajaxQueue.push(options);
    if (!ajaxOngoing) {
      processAjaxQueue();
    }
  };
}

// Abstract the user preference from the rest of the RB objects
// so that we can change the underlying implementation as needed
class UserPreferences {
  get(key:string) {
    return $.cookie(key);
  }

  set(key:string, value:any) {
    $.cookie(key, value, { expires: 365 * 10 });
  }
}

// @ts-expect-error TS(2304): Cannot find name 'RB'.
RB.Dialog = Dialog;
// @ts-expect-error TS(2304): Cannot find name 'RB'.
RB.UserPreferences = UserPreferences;
// @ts-expect-error TS(2304): Cannot find name 'RB'.
RB.ajax = ajax;
