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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Attachable } from 'core-app/features/hal/resources/mixins/attachable-mixin';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { AttachmentCollectionResource } from './attachment-collection-resource';

interface ActivityCommentResourceEmbedded {
  attachments:AttachmentCollectionResource;
  workPackage:WorkPackageResource;
}

interface ActivityCommentResourceLinks extends ActivityCommentResourceEmbedded {
  addAttachment(attachment:HalResource):Promise<unknown>;
}

class ActivityCommentBaseResource extends HalResource {
  public $embedded:ActivityCommentResourceEmbedded;
  public $links:ActivityCommentResourceLinks;
}

export const ActivityCommentResource = Attachable(ActivityCommentBaseResource);

// eslint-disable-next-line @typescript-eslint/no-redeclare
export interface ActivityCommentResource extends ActivityCommentBaseResource, ActivityCommentResourceLinks {}
