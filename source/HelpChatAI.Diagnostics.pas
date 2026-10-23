{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and        }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  Is this configuration able to answer? The question the design-time check
///  asks before it opens the chat inside the IDE, and the one an application
///  can ask itself at startup instead of discovering the answer in an error
///  bubble: the provider is registered and has what it needs, the
///  documentation index is where the settings say, the folder of the pages
///  exists.
///
///  What a provider needs is the provider's business: this unit asks the
///  registered class with <see cref="THelpChatProviderBase.ConfigurationIssue" />
///  and reports the sentence it gets back, so a new provider is still a new
///  unit and nothing else.
///
///  The texts are for whoever builds the application, not for its user: they
///  are English, they name properties and files, and they never go through
///  <c>HelpChatAI.Messages</c>.
/// </summary>
unit HelpChatAI.Diagnostics;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  HelpChatAI.Settings;

type
  /// <summary>How much a finding matters. <c>hikError</c> means the chat
  /// cannot work as configured.</summary>
  THelpChatIssueKind = (hikInfo, hikWarning, hikError);

  /// <summary>One finding of the configuration check.</summary>
  THelpChatIssue = record
    Kind: THelpChatIssueKind;
    /// <summary>What it is about ("Provider", "Documentation index"...).</summary>
    Topic: string;
    /// <summary>One sentence, naming the property or the file involved.</summary>
    Text: string;
    class function Create(const AKind: THelpChatIssueKind;
      const ATopic, AText: string): THelpChatIssue; static;
    /// <summary>"Topic: text", with the kind in front of a warning or an error.</summary>
    function ToString: string;
  end;

  THelpChatIssues = TArray<THelpChatIssue>;

/// <summary>Everything the check found, in reading order: the engine first,
/// then the provider, then the documentation. Relative paths in
/// <c>ASettings</c> resolve the way the engine resolves them, against the
/// folder of the running executable: call
/// <see cref="HelpChatExpandSettingsPaths" /> first to check them against
/// another folder.</summary>
function HelpChatCheckSettings(const ASettings: THelpChatSettings): THelpChatIssues;

/// <summary>True when at least one finding is an error.</summary>
function HelpChatHasErrors(const AIssues: THelpChatIssues): Boolean;

/// <summary>The findings as lines, errors and warnings first.</summary>
function HelpChatIssuesToText(const AIssues: THelpChatIssues): string;

/// <summary>Rewrites the relative paths of <c>ASettings</c> as absolute ones
/// against <c>ABaseFolder</c>. The engine resolves them against the folder of
/// the executable, which inside the IDE is the folder of the IDE: a design-time
/// check hands over the output folder of the project instead.</summary>
procedure HelpChatExpandSettingsPaths(const ASettings: THelpChatSettings;
  const ABaseFolder: string);

/// <summary>A copy of <c>ASource</c> as an application living in
/// <c>ABaseFolder</c> would see it: paths expanded against that folder, and
/// the configuration read the way that application would read it -
/// <c>AConfigFileName</c> alone when it names one, otherwise the shared user
/// <c>helpchatai.json</c> and the one of that folder. <c>AConfigFiles</c> lists
/// what was actually read, and raises <c>EHelpChatConfigError</c> when a
/// named file is not there, exactly as the application would. The caller owns
/// the result.</summary>
function HelpChatSettingsForFolder(const ASource: THelpChatSettings;
  const ABaseFolder, AConfigFileName: string;
  out AConfigFiles: TArray<string>): THelpChatSettings;

implementation

uses
  System.IOUtils,
  System.Classes,
  HelpChatAI.Types,
  HelpChatAI.Provider;

resourcestring
  // Not localized on purpose: see the unit summary.
  SHelpChatKindWarning = 'Warning';
  SHelpChatKindError = 'Error';

{ THelpChatIssue }

class function THelpChatIssue.Create(const AKind: THelpChatIssueKind;
  const ATopic, AText: string): THelpChatIssue;
begin
  Result.Kind := AKind;
  Result.Topic := ATopic;
  Result.Text := AText;
end;

