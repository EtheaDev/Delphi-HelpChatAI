{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                          }
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
{  See the License for the specific language governing permissions and         }
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
///
///  What is checked is one <c>THelpChatSettings</c>, that is one assistant:
///  the root of the configuration with its profile already applied on top
///  (<c>Settings.Profile</c>, as <c>LoadFromJSON</c> does).
///  <c>HelpChatCheckSettings</c> looks at the result and does not tell where
///  a value came from; what needs something else has a routine of its own:
///  <c>HelpChatCheckProfile</c> is given the files that were read and says
///  when none defines the profile, <c>HelpChatCheckActions</c> is given the
///  actions of the running application and says which name of
///  <c>AllowedActions</c> nobody registered. Nothing is started and nothing
///  is called: files are looked for and read, the model is not asked.
/// </summary>
unit HelpChatAI.Diagnostics;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  HelpChatAI.Settings;

type
  /// <summary>How much a finding matters. <c>hikInfo</c> is a fact worth
  /// showing (which file, which folder, which models), <c>hikWarning</c>
  /// something that works but probably not as meant, <c>hikError</c> means
  /// the chat cannot work as configured. The order of the members is the
  /// order of severity: <c>HelpChatIssuesToText</c> relies on it.</summary>
  THelpChatIssueKind = (hikInfo, hikWarning, hikError);

  /// <summary>One finding of the configuration check.</summary>
  THelpChatIssue = record
    Kind: THelpChatIssueKind;
    /// <summary>What it is about ("Provider", "Documentation index"...).</summary>
    Topic: string;
    /// <summary>One sentence, naming the property or the file involved.</summary>
    Text: string;
    /// <summary>A finding from its three parts; the design packages add
    /// their own (project folder, WebView2 loader) to the list this
    /// way.</summary>
    class function Create(const AKind: THelpChatIssueKind;
      const ATopic, AText: string): THelpChatIssue; static;
    /// <summary>"Topic: text", with the kind in front of a warning or an error.</summary>
    function ToString: string;
  end;

  /// <summary>The findings of one check, in the order they were made.</summary>
  THelpChatIssues = TArray<THelpChatIssue>;

/// <summary>Everything the check found, in reading order: the provider in
/// use, then every model of the catalogue (each checked as if it were the
/// one in use, under the topic "Model"), then the documentation index and
/// the folder of the pages. With a
/// remote server configured only that is checked, and only its address and
/// key: nothing else of these settings runs in this process. Relative paths
/// in <c>ASettings</c> resolve the way the engine resolves them, against the
/// folder of the running executable: call
/// <see cref="HelpChatExpandSettingsPaths" /> first to check them against
/// another folder. <c>ASettings</c> is not changed; nil gives one error.
/// With a catalogue of models, the provider checked is the one of the model
/// the engine would apply at its start (<c>ActiveModelName</c>), on a copy:
/// the <c>Provider</c> of the settings is then only the default of the
/// models that name none. <c>DocAreas</c> is compared with the areas the
/// index has.</summary>
function HelpChatCheckSettings(const ASettings: THelpChatSettings): THelpChatIssues;

/// <summary>Whether the configuration knows the profile: a warning when
/// <c>AProfile</c> is not empty and none of <c>AConfigFiles</c> (the files
/// that were read, in any order) has a section <c>Profiles.&lt;AProfile&gt;</c>
/// - the assistant then runs with the root settings alone, which is what a
/// misspelt <c>Profile</c> looks like. An information line naming the file
/// otherwise. Nothing for the default assistant. A file that cannot be read
/// is skipped: reading it is somebody else's error to report.</summary>
function HelpChatCheckProfile(const AProfile: string;
  const AConfigFiles: TArray<string>): THelpChatIssues;

/// <summary>The names of <c>Settings.AllowedActions</c> that no action of
/// the running application answers to, one warning each: a profile narrows,
/// so such a name gives nothing, and a typo there takes an action away
/// without a word. <c>AToolsJson</c> is what the assistant offers
/// (<c>IHelpChatActionInvoker.ToolsJson</c>: own and shared actions, already
/// narrowed). Only a running application can ask: the IDE has no
/// actions.</summary>
function HelpChatCheckActions(const ASettings: THelpChatSettings;
  const AToolsJson: string): THelpChatIssues;

/// <summary>True when at least one finding is an error.</summary>
function HelpChatHasErrors(const AIssues: THelpChatIssues): Boolean;

