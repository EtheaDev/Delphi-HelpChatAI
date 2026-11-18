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
Ext/DCPcrypt/            svn:external of ^/../DCPcrypt/trunk, used by the CRM demo alone
                         (uAppSecret) and by no package of the library: it is what the
                         example of an encrypted API key is built with
resources/               panel.html / panel.css / panel.js / htmx.min.js, print.css and the two
                         bands print-header.html / print-footer.html, HelpChatAI.Assistant.rc and
                         HelpChatAI.Splash.rc -> Tools\BuildResources.cmd
Redist/WebView2/         WebView2Loader.dll x86/x64 (Microsoft, NuGet 1.0.3296.44), copied next to demos
packages/Delphi13/       HelpChatAI, HelpChatAIServer, HelpChatAIVcl, HelpChatAIFmx (runtime), dclHelpChatAIVcl,
                         dclHelpChatAIFmx (design) + groupproj
packages/Delphi12/       the same six, for Delphi 12
packages/Delphi11/, packages/Delphi10.4/   the four VCL and engine ones (FMX is Delphi 12+)
packages/*.ps1           the command-line builds, shaped like those of the MarkdownProcessor:
                         BuildPackages.ps1 (one project, one version), BuildAllPackages.ps1
                         (every package in order, MarkdownProcessor first through its own
                         BuildPackages.ps1, -DelphiVersion D10.4..D13 or All, a summary
                         table), the four BuildAllPackagesD<ver>.ps1 wrappers, and
                         BuildAndTestD13.ps1 (packages, tests, both demos, server, tool,
                         then the test run: the check before a commit)
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
                         comes from; providers/ (lobe-icons) and flags/ (circle-flags, one
                         per language: gb for English, pt for Portuguese) are the SVGs of
                         HelpChatAI.Providers.res
Setup/                   Setup.iss, BuildSetup.bat and HelpChatSetup.ico, the icon of the
                         installer and of the uninstaller; InnoSetupScripts is an svn:external
README.htm               README.md as HTML, installed and linked as ReadMe in the Start menu:
                         the maintainer regenerates it after reviewing README.md, so an
                         agent never edits it - change README.md and say the HTML is due
InternalDocs/            design notes and analyses, not published: the agent that syncs GitHub
                         ignores this folder (Configuration-Profiles.md: several assistants in
                         one application, the design shipped in 1.7.0). Slide/ holds the
                         conference decks (ITDevCon: slides.md, part1/part2.md, build_slides),
                         moved here from Docs/ on purpose: the slides are never published.
                         Anything that must stay off GitHub goes under InternalDocs, never in
                         a new top-level folder
Test/source, Test/Delphi13, Test/data         DUnitX suite and fixtures
"CRM Demo"/              the sample application, in two frameworks: the Windows 10 CRM demo
                         of Embarcadero with HelpChatAI in it, and one manual for both in
                         Help/*.md (plus Help/Images and the help-index.json the applications
                         read)
"CRM Demo"/common/       uDataMod (the FireDAC data module, the database and every query),
                         uProposalReport (the invoice as HTML, and the parser of the
                         line items the model writes) and uAppSecret (the API key
                         encrypted with DCPcrypt), shared by the two demos.
                         Framework-neutral on purpose - the FireDAC wait cursor
                         (FireDAC.VCLUI.Wait / .FMXUI.Wait) is the one thing that is not,
                         so it lives in each .dpr instead. uHelpChatLog writes the log
                         of both demos with Logify: Logify.pas and Logify.Adapter.Files.pas
                         are a copy of github.com/delphi-blocks/Logify (MIT,
                         Logify.LICENSE.txt), changed only by a TInterlockedHelper under
                         {$IF CompilerVersion <= 35} (Exchange and CompareExchange on a
                         Boolean, which the TInterlocked of 10.4 and 11 lacks), suggested
                         by the author of Logify. A copy, not an external: realign it by hand
"CRM Demo"/VCL/          VCL_CRMDemo: project/ and source/ (uMainForm, uLeads, uProposal,
                         uDraftProposal, uLicenseActivation). Delphi 10.4 to 13
"CRM Demo"/FMX/          FMX_CRMDemo: project/ and source/ (uMainFormFmx, uLeadsFmx,
                         uProposalFmx, uDraftProposalFmx, uLicenseActivationFmx).
                         Delphi 12 and 13 only, because
                         TFmxHelpChatAI starts there
"CRM Demo"/*/project/*_MultiAgent.dproj   the multi-assistant edition of each demo: the
                         same sources with MULTIAGENT defined, plus uMultiAgent(Fmx).pas,
                         its own exe and dcu\<Framework>-MultiAgent
"CRM Demo"/bin/<Platform>    both executables, next to the one WebView2Loader.dll they share
"CRM Demo"/dcu/<Framework>/<Platform>   svn-ignored build output, one tree per framework so
                         the two projects cannot pick up each other's units. No Delphi
                         version in the path - so after opening a demo with a different
                         Delphi, Build and not Compile
"CRM Demo"/Build*.ps1    BuildDemo.ps1 (one framework, one version, -Edition Single|MultiAgent),
                         BuildAllDemos.ps1 (the matrix, both editions by default, with a
                         summary table) and the four per-version wrappers, same shape as
                         StyledComponents/Demos. -Framework VCL|FMX everywhere; FMX on 10.4
                         and 11 is reported N/A, not SKIP
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

All of it in one go, the MarkdownProcessor included: `packages\BuildAndTestD13.ps1`
(`-Platform Win64`, `-Config Release`).

Tests run without network. The one Claude test that would need a key skips itself when
`ANTHROPIC_API_KEY` is set.

**Encoding and line endings, uniform across the repository:** `.pas`, `.dpr`, `.dpk` and `.inc`
are UTF-8 **with BOM** and **CRLF**; `.dfm` and `.fmx` are **ANSI** (no BOM) and CRLF, which is
what the IDE writes; `.dproj` and `.groupproj` are CRLF too, for the same reason. Without the
BOM `dcc32` reads a source as ANSI and every non-ASCII literal (Italian strings, test fixtures)
is silently corrupted. After creating a `.pas`/`.dpr`/`.dpk`, add the BOM
(`packages\BuildAndTestD13.ps1` does not do it):
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
  means editing all four `.dpk`/`.dproj` pairs. `packages/BuildAllPackages.ps1` builds every
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
  there), and the first step of `packages/BuildAllPackages.ps1`. An
  application that compiles the units instead of using the packages needs
  `Ext\MarkdownProcessor\source` on its search path — that is the one line that changed in the
  demos, the tests and the server. Two traps, both of which cost a build: every package of
  the library is never-build (`{$IMPLICITBUILD OFF}` in the `.dpk`,
  `<DCC_OutputNeverBuildDcps>true` in the base group of the `.dproj`, all four versions),
  and a never-build package may only require never-build ones - so the MarkdownProcessor
  package of the same version must be one too, or E2466 "Never-build package requires
  always-build package". Both write their DCP into the shared `Dcp` folder of the IDE, so
  an `Ext\` external left behind (still ON) overwrites a good DCP at the next build:
  `svn update` from the root, which updates the externals too; and the BPL cannot be
  rewritten while an IDE has it loaded. The
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
  conversation key of an engine (`u:<user>` / `s:<session>`): one store, one worker pool,
  one index for everybody who asks that assistant. **The remote server has one engine per
  profile**, like an application: the transport posts the `Profile` of the component with
  `POST /session`, and the first session of a profile creates its engine from the settings
  `OnProfileSettings` fills (a copy of the default engine's with `Profile` set; the console
  server reloads `helpchatai-server.json`, whose `Profiles` are the only ones it accepts). A
  profile the handler does not accept, or any without a handler, gets the default engine:
  a client must never make the server create engines by naming profiles. The session carries
  its engine (`THelpChatServerSession.Engine`, nil = the server's), so every endpoint asks
  `EngineOf(ASession)`, never `Engine` - which is the default assistant's. An anonymous conversation
  (`s:<session id>`) is never written to disk; `HelpChatKeyToFileName` adds 24 hex digits
  of SHA-256 to the name of a key it had to cut, the 32-bit hash being few for ids a
  client chooses. The same key on two
  engines is two conversations: `KeyInUse` compares both, and the file of a profile's
  conversation carries the profile in its name. New endpoint = `HandleApi` in the base, and `HELPCHAT_API_*` in
  `HelpChatAI.Panel` where the contract lives.
- **The remote server decides a few things before it asks who is there.** Indy reads the
  whole body of a request before `HandleCommand` runs, so the base refuses from the headers
  (`OnHeadersAvailable`/`OnHeadersBlocked`, 413): a body over `MaxBodyBytes(AUri)` -
  `HELPCHAT_SERVER_MAX_BODY_BYTES`, or `Attachments.MaxSizeKB` plus a margin for
  `/api/attach` - and one that declares no length. `MaxConnections` (256 on the remote
  server). `ErrorTextFor` is what a 500 says: the message of the exception on the local
  server, a generic sentence on the remote one, which logs the rest. A key or a token is
  compared with `HelpChatSameSecret`, never with `=`.
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
- **The profile is the assistant; the panel switches models.** Since 1.7 three names for three
  things (design and log: `InternalDocs/Configuration-Profiles.md`): `AssistantName` is what the
  user reads ("Giulio"), `Profile` (component, copied to `Settings.Profile`, never read from a
  file) is the key of its section under `"Profiles"` in the configuration, `Models` is the
  drop-down of the panel. `THelpChatSettings.LoadFromJSON` applies the root of a file and then,
  on top, `Profiles.<Profile>` with the same keys (`LoadFromJSONObject`); in a profile a
  `Models` entry may be a bare name, a model of the catalogue already loaded. The catalogue
  is kept apart from the list (`FCatalogue`: the list of the last root that had one, else the
  component's own): a profile narrows `Models` to what it offers, and the profile of the
  file read next must still be able to name another model of the same catalogue - with the
  list as the catalogue, that raised "not a model of the configuration". `Expertise` (the
  field it knows beyond the manual), `Instructions` (what it does) and `SystemPrompt`
  (replaces the built-in rules) live at the root, not in a provider section: switching model
  must not change the expert, so `ResolveSystemPrompt` is on the settings. **`Expertise` is
  not a kind of `Instructions`**: it goes first, before the rules, and brings
  `HELPCHAT_MODEL_DEF_EXPERTISE_RULE` (explain concepts as general practice, procedures only
  from the excerpts, decline outside the field) - measured in `Test\LLMBench`
  (`--suite=expertise`, results `llm-bench-expertise-v1/v2.md`): a field declared without
  that rule changed nothing, because "answer ONLY from the excerpts" wins; with it the
  capable models answered 3-5 more of 12 questions the manual does not cover, inventing no
  more. Order: field, rules, rule, `Instructions`. The conversation, state and window files carry the profile in their name
  (`ProfileFileName`), the default assistant keeping today's; letters and digits of any
  alphabet stay in the name (ASCII only, two Cyrillic profiles shared one file), and a
  relative `ConversationFile` is resolved against the executable, like `DocIndexFile`. The keys of 1.6 (`Assistants`,
  `Assistant`, `<Provider>.SystemPrompt`) raise `EHelpChatConfigError` instead of being ignored:
  a drop-down empty for no visible reason is worse than an error that names the new key.
- **A model is a name over a provider, and the list lives in the engine.**
  `Settings.Models` (`THelpChatModelEntry`: Name, Provider, Model, BaseUrl, ApiKey,
  Icon) is what the user may switch between; `Settings.SelectedModel` is the one in use. One per
  provider would not do: three local models on one Ollama are three entries on `openai`. The
  sections keep the configuration as the file had it: `ApplyModel` sets `Provider` and
  puts model, endpoint and key as **overrides** on the section (`SetOverrides`, read by
  `ResolveModel`, `NormalizedBaseUrl`, `RawApiKey`, copied by `Assign`, never saved), so a
  switch is reversible and the Object Inspector never shows a value the panel wrote. A
  provider must therefore read `ResolveModel`, never `Model`. `Provider` itself is overridden
  the same way: while a model that names a provider is in use it reads as that one, and
  `ConfiguredProvider` is what the configuration said - what a model with no provider of its
  own goes back to, what `ResolveModels` describes such a model with, and what `SaveToJSON`
  writes (writing `Provider`, from code or from a file, sets the configured one again).
  With no list, `Provider` is the
  one implicit model and nothing can be switched (`CanSelectModel`). The engine applies
  the active one in `Start` - before the index reads `GroundingMaxChars` - and remembers the
  choice in `helpchatai-state[-<Profile>].json` next to the conversation file, never in a configuration
  file. The page asks `GET /api/assistants` the way it asks for the history, posts
  `/api/assistant/select`, and a remote server answers 403 to that: the engine there is
  everybody's. A switch that succeeds raises the UI command `model` (`HELPCHAT_UI_MODEL`),
  as the language does, and the components turn it into `OnModelChanged` (so does their
  `SelectModel`): what the application reads then is `RunSettings`, public for that reason -
  the component's own `Settings` never sees what the user picked. The icon is an id of `HelpChatAI.Icons` (lobe-icons SVG in
  `HelpChatAI.Providers.res`, the fourth versioned `.res`, listed in `Setup.iss` by name like
  the others), deduced by `HelpChatProviderIconFor` from the model name first, the endpoint
  second, the provider last - a `gemma4` served by `openai` shows Gemma - and served inline in
  the JSON so that a monochrome icon (`currentColor`) follows the theme; `docsearch` and `stub`
  get none, and the page shows no badge for a lone model without one. `ApplyModel` and
  `Assign` share a `TMonitor` lock: the switch arrives on an HTTP thread while a worker
  snapshots the settings. **The panel offers only the models that could answer**:
  `THelpChatEngine.Models` (what `GET /api/assistants` and the components' `Models` list)
  drops every entry for which `HelpChatModelIsConfigured` (`HelpChatAI.Provider`: a copy of
  the settings, `ApplyModel`, the provider's `ConfigurationIssue`) says no - `claude` and
  `gemini` without a key, `openai` on api.openai.com without one, `docsearch` without an
  index - except the one in use, which is always listed. `Start` never picks such a model
  while another of the list can answer (the first that can, not remembered). `SelectModel`
  still accepts any name of the list, and `ResolveModels` and the configuration check still
  see them all. The page asks for the list again on `focus`, because the application may
  register a key while it is open. So a catalogue may name every service an application
  supports: each user sees the ones they have a key for.
- **The language is the engine's too, and the user picks it the same way.** Six of them
  (`THelpChatLanguage`, new members **at the end**: a DFM stores the identifier, a
  configuration file the code). `Settings.Language` is the language of the chat - the strings
  of the panel and of the engine, and the language the model is told to reply in, **whatever
  language the question is in** (`LanguageRule`: until 1.12 the model followed a user who
  clearly wrote in another language; now the user who wants Italian answers picks Italian);
  `Settings.Languages` what the flag of the panel offers (fewer than two = no flag);
  `Settings.ResolveLanguage` the concrete one among them, never `hclAuto` (English when the
  configured or OS language is not offered, else the first offered). All three live under
  `Settings` and in `helpchatai.json`, not on the components, for the reason `Provider`
  does. `THelpChatEngine.SelectLanguage` **writes `Settings.Language`** - unlike an assistant,
  which is an override - because every reader of the language reads it there (the snapshot of
  a request, a dialog of the component, the page) - and sets `HelpChatDefaultLanguage`, which
  is what every `hclAuto` of the process resolves to; `Start` sets it from `ResolveLanguage`.
  The choice goes to `helpchatai-state.json` with the assistant (`SaveState` writes both, so
  one never loses the other), **only once the user made one** (`FChosenLanguage`,
  `FChosenModel`): a state file must not freeze a language - or a model - nobody picked.
  Writing the model in use froze the one the start had fallen back to, the first time the
  user picked a language. The page asks `GET /api/languages` (code,
  native name, English name, the flag as inline SVG from `HelpChatFlagSvg`), posts
  `/api/language/select` and **reloads itself**, because its labels are written into it at
  render time; the local server then raises the UI command `language` (`HELPCHAT_UI_LANGUAGE`)
  so that the component rewrites the captions it owns (window, bubble hint). Which is also why
  the components send `AssistantName` **unresolved** to the session: an empty one must be
  resolved by `RenderPage` in the language the page is rendered in. A remote server answers
  403, as for the assistant. `DocLanguage` adds `HELPCHAT_MODEL_DEF_DOC_LANGUAGE_RULE` to the
  system prompt when the manual is in another language than the chat: explain in the user's,
  keep the names of screens and buttons as the manual spells them - a translated caption is
  one the user cannot find. The search is lexical, so with `TranslateSearch` (default on) and a
  `DocLanguage` other than the chat the **model in use translates the question first**
  (`THelpChatProviderBase.SearchTerms` -> the virtual `CompleteText`, one short request with
  `SearchTermsPrompt` and the previous question for a follow-up; claude, openai, gemini
  override it, `stub`/`docsearch` return ''): the runner wraps the retriever in
  `THelpChatTranslatedRetriever`, which searches question + terms **without the hint** for
  that question - the prompt and the source line use it unaware - and remembers the terms
  per conversation key for `/prompt`. A failed request costs the terms, never the reply.
  Measured in `Test/LLMBench/results/translation-v1.md`: 21 Italian questions, the right page
  among the 3 from 12 to 20 (Haiku, no hint; with the hint 18); `--terms=` checks the request
  against the real services (~0.7 s; OpenAI Chat needs `reasoning_effort: none` and a
  150-token cap, or a local gemma4 spends the cap thinking and qwen3-coder loops).
  Embeddings are still measured in `EMBEDDINGS.md`.
- **The log is written through the settings, so a request logs through its snapshot.**
  `HelpChatAI.Log` (RTL) holds the entry (`THelpChatLogEntry`: level, severity, category,
  profile, conversation, reply id, thread, text, optional JSON `Data`), the levels
  (`llNone`, `llInfo` default, `llDetail`, `llDebug`: cumulative) and `HelpChatDispatchLog`,
  which serializes every entry of the process and swallows what a handler raises.
  `THelpChatSettings` carries `LogLevel` (published, in JSON "none".."debug", profiles
  too), the handler (`SetLogHandler`, the components' `OnLogEvent`) and a context
  (`SetLogContext`: the runner sets the conversation and the reply id on the snapshot of a
  request, so the provider, the search and the actions log with them unaware); `Assign`
  copies all three. Write `Settings.Log(level, severity, category, text)`, and ask
  `Logs(level)` before building a text that costs something. **The level is not the
  severity**: an error of the service is an `llInfo` entry with `lsError`. **llInfo never
  carries what the user wrote**; `llDetail` the whole question and the arguments of the
  actions; `llDebug` the reply, the prompt and the request bodies (`LogPost`, in `Data`,
  cut at `HELPCHAT_LOG_BODY_CHARS`) - **never the headers**, which carry the key, and the
  settings JSON with every secret masked (`MaskedSettingsJson`). The event runs on the
  thread that wrote the entry (decided with the user: lossless, fit for a file). The
  shared engine of a profile gets a proxy handler (`TSharedEngine.Log`) that hands the
  entry to the first holder with a handler, copied out of `GSharedLock` and called
  outside it - nothing may log while holding that lock. `HelpChatOnLog` gets every entry
  too, for code with no component; the lines of `THelpChatRemoteServer.OnLog` go there.
  Commands the page answers by itself reach the log through `POST /api/command/log`. The
  remote transport logs through `LogSettings` (the component's). Inside the IDE the handler
  is not called (`HelpChatDesignTime`). Page: `Logging`.
- **A line that starts with "/" is a command, and the set decides which.**
  `HelpChatAI.Commands` (RTL) owns `THelpChatCommand` and the set
  `THelpChatCommands`; `EnabledCommands` on both components is that set,
  `HELPCHAT_DEF_COMMANDS` by default (everything but `prompt`, which shows the context of a
  request, and `run`, which runs an action by hand). It travels like the assistant name,
  through `IHelpChatTransport.SetEnabledCommands` into the session, and the session is what
  enforces it: `GET /api/commands` lists only the enabled ones, `POST /api/command` answers
  403 to the rest, and a remote session starts without `run` (its actions are not here). The
  page intercepts the line in `htmx:configRequest` and never sends it to the model; a
  command of `HELPCHAT_COMMANDS_PAGE` is answered by `panel.js` (a button from the keyboard,
  the switch of assistant, the timing it measured), the others by `HelpChatRunCommand` with
  the HTML of a system bubble - shown, never stored, never in the next prompt. Adding one =
  a member of the enumeration, its name in `CommandNames`, its description in every table
  of `HelpChatAI.Messages`, and a case in `HelpChatRunCommand` or a branch in `panel.js`
  with the member in `HELPCHAT_COMMANDS_PAGE`; nothing else reads the list by name.
  `/run` goes through `IHelpChatActionInvoker.Invoke` like the model does, confirmation
  included, so an HTTP thread waits while the main thread runs the handler.
  A remote session starts without `check` as well: it prints the folders, the files and the
  missing keys of the machine the engine runs on, which there is the server.
  **Every answer starts with its heading** - "Available actions (/actions):" -
  (`HelpChatCommandHeading`, a title per command in `HelpChatAI.Messages`), in the engine and
  in the page alike. **Whatever the user can do in the panel, code can do on the component**:
  `ExecuteCommand` (any command, enabled or not: the page posts `host=1`, which only
  `THelpChatLocalServer` honours through `HostMayRunAnyCommand`), `ExplainCommand` (the same
  answer as plain text, no panel; never runs `run`, which would wait for the calling main
  thread), `ClearConversation`, `Models`/`SelectModel`, `RetryLastQuestion`,
  `SaveConversationPdf`, `CopyLastAnswer`, `AttachFile`. A new button or command gets its method
  on both components in the same change.
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
  the panel origin plus `Access-Control-Allow-Private-Network`). `HC.hostCommands = false` means nobody is
  listening. The page has no ✕ of its own: the window of the chat has one, and in a
  `Container` the application decides; Escape still posts `close`, which only a listening
  host honours.
- **Anything the page calls must be in its own CSP.** `panel.html` allows `connect-src 'self'
  {{API_BASE}} {{UI_BASE}}` and nothing else: a call to an origin the policy does not name is
  dropped by the browser before it reaches the network — no request, no error, no clue. A new
  outbound call = a new placeholder there and in `THelpChatPanel.RenderPage`.
- **A remote transport connects on first use, not on Active.** An application whose help server
  is down or unreachable must still start; the failure belongs to the moment the user asks for
  help. `IsActive` means "ready", `HasSession` means "a conversation is open". **A session
  the server expired is opened again, not kept**: every call of the session goes through
  `SessionCall`, a 403 opens a new session and repeats the call, and `GetPanelUrl` checks a
  session that was quiet for `HELPCHAT_REMOTE_CHECK_SECONDS`. The URL then carries another
  token, so the components ask `GetPanelUrl` at every opening and reload the page when it
  differs from the one loaded. On the server a session that ends is **retired, not freed**
  (`Retire`/`PurgeRetired`, `HELPCHAT_REMOTE_RETIRE_SECONDS`): a request that found it a
  moment earlier is using it outside the lock.
- **A page that is refused asks to be loaded again.** A 403 to a question or to the poll
  of a reply is a session the server no longer has: `panel.js` posts the UI command
  `reload` (`HELPCHAT_UI_RELOAD`, once per page) through the host channel, the remote
  transport forgets when it last heard from the server (`ChannelCommand`) and the component
  asks `GetPanelUrl` again (`ReloadPanel`), loading the page only when the URL changed -
  the select endpoints answer 403 too, on purpose, and must not start a loop. A session
  that ended is marked (`THelpChatServerSession.Ended`: `/api/send` answers 403), and what
  a request still left in memory after the last session of a conversation is cleared when
  that user comes back, before the file is read.
- **What only the page knows survives its reload in `localStorage`.** The question being
  written, the open documentation page with its history and the timing of `/stats`
  (`saveState`/`restoreState` in `panel.js`, one key, `hc-state`): written a moment after
  each change and on `pagehide` - a window recreated by a style change fires nothing -
  and read back only when the token stored with them is the page's, so another run of the
  application finds nothing. Not `sessionStorage`: a recreated window is a new browser.
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
  The drop-down lists of the header (models, languages: `openList`/`listKeys` in `panel.js`)
  take the arrows, Home/End, Enter and Escape, and closing one gives the caret back too. The
  header has a `z-index` above the footer's, or a long list opens under it; its height is
  capped to the bottom of the window and it scrolls.
- **Screen context is native.** `TVclHelpChatAI.BuildContext` computes it on the main thread and
  calls `Transport.SetContext`; the page never sends it (a remote client may, as override).
  Deepest `HelpKeyword`/`HelpContext` wins (focused control upwards, form last); the active
  `TTabSheet` caption is the screen label.
- **F1 goes through the Delphi help system (VCL).** `THelpChatHelpViewer` (`HelpChatAI.HelpViewer`,
  RTL: ICustomHelpViewer + IExtendedHelpViewer registered via `System.HelpIntfs.RegisterViewer`)
  receives keyword and context requests; the `TApplicationEvents.OnMessage` F1 handler only
  steps in when no control in the chain declares help, ignores key auto-repeat, and
  `OpenWithQuestion` debounces the same question within 1.5 s. Do not hook `Application.OnHelp`.
- **F1 belongs to the application, so it has one owner per process.** Several assistants may be
  active at once, each on its own form (`ResolveHostForm`: `HostForm`, else the form that owns
  the component - through a frame -, else the main form; a `HostForm` that was destroyed
  leaves the assistant with none, `FHostGone`, until another is assigned). The process-wide half lives in a
  coordinator in the implementation of each component unit (`TVclHelpChatCoordinator`,
  `TFmxHelpChatCoordinator`), created by the first active assistant and freed with the last:
  **one** `TApplicationEvents` and **one** help viewer (implementing `IHelpChatHelpTarget`), and
  the active assistants with the most recently active first. With one per component, two
  assistants answered the same key and the help manager had two viewers to choose between. F1
  goes to the assistant of the active form, else to the one whose form was active last
  (`CurrentAssistant`); a help request goes to the assistant of the form of the focused
  control. The VCL notices activation by comparing `Screen.ActiveCustomForm` on every message
  (no form is hooked) - which only sees what a dispatched message or an idle turn shows: two
  forms activated by code with nothing posted in between, and the first was never noticed
  (a test that passed or failed with the timing showed it). So when the active form hosts no
  assistant the coordinator asks `Screen.CustomForms` first (`MostRecentItem`): the VCL keeps
  it with the form focused last first, while the focus moves, and the tracked list is only
  the fallback. FMX subscribes to `TFormActivateMessage`, and the `OnKeyDown` of each host
  form is chained **once per form**, by a `TFmxFormKeyHook` the assistants of that form share
  (`HandleKeyDown` forwarding to the coordinator); the VCL bubbles do the same with the
  `WindowProc` of their parent (`TBubbleParentHook`). Each assistant used to chain by itself
  and keep the handler it found: with two on one form the one that left first could not
  unhook, and stayed in the chain of the other as a method of a freed object. A hook that
  cannot be removed (somebody hooked after it) stays, passing things on, until its form goes.
  And **a free notification is never removed** for a form or a container: it is not counted,
  the same form is usually `HostForm`, hooked form and container at once, and removing it
  for one cancelled it for the others. The
  viewer is registered only while some assistant has `RegisterHelpViewer`, because the
  design-time preview runs a component inside the IDE. The coordinator never frees its
  `TApplicationEvents` from inside its own handler: it waits for the next idle turn.
  `HelpChatAI.Tests.Coordinator` activates real forms to check all of it.
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
  own window's only; an application container persists itself. The one form with a DFM is
  the confirmation dialog (`Vcl.HelpChatAI.ConfirmDialog`, below); everything else visible
  is HTML.
- **The bubble has a window, and it fights to stay on top.** It used to be a `TSpeedButton`,
  and in a real application it vanished: a `TGraphicControl` has no window of its own, the VCL
  paints it on its parent's canvas and keeps it *below* every windowed sibling, so a grid or a
  page control covering the corner hid it (`BringToFront` only reorders the graphic ones).
  `TVclHelpChatAIBubble` (`Vcl.HelpChatAI.Bubble`) is a `TCustomControl`, and a **layered** child
  window from Windows 8 on (`WS_EX_LAYERED`, which needs the Windows 8 entry that Delphi's
  `default_app.manifest` carries): GDI+ draws it antialiased into a premultiplied DIB that
  `UpdateLayeredWindow` pushes, so the edge blends with whatever lies under it and a click on a
  transparent corner goes through. Such a window gets no `WM_PAINT`: `Invalidate` is overridden
  to push again. Where that is refused - the designer, Windows 7, no manifest - it falls back to
  `SetWindowRgn` with an ellipse, the drawing inside still GDI+ but the rim hard-clipped. The
  icon keeps its alpha through `HelpChatIconBitmap` (the white/black trick below). It is raised with `SetWindowPos(HWND_TOP)`, and it
  hooks its parent's `WindowProc` to post itself `HELPCHAT_CM_BRINGTOTOP` whenever the host
  adds a child or is resized (`CM_CONTROLLISTCHANGE`, `WM_PARENTNOTIFY`, `WM_SIZE`). The hook
  is one per parent, shared by its bubbles (see the coordinator rule), and is restored only
  while the chain is still ours. FMX needs none of this: there everything is
  drawn, so a control cannot hide another. **The user may drag it** (`BubbleDraggable`; the
  control's own `Draggable`/`OnMoved` in the VCL, mouse events on the `TCircle` with
  `AutoCapture` in FMX): a press is a click until it moves past the drag threshold, and the
  click that ends a drag is swallowed (the flag is reset at the next press, so the order of
  `Click` and `MouseUp` does not matter). Dropped, it is anchored to the nearest corner -
  bounds first, anchors after, since both frameworks take the anchor rules from where the
  control is - and remembered with `RememberPanelPosition` per class of host form.
  `HelpChatAI.UiState` (RTL, engine) holds that geometry (`THelpChatBubblePlace`: corner and
  distances at 96 DPI, kept inside a smaller form) and the file of the UI state, written one
  key at a time (`HelpChatUiStateWrite`): `"panel"` and `"bubbles"` live in the same
  `helpchatai-ui[-Profile].json`, and the old writer that replaced the whole file would have
  made each forget the other.
  **The bubble of the main form may float** (`BubbleStayOnTop`, VCL, main form only): an
  application whose secondary forms open maximized hid it. Then it is no child at all but a
  `WS_POPUP` owned by the main form (`FloatOver`: `ParentWindow` is the owner,
  `WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE`), placed in screen coordinates
  whenever the host moves, sizes or recreates its window (the host hook calls `FollowHost`,
  which fires `OnHostChanged`), `HWND_TOPMOST` while the application is active and below the
  foreground window when it is not (`WM_ACTIVATEAPP`). `ShowModal` disables every window of
  the thread, so `WM_ENABLE` False posts `HELPCHAT_CM_REENABLE` and the bubble stays
  clickable; `WM_MOUSEACTIVATE` answers `MA_NOACTIVATE`. Owned windows hide with a minimized
  owner by themselves. It may be dragged anywhere on the work area of the monitor of the
  form, outside the form too: `FromBounds`/`ToPosition` take an `AOutside` (negative
  distances, read back from the file down to -100000) and the screen position is always
  clamped to the work area - the first version clamped to the form widened by one bubble,
  which on a maximized form let it go under the taskbar for good. the DUnitX suite shows no
  window, so this was checked by a harness that drives real forms (modal, maximized,
  minimized, a drag by `WM_MOUSEMOVE`). **FMX has it on Windows** (`FMX.HelpChatAI.Bubble`,
  `TFmxHelpChatBubbleForm`): the `TCircle` fills a borderless form with `Transparency` (a
  layered window), owned through `GWLP_HWNDPARENT` - `ParentForm` is read-only and comes from
  a `Parent` that is a form, which would make the bubble a child object of the main form. Its
  geometry is Win32 pixels throughout (cursor, client rect of the host, work area, DPI): the
  position of a screen in dp is not defined on Windows with mixed scales. Three FireMonkey
  traps, each found by its harness: `Show` calls `Activate` after `ShowWindow(SW_SHOWNORMAL)`,
  which activates whatever the styles say - `Activate` is overridden empty (virtual from
  Delphi 13; on 12 `WM_ACTIVATE` is swallowed and the activation posted back); minimizing the
  main form minimizes every visible form through `DefWindowProc(SC_MINIMIZE)`, which no hook
  sees, so showing the bubble again is `SW_SHOWNOACTIVATE`, which restores it too; and a
  recreated host window would destroy the window it owns, so `TBeforeDestroyFormHandle` frees
  the bubble and `TAfterCreateFormHandle` creates it again. The FMX skills skip the bubble
  form. In a FireMonkey harness `Application.CreateForm` creates nothing until `Run`:
  `RealCreateForms` first.
- **The icon follows the Delphi contract, and ships its own fallback.** `Images`, `ImageIndex`
  and `ImageName` live on the bubble and are mirrored by `TVclHelpChatAI`: an image list of the
  application wins. With none, the bubble builds a `TVirtualImageList` over
  `HelpChatAssistantIcons`, one `TImageCollection` per process filled from
  `source/HelpChatAI.Assistant.res` (PNG, nine sizes per icon), so the DPI of the window asks for
  the size it needs. Ten icons, each a member of `THelpChatAssistantIcon` whose ordinal is its
  `ImageIndex` in the built-in list, its name in `HELPCHAT_ICON_NAMES` and a `HELPCHAT_ICON_*`
  constant (re-declared in `Vcl.HelpChatAI.Bubble`). Adding an icon = the SVG in `Images\`,
  its PNGs at the nine sizes of `HELPCHAT_ICON_SIZES` (plus 256 and 512, like the others) with
  `D:\ETHEA\SVGShellExtensions\Bin64\SVGToPNG.exe convert -in:<svg> -size:16,18,...
  -out:Images`, the entries in `resources/HelpChatAI.Assistant.rc`, `Tools\BuildResources.cmd`,
  then a member **at the end** of the enumeration with its name and constant - everything else
  (bubble, FireMonkey, property editors, configuration editor) reads
  `HelpChatAssistantIconNames`. The image lists come from `vclwinx`, which the VCL package requires.
  **`ImageIndex` and `ImageName` are kept in step** as the VCL controls do it
  (StyledComponents' `TStyledButtonRender` is the model): setting the index takes the name of
  that image, setting the name goes through `TCustomImageList.CheckIndexAndName` (the name
  wins, the index follows), and the same happens when `Images` is assigned, when the list
  changes (a `TChangeLink`, on the component too) and once in `Loaded` - never while the
  form file is read, since the list may come after the index. With no list of the
  application the built-in collection plays the list. One routine, `HelpChatSyncIconIndex`
  in `Vcl.HelpChatAI.Bubble`, for the component and the bubble. `ImageIndex` is `default 0`:
  the first built-in icon is the default assistant, and the field already started at 0
  while the property declared -1, so a 0 went into form files for nothing.
- **A modal form owns the chat while it is up.** Windows keeps a modal window above every
  window that shares its owner, and `ShowModal` calls `DisableTaskWindows`: a chat window
  owned by the host form ends up *behind* the modal one and disabled with it, which is not
  what the user asked for by pressing F1 on that very form. `UpdateOwnFormOwner`, called
  before showing the own window, makes the active modal form its `PopupParent` (and
  re-enables it); with no modal form the owner goes back to the host. Changing `PopupParent`
  recreates the window and reloads the page, so it is done only when the owner really
  changes. **`OnModalEnd` fires only when the last modal form closes**, so a dialog opened by
  another dialog took the chat with it: `TVclHelpChatHideWatch` listens to the window
  procedure of the modal owner and tells when it stops showing - which is how `ShowModal`
  ends, whoever frees the form and however soon - and `ModalOwnerHidden` hands the window to
  the modal form still up, else to the host. The watch is let go from inside its own call
  (the depth counter of the bubble hook, for the same reason).
  **And it must be undone before the modal form dies**: Windows destroys the
  windows a window owns together with it, so without `AppModalEnd` the chat disappears with
  the form the user just closed. That handler cannot ask `fsModal`, because `ShowModal`
  clears it one line before calling `Application.ModalFinished` — it asks whether the owner
  is still the host. None of this applies to a `Container` of the application: there the
  chat is a control inside a form of theirs, and that form's own modality rules apply.
- **VCL style change recreates windows.** `TStyleManager.SetStyle` posts `CM_CUSTOMSTYLECHANGED`
  to each visible form; `TCustomForm` recreates its window (the WebView reloads the page).
  `TVclHelpChatAI.AppMessage` catches the posted message first and stores the theme in the
  transport, so the reload asks for a page that already has it; the control's `CM_STYLECHANGED`
  and `OnPageReady` re-apply it via script.
- **Colours are CSS variables only.** `panel.css` never hard-codes a colour outside the `--hc-*`
  definitions; a `THelpChatTheme` (RTL, `HelpChatAI.Theme`) sets them, rendered as `:root{}` at
  page load and pushed with `window.hcApplyTheme` at runtime. Per-framework producers:
  `Vcl.HelpChatAI.Theme` (table of VCL styles + StyleServices fallback); FMX has no unit of
  its own, `ThemeMode` in `FMX.HelpChatAI` picks the page defaults or a built-in light or dark
  theme, and `OnGetTheme` is how a custom style gets its colours. Adding a
  variable = panel.css + `ForEachVariable` in HelpChatAI.Theme + the `names` list in panel.js.
- **The application's CSS travels with the theme, ahead of the colours.** `PanelStyleSheet`
  (a `TFileName` on both components, next to `PdfStyleSheet`, read once at activation, a
  named file that is missing raises `EHelpChatConfigError`) fills `THelpChatTheme.StyleSheet`
  before `OnGetTheme`, which may change it. `ToCss` writes it **before** the `:root` rule and
  `ToJson` carries it as `"css"`, which `hcApplyTheme` puts back into `<style id="hc-theme">`
  while the colours go on the root element: so the `--hc-*` variables stay the theme's at load
  and at runtime alike, and the CSS reaches a remote session through the same `themeCss` post,
  with no endpoint of its own. `RenderPage` passes it through `CssForStyleTag` ("</" can never
  close the element: a remote client posts it). `--hc-radius` is the one variable no theme
  sets, so a stylesheet owns it. The classes `hc-chat-*` are the contract such a file relies
  on: renaming one is a breaking change, to be written in the release notes.
- **The WebView is confined.** `TVclHelpChatAIPanel` cancels every navigation outside the
  panel origin and hands the link to `OnOpenLink`, else opens http(s)/mailto links in the
  system browser; new windows likewise. `panel.js` never lets a link navigate the panel:
  documentation pages open in its documentation view, other relative links do nothing.
- **Documentation pages are files of one folder.** `HelpChatAI.DocPages` (RTL) renders a page
  of `Settings.DocFolder` for `GET /api/doc?page=`: the name is normalized and must stay inside
  the folder and end in .md, the Markdown goes through `HelpChatMarkdownToSafeHtml`, images of
  the folder are inlined as data: URIs (no token-less route, CSP unchanged). The engine keeps
  `DocPages` until its destructor (a request may be running while it stops).
- **The URL of a page is its path as a link carries it.** The index builder writes it with
  `HelpChatEncodeUrlPath` (`HelpChatAI.Types`): a space, a parenthesis, a bracket, `%`, `#`,
  `?` become `%XX`, letters of any alphabet stay, so an index of plain names is byte for byte
  what it was. Written as it is, "Price list.md" ended the target of the Markdown link at
  its space. `panel.js` decodes before `GET /api/doc`, and `HelpChatSourcesLine` compares
  the decoded file name (`HelpChatDecodeUrlPath`: a `+` stays a plus) with what the reply
  names. The `id` and `sourceFile` of the index stay the plain path.
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
  copy; property changes apply to the next message. The snapshot is also where the provider
  and the language of a reply are decided (`THelpChatRunner.Submit`): the engine passes no
  provider name, so name, endpoint and key are of the same model even when the user switches
  meanwhile, and `Language` is written as `ResolveLanguage` - left as `hclAuto`, every
  message of a provider resolved against `HelpChatDefaultLanguage`, which is per process
  while engines are per profile.
- **A key goes to the address it was configured for, and nowhere else.** `THTTPClient`
  follows a redirect by itself and repeats the headers of the request at the new address:
  the three providers and the remote transport set `HandleRedirects := False`, and a 3xx
  is an error like a 4xx (`StatusCode >= 300`). The test is a pair of Indy servers
  (`TFakeService` in `Tests.Regressions`: `OnParseAuthentication` must say it handles
  `Bearer`, or Indy answers 401 by itself and the handler is never called).
- **A refusal is repeated only for what the service said about the request, and it is
  remembered per model.** `IsSystemRoleRefusal` (claude) wants "system", "role" and the
  refusal, and never an error that arrived inside a stream (`EHelpChatClaudeStreamError`);
  `RefusesEncryptedReasoning` (openai, the Responses API: a model that does not reason
  refuses `include: reasoning.encrypted_content`, `LearnsNoEncryptedReasoning` repeats the
  round without it); `RefusesReasoningEffort` is the only error the request of the search
  terms is repeated for.
- **A JSON value from a service is asked what it is, never cast.** `GetValue('x') as
  TJSONArray` is nil only for a missing key: for a `null` or a string it raises, and
  compatible servers send both (`"tool_calls": null` on every chunk, `{"error": "model not
  found"}`). `HelpChatJsonObject`, `HelpChatJsonArray` and `HelpChatJsonErrorText`
  (`HelpChatAI.Provider.Sse`) are what the providers use. For the same reason a call whose
  arguments are not one whole JSON object - cut at the token limit - is not run
  (`HelpChatActionArgsAreWhole` in `THelpChatProviderBase.InvokeAction`), and a `null`
  argument is a parameter left out.
- **A history that was cut still opens with a question.** `THelpChatStore.GetHistory` drops
  the answers left in front after the cut: with the default limit of 50 the 26th question
  made a conversation that started with the assistant, which Anthropic refuses - every later
  question failed until the conversation was cleared.
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
  sentence or nothing, overridden by `claude` and `gemini` (the key), `openai` (the key,
  unless the endpoint is on this machine or a private network: `HelpChatIsLocalEndpoint`)
  and `docsearch` (the index), and that is the
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
- **A citation is the engine's to guarantee, not the model's.** The source line of each
  excerpt is a Markdown link the model is told to copy, and that improved every model; but the
  same prompt gave Claude 8/8 citations in one benchmark run and 6/8 in the next. So the runner
  checks the final reply: `HelpChatSourcesLine` (`HelpChatAI.Provider`) adds "Source: [Title](Url)"
  when the reply links none of the pages the model was given but names one by its title or file
  name - the same search the prompt was built with. Nothing is added when the model linked a
  page, when it named none (an answer the documentation does not cover), for a provider with no
  model behind it, or after an action (`THelpChatProviderBase.ActionsInvoked`). It goes through
  the token callback too, so the stream and the stored text agree. **Only a page the words of
  the question reach is a source the engine may add**: the runner searches the question a
  second time without the screen hint (`HELPCHAT_SOURCES_QUERY_PAGES`) and passes both lists.
  A page the screen alone brought says where the user is, not what the answer is about:
  asked about the weather on the Dashboard, Claude 5.5 declined offering "what the Dashboard
  tiles count", and the Dashboard became the source of a refusal. The price, accepted: "what
  can I do here?" gets no automatic source for the page of the screen - the model usually
  cites it itself.
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
  does not get a second one, and only an endpoint on this machine or a private network
  (`HelpChatIsLocalEndpoint`: localhost, 127/8, 10/8, 172.16/12, 192.168/16, `.local`, a
  name with no dot) is spared the missing key - Groq, OpenRouter and Azure all want one,
  and without it the model is not offered in the panel. (GitHub Models, briefly in the
  demo, was retired by GitHub: its endpoint answers 200 with a bare `OK`, which reads as an
  empty reply; the `github` icon stays.) `Generate` still refuses only api.openai.com without a key: another service
  answers its own 401. Azure is the one that needs more than a URL —
  `AzureDeployment` moves the path to `/openai/deployments/<name>/chat/completions` and the
  key from `Authorization` to `api-key`. **OpenAI itself is spoken to with the Responses
  API** (`UsesResponses`: `OpenAI.Api` = `responses`/`chat`, empty = Responses only on the
  default endpoint and not Azure): in Chat Completions the GPT-6 family refuses tools while
  reasoning - `gpt-6-luna` accepts them with `reasoning_effort: 'none'`, `gpt-6.1-sol` in no
  combination at all (measured). `GenerateResponses` is the same loop of rounds: flat tools
  (`strict: false`, an action may have optional parameters), `instructions` for the system
  prompt, `store: false` and `include: reasoning.encrypted_content`, and every output item of
  a round - the encrypted reasoning first - sent back verbatim with one
  `function_call_output` per call (`THelpChatOpenAIResponsesStream`: the events are typed,
  a `function_call` arrives whole in `response.output_item.done`). Chat Completions keeps
  the other path: a refusal that asks for `reasoning_effort: 'none'` repeats the round with
  it (`AsksForNoReasoning`), never decided from the model name.
- **An action with no parameters is declared to Gemini without `parameters`.** An OBJECT
  schema with empty `properties` is what that API has refused; `BuildToolsJson` leaves the
  member out. Checked against the real service, with Claude and the Responses API.
- **Gemini agrees with nobody.** `contents` instead of messages, `parts` inside a turn, the
  assistant called `model`, `systemInstruction` apart, limits under `generationConfig`, the
  key in `x-goog-api-key`. `?alt=sse` is not optional: without it the endpoint answers with
  one JSON array at the end, which is the opposite of streaming. A `thought` part is the model
  reasoning, never the answer. And a function call arrives whole, so there is nothing to
  reassemble and nothing like `finish_reason` to wait for: a `functionCall` part *is* the
  signal.
- **The thought signature travels with the call, and must come back.** A thinking Gemini
  (3 and 4, the default `gemini-3.5-flash-lite` among them) puts a `thoughtSignature` on the part
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
  the copy an application living in a given folder would see — paths expanded, the
  `helpchatai.json` files merged (the per-user one too, when told which executable it is).
  With a catalogue of models the provider checked is the one of the model the engine would
  apply (`ActiveModelName`), `DocAreas` is compared with the areas the index has, and two
  routines take what the settings alone cannot tell: `HelpChatCheckProfile` (the files that
  were read: a profile none of them defines is a warning) and `HelpChatCheckActions` (the
  actions of the running application, for `/check`: a name of `AllowedActions` nobody
  registered). Everything that needs the IDE stays in the design packages: the
  output folder of the active project (`GetActiveProject`, `ExpandRootMacro`) and the WebView2
  loader. Those ~20 lines are duplicated in `FMX.HelpChatAI.Register` on purpose: sharing them
  would mean `dclHelpChatAIFmx` requiring `dclHelpChatAIVcl`, and with it the whole VCL runtime.
- **The design-time preview runs a copy, never the component.** `Vcl.HelpChatAI.DesignPreview`
  creates a second `TVclHelpChatAI` owned by nothing (so no `csDesigning`, which is what stops
  `Active`), with bubble, help viewer, F1 and actions off, parented to a modal window, freed
  when it closes. The copy is made with **`Assign`** (both components: every published
  property but `Active`, the events, `Name` and `Tag`; `Profile` before `Settings`, `Images`
  before `ImageIndex`/`ImageName`), then the preview switches off what it must: a copy made by
  hand forgot the icon, the style sheets and the sizes. `HelpChatAI.Tests.Component` and the
  `Assign` test of the settings fill every published property through RTTI
  (`FillPublishedProperties`, `FirstPublishedDifference` in `Tests.Helpers`), so a property
  added to the component or to `Settings` and forgotten in `Assign` fails a test.
  It opens from the form's `DoShow`, not before: the panel needs a window for
  its WebView. `WebView2Loader.dll` is loaded by full path first (the output folder of the
  project, then `$(HELPCHATAIDIR)\Redist\WebView2\<arch>`), because nothing ships it next to
  `bds.exe` and the RTL only ever asks for the bare name — once the module is in the process,
  that bare name finds it. The About box and the splash are registered by the VCL design
  package alone: one library, one entry. **FireMonkey has its twin**,
  `FMX.HelpChatAI.DesignPreview` (in `dclHelpChatAIFmx`): a FireMonkey form built in code
  with the `TFmxHelpChatAIPanel` of the component, native `TWebBrowser` included, the form
  being both `HostForm` and `Container` of the copy. It was left out for a long time on the
  fear that a native browser in an FMX form inside `bds.exe` would not behave; it does. The
  loader code is duplicated there for the reason the design glue is (no package requires
  the other). **The sizes of the VCL window are converted to the DPI of the monitor it
  opens on** (`MulDiv` from 96, centred by hand on that monitor): a form built with
  `CreateNew` is never rescaled, so `ScaleValue` multiplies by 1 and on a 200% screen the
  window came out at half its size; FireMonkey works in logical units and needs none of it.
  **Each project has its own preview conversation**: inside the IDE the executable is
  `bds.exe`, so the default conversation file was one for every preview of every project,
  and a new project opened with - and would have sent to the model - the history of the
  last one tested. `HelpChatUsePreviewConversation` (`HelpChatAI.Diagnostics`) points it at
  `%APPDATA%\HelpChatAI\Preview\<Project>-<hash of the exe path>\`, profile in the name, the
  state file next to it: never into the project's folders, never into the conversation of
  the application itself.
- **The configuration editor is two views over one controller.** `HelpChatAI.ConfigController`
  (engine package, RTL) holds every rule: the files a component reads (`FilesFor`: shared,
  application, per-user of the project's executable - never of bds.exe - or the one
  `ConfigFileName` names), one edited at a time in a `TJSONObject` so that a file written by
  hand keeps its other keys in their order (a value is replaced in place, `TJSONPair.JsonValue`),
  the root or the profile, the catalogue of models (an `ApiKeyEncrypted` already there is kept, and so is an `Icon`
  written by hand: the views show none, the icon is deduced; `stub` is not offered,
  `ModelProviders`; with no model to answer with the views open on that page, `NeedsModel` -
  asked of the whole configuration, files and component, and of the provider too: asked of
  the file being edited it sent the editor to an empty Models page at every opening whenever
  the models were in the shared file or in the form file; that page also writes the key of
  the provider's section, `ProviderKeyPath`, and a key typed there and not confirmed with
  Set is written by Add, Save, closing and a change of file, `CommitProviderKey` in the
  views, for the provider the boxes show at that moment; a missing or empty
  file is a new one, `THelpChatSettings.ReadConfigText`, at run time too),
  opened first on the file the configuration comes from (`ConfiguringFile`: the last file read
  that defines the profile, else that sets a value other than a key, else that holds a key, else
  the application's - always the application's opened an empty file while the shared one held
  everything), a Help button on `HELPCHAT_CONFIG_EDITOR_HELP_URL` (the `Component-Editor` page),
  and the provenance of every value - defaults, component, then each file's root and profile,
  applied one at a time and diffed through `SaveToJSON`, plus the keys a layer writes even with
  the value already in force. Each entry carries `InUse` (never empty: an empty value says what
  replaces it), `Value` (what a view puts in its control when the file says nothing; never a
  key), `Source` (default, component, file: plain, bold blue, bold in the list, as in the
  Object Inspector), `InComponent` (what `ResetComponentValue` takes away) and `Choices`; the
  `Kind` decides the control of a view. `AssistantName` is a property of the component, not
  of its settings, so the views pass it apart (`ComponentAssistantName`) - without that, a name
  written into the component never showed. In the VCL view, with `seFont` the IDE theme
  repaints the text of the list with its own colour and the blue never shows; with
  `StyleElements := []` the list went white on a dark theme. So only `seFont` goes, in the
  custom draw handlers (taken away in `FormCreate`, the theme put it back), and the colours
  it gave are set by hand: the VCL resets the canvas to the control's font and `Color`
  before every cell, so `PrepareCell` sets brush and font to the theme's in both
  `OnCustomDrawItem` (the first column is the caption, which the sub-item handler never
  sees) and `OnCustomDrawSubItem`, and the column headers, which the style hook paints with
  the control's `Font` once `seFont` is off, need `SettingsList.Font.Color` too.
  `Vcl.HelpChatAI.ConfigEditor` (dclHelpChatAIVcl, a DFM) and
  `FMX.HelpChatAI.ConfigEditor` (dclHelpChatAIFmx, an FMX form, FireMonkey controls) are
  clones that show and forward, with the same `Execute` contract; neither design package
  requires the other. It is verb 0, so a double click opens it. The VCL one follows the light
  or dark theme of the IDE in its `FormCreate` (`IDETheme.Utils`, from `designide`: the panels
  painted with the colours of `ThemeProperties.StyleServices`, `IDEThemeManager.RegisterFormClass`,
  `ThemeProperties.ApplyTheme`; the theme font by hand on 10.4 only), the way the editors of
  SVGIconImageList do - which is also where the FireMonkey twin would take its light and dark
  style books from, if it is to follow the IDE as well. Secrets: the clear node only,
  masked, never into the DFM (`SetComponentValue` refuses). A number that is not one -
  an emptied box included - raises `EHelpChatConfigError` in `TextToValue`, before a section
  is created for it: it used to be written as 0, and the views send the text as typed. `HelpChatAI.Tests.ConfigController`
  tests the rules without a view; the forms were checked by loading them in a harness.
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
- **The Tool Palette filters by class group, not by package.** A component that is a
  plain `TComponent` belongs to no framework, so `TFmxHelpChatAI` was offered on VCL forms
  and `TVclHelpChatAI` on FireMonkey ones: the designer of a module accepts a class when
  `TClassFinder` finds it in the group of the module's own class
  (`TCustomModule.ValidateComponentClass`), and neither the `requires` of the design
  package nor `ComponentPlatformsAttribute` has anything to do with it. Each unit says so
  in its `initialization`: `GroupDescendentsWith(TVclHelpChatAI, Vcl.Controls.TControl)`
  and `GroupDescendentsWith(TFmxHelpChatAI, FMX.Types.TFmxObject)` - what
  `TApplicationEvents` and the FireMonkey `TCommonDialog` do, for the same reason. It also
  decides which class the DFM/FMX loader finds, so a change here is checked by opening the
  demos, not only by compiling them.
- **The index is built from the component, too.** `HelpChatPlanIndexBuild` /
  `HelpChatRunIndexBuild` (`HelpChatAI.IndexBuilder`, RTL) turn the settings into a plan -
  pages folder, output file, table of contents, link extension - that the design packages
  show before building and that `Tools\HelpIndexBuilder` would produce by hand. The one
  thing deduced is the extension: no `DocBaseUrl` means the pages are read inside the
  panel, so links keep `.md`. The verb is in both component editors, and a double click on
  a component whose index is missing offers it before the preview. The deduction is
  printed in the confirmation on purpose: a design-time action that guesses in silence is
  worse than one that asks.
- **`ImageIndex` and `ImageName` need their own property editors.** The ones the IDE gives the
  standard controls are not offered to a component that is not one of them, so
  `Vcl.HelpChatAI.Register` registers `TVclHelpChatImageIndexProperty` and
  `TVclHelpChatImageNameProperty` (the pattern of SVGIconImageList and StyledComponents:
  `ICustomPropertyListDrawing`, the images drawn in the drop-down). With no `Images` of the
  application they list the built-in icons, which is the only way to discover their names.
- **One engine per profile, and the actions travel with the question.** Two instances of one
  form are two components with the same profile: `THelpChatEngines.Acquire(Self, FSettings)`
  (`HelpChatAI.Engine`) hands both the engine of that profile - created by the first with a
  **copy** of its settings, freed by the last `Release` - so the index is loaded once and the
  conversation is one. The components read `RunSettings` (the engine's while active) for what
  the user changes in the panel, never their own `Settings`. The copy's secret handler is a
  proxy that asks the assistants still holding the engine, and the registry entries live as
  long as the process: a reply in flight carries that handler in its snapshot. An engine has
  no actions of its own any more: each component gives its broker to its transport
  (`IHelpChatTransport.SetActions`), the session hands it to `THelpChatEngine.Send(..., AActions)`
  and to `THelpChatCommandRequest.Actions`, so `create_order` fills the window it was asked
  from. `THelpChatEngine.Actions` remains for code that drives an engine by itself (the
  console server, the tests). Two things follow from an engine that outlives each of its
  assistants. **What the user changes in the panel is the engine's**: `ActiveLanguage`,
  `LanguageChanged` and the language of the process at activation read `RunSettings`, never
  the component's own `Settings` - reading those took the process back to the configured
  language the moment the user picked another. **A reply may call an action of a window that
  is gone**: closing one of two windows no longer stops the engine, so the broker has
  `HostActive`, False from deactivation to the next activation - `Invoke` then answers
  `aoCancelled` at once and what was queued is answered the same way, instead of running on
  a form being torn down or parking a worker for the 60 s of the timeout. And activation is
  all-or-nothing: whatever fails after `Acquire` releases the engine, because a holder left
  in the registry keeps a pointer to the settings of a component that may be freed.
- **An expert knows an area of the manual, not a manual of its own.** One manual, one index:
  `THelpChatIndexBuilder.ExtractAreas` gives a page the first sub-folder of its path, or the
  `areas:` of its front matter (`areas: []` = everybody's), and writes `"areas"` only for the
  pages that have some - a flat manual keeps its index byte for byte. `Settings.DocAreas`
  ("Orders, Customers", an array in JSON) goes to `THelpChatDocIndex.Areas` at `Start`;
  `VisibleEntries` keeps the pages of those areas and the pages of none, **before** the scoring,
  so the idf is the area's. `Count` is still the whole index; `Search` and `Pages` are the
  area's. `DocFolder` stays the root, so a link across areas still opens in the panel.
- **An assistant does what its form registers, plus what the application shares, minus what its
  profile forbids.** `HelpChatSharedActions` (`HelpChatAI.Actions`) is a broker of definitions
  only: the broker of a component consults it after its own (`Shared`, set at activation
  unless `UseSharedActions` is False; an own action of the same name redefines it) through
  `Resolve` and `AvailableNames`, and a shared action is queued, confirmed and run by the
  component's broker - the host that was asked. `Allowed` (from `Settings.AllowedActions`)
  filters both, for declaration and for invocation alike: a configuration narrows, a name
  nobody registered gives nothing.
- **Actions are what the assistant may do, and only that.** `HelpChatAI.Actions`: the application
  registers name, description, parameters and handler; `ToolsJson` is what a provider declares
  (`SupportsActions`), `Invoke` is how it calls one. The handler runs on the application's main
  thread — the worker queues the request, fires `OnPending`, and waits with a timeout while
  watching the cancellation token; the component marshals with `TThread.Queue` and calls
  `ExecutePending`. Nothing in this path may raise into the provider: every outcome is a
  `THelpChatActionOutcome` turned into a sentence for the model.
- **An action asks unless told otherwise.** `AConfirm` defaults to True in both `Add`; an
  action that changes nothing (`open_screen`) or asks in its own way (`export_pdf`, whose
  save dialog is the confirmation) passes False explicitly. In the VCL the question goes
  through `Vcl.HelpChatAI.ConfirmDialog`: `HelpChatVclConfirmAction` creates the class in
  `VclHelpChatConfirmDialogClass` (the DFM form of the library, or one the application
  registered with `RegisterVclHelpChatConfirmDialog`, which must implement
  `IVclHelpChatConfirmDialog`), owned by the host form, one at a time **per assistant** - a
  question of the same assistant arriving while one is open dismisses it as No, a question
  of another assistant (`Asker` of the request) opens over it and leaves it waiting:
  dismissing it would refuse an action nobody refused and end that plan. The form is a DFM
  on purpose: one built with
  `CreateNew` and laid out by hand got the font of the primary screen and the layout of
  another, because `ScaleValue` multiplies by the factor of the last rescaling (1 for a form
  nobody rescaled) while the font of a new form is already at the DPI of the screen; the VCL
  scales a form it loads, at creation and on every move. Stock icons come from
  `LoadIconWithScaleDown`, because `LoadImage` with a size hands back the icon of the system
  DPI for a system icon. `Prepare` lays the request out and `Execute` shows it: the form is
  never taller than the work area of its monitor - past that the values panel moves into a
  scroll box and is laid out again without the strip the scroll bar takes (a label is
  measured when `AutoSize` changes, not when its width does) - and Yes and No are
  `hcmConfirmYes`/`hcmConfirmNo` in the language of the request, not `SMsgDlgYes`, which is
  in the language the RTL was built with. The FireMonkey twin does the same with a
  `TVertScrollBox`, checked by a harness. No is the default button, and the dialog closes as No after
  `HELPCHAT_CONFIRM_TIMEOUT_MS` (30 s), before the broker's 60 s. What it shows comes from
  `THelpChatActionArgs.ToDisplayPairs`: the description of each parameter cut at its first
  punctuation (`ParamLabel`), the values with control characters replaced and cut at
  `HELPCHAT_ACTION_DISPLAY_MAXCHARS` - the model wrote them, and a value must not be able to
  read like a sentence of ours. `FMX.HelpChatAI.ConfirmDialog` is the FireMonkey twin
  (`IFmxHelpChatConfirmDialog`, `RegisterFmxHelpChatConfirmDialog`, a form with an FMX):
  `TDialogService.MessageDialog` on Windows is the message box of the system, which no
  FireMonkey style paints, while a form follows the style like every other. Its labels are
  measured with a `TTextLayout` before the form is shown, because a FireMonkey label has no
  height to report until its style is applied; the icons are a `TPath` and a `TCircle`,
  since FireMonkey has no stock icons. It answers on the desktop only
  (`HelpChatFmxCanConfirm`: Windows and macOS, where `ShowModal` returns), so on a mobile
  platform an action needing confirmation without `OnActionConfirm` is still refused.
- **A refusal ends the plan.** `THelpChatProviderBase.InvokeAction` is how every provider
  runs an action: after the user said no to one action of a reply, every later one of that
  reply is answered `aoDenied` with `HELPCHAT_ACTION_DENIED_BEFORE_TEXT` and nobody is asked.
  A provider lives for one reply, so the rule does too. The model is told the same in
  `HELPCHAT_MODEL_ACTIONS_RULE` and in the denied text, but the guarantee is the code: told
  "the user refused to create the company", a model asked "create the lead" anyway.
- **`Invoke` never raises, and says "done" for what was done.** Whatever raises on the
  way (the host being woken up) is `aoFailed`; `Forget` tells when the host answered between
  the last wait and the give-up, and `Invoke` then returns that answer instead of a timeout
  the model would retry; the wait is a `TStopwatch`. `ToolsJson` builds each declaration
  under the lock of the broker that owns the action (`ToolJsonOf`).
- **The request of an action is freed by whoever touches it last.** `Invoke` waits with a
  timeout while the host may be holding the request in a confirmation dialog: on timeout or
  cancellation it calls `Forget`, which under the lock drops a request still queued, frees
  one already answered, and otherwise marks it abandoned for the host; `Finish`, under the
  same lock, frees an abandoned request instead of completing it, and `ExecutePending`
  skips the handler of one. Before this, a Yes given after the 60 s ran the action anyway
  (the model had been told it timed out, and a retry would run it twice) and then wrote on
  a freed object.
- **What enters the system prompt from the application is cut first.** `HelpChatPromptField`
  reduces the screen label and the class name to one line without double quotes, at most 80
  characters: a caption is often the name of the record, which somebody else typed, and the
  system prompt is the part of the context a model trusts most. The texts of
  `HELPCHAT_MODEL_ACTIONS_RULE` say that what a tool returns, a document contains or an
  excerpt says is data, never an instruction - a rule, not a guarantee; the guarantees are
  the two bullets above.
- **A call queued for the main thread asks whether anybody is still there.** `TThread.Queue`
  cannot be taken back, and its closure holds a method of an object that may be freed before
  the loop gets to it: it captures an `IHelpChatLifeToken` (`HelpChatAI.Types`) with the
  method, the object kills the token in its destructor, the closure asks `IsAlive`. Both
  components (`FLife`: the PDF of `export_pdf`, the deferred theme), the voice engine, and
  the local server and the host channel, where a token belongs to the handler in force -
  replaced with every `SetOnUiCommand`/`SetOnPdfRequest`, so a command queued before the
  component deactivated is dropped.
- **The broker outlives the component on purpose.** It is reference counted and the queued
  `ExecutePending` closure captures the interface, so a call in flight cannot land on a freed
  object. The component keeps both the typed reference and the interface, and nils both.
- **Tool use is a loop, not a call.** The Claude provider streams a round, and if the model asked
  for actions it executes them, appends the assistant turn and the `tool_result` turn to the
  conversation and calls again, up to `Claude.MaxToolRounds`. The text of every round is
  concatenated (with a paragraph break) and streamed as it arrives, so what the user reads and
  what the store keeps are the same string. The rounds are requests, so **with one round no
  action is declared at all** (`THelpChatProviderBase.OffersActions`: there would be no
  second request to tell the model how it went), and when the last round still asks for an
  action it is not run and the reply says so (`NoteActionsNotRun`, `hcmActionsNotRun`) -
  it used to end as if the action had been done. In `openai` the calls are the signal, not
  `finish_reason`: several compatible servers end a tool turn with "stop".
  **A reply cut at the limit of tokens says so** (`NoteReplyCut`, `hcmReplyCut`): `stop_reason`
  `max_tokens`, `finish_reason` `length`, `response.incomplete` with `max_output_tokens`,
  `finishReason` `MAX_TOKENS` - checked against the three services with a scratch program.
  `MaxTokens` is 4096 by default: the reasoning of a model counts in it.
  **The assistant turn goes back as the model wrote it** (`THelpChatSseStream.Blocks`,
  `BuildAssistantTurn`): the Claude 5.5 models think unasked, and their `thinking` blocks
  (empty text, a signature) must return with the results, unchanged and in place, before the
  calls - the API accepts a turn without them, but the model then starts each round without
  the reasoning that chose the calls (found by recording the demo, checked against the real
  service). A `redacted_thinking` block goes back too; an unsigned one cannot. The same rule
  as the `thoughtSignature` of Gemini and the encrypted reasoning of the Responses API.
- **The prompt cache is a prefix match, so the order of the prompt is a cost.** `claude`
  (`SplitsPrompt`) sends `BuildStablePrompt` as its system prompt - identity, field, rules,
  `Instructions`, language, then `OnBuildSystemPrompt` on that part only, then the actions
  rule - and `BuildQuestionContext` (`NowRule`, the screen, the excerpts) as a `system`
  message right after the question, which never goes back into the history: the next question
  finds tools, system prompt and conversation byte for byte. A model that refuses a `system`
  message (Haiku 4.5) gets the context as a second text block of the question, remembered per
  model for the process (`RefusesSystemMessages`; checked against the real service). With
  `Claude.PromptCaching` (default on) four breakpoints, the maximum: last tool, system prompt,
  the question (its last block, before the context), and the automatic one when tools are
  declared, for the rounds of the loop. `IdentityRule` lost now to `NowRule`; a rule with
  `%1:s` still gets it, `NowRule` is then skipped (`IdentityRuleSaysNow`) and `/check` warns,
  because the system prompt changes every minute. `BuildSystemPrompt` still writes the whole,
  the same text as before (now right after the name), for the preview of the configuration
  editor and a provider of the application that does not split; `/prompt` shows the two parts
  for a provider that splits (`SplitsPrompt`: claude, openai, gemini). Measured in `Test\LLMBench` (`--nocache`, the
  Tokens table, `results/llm-bench-cache-v1-*`, `-v2-on`, `llm-bench-expertise-v3`): -15% with
  only the tools and the loop marked, -31% split, answers unchanged (the benchmark opens a
  new conversation per question, so the reread conversation is not even in it).
  `HelpChatOnTokenUsage` (`HelpChatAI.Provider`, a diagnostic hook on the worker thread) is
  where the counts come from (`THelpChatSseStream.Usage`). The page is `Prompt-Caching`.
  **The same split for `openai` and `gemini`**, whose caches are automatic (no marks): the
  Responses API gets the context as a `developer` message after the question; Chat Completions
  in front of the question, in its message - a second `system` message is refused by the chat
  template of several local models, and with the excerpts after the question `qwen3-coder` lost
  the request (measured); Gemini as a second part of the question. A question without
  attachments stays a plain string (it is one in the history of the next request). The usage:
  `prompt_tokens_details.cached_tokens` / `cache_write_tokens` (Chat), `input_tokens_details`
  (Responses, `response.completed`), `usageMetadata.cachedContentTokenCount` (Gemini; an Ollama
  reports its prefix cache too). Measured thresholds: OpenAI 1,024; Gemini 3.5 Flash Lite about
  2,048 and Gemini 4 Argon 4,096 cached tokens on a 6,000-token prompt, Gemini Pro none - so
  the benchmark prompts (about 2,000) read nothing there, and a real application with skills does.
  **`--suite=conversation`** (`KeepConversation`) asks the questions of a target in one
  conversation, the history never cleared, and the report adds **Tokens per question**
  (read / whole input): Haiku -40% billed against `--nocache`, the read growing from 1,114 to
  6,592 tokens; the context of each question (~1,900 tokens of excerpts) is never read, by
  design (`results/llm-bench-conversation-v1*.md`).
- **A skill is a set of actions the library writes once, and an assistant gets it by name.**
  `HelpChatAI.Skills` (RTL): `THelpChatSkill` (a class registered by name with
  `HelpChatRegisterSkill`, like a provider; `Supports(AHost)` lets a VCL and an FMX skill share
  a name), `THelpChatSkillSet` (one per component: `Attach` at activation after `Allowed`,
  `Detach` on deactivation and in the except branch), and the framework-neutral half of the
  screen skills - `THelpChatSkillField` and its description line, the parsers of what the model
  writes, `HELPCHAT_SKILL_*`. **The four screen skills are written once**, in
  `HelpChatAI.Skills.Screen` (engine package, RTL + `Data.DB`, so `HelpChatAI` requires
  `dbrtl`): the skill classes, the action texts, describe/fill/cancel/find_choice, lists and
  records, pages and commands, `THelpChatDataField` (the `TField`, lookups, choice and check
  values: read and written here), the `EnterEditing` rule. A framework registers a
  `THelpChatScreenProvider` (`Supports(AHost)`, `CreateScreen(AHost)`) whose `THelpChatScreen`
  gives the fields, lists, pages and buttons of the form the user is on, and its field class
  overrides `ReadValue`/`WriteValue` for the plain controls only. `FMX.HelpChatAI.Skills`
  (HelpChatAIFmx, linked by `FMX.HelpChatAI`) is the FireMonkey screen: LiveBindings read
  through RTTI by class name (`TCustomLinkControlToField`, `TCustomLinkFillControlToField` as a
  lookup, `TCustomLinkGridToDataSource`/`TCustomLinkListControlToField` as lists) so no binding
  unit is required, tab order from `TabOrder`, visibility up the parents (an inactive tab hides
  its `Content`), the form activated last from `TFormActivateMessage`, the tabs of a
  `TTabControl` with `TabPosition = None` left out (a card panel). There is no FMX test in the
  DUnitX suite (a VCL program): the FMX screen was checked by a FireMonkey harness that builds
  a form in code. `Settings.Skills` names them (JSON string or array, profiles
  too). Three rules: **an action of the application wins** (`AddAction` skips a name the
  broker or its shared broker has, and `Detach` removes only what the skill added); **naming a
  skill allows it** (its actions are appended to a non-empty `Allowed`); **an unknown name is
  skipped**, and `HelpChatCheckSettings` warns (`CheckSkills`). `/skills` (`hccSkills`) lists
  them from the engine's `Settings.Skills`: `SkillDescription(ALanguage)` is for the user and
  localized (`hcmSkill<Name>`), the actions come from `HelpChatSkillActionNames`, which attaches
  a throwaway instance to a broker of its own. `Vcl.HelpChatAI.Skills`
  (HelpChatAIVcl, linked by `Vcl.HelpChatAI`, which is why the package requires `dbrtl` and
  `vcldb`) holds `forms`, `commands`, `records`, `pages`, every action a public function
  (`HelpChatVclDescribeForm`, `HelpChatVclFillForm`...) that the tests call on forms built in
  code. They work on `HelpChatVclWorkingForm` (the active form, else the first eligible of
  `Screen.CustomForms`, never `TVclHelpChatAIForm` or the confirm dialog; the MDI child),
  `OnGetTarget` of `HelpChatVclSkills` may change it. A field is a control an adapter accepts
  (`THelpChatVclFieldAdapter`, asked from the last registered; the data-aware one - any
  published `DataSource` + `DataField` - before the plain ones), walked in tab order
  (`GetTabOrderList`); caption: `FocusControl` label, own caption, `DisplayLabel`, nearest
  label left/above, text hint. **Nothing is saved**: `fill_form` never posts and refuses an
  insert while a record is in `dsEdit` (Insert would post it), `find_record` refuses a list in
  edit, `commands` hides what looks like a save (`TDataSetPost`, nbPost, ModalResult OK, the
  save words, `OnCommand` decides) and the navigator buttons that move while editing.
  **Reading never moves a data set that is being edited**: `First`, `Locate` and - in
  FireDAC - even `Lookup` leave edit mode first, which posts. So a lookup table in edit is
  neither scanned nor looked up (`ScanLookup`, `LookupDisplay`), and `find_record` refuses
  while a detail of the list is being edited (`EditingDetailOf`).
  `commands` leaves out what moves while editing whatever it is made of: the buttons of a
  navigator, a button with `TDataSetFirst/Prior/Next/Last/Insert/Refresh`
  (`ActionMovesWhileEditing`; with no `DataSource` on the action, any data set of the screen
  in edit is enough), and in FireMonkey the buttons of a `TBindNavigator` - told by their
  `Index`, read through extended RTTI, never by a hint the RTL translates - and the bind
  navigator actions (`NavigationWhileEditing`).
  `fill_form`, `cancel_edit`, `press_command` confirm, with `THelpChatAction.OnDisplay` giving
  the dialog a readable summary and values (localized `hcmSkill*`); `press_command` clicks
  with `TThread.ForceQueue`, after the action answered, so a modal window does not keep the
  worker waiting. Five VCL traps, each of which cost a run: **`Showing` is not taken back from
  the children of a hidden tab sheet** (the visibility is the chain of `Visible`, `IsShown`);
  **`TPageControl.Change` takes the page back from the old tab index** (set `ActivePage`, call
  `OnChange` yourself) and **`ChangeActivePage` keeps the page when the focus inside it
  cannot move** (clear `ActiveControl` first); **a `TRadioGroup` is made of `TRadioButton`s**
  (`TGroupButton`), so the radio-button adapter skips a parent that is a radio group;
  **`TNavButton` moved from `Vcl.DBCtrls` to `Vcl.Buttons` and its `Index` changed type**
  (read through RTTI); `TArray.Contains` is not in 10.4. And in tests: naming a `TEdit` gives
  it its name as text; `TryISO8601ToDate` with `AReturnUTC = False` shifts a time without
  offset.
- **Actions are local for now.** With `Settings.Remote` the model runs on the server and the
  actions live in the client: the definitions and the calls do not travel yet. The broker queue
  is shaped for it (`TakePending`/`Complete` over HTTP, the host channel already exists), but
  until that is built, registering actions with a remote engine does nothing.
- **The plain demo is where a beginner starts, so several assistants live in a twin.**
  `*_CRMDemo_MultiAgent.dproj` compiles the same sources with `MULTIAGENT`: one unit
  (`uMultiAgent`, `uMultiAgentFmx`) holds everything it adds - the general assistant's
  `AllowedActions` and a Sales assistant created on the lead window (profile, Expertise,
  `DocAreas`, `AllowedActions`) - and the main form changes in two `{$IFDEF}`s:
  `draft_proposal` goes to `HelpChatSharedActions` instead of the component, and the two
  calls around `Active`. The point it makes is that **the configuration decides who uses an
  action**, not the handler. A DFM cannot hold a directive, which is why the second assistant
  is created in code. Its DCUs go to `dcu\<Framework>-MultiAgent`: sharing the folder, one
  edition would link the other's units. The areas are in the front matter of the manual
  (`Sales`, `General`, the rest of none), so one index serves both editions - and a page of
  no area is everybody's, so the pages the Sales assistant must not see needed an area too.
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
  **The main form of the VCL demo has no custom title bar**: `CustomTitleBar` with
  `WindowState = wsMaximized` in the DFM gets the restored size scaled twice at high DPI
  (4572x2582 on a 2560x1600 screen at 200%, measured with a bare form), and the title bar
  behaves differently from 10.4 to 13. The two combo boxes are in a plain `TopPanel`, and
  `FormCreate` centres the restored bounds on the work area and then maximizes - the default
  position cascades, and `poScreenCenter` does nothing to a form that starts maximized.
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
- **An attachment belongs to the conversation, not to the question.**
  `HelpChatAI.Attachments` (RTL) holds `THelpChatAttachmentSet`, keyed the way the store is
  and owned by the engine; a request takes a copy, so a worker never reads the live list
  while an HTTP thread adds to it. It is sent again with every later question - which is
  what makes a second question about the same document work - until `Clear` takes the
  conversation and its documents away together. **The bytes never reach the conversation
  file**: a persisted JSON carrying a scanned PDF would be reloaded at every start.
  `Settings.Attachments.Enabled` is **False by default**, because what the user attaches
  leaves the machine, and that is the application's decision; the panel shows the clip only
  when that is on *and* `THelpChatProviderRegistry.SupportsDocuments` says the configured
  provider can read one.
  **Three kinds, because that is what the APIs take**: a PDF and an image travel as base64
  bytes (Anthropic `document`/`image` blocks, OpenAI a `file` part - PDF only - and an
  `image_url` data URI, Gemini `inlineData`), and everything textual is decoded on arrival
  and put in front of the question, fenced so the content of a file cannot read as an
  instruction. A `.docx` or an `.xlsx` is refused by name: no model reads one, and sending
  it would look like it worked. Base64 goes up **without line breaks** - all three refuse
  them - which is why `Base64` is wrapped in a `{$IFDEF D11+}`: 10.4 has no
  `TNetEncoding.Base64String` and the old encoder wraps at 76 characters.
  The page takes them from the clip and from a file dropped on it (a `drop` handler on the
  document, so anywhere on the panel works).
  **The server is where they live, so the page asks it**: `GET /api/attachments` rebuilds
  the bar when the page loads, because a reload - and a VCL style change recreates the
  window, which reloads the page - used to empty the bar while the documents kept going out
  with every question. The file-type glyphs are inline SVG in `panel.js` (Material Design
  Icons, Apache 2.0, generic glyphs and no brand logo): the panel is one self-contained
  page, so they cannot be PNGs in a `.res`.
- **The printable document loads no image from outside.** `THelpChatPrintableDoc.Render`
  writes `img-src data:` as its policy: the panel has a CSP, the document had none, and an
  image the model named on another site was fetched when the PDF was made. So a
  `PdfStyleSheet` cannot name an image by URL either.
- **A PDF is written by the client, never by the engine.** The engine builds a
  `THelpChatPrintableDoc` (`HelpChatAI.Html`: title, subtitle, language, body HTML) out of an
  answer, a conversation or a documentation page and hands it over - `POST /api/pdf`,
  `IHelpChatTransport.SetOnPdfRequest`, delivered with `TThread.Queue`; the component puts
  the stylesheet on it, asks the user where it goes and prints it with
  `THelpChatPdfExporter` (`HelpChatAI.Pdf`, engine package, WebView2 through interfaces we
  declare ourselves). The window it needs is created at -32000 and never shown, and the
  environment of the panel is borrowed so that no second browser process starts. **A remote
  engine answers 501**, not 404: the document would be built where there is no screen to
  save it from, and the page says so instead of doing nothing.
- **An export dispatches the messages of the thread, but not the user's.** `Wait` takes
  the callbacks of the runtime from the queue and leaves the keyboard, the mouse, `WM_CLOSE`
  and `WM_SYSCOMMAND` there (`PeekNoInput`, ranges asked in turn): dispatched from inside
  the export they closed the form, and freed the component, under `PdfRequest`. The page is
  another process, so a second click on its PDF button still arrives: `FPdfBusy` drops it.
  The handlers are `THcHandler` and are detached in `CloseController` - the runtime may
  call one after a timeout, when the exporter is gone.
- **The paper is not the stylesheet's to decide.** With no print settings the runtime prints
  Letter and ignores `@page { size }`; and a margin written in CSS **wins over** the print
  settings - `@page { margin: 0 }` in our own `print.css` cost every margin of every sheet
  (measured: 0.0 mm where 16 had been asked for). So `THelpChatPdfPage` decides the sheet,
  the margins and the orientation, `print.css` carries no `@page` rule at all, and neither
  may the stylesheet an application names in `PdfStyleSheet`.
- **A header and a footer need the DevTools call.** `PrintToPdf` takes no template, and
  Chromium implements no `@page` margin boxes - `counter(page)` in a `position: fixed`
  element prints 0 on every sheet, measured - so the only way to put a band of ours, page
  number included, on every sheet is `CallDevToolsProtocolMethod('Page.printToPDF')` with
  `headerTemplate` and `footerTemplate`. It is the same printer underneath, reached by a
  protocol Microsoft does not version with the API, so it is taken **only when a band was
  asked for**: on refusal the file is written with `PrintToPdf` and `BandsDropped` tells the
  component to say the bands are missing. A band is laid out inside the margin, so the
  margin grows by `BandMm` instead of eating into the text, and the template is a little
  document of its own - its own `<style>`, `print.css` does not reach it - whose
  placeholders `HelpChatPdfExpand` replaces, HTML-escaped. `{page}` and `{pages}` become the
  two spans the runtime knows by class name.
- **The clipboard is the page's own.** Copying an answer, the conversation or a documentation
  page is `panel.js` alone: both flavours at once (`text/html` keeps the bold, the lists and
  the tables, `text/plain` is what the browser lays out), through `ClipboardItem` and, if
  that is refused, through a hidden selection and `execCommand`, which puts both there too.
  Nothing of it reaches the engine or the host, which is why it works with a remote engine,
  where saving a file does not.
- **The model has no calendar and no clock, and does not know its name.** The system prompt
  opens with `HELPCHAT_MODEL_DEF_IDENTITY_RULE`: the name of the assistant and now - date,
  time and UTC offset, written out with `TFormatSettings.Invariant` so the month is November
  and the model translates it (`HelpChatNowText` in `HelpChatAI.Provider`). Without the date a
  document it writes is dated "today"; without the time "can I call New York now?" was
  answered by no model of the benchmark, with it by most. The name is the one of the panel
  that asked: an engine is the profile's while the name may be the component's, so the
  server passes `GetAssistantName` of the session to `Engine.Send`, and the runner writes it
  into the snapshot (empty = `Settings.AssistantName`, else `hcmUiTitle` in the language of
  the chat). `HELPCHAT_MODEL_DEF_DATE_RULE` is kept as a constant only.
- **The library never decrypts a secret: it asks - and only for the encrypted node.** Every
  secret has two nodes (1.7): `ApiKey` in clear, which the developer writes and the IDE
  reads, and `ApiKeyEncrypted`, which the application writes with its own cipher; the same
  pair for a model of the catalogue, `Remote.AppKey` and `Remote.UserToken`. None is
  published: a key belongs to a file. `HelpChatResolveSecret` (`HelpChatAI.Settings`) is the
  one rule: at run time the encrypted node wins, through `OnDecryptSecret`, else the clear
  one as it is; inside the IDE (`HelpChatDesignTime`, set by both `Register` procedures) the
  clear one, else the encrypted one as it is - nobody can decrypt there, and a check only
  asks whether a key exists (`HasConfiguredApiKey`). The model chosen in the panel brings its
  key as a whole (`SetOverrides` with both nodes); with none, `EnvironmentApiKey` (virtual,
  gemini adds `GOOGLE_API_KEY`) - never through the handler. **A key never follows a model
  to another host**: a model of the catalogue that names a `BaseUrl` on another scheme, host
  or port than the section's own endpoint, and no key of its own, gets none
  (`KeyBelongsElsewhere`) - neither the section's nor the environment's, which would hand
  the OpenAI key to Groq or to a server on the LAN. Same host, another path: the key
  stands (a gateway). The environment variable is stricter still, because it is named after
  the service: it is read only while the endpoint in force is the provider's
  `DefaultBaseUrl` (same scheme, host and port) - a section whose own `BaseUrl` points at
  Ollama, Groq or Azure says its key in the configuration, or has none. `OnDecryptSecret`
  (`THelpChatSecretEvent`, published on both components, public on `THelpChatSettings`
  because the console server has no component to put it on) imposes no format and registers
  no cipher. Two things that are not obvious: the handler lives on the **settings** and
  `Assign` copies it, because what reads the key is the snapshot a request works on, not the
  component; the calls are serialized by a critical section because they arrive on a worker
  thread, and nothing is cached, so the clear text lives as long as the request. The
  component editor reads and writes the clear node only, and needs no cipher.
  **The example is the demo's, and so is DCPcrypt**: `CRM Demo/common/uAppSecret.pas`
  (AES-256 CBC, random IV, PKCS#7, the passphrase in two XORed halves) and the
  `License activation` window of each demo, which is where a real application would ask
  its licensing service for the key - and which writes `ApiKeyEncrypted`, next to the
  developer's clear `ApiKey`. Both demos carry a catalogue of their own in the form file
  (`Claude`, `Gemini`, `OpenAI`, no key, no model: the defaults of each section), which a
  `Models` of a configuration file replaces. It opens when **the model in use** has no key, at startup and
  on `OnModelChanged`: `AppSecretMissingKey` reads `RunSettings` and lets the provider's
  `ConfigurationIssue` decide (so `docsearch` and a local server never ask). It then offers
  a field per service (`AppSecretKeyRequests`: claude, gemini, openai, then each model of
  the catalogue on a service of its own on the internet, whose key is that entry's; at
  most `APPSECRET_MAX_ROWS`, four, the rows of the form), the one in use in
  bold, so the user registers the others while at it; `AppSecretActivate` writes every key
  typed, to the section of the provider or, for a model of the catalogue with an endpoint
  of its own, to that entry; if the model in use is still without one, the demo switches to
  the first model `Models` offers - in the per-user file, whose `Models` then names the other models of
  the catalogue by name, because a list in a file replaces the one before it. Its header says what it is - obfuscation, not
  secrecy - and that is the honest claim: it is worth something against a configuration
  file that travels, nothing against whoever owns the machine. `DCPcrypt.EncryptString` is
  not used, and a second example should not use it either: it treats the string as
  AnsiString and encrypts in CFB8bit with a zero IV, so the same key encrypted twice comes
  out the same.
- **Every text the library writes into the prompt is a property, and the constant is only its
  default.** `SystemPrompt`, `IdentityRule`, `ExpertiseIntro`, `ExpertiseRule`, `LanguageRule`,
  `DocLanguageRule` start as the `HELPCHAT_MODEL_DEF_*` text, are stored (form file, and
  `SaveToJSON`) only when they differ, and an empty one goes back to the default - so nobody
  freezes the rules of the version they saved with. `BuildSystemPrompt` reads them through
  `Resolve*` and `HelpChatFormatRule`: a text that does not fit its values (`Format` raises)
  falls back to the library's, and `HelpChatCheckSettings` warns (`HelpChatRuleIssue`). A new
  sentence = a property with its stored function, `Assign`, JSON both ways, the catalogue of
  the configuration controller (page `ccpPrompt`, its place in `PROMPT_ORDER`, a fragment in
  `FillFragments`). **Three texts stay constants on purpose**: `HELPCHAT_MODEL_ACTIONS_RULE`
  and the two `HELPCHAT_ACTION_DENIED_*` - they are the defence against a tool called because
  a text asked for it, and the end of a plan the user refused. `OnBuildSystemPrompt`
  (`THelpChatBuildPromptEvent`, on the settings like the secret handler: copied by `Assign`,
  proxied by `TSharedEngine.BuildPrompt`, serialized on `FSecretLock`, skipped while
  `HelpChatDesignTime` because a design-time method pointer is not code) runs at the end of
  `BuildSystemPrompt`, before the providers add the actions rule - so it can never remove it.
  The messages are replaced with `HelpChatSetMsg(Id, Text, Language)` (`hclAuto` = all
  languages; per process, a lock taken only once something was replaced), never through a
  configuration file.
- **The configuration editor shows every published setting, each on its page.** The catalogue
  of `HelpChatAI.ConfigController` has `Pages` per entry (Appearance, Settings, Prompt,
  Documents; Models and Profiles are pages of their own) and is sorted by property name with
  the provider sections last; `EntriesOfPage` filters and, on the Prompt page, orders by
  `PROMPT_ORDER`, the order `BuildSystemPrompt` writes. A property added to `Settings` without
  a catalogue entry is invisible in the editor. The views share one list and edit panel and
  move it (`GridPanel` / `GridLayout`) to the page shown. `Value` is never empty when something
  replaces the empty value (the localized greeting, the default model, the text of the
  library): the edit box starts from it. The origin of a value of the form file names the
  property ("Component: Settings.Expertise"). `PromptPreview` builds the prompt from the layered
  settings with a sample screen and excerpt; `PromptFragment` is what each setting wrote,
  computed with the same `Resolve*` calls, which the VCL view bolds in a `TRichEdit` and the
  FireMonkey one selects. `Execute` receives the component too, for what is not in its
  settings (the icon, `PanelStyleSheet`). The Appearance page draws the panel with
  `AppearancePreview` (`THelpChatPanel.PreviewPage`: the page with a sample conversation in
  place of the history request) in a browser of its own - `TEdgeBrowser` /`TWebBrowser`,
  created in code once the WebView2 loader is reachable, never the panel of the component,
  which lets nothing but its server navigate it. **A WebView2 created before the window is
  shown stays blank**, so the first preview is drawn from `DoShow` with `TThread.ForceQueue`
  (`FShown`): drawn in `Execute`, the page appeared only after the first change. **A set
  setting is a `cvkSet`** (`Skills`): the choices are `HelpChatSkillNames` plus the names the
  files or the component carry that the IDE does not know, kept ticked as "(not registered
  here)"; `ChoiceCaptions` (the name and its actions) and `ChoiceHints` (the description) are
  what a view shows, and a view writes the choice, never its caption. The hint of
  `AllowedActions` lists the actions the skills add. The editors remember page, bounds and
  maximized state in unit variables, read once from and written back to the registry of the
  running IDE (`<BaseRegistryKey>\HelpChatAI\ConfigEditorVcl` / `...Fmx`, apart because
  the FMX bounds are not VCL pixels): kept in memory only, a restart or a package loaded
  again forgot them. Restoring a placement never raises, and never puts the window on a
  monitor that is gone (`MakeFullyVisible` in the VCL, `OnADisplay` in FireMonkey).
- **Defaults live once** in `HelpChatAI.Settings` constants (`HELPCHAT_DEF_*`). Settings also
  load/save as JSON (`helpchatai.json`: app file next to the exe, then per-user file in
  `%APPDATA%\<Exe>`); a new property must be added to `Assign`, `LoadFromJSON`, `SaveToJSON`
  and the round-trip test (the `Assign` test finds it by itself). A new published property
  of a component goes into its `Assign`, which the preview runs on.
  **Never commit a `helpchatai.json` containing a key** (it is svn-ignored).
  **A published string the constructor fills needs a `stored` function**: a string has no
  `default` directive, so Delphi writes every non-empty one - a component just dropped on a
  form wrote `Provider = 'stub'`, the Claude model, endpoint and version, the Azure version
  and an empty `Models = <>`, freezing today's defaults into the form. `IsProviderStored`,
  `IsModelsStored` (a collection is written even empty), `IsModelStored`/`IsBaseUrlStored`
  (against `DefaultModel`/`DefaultBaseUrl` of the section), `IsApiVersionStored`,
  `IsAzureApiVersionStored`; the fields keep their values, so code reading `Claude.Model`
  sees the same string. `FormFile_KeepsOnlyWhatDiffersFromTheDefaults` streams it as the
  IDE does.
- Localized strings: add the id to `THelpChatMsgId`, to the six `resourcestring` tables of
  `HelpChatAI.Messages` and to the six case functions (a test fails if one language is
  missing a string, another if a translation loses or adds a `%s`). A new language: a member
  at the end of `THelpChatLanguage`, its code, names and Windows primary language id in the
  `LANGUAGE_*` tables, a table and a case function, its flag in
  `resources/HelpChatAI.Providers.rc`, and the member in `HELPCHAT_ALL_LANGUAGES`.

## Conventions

- Ethea header block on every unit; `/// <summary>` XML doc on public types and members.
- Prefix: units `HelpChatAI.*`, types `THelpChat*` / `IHelpChat*`, constants `HELPCHAT_*`,
  CSS classes `hc-chat-*`. Locals `L*`, parameters `A*`, fields `F*`.
- New test fixtures go in `Test/source/HelpChatAI.Tests.*.pas` and are added to the `.dpr` uses.
- `Ext/` and `Setup/InnoSetupScripts` are other repositories (svn:externals), not files of
  this one: a change belongs there, as its own commit, and reaches every Ethea project that
  uses them — so it is made generic and, where it changes behaviour, kept behind a define.

## DPM package (delphi.dev)

The library is also published as a DPM package (Delphi Package Manager, https://delphi.dev,
organization EtheaDev): spec `EtheaDev.HelpChatAI.dspec` in the root (id `EtheaDev.HelpChatAI`). It is packed from the GitHub
clone and pushed by `D:\ETHEA\GitHub_EtheaDev\_sync\sync_project.py Delphi-HelpChatAI --release`; `version`
is aligned to the README release notes automatically and `repositoryCommit: '#HASH#'` is replaced
at pack time: don't edit them by hand.

**Syncing the GitHub clone and publishing (GitHub release, DPM) belong to a dedicated agent,
not to whoever works on the code here**: never run `sync_project.py`, `--release` or a push.
The work here ends with the SVN commit; say when something is ready to go out.

**Keep the dspec aligned with the packages and the Setup**: when a package folder is added or
removed (new Delphi version), a `.dpk` is added/renamed, a new kind of file is needed by the
packages (`.dfm`, `.res`, `.dcr`, ...), or a platform is enabled/disabled in a runtime `.dproj`,
update `targetPlatforms` / `templates` (`source`, `build`, `design`) in the same commit. Check
with `python D:\ETHEA\GitHub_EtheaDev\_sync\dpm_tools.py Delphi-HelpChatAI`: the publishing script refuses
to commit/release while the check fails.

- Delphi 10.4 and 11: VCL packages; 12 and 13: VCL + FMX (template `vclfmx`).
- Dependencies: `EtheaDev.MarkdownProcessor` (range `[2.1.2,)`: raise it when a newer
  MarkdownProcessor is required) and Indy as `bundled` (the IDE's copy).
- `copyLocal` copies `Redist\WebView2\x86|x64\WebView2Loader.dll` next to the executable.
