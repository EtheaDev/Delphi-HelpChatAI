# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

**HelpChatAI** is an in-app AI help chat component for Delphi (VCL from 10.4, FMX from 12). The
end user asks how to use the host application; answers come from the application's documentation
index, optionally through Anthropic Claude, and are rendered as safe HTML in an embedded browser.
Design lineage and rationale: `D:\ETHEA\KittoX\KittoX_HelpChat.md` (Parts I–III).

Version control is **SVN** (the `.svn` folder is the working copy); do not `git init`.

## Layout

```
source/                  engine units (pure RTL) — HelpChatAI.*.pas, HelpChatAI.inc, HelpChatAI.Panel.res
                         HelpChatAI.Server.pas (Indy) and Vcl.HelpChatAI*.pas (VCL) live here too but
                         belong to their own packages
Ext/MarkdownProcessor/    the Ethea MarkdownProcessor: two svn:externals (Packages and source)
                         of ^/../MarkdownProcessor/trunk, a package of its own that the engine
                         requires and every groupproj builds first
resources/               panel.html / panel.css / panel.js / htmx.min.js, HelpChatAI.Assistant.rc and
                         HelpChatAI.Splash.rc -> Tools\BuildResources.cmd
Redist/WebView2/         WebView2Loader.dll x86/x64 (Microsoft, NuGet 1.0.3296.44), copied next to demos
packages/Delphi13/       HelpChatAI, HelpChatAIServer, HelpChatAIVcl, HelpChatAIFmx (runtime), dclHelpChatAIVcl,
                         dclHelpChatAIFmx (design) + groupproj
packages/Delphi12/       the same six, for Delphi 12
packages/Delphi11/, packages/Delphi10.4/   the four VCL and engine ones (FMX is Delphi 12+)
packages/*.dcr           palette icons, shared by every version: per component a 32-bit DIB
                         named after the class (16, 24, 32, 128) plus the same PNGs as RCDATA
                         (<CLASS>_PNG, <CLASS>16_PNG...), the layout SVGIconImageListNew.dcr
                         uses. One icon per framework, so the palette tells them apart:
                         delphi-helpchat_* (Ai-Assistant-Chat.svg) for the VCL component,
                         AIAssistant_Female_* for the FMX one
Images/                  the icons as SVG and the PNGs rendered from them (component icon
                         delphi-helpchat_*, assistant AIAssistant_* and Assistant_*); the two
                         delphi-helpchat_24/32.bmp are the flattened ones Delphi 10.4 needs,
                         and HelpChatAI-Box.svg/_256.png is where Setup\HelpChatSetup.ico
                         comes from
Setup/                   Setup.iss, BuildSetup.bat and HelpChatSetup.ico, the icon of the
                         installer and of the uninstaller; InnoSetupScripts is an svn:external
README.htm               README.md as HTML, installed and linked as ReadMe in the Start menu:
                         regenerate it whenever README.md changes
Test/source, Test/Delphi13, Test/data         DUnitX suite and fixtures
"CRM Demo"/              the sample application, in two frameworks: the Windows 10 CRM demo
                         of Embarcadero with HelpChatAI in it, and one manual for both in
                         Help/*.md (plus Help/Images and the help-index.json the applications
                         read)
"CRM Demo"/common/       uDataMod (the FireDAC data module, the database and every query)
                         and uProposalReport (the invoice as HTML, and the parser of the
                         line items the model writes), shared by the two demos.
                         Framework-neutral on purpose - the FireDAC wait cursor
                         (FireDAC.VCLUI.Wait / .FMXUI.Wait) is the one thing that is not,
                         so it lives in each .dpr instead
"CRM Demo"/VCL/          VCL_CRMDemo: project/ and source/ (uMainForm, uLeads, uProposal,
                         uDraftProposal). Delphi 10.4 to 13
"CRM Demo"/FMX/          FMX_CRMDemo: project/ and source/ (uMainFormFmx, uLeadsFmx,
                         uProposalFmx, uDraftProposalFmx). Delphi 12 and 13 only, because
                         TFmxHelpChatAI starts there
"CRM Demo"/bin/<Platform>    both executables, next to the one WebView2Loader.dll they share
"CRM Demo"/dcu/<Framework>/<Platform>   svn-ignored build output, one tree per framework so
                         the two projects cannot pick up each other's units. No Delphi
                         version in the path - so after opening a demo with a different
                         Delphi, Build and not Compile
"CRM Demo"/Build*.ps1    BuildDemo.ps1 (one framework, one version), BuildAllDemos.ps1 (the
                         matrix of 12, with a summary table) and the four per-version
                         wrappers, same shape as StyledComponents/Demos. -Framework VCL|FMX
                         everywhere; FMX on 10.4 and 11 is reported N/A, not SKIP
Server/source, Server/Delphi13                HelpChatAIServerApp: the console HelpChatAI server
                         (Server/Bin, Server/Dcu and helpchatai-server.json are svn-ignored;
                         helpchatai-server.json.sample is the versioned starting point)
Lib/Delphi13/            DCU output of the packages (build artefact)
"CRM Demo"/bin/Win32|Win64   the demo executable (+ WebView2Loader.dll)
Test/Bin/<Platform>/     test executable. Binaries never depend on the Delphi version or the
                         configuration: 32/64-bit DLLs shipped next to them stay separate
Tools/HelpIndexBuilder/  CLI over HelpChatAI.IndexBuilder (Markdown folder -> help-index.json)
Test/data/               the fixtures: a synthetic help-index.json, and encodings/ with four
                         tiny pages (ANSI with accents, UTF-8 with and without BOM, one with
                         no heading) - the index builder tests run on the real manual of the
                         CRM demo, and those four cover what an all-UTF-8 manual cannot
resources/               HTML/CSS/JS of the panel (M3)
```