function THelpChatIssue.ToString: string;
begin
  case Kind of
    hikWarning: Result := Format('%s - %s: %s', [SHelpChatKindWarning, Topic, Text]);
    hikError: Result := Format('%s - %s: %s', [SHelpChatKindError, Topic, Text]);
  else
    Result := Format('%s: %s', [Topic, Text]);
  end;
end;

{ routines }

procedure Add(var AIssues: THelpChatIssues; const AKind: THelpChatIssueKind;
  const ATopic, AText: string);
begin
  AIssues := AIssues + [THelpChatIssue.Create(AKind, ATopic, AText)];
end;

procedure CheckRemote(const ASettings: THelpChatSettings; var AIssues: THelpChatIssues);
var
  LUrl: string;
begin
  LUrl := ASettings.Remote.NormalizedBaseUrl;
  if not (LUrl.StartsWith('http://', True) or LUrl.StartsWith('https://', True)) then
    Add(AIssues, hikError, 'Remote server',
      Format('Settings.Remote.BaseUrl is "%s": it must be an http:// or https:// address.', [LUrl]))
  else
    Add(AIssues, hikInfo, 'Remote server',
      Format('The engine runs on %s: provider, model key and documentation ' +
        'index are the server''s, not this application''s.', [LUrl]));
  if ASettings.Remote.AppKey = '' then
    Add(AIssues, hikWarning, 'Remote server',
      'Settings.Remote.AppKey is empty: a server that expects one will refuse the session.');
end;

/// <summary>True when the provider itself reported something broken: the
/// checks that follow then keep quiet about the same thing.</summary>
function CheckProvider(const ASettings: THelpChatSettings; var AIssues: THelpChatIssues): Boolean;
var
  LName, LIssue: string;
  LClass: THelpChatProviderClass;
begin
  Result := False;
  LName := Trim(ASettings.Provider);
  if LName = '' then
  begin
    Add(AIssues, hikWarning, 'Provider',
      'Settings.Provider is empty: the stub answers every question with the ' +
      'same placeholder. Set it to claude, to docsearch, or to a provider of yours.');
    Exit;
  end;
  LClass := THelpChatProviderRegistry.FindProviderClass(LName);
  if LClass = nil then
  begin
    Add(AIssues, hikError, 'Provider',
      Format('Nobody registered "%s". Add the unit that registers it to the ' +
        'application (HelpChatAI.Provider.Claude, HelpChatAI.Provider.DocSearch...). ' +
        'Available here: %s.',
        [LName, string.Join(', ', THelpChatProviderRegistry.ProviderNames)]));
    Exit(True);
  end;
  LIssue := LClass.ConfigurationIssue(ASettings);
  if LIssue <> '' then
  begin
    Add(AIssues, hikError, Format('Provider "%s"', [LName]), LIssue);
    Result := True;
  end
  else
    Add(AIssues, hikInfo, 'Provider', Format('"%s" is registered and configured.', [LName]));
end;

procedure CheckDocumentation(const ASettings: THelpChatSettings;
  const AProviderSpokeAlready: Boolean; var AIssues: THelpChatIssues);
var
  LIndexFile, LFolder: string;
begin
  LIndexFile := ASettings.ResolveDocIndexFile;
  if TFile.Exists(LIndexFile) then
    Add(AIssues, hikInfo, 'Documentation index', LIndexFile)
  else if AProviderSpokeAlready then
    // The provider already said what is wrong, and said it better: saying the
    // same thing again as a warning only makes the report harder to read.
    Add(AIssues, hikInfo, 'Documentation index', LIndexFile + ' (not there)')
  else
    Add(AIssues, hikWarning, 'Documentation index',
      Format('"%s" does not exist: the answers have no documentation to ground ' +
        'on. Build it with Tools\HelpIndexBuilder.', [LIndexFile]));

  LFolder := ASettings.ResolveDocFolder;
  if LFolder = '' then
    Add(AIssues, hikInfo, 'Documentation pages',
      'Settings.DocFolder is empty: a link to a page opens in the system ' +
      'browser instead of inside the panel.')
  else if TDirectory.Exists(LFolder) then
    Add(AIssues, hikInfo, 'Documentation pages', LFolder)
  else
    Add(AIssues, hikError, 'Documentation pages',
      Format('Settings.DocFolder points to "%s", which does not exist.', [LFolder]));
