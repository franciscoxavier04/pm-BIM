/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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

import React from 'react';
import { BlockNoteSchema, defaultBlockSpecs, filterSuggestionItems } from '@blocknote/core';
import { BlockNoteView } from '@blocknote/mantine';
import { getDefaultReactSlashMenuItems, SuggestionMenuController, useCreateBlockNote } from '@blocknote/react';
// import { getDefaultOpenProjectSlashMenuItems, openProjectWorkPackageBlockSpec } from "op-blocknote-extensions";
import { useEffect, useState } from 'react';
import { OpColorMode } from 'core-app/core/setup/globals/theme-utils';

export interface OpBlockNoteContainerProps {
  inputField:HTMLInputElement;
  inputText?:string;
}

const detectTheme = ():OpColorMode => { return window.OpenProject.theme.detectOpColorMode(); };

export default function OpBlockNoteContainer({ inputField, inputText }:OpBlockNoteContainerProps) {
  const [isLoading, setIsLoading] = useState(true);

  const schema = BlockNoteSchema.create({
    blockSpecs: {
      ...defaultBlockSpecs,
      // openProjectWorkPackage: openProjectWorkPackageBlockSpec,
    },
  });

  const editor = useCreateBlockNote({ schema });
  type EditorType = typeof editor;

  const getCustomSlashMenuItems = (editor:EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      // ...getDefaultOpenProjectSlashMenuItems(editor),
    ];
  };

  useEffect(() => {
    async function loadInitialContent() {
      const blocks = await editor.tryParseMarkdownToBlocks(inputText ?? '');
      editor.replaceBlocks(editor.document, blocks);
      setIsLoading(false);
    }
    loadInitialContent().catch((error:unknown) => {
      console.error('Error loading initial content:', error);
      setIsLoading(false);
    });
  }, [editor]);

  return (
    React.createElement(
      React.Fragment,
      null,
      isLoading ? React.createElement('div', null, 'Loading...') : React.createElement(
        BlockNoteView,
        {
          // @ts-expect-error: somehow when using the React.createElement syntax this becomes incompatible types
          editor,
          theme: detectTheme(),
          onChange: (editor) => {
            editor.blocksToMarkdownLossy().then((content) => {
              inputField.value = content;
            }).catch((error:unknown) => {
              console.error('Error converting blocks to markdown:', error);
            });
          },
        },
        React.createElement(SuggestionMenuController, {
          triggerCharacter: '/',
          getItems: async (query) =>
            Promise.resolve(
              filterSuggestionItems(getCustomSlashMenuItems(editor), query)
            ),
        })
      )
    )
  );
}