Folder naming per Delphi version is `Delphi10.4`, `Delphi11`, `Delphi12`, `Delphi13` (not
`D12`). Compiler-version defines live in `source/HelpChatAI.inc` (`D10_4+`, `D11+`, `D12+`, `D13+`).

## Build and test (Delphi 13 = BDS 37.0, `C:\BDS\Studio\37.0`)

```
cmd /c "call C:\BDS\Studio\37.0\bin\rsvars.bat && msbuild packages\Delphi13\HelpChatAI.dproj /t:Build /p:Config=Release /p:Platform=Win32"
cmd /c "call C:\BDS\Studio\37.0\bin\rsvars.bat && msbuild Test\Delphi13\HelpChatAITests.dproj /t:Build /p:Config=Debug /p:Platform=Win32"
Test\Bin\Win32\HelpChatAITests.exe --exitbehavior:Continue
```

Tests run without network. The one Claude test that would need a key skips itself when
`ANTHROPIC_API_KEY` is set.

**Encoding and line endings, uniform across the repository:** `.pas`, `.dpr`, `.dpk` and `.inc`
are UTF-8 **with BOM** and **CRLF**; `.dfm` and `.fmx` are **ANSI** (no BOM) and CRLF, which is
what the IDE writes; `.dproj` and `.groupproj` are CRLF too, for the same reason. Without the
BOM `dcc32` reads a source as ANSI and every non-ASCII literal (Italian strings, test fixtures)
is silently corrupted. After creating a `.pas`/`.dpr`/`.dpk`, add the BOM
(`Tools\Build_Delphi13.cmd` does not do it):
`sed -i '1s/^\xEF\xBB\xBF//;1s/^/\xEF\xBB\xBF/' file.pas`, and write it with CRLF. The
exceptions are `Setup/InnoSetupScripts` and `Ext/MarkdownProcessor`, svn:externals shared with
the other Ethea projects: their files are left exactly as those repositories have them.
**A scripted edit over these files must not assume a line ending.** The project files used to
be LF except the Delphi 13 ones, which the IDE had rewritten; a sweep whose patterns carried
`\r\n` therefore did nothing to the other three versions, and said nothing about it, which is
how three group projects ended up calling targets for a project they did not list and three
`.dproj` kept referencing units that had been deleted. Match `\r?\n`, and check the result of
the edit on every version, not on the one that happens to be open.

## Architecture rules (keep them)

- **One set of sources, one .dpk per package, one .dproj per Delphi version.** The `.dpk` files
  are identical across versions (`{$LIBSUFFIX AUTO}` works from 10.4); in the `.dproj` only
  `ProjectVersion` (19.2 / 19.5 / 20.3 / 20.4-20.5 — this is what the IDE and the installer match
  on), the `Lib/<version>` DCU folder and a couple of entries that appeared later differ
  (`<ProjectName>` and Win64x from 12, `<WelcomePageFile>` from 11). Adding a unit to a package
  means editing all four `.dpk`/`.dproj` pairs. `Tools/Build_Packages.cmd all` builds every
  version that is installed on the machine, and `"CRM Demo"/BuildAllDemos.ps1` does the same
  for the sample application on both platforms — do both before releasing. That matrix is
  what catches what a Delphi 13 build cannot: a `.vsf` listed in `Custom_Styles` that exists
  only in the newest Delphi is an RC2135 at resource time (only 7 of the stock styles exist
  in every version from 10.4 on), and the CRM demo needs `FireDAC.Phys.SQLiteWrapper.Stat`
  before Delphi 12 and `.FDEStat` from 12 on. **The oldest compiler
  decides what the sources may use**: `TFile.GetSize` (Delphi 11) broke the 10.4 build and is
  now a `FindFirst`/`TSearchRec` helper. A new RTL call deserves a 10.4 build, not only a 13
  one. The image lists of the bubble live in `vclwinx`, which every VCL package requires: in
  all four versions `vcl` alone pulls `Vcl.ImageCollection`, `Vcl.VirtualImageList` and
  `Vcl.BaseImageCollection` into the BPL (W1033) instead of sharing them.