end;

function HelpChatCheckSettings(const ASettings: THelpChatSettings): THelpChatIssues;
var
  LProviderSpoke: Boolean;
begin
  Result := [];
  if not Assigned(ASettings) then
  begin
    Add(Result, hikError, 'Settings', 'No settings to check.');
    Exit;
  end;
  // With a remote engine nothing of what follows runs in this process.
  if ASettings.Remote.IsConfigured then
  begin
    CheckRemote(ASettings, Result);
    Exit;
  end;
  LProviderSpoke := CheckProvider(ASettings, Result);
  CheckDocumentation(ASettings, LProviderSpoke, Result);
end;

function HelpChatHasErrors(const AIssues: THelpChatIssues): Boolean;
var
  LIssue: THelpChatIssue;
begin
  for LIssue in AIssues do
    if LIssue.Kind = hikError then
      Exit(True);
  Result := False;
end;

function HelpChatIssuesToText(const AIssues: THelpChatIssues): string;
var
  LKind: THelpChatIssueKind;
  LIssue: THelpChatIssue;
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    for LKind := High(THelpChatIssueKind) downto Low(THelpChatIssueKind) do
      for LIssue in AIssues do
        if LIssue.Kind = LKind then
          LLines.Add(LIssue.ToString);
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

procedure ExpandOne(var APath: string; const ABaseFolder: string);
begin
  if (APath <> '') and TPath.IsRelativePath(APath) then
    APath := TPath.GetFullPath(TPath.Combine(ABaseFolder, APath));
end;

procedure HelpChatExpandSettingsPaths(const ASettings: THelpChatSettings;
  const ABaseFolder: string);
var
  LPath: string;
begin
  if not Assigned(ASettings) or (ABaseFolder = '') then
    Exit;
  // An empty DocIndexFile means "help-index.json next to the executable": made
  // explicit here, or the engine would look for it next to the IDE.
  if Trim(ASettings.DocIndexFile) = '' then
    ASettings.DocIndexFile := TPath.Combine(ABaseFolder, HELPCHAT_DEF_DOCINDEX_FILENAME)
  else
  begin
    LPath := ASettings.DocIndexFile;
    ExpandOne(LPath, ABaseFolder);
    ASettings.DocIndexFile := LPath;
  end;
  LPath := ASettings.DocFolder;
  ExpandOne(LPath, ABaseFolder);
  ASettings.DocFolder := LPath;
  LPath := ASettings.ConversationFile;
  ExpandOne(LPath, ABaseFolder);
  ASettings.ConversationFile := LPath;
end;

function HelpChatSettingsForFolder(const ASource: THelpChatSettings;
  const ABaseFolder, AConfigFileName: string;
  out AConfigFiles: TArray<string>): THelpChatSettings;
var
  LFile: string;
  LCandidates: TArray<string>;
begin
  AConfigFiles := nil;
  Result := THelpChatSettings.Create;
  try
    Result.Assign(ASource);
    HelpChatExpandSettingsPaths(Result, ABaseFolder);
    if Trim(AConfigFileName) <> '' then
    begin
      // Named: that one and nothing else, resolved where the executable would.
      LFile := Trim(AConfigFileName);
      if TPath.IsRelativePath(LFile) then
        LFile := TPath.GetFullPath(TPath.Combine(ABaseFolder, LFile));
      if not TFile.Exists(LFile) then
        raise EHelpChatConfigError.CreateFmt(
          'HelpChat configuration file not found: %s', [LFile]);
      LCandidates := [LFile];
    end
    else
      LCandidates := [THelpChatSettings.SharedUserConfigFile,
        TPath.Combine(ABaseFolder, HELPCHAT_DEF_CONFIG_FILENAME)];
    for LFile in LCandidates do
      if Result.LoadFromFile(LFile) then
      begin
        AConfigFiles := AConfigFiles + [LFile];
        // A file may have brought in relative paths of its own.
        HelpChatExpandSettingsPaths(Result, ABaseFolder);
      end;
  except
    Result.Free;
    raise;
  end;
end;

end.