/// <summary>The findings as lines, errors first, then warnings, then the
/// rest, each group in its original order.</summary>
function HelpChatIssuesToText(const AIssues: THelpChatIssues): string;

/// <summary>Rewrites the relative paths of <c>ASettings</c> as absolute ones
/// against <c>ABaseFolder</c>. The engine resolves them against the folder of
/// the executable, which inside the IDE is the folder of the IDE: a design-time
/// check hands over the output folder of the project instead. Three paths:
/// the index (an empty one becomes <c>help-index.json</c> of that folder,
/// explicitly), the pages folder and the conversation file. Changes
/// <c>ASettings</c> in place - use it on a copy; does nothing with an empty
/// folder.</summary>
procedure HelpChatExpandSettingsPaths(const ASettings: THelpChatSettings;
  const ABaseFolder: string);

/// <summary>A copy of <c>ASource</c> as an application living in
/// <c>ABaseFolder</c> would see it: paths expanded against that folder, and
/// the configuration read the way that application would read it -
/// <c>AConfigFileName</c> alone when it names one, otherwise the shared user
/// <c>helpchatai.json</c>, the one of that folder and - when
/// <c>AExeFile</c> is given - the per-user one. <c>AConfigFiles</c> lists
/// what was actually read, and raises <c>EHelpChatConfigError</c> when a
/// named file is not there, exactly as the application would. The caller owns
/// the result.
///
/// The profile of <c>ASource</c> comes along with the copy, so each file is
/// read as that assistant reads it: its root, then the section of the
/// profile when the file has one. A profile no file defines is not an error
/// here: <see cref="HelpChatCheckProfile" /> reports it. Of the three default
/// files of <c>THelpChatSettings.LoadConfiguration</c> the third, the
/// per-user one of the application, lives in a folder named after the
/// executable: it is read when <c>AExeFile</c> says which executable that is
/// (only its name is used), and left out otherwise. A file that is not valid
/// JSON, or that still uses a key removed in 1.7, raises
/// <c>EHelpChatConfigError</c> too.</summary>
function HelpChatSettingsForFolder(const ASource: THelpChatSettings;
  const ABaseFolder, AConfigFileName: string;
  out AConfigFiles: TArray<string>; const AExeFile: string = ''): THelpChatSettings;

implementation

uses
  System.IOUtils,
  System.Classes,
  System.JSON,
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

// The address is only looked at, never called: a server that is down is
// found out when the user asks for help, like at run time. The key is only
// asked whether it is there, in either node: a deployed file carries the
// encrypted one alone, and nothing is decrypted for a check.
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
  if (Trim(ASettings.Remote.AppKey) = '') and (Trim(ASettings.Remote.AppKeyEncrypted) = '') then
    Add(AIssues, hikWarning, 'Remote server',
      'Settings.Remote.AppKey is empty: a server that expects one will refuse the session.');
end;

/// <summary>True when the provider itself reported something broken: the
/// checks that follow then keep quiet about the same thing. With a catalogue
/// of models the settings handed over already have the model in use
/// applied, and an empty provider is then not the stub but a model that
/// names none: the catalogue check says what is wrong with it.</summary>
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
  // The only thing known about any provider: one sentence, or nothing. No
  // provider is ever named in a condition here.
  LIssue := LClass.ConfigurationIssue(ASettings);
  if LIssue <> '' then
  begin
    Add(AIssues, hikError, Format('Provider "%s"', [LName]), LIssue);
    Result := True;
  end
  else
    Add(AIssues, hikInfo, 'Provider', Format('"%s" is registered and configured.', [LName]));
end;

/// <summary>Every model of the catalogue (<c>Settings.Models</c>), not only
/// the one in use: each is checked as if it were the one, on a copy of the
/// settings it is applied to, so a key or a provider missing shows up before
/// the user picks it in the panel. The routine keeps the name models had
/// before 1.7; its findings say "Model".</summary>
procedure CheckAssistants(const ASettings: THelpChatSettings; var AIssues: THelpChatIssues);
var
  LInfo: THelpChatModelInfo;
  LClass: THelpChatProviderClass;
  LCopy: THelpChatSettings;
  LIssue, LNames: string;