- **The MarkdownProcessor is a package of Ethea, not code of ours.** It used to be copied under
  `source/ThirdParty` with a `HelpChatAI.Markdown*` prefix, to avoid a unit-name clash with the
  copy an IDE may already have. Then that project grew packages of its own, and the other
  Ethea projects that use it (MarkDownHelpViewer) require them instead of copying the units —
  so this one does the same: `Ext/MarkdownProcessor/{Packages,source}` are svn:externals of
  `^/../MarkdownProcessor/trunk`, `HelpChatAI.dpk` has `requires rtl, MarkdownProcessor`, and
  `HelpChatAI.Html` uses the units under their real names. Its folders are named the way that
  project names them (`D10.4`, `D11`, `D12`, `D13`), not the way this one does.
  **Whoever compiles has to build it first**: it is the first `Projects`, the first target and
  the first `BuildGroupProject` of all four groupproj (the installer follows the order written
  there), and the first msbuild of `Build_Packages.cmd` and `Build_Delphi13.cmd`. An
  application that compiles the units instead of using the packages needs
  `Ext\MarkdownProcessor\source` on its search path — that is the one line that changed in the
  demos, the tests and the server. Two traps, both of which cost a build: a package that
  requires it may not be a never-build one (`{$IMPLICITBUILD ON}` in the `.dpk` and no
  `<DCC_OutputNeverBuildDcps>` in the `.dproj`, or E2466 "Never-build package requires
  always-build package"), and the BPL cannot be rewritten while an IDE has it loaded. The
  installer needed one thing, and it is not in this repository: with `FilesEmbedded` it
  extracts only the packages folder to `{tmp}` and reads the group projects there, so a
  `BuildGroupProject` pointing outside it does not exist yet, `TryLoadRADStudioProject`
  returns False and `TryLoadRADStudioGroupProject` **drops the project without a word** —
  the group loads, the setup never builds the MarkdownProcessor, and ours fail on the
  missing DCP. InnoSetupScripts 1.2.6 extracts `LibraryExternalFolder` as well (the define
  is in `Setup/Setup.iss`); without that define nothing changes for anyone. The rest the
  installer does by itself: it registers the search paths of every project of the group,
  so that one `.dproj` is also what puts `Ext\MarkdownProcessor\source` on the library path.
- **`source/HelpChatAI.Panel.res`, `HelpChatAI.Assistant.res` and `HelpChatAI.Splash.res` are
  versioned on purpose.** They are not project resources an IDE regenerates: the panel page,
  the assistant icons and the icons of the IDE splash screen and About box, all three compiled
  by `Tools/BuildResources.cmd`, and nothing compiles without the first two. They survive the
  "no .res in version control" rule, and the installer re-adds them explicitly because its file
  list excludes `*.res`. `HelpChatAI.Splash.res` is linked only by `Vcl.HelpChatAI.Register`: it
  carries the 48-pixel PNG the IDE wants from Delphi 11 and the flattened 24/32 bitmaps 10.4
  loads instead (`LoadBitmap`, no alpha), all generated from `Images/delphi-helpchat_*`.
- **Engine knows nothing about UI or web.** The units of the `HelpChatAI` package must stay
  RTL-only: no `Vcl.*`, `FMX.*`, Indy or WebView units. `HelpChatAI.Server` (Indy) is in
  `HelpChatAIServer`, `Vcl.HelpChatAI` in `HelpChatAIVcl`; both wrap `THelpChatEngine`.
- **One HTTP layer, two servers.** `HelpChatAI.Server` holds `THelpChatServerSession` (a secret, a
  conversation key, the screen context, the theme as CSS), the routing and the endpoints;
  `THelpChatLocalServer` adds one session and the transport interface, `THelpChatRemoteServer`
  (`HelpChatAI.Server.Remote`) adds many, application keys and storage. A session *is* a
  conversation key of the shared engine (`u:<user>` / `s:<session>`): one store, one worker pool,
  one index for everybody. New endpoint = `HandleApi` in the base, and `HELPCHAT_API_*` in
  `HelpChatAI.Panel` where the contract lives.
- **A destructor never calls a virtual method.** `THelpChatHttpServerBase.Destroy` calls the
  non-virtual `StopListening`, not `Stop`: a descendant's `Stop` would run after its own
  destructor freed the fields it uses (this cost an access violation once).
- **The theme travels as CSS, not as a record.** The colours are produced by the framework on the
  client; a remote client posts `themeCss` and the session keeps the string the page loads with.
  `THelpChatTheme.ToJson` stays what `window.hcApplyTheme` eats at runtime.
- **What the panel is called travels the same way, and for the same reason.** `Caption` (the
  title of the own window) and `AssistantName` (the header of the page) are published on both
  components and **empty by default**: empty means `hcmUiHelp` and `hcmUiTitle`, so an Italian
  application reads "Aiuto" and "Assistente" without anyone writing them. The rule lives once,
  in `THelpChatPanel.AssistantNameOf`, which the page and both components call. The name and
  the icon reach the session through `IHelpChatTransport.SetAssistant` and `POST /api/assistant`
  — never through `THelpChatSettings`: an image list is a VCL object, so only the client can
  know it, exactly like the colours. The icon is a `data:image/png` URI and nothing else is
  accepted (`AssistantIconTag` checks the prefix): the CSP of the page allows `'self'` and
  `data:` for an image, so an http URL would be dropped without a word.
- **The alpha of an image list cannot be read back.** GDI writes no alpha channel, so a bitmap
  drawn from a `TCustomImageList` comes back opaque and the header icon would carry a grey
  square. `HelpChatIconPng` draws the same image twice, over white and over black: where it is
  transparent the two differ by 255, where it is solid they are equal, and the drawing over
  black already *is* the colour multiplied by the alpha, which is what a bitmap declared
  `afDefined` holds. Measured: with themes off `TImageCollection.GetBitmap` flattens onto
  `clBtnFace` before any of this, so a console program without a manifest sees opaque icons -
  that is the VCL, not the trick, and a real application has a manifest.
- **Where the engine lives is a setting.** `Settings.Remote.BaseUrl` (in `helpchatai.json`) makes
  the components build a `THelpChatRemoteTransport` instead of the local server, and leaves the
  local engine unstarted — so nothing in the components may assume `Engine.DocIndex` exists.
  Context and theme are pushed to the server synchronously, only when they changed, with
  `Settings.Remote.TimeoutMs`: they must be there before the question that follows them.
- **The page reaches its host over HTTP, always.** Same server when the engine is local, the
  loopback `THelpChatHostChannel` when it is remote (`HC.uiBase`/`HC.uiToken`, CORS limited to
  the panel origin plus `Access-Control-Allow-Private-Network`). `HC.hostCommands = false` means
  nobody is listening and the page hides its ✕.
- **Anything the page calls must be in its own CSP.** `panel.html` allows `connect-src 'self'
  {{API_BASE}} {{UI_BASE}}` and nothing else: a call to an origin the policy does not name is
  dropped by the browser before it reaches the network — no request, no error, no clue. A new
  outbound call = a new placeholder there and in `THelpChatPanel.RenderPage`.
- **A remote transport connects on first use, not on Active.** An application whose help server
  is down or unreachable must still start; the failure belongs to the moment the user asks for
  help. `IsActive` means "ready", `HasSession` means "a conversation is open".
- **The panel is one self-contained page.** Edit `resources/*`, run `Tools\BuildResources.cmd`
  (brcc32 -> `source/HelpChatAI.Panel.res`), rebuild. The API contract (paths, token header,
  HTML fragments, `data-pending`) is in `HelpChatAI.Panel` and `panel.js`; the server tests
  (`HelpChatAI.Tests.Server`) drive it over real HTTP with `THTTPClient`.
- **In htmx 2 the `detail.elt` of a swap event is the target, not the sender.** On
  `htmx:afterSwap` it is `#hc-body`; who sent the request is `detail.requestConfig.elt`
  (comparing it with the form is why the question box never emptied, for several releases).
  The box is therefore cleared in `htmx:beforeRequest`, where the parameters are already
  collected, and the focus goes back to it on the swap. That same swap seeds the Up/Down
  question history (`panel.js`, 100 entries) from the user bubbles when the history is
  (re)loaded, so it survives a restart with the persisted conversation.
- **The microphone is the client's, so the page never owns it.** `panel.html` carries the
  button hidden; only a host that can listen shows it, with `window.hcVoiceEnable(on, label)`,
  and pushes what it hears with `hcVoiceState`/`hcVoiceText` (a hypothesis replaces the previous
  one, a final sentence stays). Nothing about it reaches the engine, the server or the
  transport: a remote page would have no microphone to offer anyway.
- **The modern dictation engine cannot be called.** What Win+H drives is
  `WindowsUdk.UI.Input.Dictation.DictationManager` (`windowsudk.shellcommon.dll`): registered,
  but internal — no metadata in `C:\Windows\System32\WinMetadata`, no unit in the Delphi RTL,
  not even in 13, whose `Winapi.Microsoft.*` cover the Windows App SDK and whose `Winapi.AI`
  has nothing about speech. Reaching it would mean reverse-engineered interfaces that an
  update can break: do not promise it. A new engine arrives as another `THelpChatVoiceEngine`
  (a cloud service, a local model), not as a trick on this one.
- **Two engines, and the application picks one.** `Vcl.HelpChatAI.Voice`:
  `Windows.Media.SpeechRecognition` (RTL from Delphi 11) reports text and state, so the box
  fills while the user talks; the dictation of Windows simulates Win+H and lets Windows type
  into the focused control, reporting nothing (`ReportsText` is False). **Nothing is swapped
  underneath**: the engine that fails says so. The default is the dictation, because it works
  wherever Win+H works, while the recognizer may answer for the language, compile its
  dictation grammar, start, hear a voice (`HeardSpeech`, from `StateChanged`) and transcribe
  nothing at all — measured on Windows 11 25H2. `VoiceEngine` is the only switch, `hveNone`
  included: a second one (the old `VoiceInput`) would have meant two ways to say the same
  thing. `CreateHelpChatVoiceInput` returns nil for `hveNone`, and for the recognizer in
  Delphi 10.4; a nil engine hides the button.
- **The consent to online speech recognition is the user's, never ours.** Free dictation goes
  through it: `HelpChatOnlineSpeechAccepted` reads it
  (`HKCU\...\Speech_OneCore\Settings\OnlineSpeechPrivacy\HasAccepted`, missing key = never
  accepted) and `HelpChatOpenSpeechSettings` opens `ms-settings:privacy-speech`. The component
  asks once, through `OnVoiceConsentNeeded` or a dialog, then lets the engine try and reports
  what Windows answers. **Never write that key**: it is the user's consent to sending their
  voice to Microsoft. Every event is marshalled with `TThread.Queue`: the recognizer answers
  on its own threads.
- **Every command ends with the caret in the question box.** `focusInput()` after each swap of
  `#hc-body` (send, clear, history), and a `mousedown` handler that cancels the default on any
  button, because that default is what moves the focus away in the first place — the click
  still happens. Focusing inside the page is not enough when the panel opens: without the
  native focus the window has no caret to give, so `TVclHelpChatAIPanel.FocusInput` focuses the
  browser *and* calls `window.hcFocus`, and `Open` and `OnPageReady` both go through it.
- **Screen context is native.** `TVclHelpChatAI.BuildContext` computes it on the main thread and
  calls `Transport.SetContext`; the page never sends it (a remote client may, as override).
  Deepest `HelpKeyword`/`HelpContext` wins (focused control upwards, form last); the active
  `TTabSheet` caption is the screen label.
- **F1 goes through the Delphi help system (VCL).** `THelpChatHelpViewer` (`HelpChatAI.HelpViewer`,
  RTL: ICustomHelpViewer + IExtendedHelpViewer registered via `System.HelpIntfs.RegisterViewer`,
  the component implements `IHelpChatHelpTarget`) receives keyword and context requests; the
  `TApplicationEvents.OnMessage` F1 handler only steps in when no control in the chain declares
  help, ignores key auto-repeat, and `OpenWithQuestion` debounces the same question within
  1.5 s. Do not hook `Application.OnHelp`.
- **FMX differs where FMX differs.** No help routing: `TFmxHelpChatAI` chains the host form's
  `OnKeyDown` (previous handler first) and offers `HandleKeyDown` for other forms. Help
  properties live on `TStyledControl` (forms have none); with nothing focused the active tab of
  the first `TTabControl` is the screen. A native `TWebBrowser` is never reparented: a new
  `TFmxHelpChatAIPanel` per container. Colours: `ThemeMode` (page defaults / built-in light /
  dark), no style tracking. Only Windows is verified; the macOS/iOS/Android branches of
  `OpenExternal` are compile-time only.
- **The page talks to its host through the server.** No WebView message bridge: the page posts
  `/api/ui/{command}` (`close`) and the transport delivers it with `TThread.Queue`
  (`SetOnUiCommand`). FMX exposes no web-message API and a remote page has no native side, so
  this is the only path; a console must `CheckSynchronize` to receive it (see the server test).
- **The chat is a control, the window is optional.** `Vcl.HelpChatAI.Panel` (`TVclHelpChatAIPanel`,
  a `TCustomPanel` with the `TEdgeBrowser`) and `FMX.HelpChatAI.Panel` (`TFmxHelpChatAIPanel`, a
  `TLayout` with the `TWebBrowser`) do the browser work and know nothing about their host. The
  component parents it to `Container` / the `AContainer` chosen in `OnBeforeShowHelp`, else to
  its own `TVclHelpChatAIForm`/`TFmxHelpChatAIForm` (created with `CreateNew`, no DFM). Position memory is the
  own window's only; an application container persists itself. There is no designable form
  and nothing registers form classes: everything visible is HTML.
- **The bubble has a window, and it fights to stay on top.** It used to be a `TSpeedButton`,
  and in a real application it vanished: a `TGraphicControl` has no window of its own, the VCL
  paints it on its parent's canvas and keeps it *below* every windowed sibling, so a grid or a
  page control covering the corner hid it (`BringToFront` only reorders the graphic ones).
  `TVclHelpChatAIBubble` (`Vcl.HelpChatAI.Bubble`) is a `TCustomControl` clipped to an ellipse with
  `SetWindowRgn` — hence no background to fake — raised with `SetWindowPos(HWND_TOP)`, and it
  hooks its parent's `WindowProc` to post itself `HELPCHAT_CM_BRINGTOTOP` whenever the host
  adds a child or is resized (`CM_CONTROLLISTCHANGE`, `WM_PARENTNOTIFY`, `WM_SIZE`). The hook
  is restored only while the chain is still ours. FMX needs none of this: there everything is
  drawn, so a control cannot hide another.
- **The icon follows the Delphi contract, and ships its own fallback.** `Images`, `ImageIndex`
  and `ImageName` live on the bubble and are mirrored by `TVclHelpChatAI`: an image list of the
  application wins. With none, the bubble builds a `TVirtualImageList` over
  `HelpChatAssistantIcons`, one `TImageCollection` per process filled from
  `source/HelpChatAI.Assistant.res` (PNG, nine sizes per icon), so the DPI of the window asks for
  the size it needs. Adding an icon = the PNGs in `Images\`, an entry in
  `resources/HelpChatAI.Assistant.rc`, `Tools\BuildResources.cmd`, a name in
  `HelpChatAssistantIcons`. The image lists come from `vclwinx`, which the VCL package requires.
- **VCL style change recreates windows.** `TStyleManager.SetStyle` posts `CM_CUSTOMSTYLECHANGED`
  to each visible form; `TCustomForm` recreates its window (the WebView reloads the page).
  `TVclHelpChatAI.AppMessage` catches the posted message first and stores the theme in the
  transport, so the reload asks for a page that already has it; the control's `CM_STYLECHANGED`
  and `OnPageReady` re-apply it via script.
- **Colours are CSS variables only.** `panel.css` never hard-codes a colour outside the `--hc-*`
  definitions; a `THelpChatTheme` (RTL, `HelpChatAI.Theme`) sets them, rendered as `:root{}` at
  page load and pushed with `window.hcApplyTheme` at runtime. Per-framework producers:
  `Vcl.HelpChatAI.Theme` (table of VCL styles + StyleServices fallback), FMX to come. Adding a
  variable = panel.css + `ForEachVariable` in HelpChatAI.Theme + the `names` list in panel.js.
- **The WebView is confined.** `TVclHelpChatAIPanel` cancels every navigation outside the
  panel origin and hands the link to `OnOpenLink`, else opens http(s)/mailto links in the
  system browser; new windows likewise. `panel.js` never lets a link navigate the panel:
  documentation pages open in its documentation view, other relative links do nothing.
- **Documentation pages are files of one folder.** `HelpChatAI.DocPages` (RTL) renders a page
  of `Settings.DocFolder` for `GET /api/doc?page=`: the name is normalized and must stay inside
  the folder and end in .md, the Markdown goes through `HelpChatMarkdownToSafeHtml`, images of
  the folder are inlined as data: URIs (no token-less route, CSP unchanged). The engine keeps
  `DocPages` until its destructor (a request may be running while it stops).
- **Nothing blocks on the model.** `THelpChatEngine.Send` returns at once with a pending assistant
  message; `THelpChatRunner` workers fill it. Never call a provider on the caller's thread.
- **Streaming goes through the store.** Providers call the token callback; the runner appends to
  the pending message; readers poll or subscribe to `OnMessageChanged` (fired on the worker
  thread — UI layers must marshal with `TThread.Queue`).
- **Cancellation is cooperative and mandatory.** Every provider checks `IHelpChatCancelToken`
  and aborts its HTTP transfer (`OnReceiveData` → `AAbort`). `Shutdown` waits with a timeout and
  detaches stuck workers; they must never touch a freed store (the shared state pattern in
  `HelpChatAI.Runner`).
- **Settings are snapshotted per request** (`THelpChatSettings.Assign`). Providers read their
  copy; property changes apply to the next message.
- **Model output is untrusted.** Render only through `HelpChatMarkdownToSafeHtml` (safe mode +
  `HelpChatSanitizeUrls`, then `HelpChatAutoLinkUrls` for bare URLs the model writes as text).
  The dialect is **mdGFM**, not CommonMark: models answer with tables, strikethrough and task
  lists all the time, and CommonMark prints a table as a line full of pipes — it was visible
  in the panel before the switch. GFM also forbids the dangerous raw HTML, one guarantee more
  on top of safe mode, and `panel.css` already styles `.hc-chat-bubble table`.
  User/system/error text goes through `HelpChatTextToHtml`, never through Markdown. The two
  layers do not trust each other: in safe mode the Markdown engine now blanks a dangerous link
  target instead of leaving it, and `HelpChatSanitizeUrls` turns an empty `href`/`src` into `#`
  too — `href=""` is not dangerous, it reloads the page, and a blocked link must look dead.
- **Providers register by name** in their unit `initialization`, so an application must link
  the units it configures. An empty name is `stub`; an unknown one (typo, unit not linked)
  gets `THelpChatUnavailableProvider`: an error bubble naming the provider and the unit to
  add, never the stub's placeholder, which would pass for an answer. Add a provider = new
  unit + `RegisterProvider`, nothing else changes. **A package does not change this rule, it
  sharpens it**: a runtime package runs the `initialization` of the units the host actually
  references, not of every unit it contains. A host that uses `HelpChatAI` but names no provider
  unit sees `stub` alone, even though all of them are inside `HelpChatAI370.bpl` — measured with
  a two-line program built with `-LUHelpChat`. That is why the **design packages** link the
  four built-in providers explicitly (`Vcl.HelpChatAI.DesignPreview`, `FMX.HelpChatAI.Register`):
  without that, the configuration check inside the IDE reported every real provider as "nobody
  registered it". A provider the application registers still cannot run in the IDE, and the
  check says so instead of calling it a typo. **What a provider needs, the provider
  says**: `THelpChatProviderBase.ConfigurationIssue` is a virtual class function returning one
  sentence or nothing, overridden by `claude` and `gemini` (the key), `openai` (the key, but
  only when it is really calling api.openai.com) and `docsearch` (the index), and that is the
  only thing `HelpChatAI.Diagnostics` knows about any of them — a check that grew a
  `if name = 'claude'` would break the promise above.
- **One settings section per provider, one shape for all of them.** `THelpChatModelSettings`
  holds what every model needs (key, model, endpoint, MaxTokens, grounding, timeouts,
  MaxToolRounds); `Claude`, `OpenAI` and `Gemini` descend from it and add only what is theirs
  (`ApiVersion`, the Azure trio, nothing). `SectionName` is both the JSON key and the property
  name, `DefaultModel`/`DefaultBaseUrl`/`ApiKeyEnvVar` are what an empty value resolves to — so
  a `helpchatai.json` that never names a model keeps following the library. **Whoever is not a
  provider reads `Settings.ActiveModel`**, never `Settings.Claude`: that is how the engine
  gets `GroundingMaxChars` and the server prints what it is about to call. `ActiveModel`
  answers with the Claude section for `stub` and `docsearch`, which have no model at all.
  The old `HELPCHAT_CLAUDE_DEF_*` constants are aliases of the `HELPCHAT_MODEL_DEF_*` ones:
  applications used them.
- **The prompt and the tool-call record belong to every provider.**
  `THelpChatProviderBase.BuildSystemPrompt` builds the instruction, the language rule, the
  screen context and the documentation excerpts: two providers that grounded their answers
  differently would answer differently to the same question. `THelpChatToolCall` likewise
  lives in `HelpChatAI.Provider` — the three APIs deliver a call differently (Anthropic in typed
  blocks, OpenAI in fragments tied by an `index`, Gemini whole in one part) and all three end
  up in that record.
- **Streaming is cut once, parsed three times.** `THelpChatSseStreamBase`
  (`HelpChatAI.Provider.Sse`) is the `TStream` the HTTP client writes into: it buffers, splits
  on newlines, decodes UTF-8 only when a line is whole (a multi-byte character is routinely
  split across two reads) and calls `ProcessLine`. Each provider overrides that one method and
  nothing else. A malformed fragment is skipped, never raised: half an answer beats an
  exception, and the status code and `Error` are checked afterwards anyway.
- **`openai` is the provider of a dozen services.** Chat Completions is what Azure OpenAI,
  Groq, OpenRouter, Mistral, DeepSeek, Ollama and LM Studio all speak, so `BaseUrl` + `Model`
  is the whole configuration. Two details earn their code: a `BaseUrl` already ending in `/v1`
  does not get a second one, and a non-default endpoint is never reported as missing a key,
  because a local server has none. Azure is the one that needs more than a URL —
  `AzureDeployment` moves the path to `/openai/deployments/<name>/chat/completions` and the
  key from `Authorization` to `api-key`.
- **Gemini agrees with nobody.** `contents` instead of messages, `parts` inside a turn, the
  assistant called `model`, `systemInstruction` apart, limits under `generationConfig`, the
  key in `x-goog-api-key`. `?alt=sse` is not optional: without it the endpoint answers with
  one JSON array at the end, which is the opposite of streaming. A `thought` part is the model
  reasoning, never the answer. And a function call arrives whole, so there is nothing to
  reassemble and nothing like `finish_reason` to wait for: a `functionCall` part *is* the
  signal.
- **The thought signature travels with the call, and must come back.** A thinking Gemini
  (3 and 4, the default `gemini-3.8-flash` among them) puts a `thoughtSignature` on the part
  that carries the first `functionCall` of a round, and the next request is rejected with a
  400 if that part comes back without it — which is exactly what the second round of the tool
  loop does. It belongs to the **part**, next to `functionCall`, not inside it; with parallel
  calls only the first one has it; it must be returned unchanged and in place.
  `THelpChatToolCall.Signature` carries it, empty for the other two providers. A signature on
  a text part (a thought summary included) is not validated but is returned too, because the
  model reasons better with its own notes back. Measured against the real service: without
  this, one action was enough to break the reply.
- **The configuration check is RTL, the design-time glue is not.** `HelpChatAI.Diagnostics`
  (engine package) answers "would this work?" over a `THelpChatSettings`: provider, key, index,
  pages folder, or the remote server when one is configured. `HelpChatSettingsForFolder` builds
  the copy an application living in a given folder would see — paths expanded, the two
  `helpchatai.json` merged. Everything that needs the IDE stays in the design packages: the
  output folder of the active project (`GetActiveProject`, `ExpandRootMacro`) and the WebView2
  loader. Those ~20 lines are duplicated in `FMX.HelpChatAI.Register` on purpose: sharing them
  would mean `dclHelpChatAIFmx` requiring `dclHelpChatAIVcl`, and with it the whole VCL runtime.
- **The design-time preview runs a copy, never the component.** `Vcl.HelpChatAI.DesignPreview`
  creates a second `TVclHelpChatAI` owned by nothing (so no `csDesigning`, which is what stops
  `Active`), with bubble, help viewer, F1 and actions off, parented to a modal window, freed
  when it closes. It opens from the form's `DoShow`, not before: the panel needs a window for
  its WebView. `WebView2Loader.dll` is loaded by full path first (the output folder of the
  project, then `$(HELPCHATAIDIR)\Redist\WebView2\<arch>`), because nothing ships it next to
  `bds.exe` and the RTL only ever asks for the bare name — once the module is in the process,
  that bare name finds it. The About box and the splash are registered by the VCL design
  package alone: one library, one entry.
- **What the Object Inspector shows is a design decision.** `HostForm` is public, not
  published: at design time the form of another unit is not a component of this one, so the
  combo would always be empty. `Container` has an editor that lists only the controls with
  `csAcceptsControls` - the stock one offers every `TWinControl`, edit boxes and buttons
  included, as places to put a chat panel. `Settings.Provider` has one that drops down the
  registered providers (registered on `THelpChatSettings`, so the FMX package gets it too),
  and `ConfigFileName` one that opens a file dialog. `Provider` stays where it
  belongs, under `Settings`, and is not mirrored on the components: a second published
  property for the same value shows up twice in the Object Inspector, and two ways to write
  one setting are one too many.
- **One configuration file, or the three defaults.** `ConfigFileName` (a `TFileName` on both
  components) replaced the old `LoadConfigFiles` flag, which said how to look rather than
  where; an empty one is what "do not load" used to mean. Named, it *is* the configuration:
  no shared file, no per-user file, nothing else, and a relative path resolves against the
  executable. **A named file that is not there raises `EHelpChatConfigError`**, at activation
  and in the design-time check alike: an application that asked for a configuration and runs
  without it is an application shipped with the wrong settings. The decision lives once, in
  `THelpChatSettings.LoadConfiguration`, so VCL and FMX cannot drift apart, and
  `HelpChatSettingsForFolder` mirrors it - the component editor turns the exception into an
  error line instead of letting it out of a check. Reading it is a virtual method of the
  components, because the preview has already read it from the folder of the project and
  must not read it again from the folder of the IDE.
- **`ImageIndex` and `ImageName` need their own property editors.** The ones the IDE gives the
  standard controls are not offered to a component that is not one of them, so
  `Vcl.HelpChatAI.Register` registers `TVclHelpChatImageIndexProperty` and
  `TVclHelpChatImageNameProperty` (the pattern of SVGIconImageList and StyledComponents:
  `ICustomPropertyListDrawing`, the images drawn in the drop-down). With no `Images` of the
  application they list the built-in icons, which is the only way to discover their names.
- **Actions are what the assistant may do, and only that.** `HelpChatAI.Actions`: the application
  registers name, description, parameters and handler; `ToolsJson` is what a provider declares
  (`SupportsActions`), `Invoke` is how it calls one. The handler runs on the application's main
  thread — the worker queues the request, fires `OnPending`, and waits with a timeout while
  watching the cancellation token; the component marshals with `TThread.Queue` and calls
  `ExecutePending`. Nothing in this path may raise into the provider: every outcome is a
  `THelpChatActionOutcome` turned into a sentence for the model.
- **The broker outlives the component on purpose.** It is reference counted and the queued
  `ExecutePending` closure captures the interface, so a call in flight cannot land on a freed
  object. The component keeps both the typed reference and the interface, and nils both.
- **Tool use is a loop, not a call.** The Claude provider streams a round, and if the model asked
  for actions it executes them, appends the assistant turn and the `tool_result` turn to the
  conversation and calls again, up to `Claude.MaxToolRounds`. The text of every round is
  concatenated (with a paragraph break) and streamed as it arrives, so what the user reads and
  what the store keeps are the same string.
- **Actions are local for now.** With `Settings.Remote` the model runs on the server and the
  actions live in the client: the definitions and the calls do not travel yet. The broker queue
  is shaped for it (`TakePending`/`Complete` over HTTP, the host channel already exists), but
  until that is built, registering actions with a remote engine does nothing.
- **The sample application is the integration, and it is where the mistakes show up.**
  `CRM Demo` is the Windows 10 CRM of Embarcadero with the component on the main form,
  `claude`, one manual in `Help/*.md` for both demos, and the actions. The **VCL** one
  (`VCL/`) is where it started, and the reference for the other.
  The **FMX** one (`FMX/`, Delphi 12+) is the same application - the seven pages, the
  lead, proposal and draft windows, the same bind sources of the same data module, and the
  same three actions. It exists because nobody had ever run the FireMonkey half of the
  library in a real application, and it is still where the FireMonkey mistakes show up.
  What FireMonkey does differently there: no `TRelativePanel` (it is `Align` plus margins
  or a scroll box, and the resize handlers of the VCL demo simply do not exist), no
  `TTitleBarPanel` (the two combo boxes go in a `TToolBar`), no `TCardPanel` (a
  `TTabControl` with `TabPosition = None`), `TMultiView` in place of `TSplitView`,
  `TCalendar` in place of `TCalendarView`, one multi-resolution `TImageList` read by
  `TGlyph` in place of `TImageCollection` + `TVirtualImageList` + `TVirtualImage`, a
  `.style` file loaded at run time in place of the VCL styles linked by `Custom_Styles`,
  `LoadFromStrings` in place of writing into the DOM of the old `TWebBrowser`, and a
  `MessageDlg` that answers in a callback.
  Three of its own, measured and all three unobvious:
  **F1 in a window that is not the host** goes through `HandleKeyDown` of the component,
  and the keyword cannot come from the form - help properties live on `TStyledControl` -
  so each unit declares it as a constant and `OnGetContext` reads it from
  `Screen.ActiveForm`;
  **a date that is null must be asked of the field, not of the control**: a null never
  reaches a `TDateEdit` as a zero, it leaves it as it was, and `IsEmpty` is what the four
  `OnAssignedValue` handlers of the VCL form blank the format for;
  **no mode of `TMultiView` is a `TSplitView`** - Panel is permanent and hides the
  `MasterButton` it is given, Drawer and NavigationPane slide over the content and close
  again at the first click outside - so the side menu is a docked Panel inside a layout
  whose width its own button changes, which is what `CloseStyle = svcCompact` does. The
  icons of its items are `TGlyph` children and not the `ImageIndex` of the item, because
  that one is sized by the style of the `TListBox`.
  Four things the integration taught, each of which cost a run:
  **a provider has to be linked** — `Settings.Provider := 'claude'` with no
  `HelpChatAI.Provider.Claude` in the uses answers "the provider is not available in this
  application", which is the registration rule seen from the user's side;
  **the keyword of the form wins over the one of the tab** when the focus is outside the
  `TPageControl` (the side menu is), so the form declares none and `OnGetContext` forces the
  active page — otherwise every F1 describes the window;
  **an action handler runs on the main thread and must return at once**: it opens the draft
  with `Show`, never `ShowModal`, or the worker waiting for it times out, and the filling
  lives in `TDraftProposalForm.PrepareDraft`, with the form that owns those controls;
  **`Help/help-index.json` is versioned because the application reads it** — change a page of
  the manual and rebuild it with
  `HelpIndexBuilder --source="CRM Demo\Help" --out="CRM Demo\Help\help-index.json"
  --toc=Index.md --url-ext=`, or the assistant keeps answering from the old text.
  The key is in nothing of the demo: it comes from `%APPDATA%\HelpChatAI\helpchatai.json`,
  the shared file. And `Help/Assistant.md` documents the assistant itself: when its behaviour
  changes, that page and the FAQ change with it — it already said "nothing is sent anywhere"
  once, which stopped being true the moment the provider became `claude`.
- **Defaults live once** in `HelpChatAI.Settings` constants (`HELPCHAT_DEF_*`). Settings also
  load/save as JSON (`helpchatai.json`: app file next to the exe, then per-user file in
  `%APPDATA%\<Exe>`); a new property must be added to `Assign`, `LoadFromJSON`, `SaveToJSON`
  and the round-trip test. **Never commit a `helpchatai.json` containing a key** (it is svn-ignored).
- Localized strings: add the id to `THelpChatMsgId` and both `resourcestring` tables in
  `HelpChatAI.Messages` (a test fails if one language is missing).

## Conventions

- Ethea header block on every unit; `/// <summary>` XML doc on public types and members.
- Prefix: units `HelpChatAI.*`, types `THelpChat*` / `IHelpChat*`, constants `HELPCHAT_*`,
  CSS classes `hc-chat-*`. Locals `L*`, parameters `A*`, fields `F*`.
- New test fixtures go in `Test/source/HelpChatAI.Tests.*.pas` and are added to the `.dpr` uses.
- `Ext/` and `Setup/InnoSetupScripts` are other repositories (svn:externals), not files of
  this one: a change belongs there, as its own commit, and reaches every Ethea project that
  uses them — so it is made generic and, where it changes behaviour, kept behind a define.
