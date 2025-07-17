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

import { BlockNoteSchema, defaultBlockSpecs, filterSuggestionItems } from "@blocknote/core";
import { BlockNoteView } from "@blocknote/mantine";
import { getDefaultReactSlashMenuItems, SuggestionMenuController, useCreateBlockNote } from "@blocknote/react";
import { dummyBlockSpec, getDefaultOpenProjectSlashMenuItems, openProjectWorkPackageBlockSpec } from "op-blocknote-extensions";
import { useEffect, useState } from "react";
import { HocuspocusProvider } from "@hocuspocus/provider";
import * as Y from 'yjs';

export interface OpBlockNoteContainerProps {
  inputField: HTMLInputElement;
  inputText?: string;
  websocketUrl: string;
  websocketAccessToken: string;
  userName: string;
  documentId: string;
}

const schema = BlockNoteSchema.create({
  blockSpecs: {
    ...defaultBlockSpecs,
    openProjectWorkPackage: openProjectWorkPackageBlockSpec,
    dummy: dummyBlockSpec,
  },
});

const detectTheme = (): "light" | "dark" => {
  if (document.body.getAttribute('data-color-mode') === 'dark') {
    return 'dark';
  }
  return 'light';
};

export default function OpBlockNoteContainer({ inputField,
                                               inputText,
                                               userName,
                                               websocketUrl,
                                               websocketAccessToken,
                                               documentId }: OpBlockNoteContainerProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [theme, setTheme] = useState<"light" | "dark">(detectTheme);

  let collaboration: any;
  if(websocketUrl != '' && documentId != '' && websocketAccessToken != '' && userName != '') {
    const doc = new Y.Doc()
    const provider = new HocuspocusProvider({
      url: websocketUrl,
      name: documentId,
      token: websocketAccessToken,
      document: doc
    });
    const cursorColor = '#' + Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0');
    collaboration = {
      provider,
      fragment: doc.getXmlFragment("document-store"),
      user: {
        name: userName,
        color: cursorColor,
      },
      showCursorLabels: "activity"
    }
  }
  const editor = useCreateBlockNote({collaboration, schema });
  type EditorType = typeof editor;

  const getCustomSlashMenuItems = (editor: EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      ...getDefaultOpenProjectSlashMenuItems(editor),
    ];
  };

  useEffect(() => {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' &&
            (mutation.attributeName === 'data-color-mode' ||
             mutation.attributeName === 'data-light-theme' ||
             mutation.attributeName === 'data-dark-theme')) {
          setTheme(detectTheme());
        }
      });
    });

    observer.observe(document.body, {
      attributes: true,
      attributeFilter: ['data-color-mode', 'data-light-theme', 'data-dark-theme']
    });

    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    async function loadInitialContent() {
      const blocks = await editor.tryParseMarkdownToBlocks(inputText || "");
      editor.replaceBlocks(editor.document, blocks);
      setIsLoading(false);
    }
    loadInitialContent();
  }, [editor]);

  return (
    <>
      {isLoading ? <div>Loading...</div>
        :
        <BlockNoteView
          editor={editor}
          theme={theme}
          onChange={async (editor) => {
            const content = await editor.blocksToMarkdownLossy();
            inputField.value = content;
          }}
        >
          <SuggestionMenuController
            triggerCharacter="/"
            getItems={async (query: string) => filterSuggestionItems(getCustomSlashMenuItems(editor), query)}
          />
        </BlockNoteView>
      }
    </>
  );
}