begin
  if ASettings.Models.Count = 0 then
    Exit;
  LNames := '';
  for LInfo in ASettings.ResolveModels do
  begin
    if LNames <> '' then
      LNames := LNames + ', ';
    LNames := LNames + LInfo.Name;
    if LInfo.Model <> '' then
      LNames := LNames + ' (' + LInfo.Model + ')';
    LClass := THelpChatProviderRegistry.FindProviderClass(LInfo.Provider);
    if LClass = nil then
    begin
      Add(AIssues, hikError, Format('Model "%s"', [LInfo.Name]),
        Format('Nobody registered its provider "%s". Available here: %s.',
          [LInfo.Provider, string.Join(', ', THelpChatProviderRegistry.ProviderNames)]));
      Continue;
    end;
    LCopy := THelpChatSettings.Create;
    try
      LCopy.Assign(ASettings);
      LCopy.ApplyModel(LInfo.Name);
      LIssue := LClass.ConfigurationIssue(LCopy);
    finally
      LCopy.Free;
    end;
    if LIssue <> '' then
      Add(AIssues, hikError, Format('Model "%s"', [LInfo.Name]), LIssue);
  end;
  Add(AIssues, hikInfo, 'Models',
    Format('%d to choose from in the panel: %s. In use: %s.',
      [ASettings.Models.Count, LNames, ASettings.ActiveModelName]));
end;

// The areas the assistant is given against the areas the pages of the index
// belong to. An area no page has is the costly mistake: the expert then
// answers from the pages of no area alone, and nothing says why. The index
// is read as JSON, not loaded: no scoring is needed to list its areas.
procedure CheckAreas(const ASettings: THelpChatSettings; const AIndexFile: string;
  var AIssues: THelpChatIssues);
var
  LWanted: TArray<string>;
  LKnown: TStringList;
  LValue, LPages, LItem, LAreas, LArea: TJSONValue;
  LName: string;
begin
  LWanted := ASettings.ResolveDocAreas;
  if Length(LWanted) = 0 then
    Exit;
  LKnown := TStringList.Create;
  try
    LKnown.CaseSensitive := False;
    LKnown.Sorted := True;
    LKnown.Duplicates := dupIgnore;
    LValue := nil;
    try
      try
        LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(AIndexFile, TEncoding.UTF8));
      except
        LValue := nil;
      end;
      // The two shapes the index loader accepts: a bare array, or
      // {"pages": [...]}.
      LPages := LValue;
      if (LValue is TJSONObject) and (TJSONObject(LValue).GetValue('pages') is TJSONArray) then
        LPages := TJSONObject(LValue).GetValue('pages');
      if not (LPages is TJSONArray) then
        Exit;   // an index that cannot be read is the engine's to report
      for LItem in TJSONArray(LPages) do
        if LItem is TJSONObject then
        begin
          LAreas := TJSONObject(LItem).GetValue('areas');
          if LAreas is TJSONArray then
          begin
            for LArea in TJSONArray(LAreas) do
              LKnown.Add(Trim(LArea.Value));
          end
          else if LAreas is TJSONString then   // read as a list, like the index does
            for LName in LAreas.Value.Split([',', ';']) do
              if Trim(LName) <> '' then
                LKnown.Add(Trim(LName));
        end;
    finally
      LValue.Free;
    end;
    for LName in LWanted do
      if LKnown.IndexOf(LName) < 0 then
      begin
        if LKnown.Count = 0 then
          Add(AIssues, hikWarning, 'Documentation areas',
            Format('Settings.DocAreas names "%s", but no page of the index belongs ' +
              'to an area: the manual is flat, or the index was built before the ' +
              'pages were moved into sub-folders. Rebuild it.', [LName]))
        else
          Add(AIssues, hikWarning, 'Documentation areas',
            Format('Settings.DocAreas names "%s", an area no page of the index ' +
              'belongs to. The index has: %s.', [LName, LKnown.CommaText]));
      end;
    if Length(LWanted) > 0 then
      Add(AIssues, hikInfo, 'Documentation areas', string.Join(', ', LWanted));
  finally
    LKnown.Free;
  end;
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
        'on. Build it with Tools\HelpIndexBuilder, or with "Rebuild ' +
        'documentation index..." on the component.', [LIndexFile]));

  if TFile.Exists(LIndexFile) then
    CheckAreas(ASettings, LIndexFile, AIssues);

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
  LApplied: THelpChatSettings;
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
  if ASettings.Models.Count > 0 then
  begin
    // The engine applies the model in use before anything else, so that is
    // what the provider check must look at: with a list, Provider alone is
    // only what a model that names none falls back on - checking it gave a
    // warning about the stub, or an error about a key, for a provider the
    // application never calls.
    LApplied := THelpChatSettings.Create;
    try
      LApplied.Assign(ASettings);
      LApplied.ApplyModel(LApplied.ActiveModelName);
      LProviderSpoke := CheckProvider(LApplied, Result);
    finally
      LApplied.Free;
    end;
  end
  else
    LProviderSpoke := CheckProvider(ASettings, Result);
  CheckAssistants(ASettings, Result);
  CheckDocumentation(ASettings, LProviderSpoke, Result);
