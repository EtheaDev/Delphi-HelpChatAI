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
///  What the configuration editor of the components does, without any form:
///  the two editors - VCL in dclHelpChatAIVcl, FireMonkey in dclHelpChatAIFmx -
///  are views over this controller and keep no rule of their own.
///
///  It edits one configuration file at a time (the shared one of the user,
///  the one next to the executable, the per-user one of the application, or
///  the one <c>ConfigFileName</c> names), at its root or in the profile of the
///  assistant, and writes back only what it was asked to change: the other
///  keys of a file edited by hand stay, in their order. It also tells, for
///  every setting, the value in force and where it comes from - the library,
///  the component, a file and its root or profile - by applying the layers
///  one at a time, the way the component does when it activates.
///
///  Secrets are edited in their clear node only (<c>Claude.ApiKey</c>...):
///  the encrypted node is the application's to write, and this unit has no
///  cipher. They are shown masked.
/// </summary>
unit HelpChatAI.ConfigController;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  HelpChatAI.Settings,
  HelpChatAI.Commands;

const
  /// <summary>The page of the online documentation about the component
  /// editor and the configuration editor: what the Help button of both
  /// editors opens.</summary>
  HELPCHAT_CONFIG_EDITOR_HELP_URL = 'https://ethea.it/docs/helpchatai/Component-Editor';

type
  /// <summary>Which configuration file: the order is the order they are read in.</summary>
  THelpChatConfigFileKind = (cfkShared, cfkApplication, cfkUser, cfkNamed);

  /// <summary>One of the files a component reads, as the editor lists
  /// them.</summary>
  THelpChatConfigFile = record
    Kind: THelpChatConfigFileKind;
    FileName: string;
    /// <summary>What the file is for, in a few words, and where it is.</summary>
    function Caption: string;
    /// <summary>Two words: what the origin of a value says.</summary>
    function ShortCaption: string;
  end;

  /// <summary>How a value is edited, which is what decides the control a
  /// view shows for it: <c>cvkText</c> a line, <c>cvkMemo</c> several (the
  /// prompts), <c>cvkBoolean</c> a check box, <c>cvkList</c> a line of names
  /// separated by commas (free: areas, actions), <c>cvkLanguage</c> a choice
  /// among <c>Choices</c>, <c>cvkSecret</c> a masked line, <c>cvkLanguages</c>
  /// a set - one tick per item of <c>Choices</c> -, <c>cvkNumber</c> a whole
  /// number, <c>cvkChoice</c> a line with the usual values offered
  /// (<c>Choices</c>) and any other accepted - a provider of the application,
  /// a model of a file read later -, <c>cvkSet</c> a set like
  /// <c>cvkLanguages</c> whose items have a caption and a hint of their own
  /// (<c>ChoiceCaptions</c>, <c>ChoiceHints</c>: the skills).</summary>
  THelpChatConfigValueKind = (cvkText, cvkMemo, cvkBoolean, cvkList, cvkLanguage, cvkSecret,
    cvkLanguages, cvkNumber, cvkChoice, cvkSet);

  /// <summary>Where in a file a value is written.</summary>
  THelpChatConfigScope = (ccsRoot, ccsProfile);

  /// <summary>The pages of the editor a setting is listed on: what the chat
  /// looks like, how it works, what the model is told, the documents it
  /// writes. A setting may be on more than one (the name of the assistant is
  /// what the panel shows and how the prompt opens).</summary>
  THelpChatConfigPage = (ccpAppearance, ccpSettings, ccpPrompt, ccpDocuments);
  THelpChatConfigPages = set of THelpChatConfigPage;

  /// <summary>Who set the value in use, in three kinds: what a view shows at
  /// a glance, the way the Object Inspector does - <c>Origin</c> says the
  /// same in words.</summary>
  THelpChatConfigSource = (csrDefault, csrComponent, csrFile);

  /// <summary>One setting as the editor lists it.</summary>
  THelpChatConfigEntry = record
    /// <summary>The JSON path: <c>DocAreas</c>, <c>Claude.Model</c>. It is
    /// also the name of the property under <c>Settings</c> - what the list
    /// shows first and is sorted by, as in the Object Inspector.</summary>
    Path: string;
    /// <summary>What the setting is, in a few words.</summary>
    Caption: string;
    Hint: string;
    Kind: THelpChatConfigValueKind;
    /// <summary>The pages of the editor that list it.</summary>
    Pages: THelpChatConfigPages;
    /// <summary>A setting of one provider (<c>Claude.*</c>, <c>OpenAI.*</c>,
    /// <c>Gemini.*</c>): listed after those of the component.</summary>
    IsModel: Boolean;
    /// <summary>The value the component uses, as text, never empty: what is
    /// configured, else what an empty value resolves to - the default model
    /// of the provider, the localized greeting, the language of the OS - or,
    /// where nothing takes its place, a word in parentheses that says so
    /// ("(none)", "(the whole manual)"). A secret is masked.</summary>
    InUse: string;
    /// <summary>The value in use as it would be written - no masking, no
    /// word in parentheses: what a view puts in its edit control when the
    /// file being edited does not say the value itself. When nothing is
    /// configured it is what replaces the empty value - the localized
    /// greeting, the default model, the text of the library - so that a
    /// small correction is a correction and not a value typed from scratch;
    /// empty only where nothing replaces it. Always empty for a secret: a
    /// key is shown only from the file that holds it.</summary>
    Value: string;
    /// <summary>What a view offers for a <c>cvkLanguage</c>,
    /// <c>cvkLanguages</c> or <c>cvkChoice</c>: the language codes (with
    /// <c>auto</c> for a single language), the providers registered in this
    /// process, the names of the models in force. Empty for the other
    /// kinds. For a <c>cvkSet</c>, the names registered in this process
    /// followed by those the file being edited names and nobody registered
    /// here (a skill of the application): ticked, so that saving keeps
    /// them.</summary>
    Choices: TArray<string>;
    /// <summary>For a <c>cvkSet</c>, what the view shows for each item of
    /// <c>Choices</c> (the name and the actions of a skill), in the same
    /// order; empty for the other kinds, where the item is its own
    /// caption. What a view writes back is always the item of
    /// <c>Choices</c>.</summary>
    ChoiceCaptions: TArray<string>;
    /// <summary>For a <c>cvkSet</c>, what each item of <c>Choices</c> is, in
    /// a sentence or two: what a view shows when the item is
    /// selected.</summary>
    ChoiceHints: TArray<string>;
    /// <summary>Who set it: "Library default", the property of the
    /// component that holds it ("Component: Settings.Expertise"), or the
    /// caption of a file with "root" or "profile X".</summary>
    Origin: string;
    /// <summary><c>Origin</c> as one of three kinds.</summary>
    Source: THelpChatConfigSource;
    /// <summary>In the file being edited, at its root.</summary>
    RootValue: string;
    InRoot: Boolean;
    /// <summary>In the file being edited, in the profile of the assistant.</summary>
    ProfileValue: string;
    InProfile: Boolean;
    /// <summary>True when the component sets a value of its own, other than
    /// the library's - what the form file stores, and what
    /// <c>ResetComponentValue</c> takes away. A file may still prevail over
    /// it, so this is not the same as <c>Source</c> = <c>csrComponent</c>.</summary>
    InComponent: Boolean;
  end;

  /// <summary>One model of a catalogue.</summary>
  THelpChatConfigModel = record
    Name: string;
    Provider: string;
    Model: string;
    BaseUrl: string;
    Icon: string;
    /// <summary>The clear key of this model, when it has one of its own.</summary>
    ApiKey: string;
    /// <summary>The name the model has in the file, as <c>Models</c> read it;
    /// empty for a model the view is adding. <c>SetModels</c> finds the entry
    /// of the file by it, so a model that is renamed keeps what the editor
    /// does not show (its encrypted key, a key written by hand).</summary>
    Original: string;
  end;

  /// <summary>The model behind the two configuration editors. It holds the
  /// file being edited as a JSON document (<c>TargetIndex</c> of <c>Files</c>)
  /// and answers, for the assistant <c>Profile</c>: every setting with its
  /// value in force and where it comes from (<c>Entries</c>), the profiles of
  /// the file, its catalogue of models and the models the profile offers.
  /// Nothing is written to disk until <c>Save</c>; the other files are read as
  /// they are on disk. Main thread, design time: it never touches an
  /// engine.</summary>
  THelpChatConfigController = class
  strict private
    FComponentSettings: THelpChatSettings;
    FProfile: string;
    FFiles: TArray<THelpChatConfigFile>;
    FTargetIndex: Integer;
    FDoc: TJSONObject;
    FModified: Boolean;
    FLastError: string;
    FLoadError: string;
    FComponentAssistantName: string;
    /// <summary>Path -> text, filled by PromptPreview.</summary>
    FFragments: TDictionary<string, string>;
    /// <summary>The executable of the project: its folder is where a relative
    /// file of the component is looked for.</summary>
    FExeFile: string;
    procedure SetTargetIndex(const Value: Integer);
    /// <summary>What <c>InUse</c> says for APath, given the settings with
    /// every layer applied and ARaw, the value they hold as text.</summary>
    function InUseText(const ASettings: THelpChatSettings; const APath, ARaw: string): string;
    /// <summary>What <c>Choices</c> says for APath, given the settings with
    /// every layer applied.</summary>
    class function ChoicesOf(const ASettings: THelpChatSettings; const APath: string;
      const AKind: THelpChatConfigValueKind): TArray<string>; static;
    procedure SetProfile(const Value: string);
    function ScopeObject(const AScope: THelpChatConfigScope; const ACreate: Boolean): TJSONObject;
    class function FindValue(const AObject: TJSONObject; const APath: string): TJSONValue; static;
    function ValueToText(const AValue: TJSONValue): string;
    function TextToValue(const APath, AText: string): TJSONValue;
    function ProfilesObject(const ACreate: Boolean): TJSONObject;
    function DocumentOf(const AIndex: Integer): TJSONObject;
    /// <summary>What each setting writes into APrompt, built from ASettings.</summary>
    procedure FillFragments(const ASettings: THelpChatSettings; const APrompt: string);
    /// <summary>The settings this assistant runs with: the component, then
    /// each file (the one being edited as it is in memory), root and
    /// profile. The caller frees them. Raises what a file raises, with its
    /// name.</summary>
    function LayeredSettings: THelpChatSettings;
  public
    /// <summary>ASettings are the component's (its DFM values), not owned:
    /// SetComponentValue writes into them. AExeFile is the executable of the
    /// project (its folder holds the application file, its name the per-user
    /// folder); AConfigFileName the component's - named, it is the only file.</summary>
    constructor Create(const AComponentSettings: THelpChatSettings;
      const AProfile, AExeFile, AConfigFileName: string);
    destructor Destroy; override;

    /// <summary>Every setting the editor offers, without values.</summary>
    class function Catalogue: TArray<THelpChatConfigEntry>; static;
    /// <summary>How the value at APath is edited: what the catalogue says, and
    /// for a path it does not list a secret when the name ends in ApiKey,
    /// AppKey or UserToken, text otherwise.</summary>
    class function KindOf(const APath: string): THelpChatConfigValueKind; static;
    /// <summary>A secret as it can be shown: its length and its last four
    /// characters, never more.</summary>
    class function MaskSecret(const AValue: string): string; static;
    /// <summary>The files of the component, in the order they are read.</summary>
    class function FilesFor(const AExeFile, AConfigFileName: string): TArray<THelpChatConfigFile>; static;
    /// <summary>The index in AFiles of the file the configuration of the
    /// assistant AProfile comes from, which is the one the editor opens on.
    /// Read from the last file to the first (the last one read wins): the
    /// last that defines the profile; else the last that sets a value of the
    /// catalogue other than a key, or names models; else the last that holds
    /// a key of the catalogue - a file with nothing but a key (the per-user
    /// one, where an application writes its encrypted key) is where the key
    /// is, not the configuration. With none of these the application file,
    /// the one that ships; 0 when there is none, or one file only. A file
    /// that is missing or not a JSON object counts as empty.</summary>
    class function ConfiguringFile(const AFiles: TArray<THelpChatConfigFile>;
      const AProfile: string): Integer; static;

    /// <summary>Reads the file being edited again, dropping what was not saved.</summary>
    procedure Reload;
    /// <summary>Writes the file being edited, creating its folder. False with
    /// the reason in <c>LastError</c> - also when the file was there and
    /// could not be read (<c>LoadError</c>): what is in memory is then an
    /// empty document, and writing it would replace a file somebody only has
    /// to fix a comma in.</summary>
    function Save: Boolean;
    /// <summary>The configuration this assistant would run with, read the way
    /// the component reads it: '' when it loads, else the error it would
    /// raise (a key before 1.7, a model the catalogue does not have...).</summary>
    function Validate: string;

    /// <summary>The settings, their value in force and its origin, and what
    /// the file being edited says of each at its root and in the profile.
    /// Those of the component first, by name, then those of the providers.</summary>
    function Entries: TArray<THelpChatConfigEntry>;
    /// <summary>The settings of AEntries listed on APage, in the order the
    /// page shows them: by name, the providers last - and on the Prompt
    /// page in the order the prompt is written, so that the list reads
    /// like the text beside it (<c>PROMPT_ORDER</c>).</summary>
    class function EntriesOfPage(const AEntries: TArray<THelpChatConfigEntry>;
      const APage: THelpChatConfigPage): TArray<THelpChatConfigEntry>; static;
    /// <summary>The system prompt this assistant would send, built from the
    /// settings in force - the component, the files as the editor has them,
    /// the profile - for a sample question asked from a sample screen, with a
    /// sample excerpt of the manual: what the Prompt page shows. The rule
    /// about the actions, which nobody may change, is named at the end
    /// rather than copied. <c>OnBuildSystemPrompt</c> does not run in the
    /// IDE, so whatever it would change is not in it.</summary>
    function PromptPreview: string;
    /// <summary>The part of the last <see cref="PromptPreview" /> that the
    /// setting at APath writes: the sentence of a rule, the instructions, the
    /// excerpts of the manual for the grounding of a provider. Empty when
    /// the setting writes nothing there (or nothing now: a rule of the
    /// expertise with no expertise). What the Prompt page shows in bold.</summary>
    function PromptFragment(const APath: string): string;
    /// <summary>
    ///  The panel as this assistant would show it, for the Appearance page:
    ///  the page of the library with the greeting, a question, a short answer
    ///  and the answer of <c>/help</c>, in the language, with the name and the
    ///  greeting the settings in force give.
    ///  <para><c>ADark</c> picks the built-in dark theme, else the light one;
    ///  <c>AIconDataUri</c> is the icon of the component (the view draws it:
    ///  an image list is the framework's); <c>AStyleSheetFile</c> its
    ///  <c>PanelStyleSheet</c>, relative to the folder of the executable of
    ///  the project. A style sheet that cannot be read is left out and
    ///  <c>AStyleSheetError</c> says why: the preview must not fail where the
    ///  application would refuse to start, it must say so.</para>
    /// </summary>
    function AppearancePreview(const ADark: Boolean; const AIconDataUri,
      AStyleSheetFile: string; const ACommands: THelpChatCommands;
      out AStyleSheetError: string): string;
    /// <summary>What the file being edited says at APath, at its root or in
    /// the profile: False when the key is not there (which is not the same as
    /// an empty value). A secret comes back in clear: the caller masks
    /// it.</summary>
    function GetValue(const APath: string; const AScope: THelpChatConfigScope;
      out AText: string): Boolean;
    /// <summary>Writes AText at APath of the file being edited. A list is
    /// written as an array, a boolean as a boolean, the rest as text.</summary>
    procedure SetValue(const APath: string; const AScope: THelpChatConfigScope;
      const AText: string);
    /// <summary>Takes the key away from the file being edited, so that the
    /// layer below decides again. An empty section is left behind.</summary>
    procedure RemoveValue(const APath: string; const AScope: THelpChatConfigScope);
    /// <summary>Writes AText into the component's settings - what goes into
    /// the form file. Secrets are refused: a key belongs to a file.
    /// <c>AssistantName</c> also becomes <see cref="ComponentAssistantName" />:
    /// the settings do not publish it, so the caller moves it from them to
    /// the property of the component.</summary>
    procedure SetComponentValue(const APath, AText: string);
    /// <summary>Gives the setting at APath of the component the value of the
    /// library back, like "Revert to inherited" in the Object Inspector:
    /// the form file stops storing it. <c>AssistantName</c> empties
    /// <see cref="ComponentAssistantName" />. Secrets are refused, as by
    /// <c>SetComponentValue</c>.</summary>
    procedure ResetComponentValue(const APath: string);

    /// <summary>The profiles of the file being edited.</summary>
    function Profiles: TArray<string>;
    /// <summary>Adds an empty profile to the file being edited; nothing
    /// happens when the name is empty or taken.</summary>
    procedure AddProfile(const AName: string);
    /// <summary>Renames a profile of the file being edited, keeping its place
    /// and its content; this controller follows when it was editing that one.
    /// The <c>Profile</c> of the components that name it is theirs to change:
    /// the tie is the name.</summary>
    procedure RenameProfile(const AOldName, ANewName: string);
    /// <summary>Removes a profile of the file being edited with everything it
    /// says.</summary>
    procedure DeleteProfile(const AName: string);

    /// <summary>The catalogue of models at the root of the file being edited.</summary>
    function Models: TArray<THelpChatConfigModel>;
    /// <summary>Replaces the catalogue. A model the file already had (found
    /// by <c>Original</c>, else by <c>Name</c>) keeps every key the editor
    /// does not show, in its place: the encrypted key, which this editor
    /// never writes and never drops, and whatever was written by hand.</summary>
    procedure SetModels(const AModels: TArray<THelpChatConfigModel>);
    /// <summary>The names a view offers to tick for the profile: the models
    /// of the catalogue of this file, then the names the profile already
    /// offers that are not among them - a model of the catalogue of another
    /// file, or one the profile defines inline. Without the second half a
    /// view showed them unticked, and the next write took them away.</summary>
    function ProfileModelChoices: TArray<string>;
    /// <summary>The names of the models the profile offers; nil when it names
    /// none (the catalogue of the root applies).</summary>
    function ProfileModelNames: TArray<string>;
    /// <summary>Writes the models the profile offers as a list of names of the
    /// catalogue; an empty list removes the key, and the catalogue of the root
    /// applies again. A model the profile defined inline (an object, not a
    /// name) and that is still in the list stays the object it was.</summary>
    procedure SetProfileModelNames(const ANames: TArray<string>);

    /// <summary>The files the component reads, in the order it reads them: the
    /// named one alone, or the shared, the application's and the per-user
    /// one.</summary>
    property Files: TArray<THelpChatConfigFile> read FFiles;
    /// <summary>The file being edited; setting it reloads.</summary>
    property TargetIndex: Integer read FTargetIndex write SetTargetIndex;
    /// <summary>The profile of the assistant; empty = the default one.</summary>
    property Profile: string read FProfile write SetProfile;
    /// <summary>The <c>AssistantName</c> of the component: a property of the
    /// component, not of its settings, which is why the views pass it apart.
    /// It is the component's layer of "Name of the assistant", under the
    /// files, as at run time: a name in a file prevails.</summary>
    property ComponentAssistantName: string read FComponentAssistantName
      write FComponentAssistantName;
    /// <summary>Why the file being edited could not be read (it exists and is
    /// not a JSON object); empty when it was read, or is not there yet. While
    /// it is set the file is shown empty and <c>Save</c> refuses.</summary>
    property LoadError: string read FLoadError;
    /// <summary>True when the file being edited has changes <c>Save</c> has
    /// not written yet.</summary>
    property Modified: Boolean read FModified;
    /// <summary>Why the last <c>Reload</c>, <c>Save</c> or <c>Entries</c> did
    /// not go as asked; empty when it did.</summary>
    property LastError: string read FLastError;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.TypInfo,
  System.Variants,
  HelpChatAI.Types,
  HelpChatAI.Html,
  HelpChatAI.Panel,
  HelpChatAI.Theme,
  HelpChatAI.Messages,
  HelpChatAI.Provider,
  HelpChatAI.Skills;

