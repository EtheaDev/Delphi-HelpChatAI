# HelpChatAI packages

One folder per Delphi version. The full guide, with the Setup and DPM, is the
[Installation](https://ethea.it/docs/helpchatai/Installation) page of the documentation; this
file is the part you need when you build the packages by hand.

## What each Delphi version gets

| Folder | Delphi | Packages | What you can use |
|---|---|---|---|
| `Delphi13` | 13 Florence | all six | VCL and FMX components, engine, server |
| `Delphi12` | 12 Athens | all six | VCL and FMX components, engine, server |
| `Delphi11` | 11 Alexandria | four (no FMX) | VCL component, engine, server |
| `Delphi10.4` | 10.4 Sydney | four (no FMX) | VCL component, engine, server |
| `Delphi10.3` | 10.3 Rio | `HelpChatAI`, `HelpChatAIServer` | engine and server only, from code |
| `Delphi10.2` | 10.2 Tokyo | `HelpChatAI`, `HelpChatAIServer` | engine and server only, from code (not verified) |

| Package | Kind | Contents |
|---|---|---|
| `HelpChatAI` | runtime | the engine: store, providers, index, actions, skills, the panel page |
| `HelpChatAIServer` | runtime | the transports: local server, remote client, remote server, host channel |
| `HelpChatAIVcl` | runtime | `TVclHelpChatAI`, the chat control, VCL style theming, the VCL skills |
| `dclHelpChatAIVcl` | design | palette, component editor with the configuration editor and the preview, property editors |
| `HelpChatAIFmx` | runtime | `TFmxHelpChatAI` and its chat control, the FireMonkey skills |
| `dclHelpChatAIFmx` | design | palette and component editor of the FireMonkey component |

## Installing by hand

1. Get the sources (clone or download the repository).
2. Open `HelpChatAIPackages.groupproj` in the folder of your Delphi version.
3. **Build** the group (Release), then **Install** the design-time packages:
   `dclHelpChatAIVcl`, and `dclHelpChatAIFmx` from Delphi 12 on. The first project of the
   group is the [MarkdownProcessor](https://github.com/EtheaDev/MarkdownProcessor) of Ethea,
   which the engine requires: it is built before the others, and an IDE that already has it
   loaded has to be closed first.
4. Add to the library path of every platform you target:

   ```
   <HelpChatAI>\source
   <HelpChatAI>\Ext\MarkdownProcessor\source
   ```
5. For *Test HelpChat...* and the Appearance preview inside the IDE, either define the IDE
   environment variable `HELPCHATAIDIR` (Tools > Options > Environment Variables) as the folder
   of the library, or copy `Redist\WebView2\<x86|x64>\WebView2Loader.dll` into the output folder
   of your project.

Your application ships `Redist\WebView2\x86|x64\WebView2Loader.dll` next to its executable.

On **Delphi 10.2 and 10.3** steps 3 and 5 do not apply: there is no design-time package and
nothing to install. Build the group, and use `THelpChatEngine` from code - with a user interface
of your own, or as a [server](https://ethea.it/docs/helpchatai/Server).

## From a command line

- `BuildAllPackages.ps1` builds every version installed under `C:\BDS\Studio` - the
  MarkdownProcessor first, then the runtime and the design-time packages - and ends with a
  table of the results; `-DelphiVersion D13,D12` limits it to those versions.
- `BuildAllPackagesD13.ps1` (and `D12`, `D11`, `D10.4`, `D10.3`, `D10.2`) builds one version.
- `BuildPackages.ps1` builds one package of one version.
- `BuildAndTestD13.ps1` builds the packages, the tests, the demos, the server and the tools of
  Delphi 13, then runs the tests.

## Why the components stop at 10.4

The engine needs nothing newer than Delphi 10.2. The VCL and FireMonkey components do:

- the panel is a WebView2 page in `TEdgeBrowser` (VCL) and `TWebBrowser` (FMX); `TEdgeBrowser`
  and the WebView2 interfaces arrived in 10.4, and the PDF export, the design-time preview and
  the configuration editor use them too;
- the icon of the assistant and its property editors rely on image names (`TImageName`,
  `GetIndexByName`, `CheckIndexAndName`), a 10.4 feature, and on `TImageCollection` and
  `TVirtualImageList` (10.3);
- the bubble and the dialogs scale with `TControl.ScaleValue` (10.4) and `CurrentPPI` (10.3);
- the chat stays usable above a modal form thanks to `TApplicationEvents.OnModalEnd`;
- the design packages follow the IDE theme with `IDETheme.Utils`;
- `TFmxHelpChatAI` needs FireMonkey of Delphi 12.

The `.dpk` files are the same in every folder from 10.4 on, thanks to `{$LIBSUFFIX AUTO}`;
the 10.2 and 10.3 ones carry their suffix by hand (`250`, `260`), because `AUTO` arrived in 10.4.
In the `.dproj` only `ProjectVersion` and the folder of the DCUs (`Lib\<version>`) change.