end;

function HelpChatCheckProfile(const AProfile: string;
  const AConfigFiles: TArray<string>): THelpChatIssues;
var
  LProfile, LFile, LFound: string;
  LValue, LProfiles: TJSONValue;
  LPair, LEntry: TJSONPair;
begin
  Result := [];
  LProfile := Trim(AProfile);
  if LProfile = '' then
    Exit;
  LFound := '';
  for LFile in AConfigFiles do
  begin
    LValue := nil;
    try
      try
        LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(LFile, TEncoding.UTF8));
      except
        LValue := nil;
      end;
      if LValue is TJSONObject then
        for LPair in TJSONObject(LValue) do
          if SameText(LPair.JsonString.Value, 'Profiles') and (LPair.JsonValue is TJSONObject) then
          begin
            LProfiles := LPair.JsonValue;
            for LEntry in TJSONObject(LProfiles) do
              if SameText(LEntry.JsonString.Value, LProfile) then
              begin
                if LFound <> '' then
                  LFound := LFound + ', ';
                LFound := LFound + LFile;
              end;
          end;
    finally
      LValue.Free;
    end;
  end;
  if LFound <> '' then
    Add(Result, hikInfo, 'Profile', Format('"%s", defined in %s.', [LProfile, LFound]))
  else if Length(AConfigFiles) = 0 then
    Add(Result, hikWarning, 'Profile',
      Format('The component has Profile "%s" and no configuration file was read: ' +
        'this assistant runs with the settings of the component alone, and only ' +
        'the names of its conversation and state files say which one it is.', [LProfile]))
  else
    Add(Result, hikWarning, 'Profile',
      Format('No configuration file has a section "Profiles": {"%s": ...}: this ' +
        'assistant runs with the root settings alone - the same instructions, ' +
        'models and documentation areas as the default one. Check the spelling ' +
        'of Profile, or add the section.', [LProfile]));
end;

function HelpChatCheckActions(const ASettings: THelpChatSettings;
  const AToolsJson: string): THelpChatIssues;
var
  LOffered: TStringList;
  LValue, LItem: TJSONValue;
  LName: string;
begin
  Result := [];
  if not Assigned(ASettings) or (Length(ASettings.ResolveAllowedActions) = 0) then
    Exit;
  LOffered := TStringList.Create;
  try
    LOffered.CaseSensitive := False;
    LValue := TJSONObject.ParseJSONValue(AToolsJson);
    try
      if LValue is TJSONArray then
        for LItem in TJSONArray(LValue) do
          if LItem is TJSONObject then
            LOffered.Add(TJSONObject(LItem).GetValue<string>('name', ''));
    finally
      LValue.Free;
    end;
    for LName in ASettings.ResolveAllowedActions do
      if LOffered.IndexOf(LName) < 0 then
        Add(Result, hikWarning, 'Actions',
          Format('Settings.AllowedActions names "%s", which no action of this ' +
            'assistant answers to (its form registered none by that name, and ' +
            'neither did HelpChatSharedActions): the name allows nothing.', [LName]));
  finally
    LOffered.Free;
  end;
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
    // One pass per kind, the most severe first: the order inside a kind is
    // the order of the check, which a sort would not promise to keep.
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
  out AConfigFiles: TArray<string>; const AExeFile: string): THelpChatSettings;
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
    begin
      LCandidates := [THelpChatSettings.SharedUserConfigFile,
        TPath.Combine(ABaseFolder, HELPCHAT_DEF_CONFIG_FILENAME)];
      // The third file of the defaults: the per-user one, in a folder named
      // after the executable - the application's, never the one running
      // this check (inside the IDE that would be bds.exe).
      if Trim(AExeFile) <> '' then
        LCandidates := LCandidates + [TPath.Combine(TPath.Combine(TPath.GetHomePath,
          TPath.GetFileNameWithoutExtension(AExeFile)), HELPCHAT_DEF_CONFIG_FILENAME)];
    end;
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
