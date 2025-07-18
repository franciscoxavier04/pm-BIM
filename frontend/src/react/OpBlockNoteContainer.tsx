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

import {
  BlockNoteSchema,
  defaultBlockSpecs,
  filterSuggestionItems,
  BlockNoteExtensionFactory,
  BlockNoteEditor
} from "@blocknote/core";
import { BlockNoteView } from "@blocknote/mantine";
import {
  FormattingToolbar,
  FormattingToolbarController,
  getDefaultReactSlashMenuItems,
  getFormattingToolbarItems,
  SuggestionMenuController,
  useCreateBlockNote
} from "@blocknote/react";
import {
  dummyBlockSpec,
  getDefaultOpenProjectSlashMenuItems,
  openProjectWorkPackageBlockSpec
} from "op-blocknote-extensions";

import { useEffect, useState } from "react";

import { HocuspocusProvider } from "@hocuspocus/provider";
import * as Y from 'yjs';

import { en } from "@blocknote/core/locales";
import { en as aiEn } from "@blocknote/xl-ai/locales";
import { AIMenuController, AIToolbarButton, createAIExtension, getAISlashMenuItems, } from "@blocknote/xl-ai";
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';

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

const dictionary = {
  ...en,
  ai: aiEn
}


const provider = createOpenAICompatible({
  name: 'haystack-op',
  apiKey: 'DUMMY_KEY',
  baseURL: 'https://haystack.pmflex.one/haystack/v1',
});

const model = provider("mistral:latest");

const extensions:Array<BlockNoteExtensionFactory> = [
  createAIExtension({model}),
]

export default function OpBlockNoteContainer({ inputField,
                                               inputText,
                                               userName,
                                               websocketUrl,
                                               websocketAccessToken,
                                               documentId }: OpBlockNoteContainerProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [theme, setTheme] = useState<"light" | "dark">(detectTheme);

  let collaboration: any;
  let provider: HocuspocusProvider | null = null;
  
  if(websocketUrl != '' && documentId != '' && websocketAccessToken != '' && userName != '') {
    const doc = new Y.Doc()
    provider = new HocuspocusProvider({
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

  // Enable collaboration if all required parameters are provided
  const editor = useCreateBlockNote(collaboration ? {collaboration, schema, dictionary, extensions } : { schema, dictionary, extensions });

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
      // Only load initial content if not using collaboration or if the document is empty
      if (provider && collaboration && collaboration.fragment) {
        // Wait for provider to be connected
        provider.on('synced', async () => {
          // Check if the Y.js document is empty after sync
          const fragment = collaboration.fragment;
          const isEmpty = fragment.length === 0;
          
          if (isEmpty && inputText) {
            // New document - load initial content
            const blocks = await editor.tryParseMarkdownToBlocks(inputText);
            editor.replaceBlocks(editor.document, blocks);
          }
          // For existing documents, the content will be synchronized automatically
          setIsLoading(false);
        });
        
        // Handle connection errors
        provider.on('disconnect', () => {
          console.error('BlockNote collaboration disconnected');
        });
      } else {
        // No collaboration - load content normally
        const blocks = await editor.tryParseMarkdownToBlocks(inputText || "");
        editor.replaceBlocks(editor.document, blocks);
        setIsLoading(false);
      }
    }

    void loadInitialContent();
    
    // Cleanup
    return () => {
      if (provider) {
        provider.destroy();
      }
    };
  }, [editor, collaboration, inputText, provider]);

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
          slashMenu={false}
          formattingToolbar={false}
        >
          <AIMenuController/>
          <FormattingToolbarWithAI/>
          <SuggestionMenuWithAI editor={editor}/>
        </BlockNoteView>
      }
    </>
  );
}

function FormattingToolbarWithAI() {
  return (
    <FormattingToolbarController
      formattingToolbar={() => (
        <FormattingToolbar>
          {...getFormattingToolbarItems()}
          <AIToolbarButton/>
        </FormattingToolbar>
      )}
    />
  );
}

function SuggestionMenuWithAI(props:{
  editor:BlockNoteEditor<any, any, any>;
}) {
  return (
    <SuggestionMenuController
      triggerCharacter="/"
      getItems={async (query) =>
        filterSuggestionItems(
          [
            ...getDefaultReactSlashMenuItems(props.editor),
            ...getDefaultOpenProjectSlashMenuItems(props.editor),
            ...getAISlashMenuItems(props.editor),
          ],
          query,
        )
      }
    />
  );
}