const
  SKILL_NOT_REGISTERED_CAPTION = '%s (not registered here)';
  SKILL_NOT_REGISTERED_HINT = 'No skill of this name is registered in the IDE: it may be one ' +
    'the application registers, or a typo. It stays in the file as it is; untick it to remove it.';

/// <summary>Completes an entry of kind cvkSet: the names the file being
/// edited or the settings in force name and nobody registered here are added
/// to the choices, and every choice gets its caption and its hint.</summary>
procedure CompleteSetEntry(var AEntry: THelpChatConfigEntry);

  procedure AddNamesOf(const AText: string);
  var
    LName: string;
  begin
    for LName in AText.Split([',', ';']) do
      if (Trim(LName) <> '') and not MatchText(Trim(LName), AEntry.Choices) then
        AEntry.Choices := AEntry.Choices + [Trim(LName)];
  end;

var
  I: Integer;
  LActions: TArray<string>;
begin
  if not SameText(AEntry.Path, 'Skills') then
    Exit;
  AddNamesOf(AEntry.Value);
  AddNamesOf(AEntry.RootValue);
  AddNamesOf(AEntry.ProfileValue);
  SetLength(AEntry.ChoiceCaptions, Length(AEntry.Choices));
  SetLength(AEntry.ChoiceHints, Length(AEntry.Choices));
  for I := 0 to High(AEntry.Choices) do
    if HelpChatIsSkillRegistered(AEntry.Choices[I]) then
    begin
      LActions := HelpChatSkillActionNames(AEntry.Choices[I]);
      AEntry.ChoiceCaptions[I] := AEntry.Choices[I] + ' - ' + string.Join(', ', LActions);
      AEntry.ChoiceHints[I] := HelpChatSkillDescription(AEntry.Choices[I], hclEnglish);
    end
    else
    begin
      AEntry.ChoiceCaptions[I] := Format(SKILL_NOT_REGISTERED_CAPTION, [AEntry.Choices[I]]);
      AEntry.ChoiceHints[I] := SKILL_NOT_REGISTERED_HINT;
    end;
end;

