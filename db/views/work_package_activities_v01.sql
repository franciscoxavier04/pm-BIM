-- copyright
-- OpenProject is an open source project management software.
-- Copyright (C) the OpenProject GmbH
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License version 3.
--
-- OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
-- Copyright (C) 2006-2013 Jean-Philippe Lang
-- Copyright (C) 2010-2013 the ChiliProject Team
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
--
-- See COPYRIGHT and LICENSE files for more details.

-- Historical Journals including comments from Journal#notes (before migration to Comment model)
SELECT
  j.id,
  j.journable_id as work_package_id,
  j.created_at,
  j.user_id,
  j.notes as comments,
  j.version,
  'Journal' as kind,
  j.restricted as internal
FROM journals j
WHERE j.journable_type = 'WorkPackage'
  AND j.journable_id IS NOT NULL

UNION ALL

-- New comments from Comment model (after migration)
SELECT
  c.id,
  c.commented_id as work_package_id,
  c.created_at,
  c.author_id as user_id,
  c.comments,
  NULL as version,
  'Comment' as kind,
  c.internal
FROM comments c
WHERE c.commented_type = 'WorkPackage'
  AND c.commented_id IS NOT NULL

UNION ALL

-- Revisions (Changesets)
SELECT
  cs.id,
  cwp.work_package_id,
  cs.committed_on as created_at,
  cs.user_id,
  cs.comments,
  NULL as version,
  'Revision' as kind,
  false as internal
FROM changesets cs
INNER JOIN changesets_work_packages cwp ON cs.id = cwp.changeset_id
WHERE cwp.work_package_id IS NOT NULL

ORDER BY created_at DESC, id DESC;
