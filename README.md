# HelpChatAI for Delphi

[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/EtheaDev/Delphi-HelpChatAI?label=release&color=blue)](https://github.com/EtheaDev/Delphi-HelpChatAI/releases)
[![Delphi 10.4+](https://img.shields.io/badge/Delphi-10.4%2B-e62329.svg)](https://www.embarcadero.com/products/delphi)
[![Platform: VCL and FMX](https://img.shields.io/badge/Platform-VCL%20%7C%20FMX-8a2be2.svg)](https://docwiki.embarcadero.com/RADStudio/en/Main_Page)
[![Microsoft Edge WebView2](https://img.shields.io/badge/WebView2-Edge-0078d4.svg)](https://developer.microsoft.com/microsoft-edge/webview2/)
[![Windows 10 and 11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078d6.svg)](https://www.microsoft.com/windows)

![Delphi Support](./Images/SupportingDelphi.jpg)

Related links: https://www.embarcadero.com/ - https://learndelphi.org/

---

## An in-app AI help assistant for your VCL and FireMonkey applications

Your users do not read the manual: they ask. HelpChatAI puts a chat bubble in the corner of
your application, answers *"how do I export this grid?"* from **your own documentation**, and
knows which screen the user is on while answering. **F1 opens it**, through the standard Delphi
help system, so the `HelpKeyword` you already wrote keeps working.

| Component | Description |
| - | - |
| ![TVclHelpChatAI](./Images/delphi-helpchat_64.png) | **TVclHelpChatAI** is the VCL component: drop it on the main form, set `Active`, and you have the bubble, F1 contextual help and the chat panel (a WebView2 `TEdgeBrowser`), either in its own tool window or embedded in a container of yours. Colours follow the active VCL style |
| ![TFmxHelpChatAI](./Images/AIAssistant_Female_64.png) | **TFmxHelpChatAI** is the FireMonkey twin (Delphi 12+): same settings, same engine, the chat in a `TWebBrowser`. F1 through the host form's `OnKeyDown`, light/dark theme instead of VCL styles. Available only for Delphi 12 and 13 |

### How it works

1. You build a **documentation index** (`help-index.json`) from the Markdown pages of your
   manual, with the `HelpIndexBuilder` tool.
2. The user asks. The component adds the **screen context** — the active form, its caption, the
   `HelpKeyword`/`HelpContext` of the focused control, the active tab.
3. A **provider** answers. `docsearch` finds the right page offline and quotes it, with no API
   key at all; `claude`, `openai` and `gemini` read the pages the retriever found and answer
   *from those*, citing the source and saying when they do not know.
4. The reply **streams** into the panel token by token, rendered as safe HTML. Nothing ever
   runs on the UI thread, and the user can stop it.
5. If you let it, the assistant can also **act**: you register the actions your application
   allows, and it calls them on the main thread, asking the user first when they change data.
6. And it can **read a document the user hands it**: a paper clip next to the question box
   takes a PDF, an image or a text file. Together with an action, that is a PDF filling a
   form without anybody retyping it. Off until you turn it on, because an attachment leaves
   the machine.
7. What it answered does not stay in the panel. Every answer, the whole conversation and
   every page of the manual can be **copied** — as text and as HTML, so a table pasted into
   Word is still a table — or **saved as a PDF**, laid out by a stylesheet of yours and
   headed with the name of your application, the user and the page number.

The engine knows nothing about the UI: it runs inside your application or on a **HelpChatAI
server**, chosen in a configuration file, so the model API key never has to reach the user's
machine. When it has to, `OnDecryptSecret` lets you keep it encrypted in the configuration
and decrypt it the way your application sees fit.

### Providers

| `Provider` | Needs | Streams | Actions |
|---|---|---|---|
| `docsearch` | the documentation index, no key | no | no |
| `claude` | `ANTHROPIC_API_KEY` | yes | yes |
| `openai` | `OPENAI_API_KEY`, nothing for a local model | yes | yes |
| `gemini` | `GEMINI_API_KEY` | yes | yes |

`openai` is wider than its name: Chat Completions is the API that Azure OpenAI, Groq,
OpenRouter, Mistral, DeepSeek, Ollama and LM Studio also speak, so `BaseUrl` and `Model` are
enough to point the same provider at any of them — including a model running on the user's own
machine, where nothing leaves the PC.

## Setup for automatic installation of components

An "Installer" ready to use is located in the Release area:
[Download the Installer](https://github.com/EtheaDev/Delphi-HelpChatAI/releases/latest/download/HelpChatAI_Setup.exe).

The Installer automatically detects your Delphi versions, installs sources, builds and installs
packages and adds source paths.

![Setup](./Images/Setup.png)

To do it by hand instead:
- open the group project of your version under `packages/` — `Delphi13`,
`Delphi12`, `Delphi11` or `Delphi10.4` 
- build it and install `dclHelpChatAIVcl` (and
`dclHelpChatAIFmx`, then add `source` and `Ext/MarkdownProcessor/source` to the library path.

`Tools/Build_Packages.cmd [Delphi13|Delphi12|Delphi11|Delphi10.4|all]` builds them from a
command line.

Ship `WebView2Loader.dll` (`Redist/WebView2/x86|x64`) next to your executable; the WebView2
runtime itself is already part of Windows 11 and of every machine with Edge.

## Documentation

Follow the [Project Site](https://ethea.it/docs/helpchatai/) to learn how to add an AI help
assistant to your Delphi application, and how to make its answers good.

| Page | What you find |
|---|---|
| [Quick Start](https://ethea.it/docs/helpchatai/Quick-Start) | From an empty form to a working chat |
| [The VCL component](https://ethea.it/docs/helpchatai/VCL-Component) | Bubble, F1, embedding, dictation, the design-time preview |
| [The FMX component](https://ethea.it/docs/helpchatai/FMX-Component) | What FireMonkey does differently |
| [Providers](https://ethea.it/docs/helpchatai/Providers) | The five of them, their settings, writing your own |
| [The documentation index](https://ethea.it/docs/helpchatai/Documentation-Index) | Building `help-index.json`, and the pages shown inside the panel |
| [Actions](https://ethea.it/docs/helpchatai/Actions) | An assistant that does things, safely |
| [Attaching documents](https://ethea.it/docs/helpchatai/Attachments) | Handing the assistant a PDF, an image or a text file |
| [Saving and copying](https://ethea.it/docs/helpchatai/Saving-and-Copying) | The PDF of an answer, its header and footer, and the clipboard |
| [Running the engine on a server](https://ethea.it/docs/helpchatai/Server) | When the API key must not be on the user's machine |
| [Configuration](https://ethea.it/docs/helpchatai/Configuration) | `helpchatai.json`, and checking a configuration |
| [Security and privacy](https://ethea.it/docs/helpchatai/Security-and-Privacy) | What travels, where, and what never does |

## Supported Delphi versions

| Framework | Versions | Verified |
|---|---|---|
| Engine (RTL only) | Delphi 10.4 Sydney → 13 Florence | packages built with each compiler |
| VCL (`TEdgeBrowser`) | Delphi 10.4 → 13 | built on all four, run on 13 |
| FMX (`TWebBrowser`) | Delphi 12 → 13 | built on both, run on Windows |

FireMonkey compiles for macOS, iOS and Android, but only Windows has been tried so far.

## Packages

One folder per Delphi version, the same `.dpk` for all of them.

| Package | Requires | Contents |
|---|---|---|
| `HelpChatAI` (runtime) | rtl, MarkdownProcessor | the engine, the index builder, the panel page |
| `HelpChatAIServer` (runtime) | HelpChatAI, Indy | the transports: local server, remote server, remote client, host channel |
| `HelpChatAIVcl` (runtime) | HelpChatAIServer, vcl, vcledge | `TVclHelpChatAI`, the chat control, VCL style theming |
| `dclHelpChatAIVcl` (design-time) | HelpChatAIVcl, designide | palette, splash and About box, component editor with the live preview, property editors |
| `HelpChatAIFmx` (runtime) | HelpChatAIServer, fmx | `TFmxHelpChatAI` and its chat control |
| `dclHelpChatAIFmx` (design-time) | HelpChatAIFmx, designide | palette, component editor with the configuration check |

## Demo and tests

`CRM Demo` is the Windows 10 CRM demo of Embarcadero with HelpChatAI in it: a real little
application — leads, accounts, proposals — with a manual of sixteen pages in `CRM Demo\Help`
and the assistant answering from it. Press **F1** on any screen, or ask it to open a screen,
create a lead or prepare a proposal.

It comes **in both frameworks**, sharing one data module, one database and one manual:

| | Project | Delphi | What it is |
|---|---|---|---|
| VCL | `CRM Demo\VCL\project\VCL_CRMDemo.dproj` | 10.4 → 13 | The whole application: seven pages, the lead and proposal windows, and all three actions |
| FMX | `CRM Demo\FMX\project\FMX_CRMDemo.dproj` | 12 → 13 | The same application: the seven pages, the lead, proposal and draft windows, and the same three actions |

Neither of them keeps the API key in clear: `CRM Demo\common\uAppSecret.pas` encrypts it
with DCPcrypt (an svn:external of the demo, no package of the library requires it) and the
**License activation** window asks for it the first time, when no key is found anywhere.
`Tools\ResetDemoKey.ps1` puts that back to "no key", to show it again.

`CRM Demo\BuildAllDemos.ps1` builds both with every Delphi it finds, Win32 and Win64: twelve
builds, and the FireMonkey ones are reported `N/A` below Delphi 12 rather than failed.

`Test/Delphi13/HelpChatAITests.dproj` is a DUnitX suite of **305 tests** that runs without
network: store, worker pool, cancellation, index scoring, Markdown safety, the SSE parsing and
request building of each model provider, the configuration check, both transports over real
HTTP, the actions from a real worker thread, the secrets of the settings and the printable
document - the last two of which write a real PDF with the WebView2 runtime of the machine,
and skip themselves where there is none.

```
Test\Bin\Win32\HelpChatAITests.exe --exitbehavior:Continue
```

## Release Notes ##

2 Nov 2026: ver. 1.3.0

An answer that cannot leave the panel is a note nobody keeps. This release takes it out, in
the two ways people actually ask for: the clipboard and a PDF - of one answer, of the whole
conversation, or of a page of the manual.

- **Save as PDF** (`HelpChatAI.Pdf`, engine package): the document is laid out by the
  WebView2 runtime the panel already needs, on a window that is never shown, and written
  where the user says. A4 or Letter, margins, orientation and backgrounds live in
  `Settings.Pdf`; the look is `resources/print.css` - no bubbles, no dark theme, tables that
  repeat their header row on every sheet - or the stylesheet of your application, named in
  the new `PdfStyleSheet`. Measured on this machine: half a second for the first sheet, a
  quarter for the next, with no second browser process, because the exporter borrows the
  environment of the panel
- **A header and a footer of your own**, with the page number: `Settings.Pdf.HeaderFooter`
  prints a band at the top and at the foot of every sheet, out of two HTML templates
  (`resources/print-header.html` and `print-footer.html`, or the files named in
  `PdfHeaderFile` and `PdfFooterFile`) whose placeholders - `{app} {version} {user} {title}
  {date} {time} {extra} {page} {pages}` - the library fills. The name and the version come
  from the version information of your executable and the user from Windows, and the new
  `OnPdfInfo` corrects any of it, because the user of an application is rarely the user of
  the machine. The band grows the margin by `BandMm` instead of eating into the text
- **Copy, as text *and* as HTML**: a button beside the one that saves, on every answer, on
  the header of the panel and on a page of the manual. The clipboard gets both flavours, so
  the bold, the lists and the tables survive a paste into Word while an editor still gets
  clean text. It needs neither the host nor the engine, so it is there with a remote engine
  too, where saving a file is not
- **The assistant can write a document and hand it over**: with
  `Settings.Pdf.Action := True` it gets the `export_pdf` tool - *"write me a PDF summary of
  the open leads"* - and the save dialog opens with what it wrote. Off by default: it is one
  more tool in every request, and an answer that becomes a file without being asked
- **The API key does not have to sit in clear in the configuration.** The new
  `OnDecryptSecret` is asked for every secret just before it is used - the key of the
  provider and the credentials of a remote engine, told apart by name, from the property
  *and* from the environment variable - and your handler turns it into the value to use.
  The library imposes no format and registers no cipher: without a handler nothing changes.
  It runs on the worker thread, and what a request reads is a snapshot of the settings, so
  the handler travels with it. The CRM demo shows one way of doing it, DCPcrypt and all:
  a **License activation** window - where a real application would ask its licensing
  service for the key - writes it AES-256 encrypted into the per-user `helpchatai.json`,
  with a passphrase that is not a string in the executable. It is obfuscation and the demo
  says so: it is worth something against a configuration file that travels, nothing against
  whoever owns the machine
- **The documentation index can be rebuilt from the IDE.** *Rebuild documentation
  index...*, on the component editor of both components, builds `help-index.json` out of
  the folder the settings already name, showing what it is about to do before doing it; a
  double click on a component whose index is not there offers to build it before opening
  the preview. The plan and the build are RTL (`HelpChatPlanIndexBuild`,
  `HelpChatRunIndexBuild`), so an application or a build step can do the same without
  `Tools\HelpIndexBuilder`
- **Each component is offered in its own Tool Palette only**: a plain `TComponent` belongs
  to no framework, so the FireMonkey one could be dropped on a VCL form and the other way
  round. Both now declare their class group, the way `TApplicationEvents` and the
  FireMonkey dialogs do
- **The model now knows what day it is.** The system prompt carries the date, so a document
  it writes is dated instead of saying "today" - which is what it used to do
- The save dialog is the one of Windows (`IFileSaveDialog`), not the box of Windows 95
- Fixed: the sheet came out with no margins at all. `@page { margin: 0 }` in our own print
  stylesheet beat the margins of the print settings - measured, four sheets, 0.0 mm against
  the 16 that had been asked for. The rule is gone, the default margin is 10 mm, and a
  stylesheet of an application must leave `@page` alone for the same reason
- With a **remote engine** the PDF buttons answer "not available in this application"
  (HTTP 501): the document would be built where there is no screen to save it from. Copying
  works there, because it never leaves the browser
- 305 tests, 34 of them new, two of which write a real PDF with the runtime of the machine -
  one of them through `Page.printToPDF`, the DevTools call that is the only way to put our
  own header and footer on the sheet: `PrintToPdf` takes no template, and Chromium
  implements no `@page` margin boxes, so a CSS counter prints 0 on every page. If that call
  is ever refused, the PDF is written the ordinary way and the component says the bands are
  missing

30 Oct 2026: ver. 1.2.0

The user can hand the assistant a document. A paper clip next to the question box takes a
PDF, an image or a text file, and the model reads it - which, together with an action, is a
PDF filling a form without anybody retyping what is in it.

- **Attachments** (`HelpChatAI.Attachments`, RTL): `.pdf` and `.png .jpg .jpeg .gif .webp`
  travel as bytes in the block each API wants (Anthropic `document`/`image`, OpenAI a `file`
  part and an `image_url` data URI, Gemini `inlineData`); `.txt .md .csv .json .xml .log
  .ini .yaml .yml` are decoded when they arrive - BOM, else UTF-8, else the ANSI code page -
  and put in front of the question, fenced so the content of a file cannot read as an
  instruction. **A `.docx` or an `.xlsx` is refused by name**: no model reads one, and
  sending it anyway would look like it worked
- **The paper clip, or a file dropped on the panel** - anywhere on it, and more than one at
  a time. A chip per document above the question box, with the glyph of its kind, its size
  and an ✕, and a turning ring while the bytes go up
- **Off until you turn it on**: `Settings.Attachments.Enabled` is `False`, because what the
  user attaches leaves the machine. `MaxCount`, `MaxSizeKB` and `MaxTotalKB` bound the rest.
  The clip appears only when attachments are enabled *and* the configured provider can read
  documents, so `docsearch` and `stub` never promise what their answer could not deliver
- **An attachment belongs to the conversation, not to the question**: it is sent again with
  every later question, so a second question about the same document needs no second upload,
  and ↺ takes the documents away with the conversation. They live in memory and are **never**
  written to the conversation file on disk
- **The panel draws the chips from the server** (`GET /api/attachments`), not from its own
  memory: a page reload - a VCL style change recreates the window and reloads it - used to
  leave the bar empty while the documents kept going out with every question
- The file-type glyphs are inline SVG in the panel page (Material Design Icons,
  Apache 2.0): generic glyphs, no brand logo, and nothing new to ship
- `CRM Demo\Docs` holds two documents to try it with - a request for information as a PDF
  and the notes of the follow-up call - and both demos accept attachments. Attach the PDF,
  ask *"create a lead from the attached request"*, and the model fills `create_lead` with
  what it read
- 271 tests, 25 of them new: the accepted and refused types, the three limits, text
  decoding, the blocks each of the three providers builds, and the endpoints over real HTTP

27 Oct 2026: ver. 1.1.1

The library did not change in this release: `source` is the one of 1.1.0, and so are the
246 tests. What changed is the FireMonkey sample application, which is now the whole
application and not only its main form.

- **The lead, proposal and proposal draft windows ported to FireMonkey**, over the same bind
  sources as the VCL ones, so the FireMonkey demo registers the same three actions -
  `open_screen`, `create_lead` and `draft_proposal`. Four things FireMonkey does differently
  there, each worth knowing before porting something of your own: a `TCardPanel` is a
  `TTabControl` with `TabPosition = None`; a `TRelativePanel` that rearranges itself is
  `Align` plus a scroll box, and the five resize handlers simply disappear; `MessageDlg`
  answers in a callback, so what follows the question lives there; and the DOM of the old
  `TWebBrowser` is replaced by `LoadFromStrings`
- **F1 works in those windows too.** Help properties live on `TStyledControl` and a
  FireMonkey form has none, so each unit carries its keyword as a constant and
  `OnGetContext` reads it from the active form - which is what `HandleKeyDown` of the
  component is there for
- **The side menu of the FireMonkey demo behaves like the VCL one**: open until the user
  presses its button, then narrowed to its icons - and they are the icons of the VCL menu,
  read from the same image collection. None of the three modes of `TMultiView` does this on
  its own (Panel is permanent and hides the button it is given, Drawer and NavigationPane
  slide over the content and close again at the first click outside), so the pane is a
  docked Panel inside a layout whose width the button changes
- **The proposal document moved to `CRM Demo\common\uProposalReport.pas`**, plain RTL with
  no VCL and no FireMonkey in it, so the two demos build byte for byte the same invoice from
  the same code - and the VCL one is ninety lines lighter. On the way there the line titles
  gained a `TNetEncoding.HTML.Encode` they did not have: that text can come from the model

27 Oct 2026: ver. 1.1.0
- `Caption` and `AssistantName` on both components: the title of the window the chat opens in, and the name written in the header of the panel. Empty - the default - means the word of the current language, so an English application reads "Help" and "Assistant" and an Italian one "Aiuto" and "Assistente" without anybody writing them
- The header of the panel shows the icon of the bubble next to the name. Name and icon reach the page the way the colours do, through the transport and `POST /api/assistant`: an image list is an object of the framework, so only the client can know it
- The icons of the assistant moved to the engine (`HelpChatAI.Assistant`), where both frameworks can reach them. For the built-in ones the icon the page loads is the PNG itself, with its transparency, and no drawing in between
- FireMonkey caught up with the VCL: the bubble is round and wears the icon, and `Images`, `ImageIndex` and `ImageName` are published there too, with the four names in the Object Inspector
- Fixed, both found by running the new FireMonkey demo: the FMX bubble was placed outside the window the first time the form was resized (FireMonkey computes the anchor rules once, against the parent the control has at that moment, and it had none yet), and a relative `DocIndexFile` was resolved against the current directory instead of the executable, so the documentation index was found or not depending on who started the application
- **Two sample applications**, `CRM Demo\VCL` and `CRM Demo\FMX`, sharing one data module and one manual. The FireMonkey one is the main form alone - the seven pages, the same bind sources, `TFmxHelpChatAI` with a `HelpKeyword` per tab - and needs Delphi 12 or later, because `TFmxHelpChatAI` starts there
- 246 tests, and a build matrix of 12: VCL on Delphi 10.4 to 13, FMX on 12 and 13, Win32 and Win64

25 Oct 2026: ver. 1.0.0
- First release: in-app AI help chat for VCL (Delphi 10.4+) and FMX (Delphi 12+) applications
- Engine (RTL only) with the providers `docsearch` (local documentation index, no key needed), `claude` (Anthropic), `openai` (Chat Completions, and with it Azure, Groq, OpenRouter, Mistral, Ollama...) and `gemini` (Google): all three models stream and can call the actions of the application, grounded on the documentation and on the screen context
- `TVclHelpChatAI` (`TEdgeBrowser`) and `TFmxHelpChatAI` (`TWebBrowser`): chat bubble, F1 contextual help, chat panel embeddable in any container, colours from the VCL style
- An assistant that acts: the application registers the actions it may call, with confirmation for the ones that change data
- Question dictation, design-time live preview and configuration check
- HelpChatAI server: engine, index and API key on a server, remote transport chosen in the configuration file
- HelpIndexBuilder: builds the documentation index (`help-index.json`) from a folder of Markdown files
- Packages for Delphi 10.4, 11, 12 and 13, DUnitX tests and installer
- A sample application with the component in it: the Windows 10 CRM demo of Embarcadero, with a manual of its own, F1 on every screen and three actions the assistant can run

## License

Apache License 2.0 — Copyright (c) 2026 Ethea S.r.l.

The Ethea MarkdownProcessor, which the engine package requires, keeps its own license
(Apache 2.0 / BSD, see [Delphi-MarkdownProcessor](https://github.com/EtheaDev/MarkdownProcessor)).