/// <summary>Adds to the hint of AllowedActions the actions the skills add to
/// it: naming a skill allows its actions, which a list of allowed actions
/// does not show.</summary>
procedure NoteSkillActions(const ASettings: THelpChatSettings; var AEntry: THelpChatConfigEntry);
var
  LSkill, LAction: string;
  LActions: TArray<string>;
begin
  if not SameText(AEntry.Path, 'AllowedActions') or
     (Length(ASettings.ResolveAllowedActions) = 0) then
    Exit;
  LActions := nil;
  for LSkill in ASettings.ResolveSkills do
    for LAction in HelpChatSkillActionNames(LSkill) do
      if not MatchText(LAction, LActions) then
        LActions := LActions + [LAction];
  if Length(LActions) > 0 then
    AEntry.Hint := AEntry.Hint + '; the skills add their own: ' + string.Join(', ', LActions);
end;

type
  TCatalogueItem = record
    Path: string;
    Caption: string;
    Kind: THelpChatConfigValueKind;
    Pages: THelpChatConfigPages;
    Hint: string;
  end;

const
  CATALOGUE_ITEMS: array[0..79] of TCatalogueItem = (
    (Path: 'AssistantName'; Caption: 'Name of the assistant'; Kind: cvkText;
      Pages: [ccpAppearance, ccpPrompt]; Hint: 'What the panel calls it and how the prompt opens; prevails over the property of the component'),
    (Path: 'Greeting'; Caption: 'Greeting'; Kind: cvkText;
      Pages: [ccpAppearance]; Hint: 'The first bubble; empty = the localized one'),
    (Path: 'Expertise'; Caption: 'Field of expertise'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: 'What it knows beyond the manual ("general accounting"): opens the system prompt'),
    (Path: 'Instructions'; Caption: 'Instructions'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: 'What this assistant does in detail: added after the rules'),
    (Path: 'SystemPrompt'; Caption: 'Rules of the assistant'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: 'The built-in rules about the excerpts and the citations: change them with care; empty = the librarys'),
    (Path: 'IdentityRule'; Caption: 'Opening sentence'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: '%0:s the name of the assistant; empty = the librarys'),
    (Path: 'NowRule'; Caption: 'Date and time'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: '%s now; it goes with the question (claude), not in the system prompt; empty = the librarys'),
    (Path: 'LanguageRule'; Caption: 'Language of the reply'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: '%0:s the language of the chat; empty = the librarys'),
    (Path: 'DocLanguageRule'; Caption: 'Manual in another language'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: 'When DocLanguage differs from the chat: %0:s the manuals, %1:s the chats; empty = the librarys'),
    (Path: 'ExpertiseIntro'; Caption: 'Field of expertise, as said'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: 'What Expertise (%s) becomes in the prompt; empty = the librarys'),
    (Path: 'ExpertiseRule'; Caption: 'Rule of the expertise'; Kind: cvkMemo;
      Pages: [ccpPrompt]; Hint: 'Added after the rules when there is an Expertise; empty = the librarys'),
    (Path: 'Provider'; Caption: 'Provider'; Kind: cvkChoice;
      Pages: [ccpSettings]; Hint: 'stub, docsearch, claude, openai, gemini or one of yours'),
    (Path: 'SelectedModel'; Caption: 'Model in use at start'; Kind: cvkChoice;
      Pages: [ccpSettings]; Hint: 'A name of the Models list'),
    (Path: 'Language'; Caption: 'Language of the chat'; Kind: cvkLanguage;
      Pages: [ccpSettings, ccpPrompt]; Hint: 'auto, en, it, es, fr, de, pt'),
    (Path: 'Languages'; Caption: 'Languages offered'; Kind: cvkLanguages;
      Pages: [ccpSettings]; Hint: 'What the flag of the panel offers; fewer than two = no flag'),
    (Path: 'DocLanguage'; Caption: 'Language of the manual'; Kind: cvkLanguage;
      Pages: [ccpSettings, ccpPrompt]; Hint: 'auto = not stated'),
    (Path: 'DocIndexFile'; Caption: 'Documentation index'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Relative to the executable'),
    (Path: 'DocFolder'; Caption: 'Pages folder'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Relative to the executable'),
    (Path: 'DocBaseUrl'; Caption: 'Base URL of the pages'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: ''),
    (Path: 'DocAreas'; Caption: 'Areas of the manual'; Kind: cvkList;
      Pages: [ccpSettings]; Hint: 'The sub-folders this assistant knows; empty = the whole manual'),
    (Path: 'AllowedActions'; Caption: 'Allowed actions'; Kind: cvkList;
      Pages: [ccpSettings]; Hint: 'Narrows what the code registers; empty = all of them'),
    (Path: 'Skills'; Caption: 'Skills'; Kind: cvkSet;
      Pages: [ccpSettings]; Hint: 'Sets of actions the library writes: tick the ones this assistant has'),
    (Path: 'PersistConversation'; Caption: 'Save the conversation'; Kind: cvkBoolean;
      Pages: [ccpSettings]; Hint: ''),
    (Path: 'ConversationFile'; Caption: 'Conversation file'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = in the per-user folder of the application'),
    (Path: 'ConversationMaxAgeDays'; Caption: 'Days a saved conversation lasts'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'An older one is discarded at load; 0 = never'),
    (Path: 'MessageMaxLength'; Caption: 'Longest question'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In characters, longer ones are cut; 0 = no limit'),
    (Path: 'HistoryMaxMessages'; Caption: 'Messages sent with a question'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'The most recent ones of the conversation; 0 = all'),
    (Path: 'MaxStoredMessages'; Caption: 'Messages kept'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'Older ones are pruned; 0 = unlimited'),
    (Path: 'PoolSize'; Caption: 'Replies at the same time'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'Worker threads producing replies, 1 or more'),
    (Path: 'Attachments.Enabled'; Caption: 'Attachments allowed'; Kind: cvkBoolean;
      Pages: [ccpSettings]; Hint: 'What the user attaches leaves the machine'),
    (Path: 'Attachments.MaxCount'; Caption: 'Attachments at most'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'Documents in one conversation'),
    (Path: 'Attachments.MaxSizeKB'; Caption: 'Largest attachment'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In KB'),
    (Path: 'Attachments.MaxTotalKB'; Caption: 'All attachments together'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In KB'),
    (Path: 'Remote.BaseUrl'; Caption: 'Remote server'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = the engine runs in the application'),
    (Path: 'Remote.AppKey'; Caption: 'Remote: application key'; Kind: cvkSecret;
      Pages: [ccpSettings]; Hint: ''),
    (Path: 'Remote.UserId'; Caption: 'Remote: user'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Who the server keeps the conversation of'),
    (Path: 'Remote.UserToken'; Caption: 'Remote: user token'; Kind: cvkSecret;
      Pages: [ccpSettings]; Hint: ''),
    (Path: 'Remote.UseHostChannel'; Caption: 'Remote: host channel'; Kind: cvkBoolean;
      Pages: [ccpSettings]; Hint: 'The page reaches the application through a local channel'),
    (Path: 'Remote.TimeoutMs'; Caption: 'Remote: timeout'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In milliseconds'),
    (Path: 'Pdf.Enabled'; Caption: 'PDF from the panel'; Kind: cvkBoolean;
      Pages: [ccpDocuments]; Hint: 'The buttons that save an answer, the conversation or a page as PDF'),
    (Path: 'Pdf.Action'; Caption: 'PDF on request'; Kind: cvkBoolean;
      Pages: [ccpDocuments]; Hint: 'The assistant may write a document when the user asks for one'),
    (Path: 'Pdf.Paper'; Caption: 'Paper'; Kind: cvkChoice;
      Pages: [ccpDocuments]; Hint: 'a4 or letter'),
    (Path: 'Pdf.Orientation'; Caption: 'Orientation'; Kind: cvkChoice;
      Pages: [ccpDocuments]; Hint: 'portrait or landscape'),
    (Path: 'Pdf.MarginMm'; Caption: 'Margins'; Kind: cvkNumber;
      Pages: [ccpDocuments]; Hint: 'In millimetres'),
    (Path: 'Pdf.PrintBackgrounds'; Caption: 'Print backgrounds'; Kind: cvkBoolean;
      Pages: [ccpDocuments]; Hint: ''),
    (Path: 'Pdf.HeaderFooter'; Caption: 'Header and footer'; Kind: cvkBoolean;
      Pages: [ccpDocuments]; Hint: 'The bands of PdfHeaderFile and PdfFooterFile, or the librarys'),
    (Path: 'Pdf.BandMm'; Caption: 'Height of the bands'; Kind: cvkNumber;
      Pages: [ccpDocuments]; Hint: 'In millimetres, added to the margin'),
    (Path: 'Claude.ApiKey'; Caption: 'Claude: API key'; Kind: cvkSecret;
      Pages: [ccpSettings]; Hint: 'The clear key of the developer; the application writes ApiKeyEncrypted'),
    (Path: 'Claude.Model'; Caption: 'Claude: model'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = the default'),
    (Path: 'Claude.BaseUrl'; Caption: 'Claude: endpoint'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = the default'),
    (Path: 'Claude.MaxTokens'; Caption: 'Claude: longest reply'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In tokens'),
    (Path: 'Claude.GroundingMaxPages'; Caption: 'Claude: pages of the manual'; Kind: cvkNumber;
      Pages: [ccpSettings, ccpPrompt]; Hint: 'Excerpts sent with a question; 0 = none'),
    (Path: 'Claude.GroundingMaxChars'; Caption: 'Claude: length of an excerpt'; Kind: cvkNumber;
      Pages: [ccpSettings, ccpPrompt]; Hint: 'In characters'),
    (Path: 'Claude.ConnectTimeoutMs'; Caption: 'Claude: connection timeout'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In milliseconds'),
    (Path: 'Claude.ResponseTimeoutMs'; Caption: 'Claude: response timeout'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In milliseconds'),
    (Path: 'Claude.MaxToolRounds'; Caption: 'Claude: rounds of actions'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'Model, actions, model again: how many times at most'),
    (Path: 'Claude.ApiVersion'; Caption: 'Claude: API version'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = the default'),
    (Path: 'Claude.PromptCaching'; Caption: 'Claude: prompt caching'; Kind: cvkBoolean;
      Pages: [ccpSettings]; Hint: 'What repeats is billed at a tenth; off for a proxy that refuses it'),
    (Path: 'OpenAI.ApiKey'; Caption: 'OpenAI: API key'; Kind: cvkSecret;
      Pages: [ccpSettings]; Hint: 'The clear key of the developer; the application writes ApiKeyEncrypted'),
    (Path: 'OpenAI.Model'; Caption: 'OpenAI: model'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = the default'),
    (Path: 'OpenAI.BaseUrl'; Caption: 'OpenAI: endpoint'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Ollama, LM Studio, Azure, Groq...'),
    (Path: 'OpenAI.MaxTokens'; Caption: 'OpenAI: longest reply'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In tokens'),
    (Path: 'OpenAI.GroundingMaxPages'; Caption: 'OpenAI: pages of the manual'; Kind: cvkNumber;
      Pages: [ccpSettings, ccpPrompt]; Hint: 'Excerpts sent with a question; 0 = none'),
    (Path: 'OpenAI.GroundingMaxChars'; Caption: 'OpenAI: length of an excerpt'; Kind: cvkNumber;
      Pages: [ccpSettings, ccpPrompt]; Hint: 'In characters'),
    (Path: 'OpenAI.ConnectTimeoutMs'; Caption: 'OpenAI: connection timeout'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In milliseconds'),
    (Path: 'OpenAI.ResponseTimeoutMs'; Caption: 'OpenAI: response timeout'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In milliseconds'),
    (Path: 'OpenAI.MaxToolRounds'; Caption: 'OpenAI: rounds of actions'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'Model, actions, model again: how many times at most'),
    (Path: 'OpenAI.Api'; Caption: 'OpenAI: API'; Kind: cvkChoice;
      Pages: [ccpSettings]; Hint: 'responses or chat; empty = Responses on api.openai.com, chat elsewhere'),
    (Path: 'OpenAI.Organization'; Caption: 'OpenAI: organization'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: ''),
    (Path: 'OpenAI.AzureDeployment'; Caption: 'OpenAI: Azure deployment'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Moves the path to /openai/deployments/<name>'),
    (Path: 'OpenAI.AzureApiVersion'; Caption: 'OpenAI: Azure API version'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = the default'),
    (Path: 'Gemini.ApiKey'; Caption: 'Gemini: API key'; Kind: cvkSecret;
      Pages: [ccpSettings]; Hint: 'The clear key of the developer; the application writes ApiKeyEncrypted'),
    (Path: 'Gemini.Model'; Caption: 'Gemini: model'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = the default'),
    (Path: 'Gemini.BaseUrl'; Caption: 'Gemini: endpoint'; Kind: cvkText;
      Pages: [ccpSettings]; Hint: 'Empty = the default'),
    (Path: 'Gemini.MaxTokens'; Caption: 'Gemini: longest reply'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In tokens'),
    (Path: 'Gemini.GroundingMaxPages'; Caption: 'Gemini: pages of the manual'; Kind: cvkNumber;
      Pages: [ccpSettings, ccpPrompt]; Hint: 'Excerpts sent with a question; 0 = none'),
    (Path: 'Gemini.GroundingMaxChars'; Caption: 'Gemini: length of an excerpt'; Kind: cvkNumber;
      Pages: [ccpSettings, ccpPrompt]; Hint: 'In characters'),
    (Path: 'Gemini.ConnectTimeoutMs'; Caption: 'Gemini: connection timeout'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In milliseconds'),
    (Path: 'Gemini.ResponseTimeoutMs'; Caption: 'Gemini: response timeout'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'In milliseconds'),
    (Path: 'Gemini.MaxToolRounds'; Caption: 'Gemini: rounds of actions'; Kind: cvkNumber;
      Pages: [ccpSettings]; Hint: 'Model, actions, model again: how many times at most'));

  ORIGIN_DEFAULT = 'Library default';
  ORIGIN_COMPONENT = 'Component';
  /// <summary>The sections of the providers: their settings are listed last.</summary>
  MODEL_SECTIONS: array[0..2] of string = ('Claude', 'OpenAI', 'Gemini');
  /// <summary>The settings of the Prompt page in the order the prompt is
  /// written (BuildSystemPrompt and ResolveSystemPrompt): the opening
  /// sentence with the name, the field of expertise, the rules, the rule of
  /// the expertise, the instructions, the language of the reply, the
  /// language of the manual, then the excerpts the grounding of each
  /// provider decides. A setting not listed goes after them.</summary>
  PROMPT_ORDER: array[0..17] of string = ('AssistantName', 'IdentityRule', 'Expertise',
    'ExpertiseIntro', 'SystemPrompt', 'ExpertiseRule', 'Instructions', 'Language',
    'LanguageRule', 'DocLanguage', 'DocLanguageRule', 'NowRule',
    'Claude.GroundingMaxPages', 'Claude.GroundingMaxChars',
    'OpenAI.GroundingMaxPages', 'OpenAI.GroundingMaxChars',
    'Gemini.GroundingMaxPages', 'Gemini.GroundingMaxChars');
  /// <summary>The texts of the prompt whose default is a constant of the
  /// library: a file or a form that does not name them follows it.</summary>
  PROMPT_TEXTS: array[0..6] of string = ('SystemPrompt', 'IdentityRule', 'NowRule',
    'LanguageRule', 'DocLanguageRule', 'ExpertiseIntro', 'ExpertiseRule');

{ THelpChatConfigFile }

function THelpChatConfigFile.Caption: string;
begin
  case Kind of
    cfkShared: Result := 'Shared by the HelpChat applications of this user';
    cfkApplication: Result := 'Next to the executable (shipped with the application)';
    cfkUser: Result := 'Per-user file of this application';
  else
    Result := 'ConfigFileName of the component';
  end;
  Result := Result + ' - ' + FileName;
end;

function THelpChatConfigFile.ShortCaption: string;
begin
  case Kind of
    cfkShared: Result := 'Shared file';
    cfkApplication: Result := 'Application file';
    cfkUser: Result := 'User file';
  else
    Result := 'ConfigFileName';
  end;
end;

{ helpers }

/// <summary>Every setting of ASettings as path -> text, through the JSON the
/// settings write: one level of sections, arrays joined by commas, the
/// models list left out (it has its own page).</summary>
function Flatten(const ASettings: THelpChatSettings): TDictionary<string, string>;
var
  LRoot: TJSONValue;
  LPair, LInner: TJSONPair;
  LItem: TJSONValue;
  LText: string;
begin
  Result := TDictionary<string, string>.Create;
  LRoot := TJSONObject.ParseJSONValue(ASettings.SaveToJSON);
  try
    if not (LRoot is TJSONObject) then
      Exit;
    for LPair in TJSONObject(LRoot) do
    begin
      if SameText(LPair.JsonString.Value, 'Models') then
        Continue;
      if LPair.JsonValue is TJSONObject then
      begin
        for LInner in TJSONObject(LPair.JsonValue) do
          if not (LInner.JsonValue is TJSONObject) then
            Result.AddOrSetValue(LPair.JsonString.Value + '.' + LInner.JsonString.Value,
              LInner.JsonValue.Value);
      end
      else if LPair.JsonValue is TJSONArray then
      begin
        LText := '';
        for LItem in TJSONArray(LPair.JsonValue) do
        begin
          if LText <> '' then
            LText := LText + ', ';
          LText := LText + LItem.Value;
        end;
        Result.AddOrSetValue(LPair.JsonString.Value, LText);
      end
      else
        Result.AddOrSetValue(LPair.JsonString.Value, LPair.JsonValue.Value);
    end;
  finally
    LRoot.Free;
  end;
end;

var
  GDefaults: THelpChatSettings;

/// <summary>Settings nobody touched: the defaults of the library, read by
/// RTTI. Main thread, design time.</summary>
function DefaultsSettings: THelpChatSettings;
begin
  if GDefaults = nil then
    GDefaults := THelpChatSettings.Create;
  Result := GDefaults;
end;

{ THelpChatConfigController }

constructor THelpChatConfigController.Create(const AComponentSettings: THelpChatSettings;
  const AProfile, AExeFile, AConfigFileName: string);
begin
  inherited Create;
  FComponentSettings := AComponentSettings;
  FProfile := Trim(AProfile);
  FExeFile := AExeFile;
  FFiles := FilesFor(AExeFile, AConfigFileName);
  // The file to edit first: the one the configuration of this assistant
  // comes from. Always the application's, it opened on an empty file next to
  // the executable while the whole configuration was in the shared one.
  FTargetIndex := ConfiguringFile(FFiles, FProfile);
  Reload;
end;

destructor THelpChatConfigController.Destroy;
begin
  FFragments.Free;
  FDoc.Free;
  inherited;
end;

function IsModelPath(const APath: string): Boolean;
var
  LSection: string;
begin
  for LSection in MODEL_SECTIONS do
    if APath.StartsWith(LSection + '.', True) then
      Exit(True);
  Result := False;
end;

function IsPromptText(const APath: string): Boolean;
var
  LName: string;
begin
  for LName in PROMPT_TEXTS do
    if SameText(LName, APath) then
      Exit(True);
  Result := False;
end;

/// <summary>The value of a published property of ASettings at APath
/// (<c>Claude.Model</c>) as text, through RTTI: what the settings hold even
/// when their JSON leaves it out.</summary>
function PropText(const ASettings: THelpChatSettings; const APath: string): string;
var
  LObject: TObject;
  LParts: TArray<string>;
  I: Integer;
begin
  Result := '';
  LObject := ASettings;
  LParts := APath.Split(['.']);
  for I := 0 to High(LParts) - 1 do
  begin
    if not IsPublishedProp(LObject, LParts[I]) then
      Exit;
    LObject := GetObjectProp(LObject, LParts[I]);
    if LObject = nil then
      Exit;
  end;
  if IsPublishedProp(LObject, LParts[High(LParts)]) then
    Result := VarToStr(GetPropValue(LObject, LParts[High(LParts)], True));
end;

/// <summary>InUse without the note a view reads and a file must not get:
/// "Assistant (localized)" is the name Assistant.</summary>
function StripNote(const AText: string): string;
begin
  Result := AText;
  if Result.EndsWith(' (localized)') then
    Result := Result.Substring(0, Result.Length - Length(' (localized)'))
  else if Result.EndsWith(' (auto)') then
    Result := Result.Substring(0, Result.Length - Length(' (auto)'));
end;

class function THelpChatConfigController.Catalogue: TArray<THelpChatConfigEntry>;
var
  I, J: Integer;
  LEntry: THelpChatConfigEntry;

  function Before(const A, B: THelpChatConfigEntry): Boolean;
  begin
    // The component's settings first, by name; those of the providers last.
    if A.IsModel <> B.IsModel then
      Exit(B.IsModel);
    Result := CompareText(A.Path, B.Path) < 0;
  end;

begin
  SetLength(Result, Length(CATALOGUE_ITEMS));
  for I := 0 to High(CATALOGUE_ITEMS) do
  begin
    Result[I] := Default(THelpChatConfigEntry);
    Result[I].Path := CATALOGUE_ITEMS[I].Path;
    Result[I].Caption := CATALOGUE_ITEMS[I].Caption;
    Result[I].Hint := CATALOGUE_ITEMS[I].Hint;
    Result[I].Kind := CATALOGUE_ITEMS[I].Kind;
    Result[I].Pages := CATALOGUE_ITEMS[I].Pages;
    Result[I].IsModel := IsModelPath(CATALOGUE_ITEMS[I].Path);
  end;
  // An insertion sort: a few dozen items, once per refresh.
  for I := 1 to High(Result) do
  begin
    LEntry := Result[I];
    J := I - 1;
    while (J >= 0) and Before(LEntry, Result[J]) do
    begin
      Result[J + 1] := Result[J];
      Dec(J);
    end;
    Result[J + 1] := LEntry;
  end;
end;

class function THelpChatConfigController.EntriesOfPage(
  const AEntries: TArray<THelpChatConfigEntry>;
  const APage: THelpChatConfigPage): TArray<THelpChatConfigEntry>;

  function Rank(const APath: string): Integer;
  var
    I: Integer;
  begin
    for I := 0 to High(PROMPT_ORDER) do
      if SameText(PROMPT_ORDER[I], APath) then
        Exit(I);
    Result := Length(PROMPT_ORDER);
  end;

var
  LEntry: THelpChatConfigEntry;
  I, J: Integer;
begin
  Result := nil;
  for LEntry in AEntries do
    if APage in LEntry.Pages then
      Result := Result + [LEntry];
  if APage <> ccpPrompt then
    Exit; // Entries already gives them by name, the providers last
  // A stable insertion sort by the place in the prompt.
  for I := 1 to High(Result) do
  begin
    LEntry := Result[I];
    J := I - 1;
    while (J >= 0) and (Rank(Result[J].Path) > Rank(LEntry.Path)) do
    begin
      Result[J + 1] := Result[J];
      Dec(J);
    end;
    Result[J + 1] := LEntry;
  end;
end;

class function THelpChatConfigController.KindOf(const APath: string): THelpChatConfigValueKind;
var
  LItem: TCatalogueItem;
begin
  for LItem in CATALOGUE_ITEMS do
    if SameText(LItem.Path, APath) then
      Exit(LItem.Kind);
  if SameText(APath, 'Models') then
    Exit(cvkList); // the names a profile offers
  // Not in the catalogue: a key is secret by its name, the rest is text.
  if APath.EndsWith('ApiKey', True) or APath.EndsWith('AppKey', True) or
     APath.EndsWith('UserToken', True) then
    Result := cvkSecret
  else
    Result := cvkText;
end;

class function THelpChatConfigController.MaskSecret(const AValue: string): string;
var
  LValue: string;
begin
  LValue := Trim(AValue);
  if LValue = '' then
    Exit('');
  if LValue.Length <= 8 then
    Exit(StringOfChar('*', LValue.Length));
  Result := StringOfChar('*', 8) + LValue.Substring(LValue.Length - 4) +
    Format(' (%d characters)', [LValue.Length]);
end;

class function THelpChatConfigController.FilesFor(const AExeFile,
  AConfigFileName: string): TArray<THelpChatConfigFile>;
var
  LFile: THelpChatConfigFile;
  LName, LFolder: string;
begin
  Result := nil;
  LFolder := TPath.GetDirectoryName(AExeFile);
  if Trim(AConfigFileName) <> '' then
  begin
    // Named: that file is the whole configuration, wherever it is.
    LName := Trim(AConfigFileName);
    if TPath.IsRelativePath(LName) and (LFolder <> '') then
      LName := TPath.GetFullPath(TPath.Combine(LFolder, LName));
    LFile.Kind := cfkNamed;
    LFile.FileName := LName;
    Exit(TArray<THelpChatConfigFile>.Create(LFile));
  end;
  LFile.Kind := cfkShared;
  LFile.FileName := THelpChatSettings.SharedUserConfigFile;
  Result := Result + [LFile];
  if LFolder <> '' then
  begin
    LFile.Kind := cfkApplication;
    LFile.FileName := TPath.Combine(LFolder, HELPCHAT_DEF_CONFIG_FILENAME);
    Result := Result + [LFile];
    LFile.Kind := cfkUser;
    LFile.FileName := TPath.Combine(TPath.Combine(TPath.GetHomePath,
      TPath.GetFileNameWithoutExtension(AExeFile)), HELPCHAT_DEF_CONFIG_FILENAME);
    Result := Result + [LFile];
  end;
end;

procedure THelpChatConfigController.SetTargetIndex(const Value: Integer);
begin
  if (Value < 0) or (Value > High(FFiles)) or (Value = FTargetIndex) then
    Exit;
  FTargetIndex := Value;
  Reload;
end;

procedure THelpChatConfigController.SetProfile(const Value: string);
begin
  FProfile := Trim(Value);
end;

function THelpChatConfigController.DocumentOf(const AIndex: Integer): TJSONObject;
var
  LValue: TJSONValue;
begin
  // The file being edited is the one in memory; the others as they are on disk.
  if AIndex = FTargetIndex then
    Exit(TJSONObject(FDoc.Clone));
  Result := nil;
  if not TFile.Exists(FFiles[AIndex].FileName) then
    Exit;
  LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(FFiles[AIndex].FileName, TEncoding.UTF8));
  if LValue is TJSONObject then
    Result := TJSONObject(LValue)
  else
    LValue.Free;
end;

class function THelpChatConfigController.ConfiguringFile(
  const AFiles: TArray<THelpChatConfigFile>; const AProfile: string): Integer;
type
  TPass = (pProfile, pSettings, pKeys);
var
  LPass: TPass;
  LDocs: TArray<TJSONObject>;
  LValue: TJSONValue;
  I: Integer;

  function Matches(const ADoc: TJSONObject): Boolean;
  var
    LProfiles: TJSONValue;
    LItem: TCatalogueItem;
  begin
    Result := False;
    if ADoc = nil then
      Exit;
    case LPass of
      pProfile:
        begin
          LProfiles := FindValue(ADoc, 'Profiles');
          Result := (Trim(AProfile) <> '') and (LProfiles is TJSONObject) and
            (FindValue(TJSONObject(LProfiles), Trim(AProfile)) is TJSONObject);
        end;
      pSettings:
        begin
          Result := FindValue(ADoc, 'Models') <> nil;
          for LItem in CATALOGUE_ITEMS do
            if not Result and (LItem.Kind <> cvkSecret) then
              Result := FindValue(ADoc, LItem.Path) <> nil;
        end;
      pKeys:
        for LItem in CATALOGUE_ITEMS do
          if not Result and (LItem.Kind = cvkSecret) then
            Result := FindValue(ADoc, LItem.Path) <> nil;
    end;
  end;

begin
  Result := 0;
  if Length(AFiles) <= 1 then
    Exit;
  SetLength(LDocs, Length(AFiles));
  try
    for I := 0 to High(AFiles) do
    begin
      LValue := nil;
      try
        if TFile.Exists(AFiles[I].FileName) then
          LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(AFiles[I].FileName,
            TEncoding.UTF8));
      except
        LValue := nil; // unreadable: Reload says so when it is opened
      end;
      if LValue is TJSONObject then
        LDocs[I] := TJSONObject(LValue)
      else
        LValue.Free;
    end;
    for LPass := Low(TPass) to High(TPass) do
      for I := High(LDocs) downto 0 do
        if Matches(LDocs[I]) then
          Exit(I);
    for I := 0 to High(AFiles) do
      if AFiles[I].Kind = cfkApplication then
        Exit(I);
  finally
    for I := 0 to High(LDocs) do
      LDocs[I].Free;
  end;
end;

procedure THelpChatConfigController.Reload;
var
  LValue: TJSONValue;
begin
  FreeAndNil(FDoc);
  FLastError := '';
  FLoadError := '';
  if (Length(FFiles) > 0) and TFile.Exists(FFiles[FTargetIndex].FileName) then
  begin
    try
      LValue := TJSONObject.ParseJSONValue(
        TFile.ReadAllText(FFiles[FTargetIndex].FileName, TEncoding.UTF8));
    except
      LValue := nil;
    end;
    if LValue is TJSONObject then
      FDoc := TJSONObject(LValue)
    else
    begin
      LValue.Free;
      // Kept apart from LastError, which the next call resets: this one
      // stays until the file is read again, and stops Save.
      FLoadError := 'Not a valid JSON document (nothing will be saved over it): ' +
        FFiles[FTargetIndex].FileName;
      FLastError := FLoadError;
    end;
  end;
  if FDoc = nil then
    FDoc := TJSONObject.Create;
  FModified := False;
end;

function THelpChatConfigController.Save: Boolean;
var
  LFile: string;
begin
  FLastError := '';
  if FLoadError <> '' then
  begin
    FLastError := FLoadError;
    Exit(False);
  end;
  LFile := FFiles[FTargetIndex].FileName;
  try
    if TPath.GetDirectoryName(LFile) <> '' then
      TDirectory.CreateDirectory(TPath.GetDirectoryName(LFile));
    TFile.WriteAllText(LFile, FDoc.Format(2), TEncoding.UTF8);
    FModified := False;
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result := False;
    end;
  end;
end;

function THelpChatConfigController.Validate: string;
var
  LSettings: THelpChatSettings;
  I: Integer;
  LDoc: TJSONObject;
begin
  Result := '';
  if FLoadError <> '' then
    Exit(FLoadError);
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Assign(FComponentSettings);
    LSettings.Profile := FProfile;
    for I := 0 to High(FFiles) do
    begin
      LDoc := DocumentOf(I);
      if LDoc = nil then
        Continue;
      try
        try
          LSettings.LoadFromJSON(LDoc.ToJSON);
        except
          on E: Exception do
            Exit(Format('%s: %s', [TPath.GetFileName(FFiles[I].FileName), E.Message]));
        end;
      finally
        LDoc.Free;
      end;
    end;
  finally
    LSettings.Free;
  end;
end;

function THelpChatConfigController.ProfilesObject(const ACreate: Boolean): TJSONObject;
var
  LValue: TJSONValue;
begin
  LValue := FindValue(FDoc, 'Profiles');
  if LValue is TJSONObject then
    Exit(TJSONObject(LValue));
  Result := nil;
  if ACreate then
  begin
    Result := TJSONObject.Create;
    FDoc.AddPair('Profiles', Result);
  end;
end;

function THelpChatConfigController.ScopeObject(const AScope: THelpChatConfigScope;
  const ACreate: Boolean): TJSONObject;
var
  LProfiles: TJSONObject;
  LValue: TJSONValue;
begin
  if (AScope = ccsRoot) or (FProfile = '') then
    Exit(FDoc);
  Result := nil;
  LProfiles := ProfilesObject(ACreate);
  if LProfiles = nil then
    Exit;
  LValue := FindValue(LProfiles, FProfile);
  if LValue is TJSONObject then
    Exit(TJSONObject(LValue));
  if ACreate then
  begin
    Result := TJSONObject.Create;
    LProfiles.AddPair(FProfile, Result);
  end;
end;

class function THelpChatConfigController.FindValue(const AObject: TJSONObject;
  const APath: string): TJSONValue;
var
  LParts: TArray<string>;
  LObject: TJSONObject;
  LPair: TJSONPair;
  I: Integer;
  LFound: Boolean;
begin
  Result := nil;
  if AObject = nil then
    Exit;
  LParts := APath.Split(['.']);
  LObject := AObject;
  for I := 0 to High(LParts) do
  begin
    LFound := False;
    for LPair in LObject do
      // The keys are case-insensitive, as the settings read them.
      if SameText(LPair.JsonString.Value, LParts[I]) then
      begin
        Result := LPair.JsonValue;
        LFound := True;
        Break;
      end;
    if not LFound then
      Exit(nil);
    if I < High(LParts) then
    begin
      if not (Result is TJSONObject) then
        Exit(nil);
      LObject := TJSONObject(Result);
    end;
  end;
end;

function THelpChatConfigController.ValueToText(const AValue: TJSONValue): string;
var
  LItem: TJSONValue;
begin
  if AValue is TJSONArray then
  begin
    Result := '';
    for LItem in TJSONArray(AValue) do
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + LItem.Value;
    end;
  end
  else if AValue is TJSONBool then
    Result := LowerCase(BoolToStr(TJSONBool(AValue).AsBoolean, True))
  else if Assigned(AValue) then
    Result := AValue.Value
  else
    Result := '';
end;

function THelpChatConfigController.TextToValue(const APath, AText: string): TJSONValue;
var
  LArray: TJSONArray;
  LItem: string;
begin
  case KindOf(APath) of
    cvkBoolean:
      Result := TJSONBool.Create(SameText(Trim(AText), 'true') or (Trim(AText) = '1'));
    cvkNumber:
      Result := TJSONNumber.Create(StrToIntDef(Trim(AText), 0));
    cvkList, cvkLanguages, cvkSet:
      begin
        LArray := TJSONArray.Create;
        for LItem in AText.Split([',', ';']) do
          if Trim(LItem) <> '' then
            LArray.Add(Trim(LItem));
        Result := LArray;
      end;
  else
    Result := TJSONString.Create(AText);
  end;
end;

function THelpChatConfigController.GetValue(const APath: string;
  const AScope: THelpChatConfigScope; out AText: string): Boolean;
var
  LValue: TJSONValue;
begin
  AText := '';
  if (AScope = ccsProfile) and (FProfile = '') then
    Exit(False);
  LValue := FindValue(ScopeObject(AScope, False), APath);
  Result := LValue <> nil;
  if Result then
    AText := ValueToText(LValue);
end;

procedure THelpChatConfigController.SetValue(const APath: string;
  const AScope: THelpChatConfigScope; const AText: string);
var
  LObject, LInner: TJSONObject;
  LParts: TArray<string>;
  LPair: TJSONPair;
  LValue: TJSONValue;
  I: Integer;
  LFound: Boolean;
begin
  LObject := ScopeObject(AScope, True);
  LParts := APath.Split(['.']);
  // Down to the section, creating it when missing.
  for I := 0 to High(LParts) - 1 do
  begin
    LValue := FindValue(LObject, LParts[I]);
    if LValue is TJSONObject then
      LObject := TJSONObject(LValue)
    else
    begin
      LInner := TJSONObject.Create;
      LObject.AddPair(LParts[I], LInner);
      LObject := LInner;
    end;
  end;
  // In place when the key is there: the file keeps its order.
  LFound := False;
  for LPair in LObject do
    if SameText(LPair.JsonString.Value, LParts[High(LParts)]) then
    begin
      LPair.JsonValue := TextToValue(APath, AText);
      LFound := True;
      Break;
    end;
  if not LFound then
    LObject.AddPair(LParts[High(LParts)], TextToValue(APath, AText));
  FModified := True;
end;

procedure THelpChatConfigController.RemoveValue(const APath: string;
  const AScope: THelpChatConfigScope);
var
  LObject: TJSONObject;
  LParts: TArray<string>;
  LValue: TJSONValue;
  LPair: TJSONPair;
  I: Integer;
begin
  LObject := ScopeObject(AScope, False);
  if LObject = nil then
    Exit;
  LParts := APath.Split(['.']);
  for I := 0 to High(LParts) - 1 do
  begin
    LValue := FindValue(LObject, LParts[I]);
    if not (LValue is TJSONObject) then
      Exit;
    LObject := TJSONObject(LValue);
  end;
  for LPair in LObject do
    if SameText(LPair.JsonString.Value, LParts[High(LParts)]) then
    begin
      LObject.RemovePair(LPair.JsonString.Value).Free;
      FModified := True;
      Exit;
    end;
end;

procedure THelpChatConfigController.SetComponentValue(const APath, AText: string);
var
  LRoot, LObject, LInner: TJSONObject;
  LParts: TArray<string>;
  I: Integer;
  LProfile: string;
begin
  if KindOf(APath) = cvkSecret then
    raise EHelpChatConfigError.Create('A key belongs to a configuration file, not to the form file');
  // A partial document, read the way a file is: only that key changes.
  LRoot := TJSONObject.Create;
  try
    LObject := LRoot;
    LParts := APath.Split(['.']);
    for I := 0 to High(LParts) - 1 do
    begin
      LInner := TJSONObject.Create;
      LObject.AddPair(LParts[I], LInner);
      LObject := LInner;
    end;
    LObject.AddPair(LParts[High(LParts)], TextToValue(APath, AText));
    // Not the profile: the component's own values are its root.
    LProfile := FComponentSettings.Profile;
    FComponentSettings.LoadFromJSON(LRoot.ToJSON);
    FComponentSettings.Profile := LProfile;
    // LoadFromJSON leaves the name alone when the text is empty, and the
    // caller moves it to the component and empties the settings: what the
    // component holds from now on is this.
    if SameText(APath, 'AssistantName') then
    begin
      FComponentAssistantName := Trim(AText);
      FComponentSettings.AssistantName := FComponentAssistantName;
    end;
  finally
    LRoot.Free;
  end;
end;

class function THelpChatConfigController.ChoicesOf(const ASettings: THelpChatSettings;
  const APath: string; const AKind: THelpChatConfigValueKind): TArray<string>;
var
  LLanguage: THelpChatLanguage;
  LModel: THelpChatModelInfo;
begin
  Result := nil;
  case AKind of
    cvkLanguage, cvkLanguages:
      begin
        if AKind = cvkLanguage then
          Result := ['auto'];
        for LLanguage in HelpChatLanguageList(HELPCHAT_ALL_LANGUAGES) do
          Result := Result + [HelpChatLanguageCode(LLanguage)];
      end;
    cvkChoice:
      if SameText(APath, 'Provider') then
        Result := THelpChatProviderRegistry.ProviderNames
      else if SameText(APath, 'SelectedModel') then
        for LModel in ASettings.ResolveModels do
          Result := Result + [LModel.Name]
      else if SameText(APath, 'Pdf.Paper') then
        Result := ['a4', 'letter']
      else if SameText(APath, 'Pdf.Orientation') then
        Result := ['portrait', 'landscape']
      else if SameText(APath, 'OpenAI.Api') then
        Result := ['responses', 'chat'];
    cvkSet:
      if SameText(APath, 'Skills') then
        Result := HelpChatSkillNames;
  end;
end;

procedure THelpChatConfigController.ResetComponentValue(const APath: string);
var
  LDefaults: THelpChatSettings;
  LFlat: TDictionary<string, string>;
  LText: string;
begin
  // The default as text, read from settings nobody touched, and written the
  // way any other value is: the same path, the same conversions.
  LDefaults := THelpChatSettings.Create;
  try
    LFlat := Flatten(LDefaults);
    try
      // A text of the prompt is not in the JSON when it is the library's:
      // the property itself says what it is.
      if not LFlat.TryGetValue(APath, LText) then
        LText := PropText(LDefaults, APath);
    finally
      LFlat.Free;
    end;
  finally
    LDefaults.Free;
  end;
  SetComponentValue(APath, LText);
end;

function THelpChatConfigController.InUseText(const ASettings: THelpChatSettings;
  const APath, ARaw: string): string;
var
  LSection: THelpChatModelSettings;
  LPrefix, LName, LVariable: string;
begin
  LPrefix := '';
  LName := APath;
  if APath.Contains('.') then
  begin
    LPrefix := APath.Substring(0, APath.IndexOf('.'));
    LName := APath.Substring(APath.IndexOf('.') + 1);
  end;
  LSection := nil;
  if LPrefix <> '' then
    LSection := ASettings.ModelFor(LPrefix);
  // A language says the concrete one even when it is configured as auto.
  if SameText(APath, 'Language') then
  begin
    if SameText(ARaw, 'auto') or (ARaw = '') then
      Exit(HelpChatLanguageCode(ASettings.ResolveLanguage) + ' (auto)');
    Exit(ARaw);
  end;
  if SameText(APath, 'DocLanguage') and (SameText(ARaw, 'auto') or (ARaw = '')) then
    Exit('auto (not stated)');
  if KindOf(APath) = cvkSecret then
  begin
    if ARaw <> '' then
      Exit(MaskSecret(ARaw));
    if Assigned(LSection) and LSection.HasConfiguredApiKey then
      Exit('(ApiKeyEncrypted: decrypted by the application)');
    if Assigned(LSection) then
    begin
      LVariable := LSection.ApiKeyEnvVar;
      if (LVariable <> '') and (GetEnvironmentVariable(LVariable) <> '') then
        Exit('(environment variable ' + LVariable + ')');
    end;
    Exit('(none)');
  end;
  if ARaw <> '' then
    Exit(ARaw);
  // A text of the prompt left to the library: the text itself, as the
  // property holds it - "(the built-in rules)" told nothing.
  if IsPromptText(APath) then
  begin
    Result := PropText(ASettings, APath);
    if Trim(Result) = '' then
      Result := PropText(DefaultsSettings, APath);
    Exit;
  end;
  // Empty: what takes its place, or a word that says nothing does.
  if Assigned(LSection) and SameText(LName, 'Model') then
    Result := LSection.ResolveModel
  else if Assigned(LSection) and SameText(LName, 'BaseUrl') then
    Result := LSection.NormalizedBaseUrl
  else if SameText(APath, 'AssistantName') then
    Result := HelpChatMsg(hcmUiTitle, ASettings.ResolveLanguage) + ' (localized)'
  else if SameText(APath, 'Greeting') then
    Result := ASettings.ResolveGreeting
  else if SameText(APath, 'Provider') then
    Result := 'stub'
  else if SameText(APath, 'SelectedModel') then
    Result := ASettings.ActiveModelName
  else if SameText(APath, 'ConversationFile') then
    Result := ASettings.ResolveConversationFile
  else if SameText(APath, 'Instructions') then
    Result := '(none: the rules alone)'
  else if SameText(APath, 'Expertise') then
    Result := '(none: the application and nothing else)'
  else if SameText(APath, 'DocIndexFile') then
    Result := HELPCHAT_DEF_DOCINDEX_FILENAME
  else if SameText(APath, 'DocFolder') then
    Result := '(none: links keep their URL)'
  else if SameText(APath, 'DocAreas') then
    Result := '(the whole manual)'
  else if SameText(APath, 'AllowedActions') then
    Result := '(all of them)'
  else if SameText(APath, 'Remote.BaseUrl') then
    Result := '(none: the engine runs in the application)'
  else
    Result := '(none)';
  if Result = '' then
    Result := '(none)';
end;

function THelpChatConfigController.Entries: TArray<THelpChatConfigEntry>;
var
  LSettings: THelpChatSettings;
  LBefore, LAfter: TDictionary<string, string>;
  LOrigins: TDictionary<string, string>;
  LOwn: TList<string>;
  LDoc: TJSONObject;
  LProfiles: TJSONPair;
  LProfile: TJSONValue;
  I: Integer;
  LKey, LValue, LName: string;

  // A key the layer writes is credited to it even when it writes the value
  // already in force: the file says so, and the editor must show it.
  procedure Present(const AObject: TJSONObject; const AOrigin: string);
  var
    LItem: TCatalogueItem;
  begin
    for LItem in CATALOGUE_ITEMS do
      if FindValue(AObject, LItem.Path) <> nil then
        LOrigins.AddOrSetValue(LItem.Path, AOrigin);
  end;

  procedure Layer(const AOrigin: string);
  var
    LPair: TPair<string, string>;
  begin
    LAfter := Flatten(LSettings);
    for LPair in LAfter do
      if not LBefore.ContainsKey(LPair.Key) or (LBefore[LPair.Key] <> LPair.Value) then
        LOrigins.AddOrSetValue(LPair.Key, AOrigin);
    LBefore.Free;
    LBefore := LAfter;
    LAfter := nil;
  end;

begin
  Result := Catalogue;
  // Not emptied: a file that could not be read is the first thing to say.
  FLastError := FLoadError;
  LOrigins := TDictionary<string, string>.Create;
  LOwn := TList<string>.Create;
  LSettings := THelpChatSettings.Create;
  LBefore := nil;
  try
    // The library, then the component, then each file: its root, then the
    // profile - the order the component reads them in, one at a time, so
    // that whoever changed a value last is the one it is credited to.
    LBefore := Flatten(LSettings);
    for LKey in LBefore.Keys do
      LOrigins.AddOrSetValue(LKey, ORIGIN_DEFAULT);
    LSettings.Assign(FComponentSettings);
    LSettings.Profile := '';
    // The name of the assistant is a property of the component, not of its
    // settings: without this it was never credited to the component, and
    // never shown in use once written there.
    if LSettings.AssistantName = '' then
      LSettings.AssistantName := FComponentAssistantName;
    Layer(ORIGIN_COMPONENT);
    // What the component sets, before any file has a say over it.
    for LKey in LOrigins.Keys do
      if LOrigins[LKey] = ORIGIN_COMPONENT then
        LOwn.Add(LKey);
    for I := 0 to High(FFiles) do
    begin
      LDoc := DocumentOf(I);
      if LDoc = nil then
        Continue;
      try
        LName := TPath.GetFileName(FFiles[I].FileName);
        LProfiles := LDoc.RemovePair('Profiles');
        try
          try
            LSettings.LoadFromJSON(LDoc.ToJSON);
            Layer(FFiles[I].ShortCaption + ', root');
            Present(LDoc, FFiles[I].ShortCaption + ', root');
            if (FProfile <> '') and Assigned(LProfiles) and (LProfiles.JsonValue is TJSONObject) then
            begin
              LProfile := FindValue(TJSONObject(LProfiles.JsonValue), FProfile);
              if LProfile is TJSONObject then
              begin
                LSettings.LoadFromJSON(LProfile.ToJSON);
                Layer(FFiles[I].ShortCaption + ', profile ' + FProfile);
                Present(TJSONObject(LProfile), FFiles[I].ShortCaption + ', profile ' + FProfile);
              end;
            end;
          except
            on E: Exception do
              FLastError := Format('%s: %s', [LName, E.Message]);
          end;
        finally
          LProfiles.Free;
        end;
      finally
        LDoc.Free;
      end;
    end;
    for I := 0 to High(Result) do
    begin
      if not LBefore.TryGetValue(Result[I].Path, LValue) then
        LValue := '';
      Result[I].InUse := InUseText(LSettings, Result[I].Path, LValue);
      if Result[I].Kind <> cvkSecret then
        Result[I].Value := LValue;
      // Nothing configured: the edit box starts from what replaces it - the
      // text of the library, the localized greeting, the default model - so
      // that correcting it does not mean typing it again. Not a word in
      // parentheses, which says that nothing replaces it.
      if (Result[I].Value = '') and (Result[I].Kind in [cvkText, cvkMemo, cvkChoice]) and
         not Result[I].InUse.StartsWith('(') then
        Result[I].Value := StripNote(Result[I].InUse);
      Result[I].Choices := ChoicesOf(LSettings, Result[I].Path, Result[I].Kind);
      if not LOrigins.TryGetValue(Result[I].Path, Result[I].Origin) then
        Result[I].Origin := ORIGIN_DEFAULT;
      if Result[I].Origin = ORIGIN_DEFAULT then
        Result[I].Source := csrDefault
      else if Result[I].Origin = ORIGIN_COMPONENT then
        Result[I].Source := csrComponent
      else
        Result[I].Source := csrFile;
      // The property of the component that holds it, as the Object
      // Inspector names it: the name is a property of the component itself.
      if Result[I].Source = csrComponent then
        if SameText(Result[I].Path, 'AssistantName') then
          Result[I].Origin := ORIGIN_COMPONENT + ': AssistantName'
        else
          Result[I].Origin := ORIGIN_COMPONENT + ': Settings.' + Result[I].Path;
      Result[I].InComponent := LOwn.Contains(Result[I].Path);
      Result[I].InRoot := GetValue(Result[I].Path, ccsRoot, Result[I].RootValue);
      Result[I].InProfile := GetValue(Result[I].Path, ccsProfile, Result[I].ProfileValue);
      if Result[I].Kind = cvkSecret then
      begin
        Result[I].RootValue := MaskSecret(Result[I].RootValue);
        Result[I].ProfileValue := MaskSecret(Result[I].ProfileValue);
      end;
      if Result[I].Kind = cvkSet then
        CompleteSetEntry(Result[I]);
      NoteSkillActions(LSettings, Result[I]);
    end;
  finally
    LBefore.Free;
    LSettings.Free;
    LOwn.Free;
    LOrigins.Free;
  end;
end;

type
  /// <summary>One page of a manual, to show how an excerpt reaches the
  /// prompt; the real index is the application's to load.</summary>
  TSampleRetriever = class(TInterfacedObject, IHelpChatRetriever)
  public
    function IsAvailable: Boolean;
    function GetBaseUrl: string;
    function Search(const AQuery, AHint: string; const AMaxPages: Integer): TArray<THelpChatDocPage>;
  end;

function TSampleRetriever.IsAvailable: Boolean;
begin
  Result := True;
end;

function TSampleRetriever.GetBaseUrl: string;
begin
  Result := '';
end;

function TSampleRetriever.Search(const AQuery, AHint: string;
  const AMaxPages: Integer): TArray<THelpChatDocPage>;
var
  LPage: THelpChatDocPage;
begin
  LPage := Default(THelpChatDocPage);
  LPage.Title := 'Customers';
  LPage.Summary := '(the summary of the page, from the index)';
  LPage.Excerpt := '(the passages of the page around the words of the question)';
  LPage.Url := 'Customers.md';
  Result := [LPage];
end;

procedure THelpChatConfigController.FillFragments(const ASettings: THelpChatSettings;
  const APrompt: string);
var
  LLang: THelpChatLanguage;
  LName, LText, LSection, LExcerpts: string;
  LStart: Integer;
begin
  if FFragments = nil then
    FFragments := TDictionary<string, string>.Create;
  FFragments.Clear;
  // The same calls BuildSystemPrompt makes, on the same settings: each
  // sentence is found in the prompt as it is.
  LLang := ASettings.ResolveLanguage;
  if Trim(ASettings.AssistantName) <> '' then
    LName := HelpChatPromptField(ASettings.AssistantName)
  else
    LName := HelpChatMsg(hcmUiTitle, LLang);
  LText := ASettings.ResolveIdentityRule(LName, HelpChatNowText);
  FFragments.Add('identityrule', LText);
  FFragments.Add('assistantname', LText);
  FFragments.Add('nowrule', ASettings.ResolveNowRule(HelpChatNowText));
  LText := Trim(ASettings.SystemPrompt);
  if LText = '' then
    LText := HELPCHAT_MODEL_DEF_SYSTEMPROMPT;
  FFragments.Add('systemprompt', LText);
  if Trim(ASettings.Expertise) <> '' then
  begin
    LText := HelpChatFormatRule(ASettings.ExpertiseIntro, HELPCHAT_MODEL_DEF_EXPERTISE,
      [Trim(ASettings.Expertise)]);
    FFragments.Add('expertise', LText);
    FFragments.Add('expertiseintro', LText);
    LText := Trim(ASettings.ExpertiseRule);
    if LText = '' then
      LText := HELPCHAT_MODEL_DEF_EXPERTISE_RULE;
    FFragments.Add('expertiserule', LText);
  end;
  FFragments.Add('instructions', Trim(ASettings.Instructions));
  LText := ASettings.ResolveLanguageRule(LLang);
  FFragments.Add('languagerule', LText);
  FFragments.Add('language', LText);
  LText := ASettings.ResolveDocLanguageRule(LLang);
  FFragments.Add('doclanguagerule', LText);
  FFragments.Add('doclanguage', LText);
  // The excerpts, from their heading to the end: what the grounding of the
  // provider in use decides.
  LExcerpts := '';
  LStart := APrompt.IndexOf(HelpChatMsg(hcmRelevantDocs, LLang));
  if LStart >= 0 then
    LExcerpts := APrompt.Substring(LStart);
  for LSection in MODEL_SECTIONS do
  begin
    FFragments.Add(LowerCase(LSection + '.GroundingMaxPages'), LExcerpts);
    FFragments.Add(LowerCase(LSection + '.GroundingMaxChars'), LExcerpts);
  end;
end;

function THelpChatConfigController.PromptFragment(const APath: string): string;
begin
  if (FFragments = nil) or not FFragments.TryGetValue(LowerCase(APath), Result) then
    Result := '';
end;

function THelpChatConfigController.LayeredSettings: THelpChatSettings;
var
  LDoc: TJSONObject;
  I: Integer;
begin
  Result := THelpChatSettings.Create;
  try
    // The layers as the component applies them, the profile included, the
    // file being edited as it is in memory.
    Result.Assign(FComponentSettings);
    if Result.AssistantName = '' then
      Result.AssistantName := FComponentAssistantName;
    Result.Profile := FProfile;
    for I := 0 to High(FFiles) do
    begin
      LDoc := DocumentOf(I);
      if LDoc = nil then
        Continue;
      try
        try
          Result.LoadFromJSON(LDoc.ToJSON);
        except
          on E: Exception do
            raise EHelpChatConfigError.CreateFmt('%s: %s',
              [TPath.GetFileName(FFiles[I].FileName), E.Message]);
        end;
      finally
        LDoc.Free;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function THelpChatConfigController.AppearancePreview(const ADark: Boolean;
  const AIconDataUri, AStyleSheetFile: string; const ACommands: THelpChatCommands;
  out AStyleSheetError: string): string;
var
  LSettings: THelpChatSettings;
  LOptions: THelpChatPanelOptions;
  LLang: THelpChatLanguage;
  LFile, LBody: string;
  LAnswer: THelpChatMessage;
begin
  AStyleSheetError := '';
  try
    LSettings := LayeredSettings;
  except
    // A file that does not load: the preview of the defaults, and the status
    // line of the editor already says what is wrong.
    LSettings := THelpChatSettings.Create;
  end;
  try
    LLang := LSettings.ResolveLanguage;
    LOptions := THelpChatPanelOptions.Default;
    LOptions.Language := LLang;
    LOptions.AssistantName := LSettings.AssistantName;
    LOptions.AssistantIcon := AIconDataUri;
    LOptions.PdfEnabled := LSettings.Pdf.Enabled;
    if ADark then
      LOptions.Theme := THelpChatTheme.Dark
    else
      LOptions.Theme := THelpChatTheme.Light;
    LFile := Trim(AStyleSheetFile);
    if LFile <> '' then
    begin
      if TPath.IsRelativePath(LFile) and (FExeFile <> '') then
        LFile := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(FExeFile), LFile));
      try
        LOptions.Theme.StyleSheet := THelpChatPanel.PanelCss(LFile);
      except
        on E: Exception do
          AStyleSheetError := E.Message;
      end;
    end;
    // What a conversation shows: the greeting, a question, a short answer
    // with the formatting a model uses, and the answer of a command.
    LBody := HelpChatRenderGreeting(LSettings.ResolveGreeting);
    LAnswer := Default(THelpChatMessage);
    LAnswer.Id := 'preview-question';
    LAnswer.Role := hcrUser;
    LAnswer.Content := 'How do I add a new customer?';
    LBody := LBody + HelpChatRenderBubble(LAnswer);
    LAnswer.Id := 'preview-answer';
    LAnswer.Role := hcrAssistant;
    LAnswer.Content := 'Open **Customers** and press **New**:' + #10#10 +
      '1. Fill in the *name* and the `VAT number`.' + #10 +
      '2. Press **Save**.' + #10#10 + 'Source: [Customers](Customers.md)';
    LBody := LBody + HelpChatRenderBubble(LAnswer);
    LBody := LBody + '<div class="hc-chat-msg hc-chat-system"><div class="hc-chat-bubble">' +
      HelpChatHelpAnswerHtml(ACommands, LLang) + '</div></div>';
    Result := THelpChatPanel.PreviewPage(LOptions, LBody);
  finally
    LSettings.Free;
  end;
end;

function THelpChatConfigController.PromptPreview: string;
var
  LSettings: THelpChatSettings;
  LHistory: TArray<THelpChatMessage>;
  LContext: THelpChatContext;
begin
  try
    LSettings := LayeredSettings;
  except
    on E: Exception do
      Exit(E.Message);
  end;
  try
    SetLength(LHistory, 1);
    LHistory[0] := Default(THelpChatMessage);
    LHistory[0].Role := hcrUser;
    LHistory[0].Content := 'How do I add a customer?';
    LContext := Default(THelpChatContext);
    LContext.ScreenLabel := 'Customers';
    LContext.ScreenType := 'TCustomersForm';
    Result := THelpChatProviderBase.BuildSystemPrompt(LHistory, LContext, LSettings,
      TSampleRetriever.Create);
    FillFragments(LSettings, Result);
    Result := Result + sLineBreak + sLineBreak +
      '(When the application registers actions, the rule about them follows here: ' +
      'it is not customizable.)';
  finally
    LSettings.Free;
  end;
end;

function THelpChatConfigController.Profiles: TArray<string>;
var
  LProfiles: TJSONObject;
  LPair: TJSONPair;
begin
  Result := nil;
  LProfiles := ProfilesObject(False);
  if LProfiles <> nil then
    for LPair in LProfiles do
      Result := Result + [LPair.JsonString.Value];
end;

procedure THelpChatConfigController.AddProfile(const AName: string);
var
  LProfiles: TJSONObject;
begin
  if (Trim(AName) = '') or (FindValue(ProfilesObject(False), Trim(AName)) <> nil) then
    Exit;
  LProfiles := ProfilesObject(True);
  LProfiles.AddPair(Trim(AName), TJSONObject.Create);
  FModified := True;
end;

procedure THelpChatConfigController.RenameProfile(const AOldName, ANewName: string);
var
  LProfiles: TJSONObject;
  LPair: TJSONPair;
begin
  LProfiles := ProfilesObject(False);
  if (LProfiles = nil) or (Trim(ANewName) = '') or
     (FindValue(LProfiles, Trim(ANewName)) <> nil) then
    Exit;
  for LPair in LProfiles do
    if SameText(LPair.JsonString.Value, AOldName) then
    begin
      LPair.JsonString := TJSONString.Create(Trim(ANewName));
      if SameText(FProfile, AOldName) then
        FProfile := Trim(ANewName);
      FModified := True;
      Exit;
    end;
end;

procedure THelpChatConfigController.DeleteProfile(const AName: string);
var
  LProfiles: TJSONObject;
  LPair: TJSONPair;
begin
  LProfiles := ProfilesObject(False);
  if LProfiles = nil then
    Exit;
  for LPair in LProfiles do
    if SameText(LPair.JsonString.Value, AName) then
    begin
      LProfiles.RemovePair(LPair.JsonString.Value).Free;
      FModified := True;
      Exit;
    end;
end;

function THelpChatConfigController.Models: TArray<THelpChatConfigModel>;
var
  LValue, LItem: TJSONValue;
  LModel: THelpChatConfigModel;
begin
  Result := nil;
  LValue := FindValue(FDoc, 'Models');
  if not (LValue is TJSONArray) then
    Exit;
  for LItem in TJSONArray(LValue) do
    if LItem is TJSONObject then
    begin
      LModel := Default(THelpChatConfigModel);
      LModel.Name := ValueToText(FindValue(TJSONObject(LItem), 'Name'));
      LModel.Provider := ValueToText(FindValue(TJSONObject(LItem), 'Provider'));
      LModel.Model := ValueToText(FindValue(TJSONObject(LItem), 'Model'));
      LModel.BaseUrl := ValueToText(FindValue(TJSONObject(LItem), 'BaseUrl'));
      LModel.Icon := ValueToText(FindValue(TJSONObject(LItem), 'Icon'));
      LModel.ApiKey := ValueToText(FindValue(TJSONObject(LItem), 'ApiKey'));
      LModel.Original := LModel.Name;
      Result := Result + [LModel];
    end;
end;

procedure THelpChatConfigController.SetModels(const AModels: TArray<THelpChatConfigModel>);
var
  LOld: TJSONValue;
  LArray: TJSONArray;
  LObject: TJSONObject;
  LModel: THelpChatConfigModel;
  LItem: TJSONValue;
  LKey: string;
  LPair: TJSONPair;
  LFound: Boolean;

  // The value of a key the editor shows: replaced where it is, added at the
  // end when new, removed when emptied.
  procedure Put(const AKey, AValue: string);
  var
    LOwn: TJSONPair;
  begin
    for LOwn in LObject do
      if SameText(LOwn.JsonString.Value, AKey) then
      begin
        LObject.RemovePair(LOwn.JsonString.Value).Free;
        Break;
      end;
    if AValue <> '' then
      LObject.AddPair(AKey, AValue);
  end;

begin
  LOld := FindValue(FDoc, 'Models');
  LArray := TJSONArray.Create;
  for LModel in AModels do
  begin
    // The entry the file had for this model, by the name it was read with:
    // a rename must not lose what the editor does not show. A copy of it is
    // the starting point, so the encrypted key - the application's - and
    // any key written by hand stay.
    LObject := nil;
    LKey := LModel.Original;
    if LKey = '' then
      LKey := LModel.Name;
    if LOld is TJSONArray then
      for LItem in TJSONArray(LOld) do
        if (LItem is TJSONObject) and
           SameText(ValueToText(FindValue(TJSONObject(LItem), 'Name')), LKey) then
        begin
          LObject := TJSONObject(LItem.Clone);
          Break;
        end;
    if LObject = nil then
    begin
      LObject := TJSONObject.Create;
      Put('Name', LModel.Name);
      Put('Provider', LModel.Provider);
      Put('Model', LModel.Model);
      Put('BaseUrl', LModel.BaseUrl);
      Put('ApiKey', LModel.ApiKey);
      Put('Icon', LModel.Icon);
    end
    else
    begin
      // In place when the key was there (Put re-adds at the end only what
      // changed its value from empty): the order of a hand-written entry is
      // kept as far as its values are.
      if ValueToText(FindValue(LObject, 'Name')) <> LModel.Name then
        Put('Name', LModel.Name);
      if ValueToText(FindValue(LObject, 'Provider')) <> LModel.Provider then
        Put('Provider', LModel.Provider);
      if ValueToText(FindValue(LObject, 'Model')) <> LModel.Model then
        Put('Model', LModel.Model);
      if ValueToText(FindValue(LObject, 'BaseUrl')) <> LModel.BaseUrl then
        Put('BaseUrl', LModel.BaseUrl);
      if ValueToText(FindValue(LObject, 'ApiKey')) <> LModel.ApiKey then
        Put('ApiKey', LModel.ApiKey);
      if ValueToText(FindValue(LObject, 'Icon')) <> LModel.Icon then
        Put('Icon', LModel.Icon);
    end;
    LArray.AddElement(LObject);
  end;
  LFound := False;
  for LPair in FDoc do
    if SameText(LPair.JsonString.Value, 'Models') then
    begin
      LPair.JsonValue := LArray;
      LFound := True;
      Break;
    end;
  if not LFound then
    FDoc.AddPair('Models', LArray);
  FModified := True;
end;

function THelpChatConfigController.ProfileModelNames: TArray<string>;
var
  LValue, LItem: TJSONValue;
begin
  Result := nil;
  if FProfile = '' then
    Exit;
  LValue := FindValue(ScopeObject(ccsProfile, False), 'Models');
  if LValue is TJSONArray then
    for LItem in TJSONArray(LValue) do
      if LItem is TJSONString then
        Result := Result + [LItem.Value]
      else if LItem is TJSONObject then
        Result := Result + [ValueToText(FindValue(TJSONObject(LItem), 'Name'))];
end;

function THelpChatConfigController.ProfileModelChoices: TArray<string>;
var
  LModel: THelpChatConfigModel;
  LName, LKnown: string;
  LFound: Boolean;
begin
  Result := nil;
  for LModel in Models do
    Result := Result + [LModel.Name];
  for LName in ProfileModelNames do
  begin
    LFound := False;
    for LKnown in Result do
      if SameText(LKnown, LName) then
        LFound := True;
    if not LFound and (LName <> '') then
      Result := Result + [LName];
  end;
end;

procedure THelpChatConfigController.SetProfileModelNames(const ANames: TArray<string>);
var
  LName: string;
  LScope: TJSONObject;
  LOld, LItem: TJSONValue;
  LInline: TArray<TJSONValue>;
  LArray: TJSONArray;
  LPair: TJSONPair;
  LEntry: TJSONValue;
begin
  if FProfile = '' then
    Exit;
  if Length(ANames) = 0 then
  begin
    RemoveValue('Models', ccsProfile);
    Exit;
  end;
  // The models the profile defined by itself, as objects: a list of names
  // written over them would turn each into the name of a model no catalogue
  // has, and the next load would raise.
  LInline := nil;
  LOld := FindValue(ScopeObject(ccsProfile, False), 'Models');
  if LOld is TJSONArray then
    for LItem in TJSONArray(LOld) do
      if LItem is TJSONObject then
        LInline := LInline + [LItem];
  if Length(LInline) = 0 then
  begin
    LName := string.Join(', ', ANames);
    SetValue('Models', ccsProfile, LName);
    Exit;
  end;
  LArray := TJSONArray.Create;
  for LName in ANames do
  begin
    LEntry := nil;
    for LItem in LInline do
      if SameText(ValueToText(FindValue(TJSONObject(LItem), 'Name')), LName) then
        LEntry := LItem.Clone as TJSONValue;
    if LEntry = nil then
      LEntry := TJSONString.Create(LName);
    LArray.AddElement(LEntry);
  end;
  LScope := ScopeObject(ccsProfile, True);
  for LPair in LScope do
    if SameText(LPair.JsonString.Value, 'Models') then
    begin
      LScope.RemovePair(LPair.JsonString.Value).Free;
      Break;
    end;
  LScope.AddPair('Models', LArray);
  FModified := True;
end;

initialization

finalization
  FreeAndNil(GDefaults);

end.
