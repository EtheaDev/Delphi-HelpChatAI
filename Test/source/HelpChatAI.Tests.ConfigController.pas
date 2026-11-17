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
///  The controller of the configuration editor, without any view: which
///  files, what they say at the root and in a profile, where a value in force
///  comes from, what is written back - and that a secret is only ever shown
///  masked and never goes into the form file.
/// </summary>
unit HelpChatAI.Tests.ConfigController;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  HelpChatAI.Settings,
  HelpChatAI.ConfigController;

type
  [TestFixture]
  TConfigControllerTests = class
  strict private
    FFolder: string;
    FFile: string;
    FComponent: THelpChatSettings;
    function NewController(const AProfile: string): THelpChatConfigController;
    function EntryOf(const AEntries: TArray<THelpChatConfigEntry>;
      const APath: string): THelpChatConfigEntry;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Files_DefaultsOrTheNamedOne;
    [Test]
    procedure Values_RootAndProfile;
    [Test]
    procedure Save_KeepsWhatItDidNotTouch;
    [Test]
    procedure Values_ListsAndBooleans_KeepTheirJsonType;
    [Test]
    procedure Entries_TellWhereAValueComesFrom;
    [Test]
    procedure InUse_IsNeverEmpty_AndSaysWhoSetIt;
    [Test]
    procedure AssistantName_OfTheComponent_IsInUse;
    [Test]
    procedure Kinds_NumbersSetsAndChoices;
    [Test]
    procedure Skills_AreTicks_WithTheirActions_AndTheUnknownKept;
    [Test]
    procedure ResetComponentValue_GivesTheLibraryValueBack;
    [Test]
    procedure Secrets_AreMasked_AndNeverGoToTheFormFile;
    [Test]
    procedure Profiles_AddRenameDelete;
    [Test]
    procedure Models_KeepTheEncryptedKey;
    [Test]
    procedure Models_ARenamedOne_KeepsWhatTheEditorDoesNotShow;
    [Test]
    procedure ProfileModels_InlineAndForeignOnes_AreNotLost;
    [Test]
    procedure Validate_NamesTheProblem;
    [Test]
    procedure MalformedFile_IsReported_AndNeverOverwritten;
    [Test]
    procedure FirstFile_IsTheOneTheConfigurationComesFrom;
    [Test]
    procedure Entries_ComponentByName_ThenTheProviders;
    [Test]
    procedure PromptTexts_ShowTheirText_AndResetToIt;
    [Test]
    procedure PromptPreview_IsWhatTheModelWouldRead;
    [Test]
    procedure AppearancePreview_IsThePanelWithASampleConversation;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  HelpChatAI.Types,
  HelpChatAI.Theme,
  HelpChatAI.Commands,
  HelpChatAI.Skills.Screen; // registers the four screen skills

const
  CONFIG =
    '{' + sLineBreak +
    '  "// note": "written by hand",' + sLineBreak +
    '  "Language": "it",' + sLineBreak +
    '  "Claude": {"ApiKey": "sk-ant-0123456789abcdef", "ApiKeyEncrypted": "enc:xyz"},' + sLineBreak +
    '  "Models": [{"Name": "Claude", "Provider": "claude", "ApiKeyEncrypted": "enc:m"}],' + sLineBreak +
    '  "Profiles": {"Orders": {"DocAreas": ["Orders"], "AssistantName": "Giulio"}}' + sLineBreak +
    '}';

procedure TConfigControllerTests.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'helpchatai-config-controller');
  TDirectory.CreateDirectory(FFolder);
  FFile := TPath.Combine(FFolder, 'mine.json');
  TFile.WriteAllText(FFile, CONFIG, TEncoding.UTF8);
  FComponent := THelpChatSettings.Create;
  FComponent.DocIndexFile := 'Help\from-the-dfm.json';
end;

procedure TConfigControllerTests.TearDown;
begin
  FComponent.Free;
  TDirectory.Delete(FFolder, True);
end;

function TConfigControllerTests.NewController(const AProfile: string): THelpChatConfigController;
begin
  // A named file: the only one read, and not the developer's own.
  Result := THelpChatConfigController.Create(FComponent, AProfile,
    TPath.Combine(FFolder, 'App.exe'), FFile);
end;

function TConfigControllerTests.EntryOf(const AEntries: TArray<THelpChatConfigEntry>;
  const APath: string): THelpChatConfigEntry;
var
  LEntry: THelpChatConfigEntry;
begin
  for LEntry in AEntries do
    if SameText(LEntry.Path, APath) then
      Exit(LEntry);
  Assert.Fail('no entry ' + APath);
end;

procedure TConfigControllerTests.Files_DefaultsOrTheNamedOne;
var
  LFiles: TArray<THelpChatConfigFile>;
begin
  LFiles := THelpChatConfigController.FilesFor('C:\Apps\Crm\Crm.exe', '');
  Assert.AreEqual(3, Length(LFiles), 'shared, application, user');
  Assert.AreEqual(Ord(cfkShared), Ord(LFiles[0].Kind));
  Assert.AreEqual('C:\Apps\Crm\helpchatai.json', LFiles[1].FileName);
  Assert.AreEqual('helpchatai.json', TPath.GetFileName(LFiles[2].FileName));
  Assert.AreEqual('Crm', TPath.GetFileName(TPath.GetDirectoryName(LFiles[2].FileName)),
    'the per-user folder is named after the executable of the project, not after the IDE');
  LFiles := THelpChatConfigController.FilesFor('C:\Apps\Crm\Crm.exe', 'cfg\crm.json');
  Assert.AreEqual(1, Length(LFiles), 'named: that one alone');
  Assert.AreEqual('C:\Apps\Crm\cfg\crm.json', LFiles[0].FileName);
end;

procedure TConfigControllerTests.Values_RootAndProfile;
var
  LController: THelpChatConfigController;
  LText: string;
begin
  LController := NewController('Orders');
  try
    Assert.IsTrue(LController.GetValue('Language', ccsRoot, LText));
    Assert.AreEqual('it', LText);
    Assert.IsTrue(LController.GetValue('DocAreas', ccsProfile, LText));
    Assert.AreEqual('Orders', LText);
    Assert.IsFalse(LController.GetValue('DocAreas', ccsRoot, LText));
    LController.SetValue('Instructions', ccsProfile, 'You are the order expert.');
    Assert.IsTrue(LController.Modified);
    Assert.IsTrue(LController.GetValue('Instructions', ccsProfile, LText));
    Assert.IsFalse(LController.GetValue('Instructions', ccsRoot, LText), 'the profile, not the root');
    LController.RemoveValue('Language', ccsRoot);
    Assert.IsFalse(LController.GetValue('Language', ccsRoot, LText));
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.Save_KeepsWhatItDidNotTouch;
var
  LController: THelpChatConfigController;
  LSaved: string;
begin
  LController := NewController('Orders');
  try
    LController.SetValue('Claude.Model', ccsRoot, 'claude-sonnet-x');
    Assert.IsTrue(LController.Save, LController.LastError);
    Assert.IsFalse(LController.Modified);
  finally
    LController.Free;
  end;
  LSaved := TFile.ReadAllText(FFile, TEncoding.UTF8);
  Assert.Contains(LSaved, 'written by hand', 'a key it does not know stays');
  Assert.Contains(LSaved, 'enc:xyz', 'the encrypted node is the application''s: untouched');
  Assert.Contains(LSaved, 'claude-sonnet-x');
  Assert.IsTrue(LSaved.IndexOf('"Language"') < LSaved.IndexOf('"Claude"'), 'in its order');
end;

procedure TConfigControllerTests.Values_ListsAndBooleans_KeepTheirJsonType;
var
  LController: THelpChatConfigController;
  LDoc: TJSONValue;
begin
  LController := NewController('Orders');
  try
    LController.SetValue('AllowedActions', ccsProfile, 'create_order, open_screen');
    LController.SetValue('Attachments.Enabled', ccsRoot, 'true');
    LController.Save;
  finally
    LController.Free;
  end;
  LDoc := TJSONObject.ParseJSONValue(TFile.ReadAllText(FFile, TEncoding.UTF8));
  try
    Assert.AreEqual('["create_order","open_screen"]',
      LDoc.GetValue<TJSONValue>('Profiles.Orders.AllowedActions').ToJSON);
    Assert.IsTrue(LDoc.GetValue<TJSONValue>('Attachments.Enabled') is TJSONBool);
  finally
    LDoc.Free;
  end;
end;

procedure TConfigControllerTests.Entries_TellWhereAValueComesFrom;
var
  LController: THelpChatConfigController;
  LEntries: TArray<THelpChatConfigEntry>;
begin
  LController := NewController('Orders');
  try
    LEntries := LController.Entries;
    Assert.AreEqual('', LController.LastError);
    Assert.AreEqual('Help\from-the-dfm.json', EntryOf(LEntries, 'DocIndexFile').InUse);
    // The property that holds it, as the Object Inspector names it.
    Assert.AreEqual('Component: Settings.DocIndexFile', EntryOf(LEntries, 'DocIndexFile').Origin);
    Assert.AreEqual('it', EntryOf(LEntries, 'Language').InUse);
    Assert.EndsWith(', root', EntryOf(LEntries, 'Language').Origin);
    Assert.AreEqual('Orders', EntryOf(LEntries, 'DocAreas').InUse);
    Assert.EndsWith('profile Orders', EntryOf(LEntries, 'DocAreas').Origin);
    Assert.IsTrue(EntryOf(LEntries, 'DocAreas').InProfile);
    Assert.IsFalse(EntryOf(LEntries, 'DocAreas').InRoot);
    Assert.AreEqual('Library default', EntryOf(LEntries, 'Greeting').Origin);
    // An unsaved change already counts: the editor shows what it will be.
    LController.SetValue('Greeting', ccsProfile, 'Ciao');
    Assert.AreEqual('Ciao', EntryOf(LController.Entries, 'Greeting').InUse);
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.InUse_IsNeverEmpty_AndSaysWhoSetIt;
var
  LController: THelpChatConfigController;
  LEntries: TArray<THelpChatConfigEntry>;
  LEntry: THelpChatConfigEntry;
begin
  LController := NewController('');
  try
    LEntries := LController.Entries;
    for LEntry in LEntries do
      Assert.AreNotEqual('', LEntry.InUse, LEntry.Path + ' has a value in use');
    // An empty value says what takes its place.
    Assert.AreEqual(THelpChatClaudeSettings.DefaultModel, EntryOf(LEntries, 'Claude.Model').InUse);
    Assert.AreEqual('(the whole manual)', EntryOf(LEntries, 'DocAreas').InUse);
    Assert.AreEqual(Ord(csrDefault), Ord(EntryOf(LEntries, 'Claude.Model').Source));
    Assert.AreEqual(Ord(csrComponent), Ord(EntryOf(LEntries, 'DocIndexFile').Source));
    Assert.AreEqual(Ord(csrFile), Ord(EntryOf(LEntries, 'Language').Source));
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.AssistantName_OfTheComponent_IsInUse;
var
  LController: THelpChatConfigController;
  LEntry: THelpChatConfigEntry;
begin
  // The default assistant: the file names nobody at its root.
  LController := NewController('');
  try
    LController.ComponentAssistantName := 'Bob';
    LEntry := EntryOf(LController.Entries, 'AssistantName');
    Assert.AreEqual('Bob', LEntry.InUse);
    Assert.AreEqual(Ord(csrComponent), Ord(LEntry.Source));
    // Written from the editor: the controller knows it at once, and an empty
    // one takes it away again.
    LController.SetComponentValue('AssistantName', 'Anna');
    Assert.AreEqual('Anna', LController.ComponentAssistantName);
    Assert.AreEqual('Anna', EntryOf(LController.Entries, 'AssistantName').InUse);
    LController.SetComponentValue('AssistantName', '');
    Assert.AreEqual(Ord(csrDefault), Ord(EntryOf(LController.Entries, 'AssistantName').Source));
  finally
    LController.Free;
  end;
  // A name in the profile prevails, as at run time.
  LController := NewController('Orders');
  try
    LController.ComponentAssistantName := 'Bob';
    LEntry := EntryOf(LController.Entries, 'AssistantName');
    Assert.AreEqual('Giulio', LEntry.InUse);
    Assert.AreEqual(Ord(csrFile), Ord(LEntry.Source));
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.Kinds_NumbersSetsAndChoices;
var
  LController: THelpChatConfigController;
  LEntries: TArray<THelpChatConfigEntry>;
  LEntry: THelpChatConfigEntry;
  LDoc: TJSONValue;
begin
  LController := NewController('');
  try
    LController.ComponentAssistantName := 'Bob';
    LEntries := LController.Entries;
    // What a view puts in its control: the value in use, also when the file
    // being edited does not say it - and never a key.
    Assert.AreEqual('Bob', EntryOf(LEntries, 'AssistantName').Value);
    Assert.AreEqual('Help\from-the-dfm.json', EntryOf(LEntries, 'DocIndexFile').Value);
    Assert.AreEqual('', EntryOf(LEntries, 'Claude.ApiKey').Value);
    LEntry := EntryOf(LEntries, 'Claude.MaxTokens');
    Assert.AreEqual(Ord(cvkNumber), Ord(LEntry.Kind));
    Assert.AreEqual(IntToStr(HELPCHAT_MODEL_DEF_MAXTOKENS), LEntry.Value);
    LEntry := EntryOf(LEntries, 'Languages');
    Assert.AreEqual(Ord(cvkLanguages), Ord(LEntry.Kind));
    Assert.AreEqual(6, Length(LEntry.Choices), 'one tick per language');
    LEntry := EntryOf(LEntries, 'Language');
    Assert.AreEqual('auto', LEntry.Choices[0]);
    Assert.AreEqual(7, Length(LEntry.Choices), 'auto and the six languages');
    Assert.AreEqual(Ord(cvkChoice), Ord(EntryOf(LEntries, 'SelectedModel').Kind));
    Assert.AreEqual('Claude', EntryOf(LEntries, 'SelectedModel').Choices[0],
      'the models of the catalogue in force');
    LController.SetValue('Claude.MaxTokens', ccsRoot, '2048');
    LController.SetValue('Languages', ccsRoot, 'it, en');
    LController.Save;
  finally
    LController.Free;
  end;
  LDoc := TJSONObject.ParseJSONValue(TFile.ReadAllText(FFile, TEncoding.UTF8));
  try
    Assert.IsTrue(LDoc.GetValue<TJSONValue>('Claude.MaxTokens') is TJSONNumber, 'a number');
    Assert.AreEqual(2048, LDoc.GetValue<Integer>('Claude.MaxTokens'));
    Assert.AreEqual('["it","en"]', LDoc.GetValue<TJSONValue>('Languages').ToJSON, 'an array');
  finally
    LDoc.Free;
  end;
end;

procedure TConfigControllerTests.Skills_AreTicks_WithTheirActions_AndTheUnknownKept;
var
  LController: THelpChatConfigController;
  LEntry: THelpChatConfigEntry;
  LDoc: TJSONValue;
  I: Integer;

  function IndexOfChoice(const AName: string): Integer;
  begin
    for Result := 0 to High(LEntry.Choices) do
      if SameText(LEntry.Choices[Result], AName) then
        Exit;
    Result := -1;
  end;

begin
  FComponent.AllowedActions := 'open_screen';
  LController := NewController('');
  try
    // A skill the application registers is not registered in the IDE: the
    // file names it, the editor keeps it.
    LController.SetValue('Skills', ccsRoot, 'forms, crm_extra');
    LEntry := EntryOf(LController.Entries, 'Skills');
    Assert.AreEqual(Ord(cvkSet), Ord(LEntry.Kind));
    Assert.AreEqual(Length(LEntry.Choices), Length(LEntry.ChoiceCaptions));
    Assert.AreEqual(Length(LEntry.Choices), Length(LEntry.ChoiceHints));
    for I := 0 to High(LEntry.Choices) do
      Assert.IsTrue(LEntry.ChoiceHints[I] <> '', LEntry.Choices[I] + ' has a hint');
    I := IndexOfChoice('forms');
    Assert.IsTrue(I >= 0, 'forms offered');
    Assert.Contains(LEntry.ChoiceCaptions[I], 'describe_form', 'its actions in the caption');
    Assert.Contains(LEntry.ChoiceCaptions[I], 'fill_form');
    Assert.IsTrue(IndexOfChoice('records') >= 0, 'a skill nobody named is offered too');
    I := IndexOfChoice('crm_extra');
    Assert.IsTrue(I >= 0, 'the unknown name is kept');
    Assert.Contains(LEntry.ChoiceCaptions[I], 'not registered');
    // Naming a skill allows its actions: the hint of AllowedActions says so.
    Assert.Contains(EntryOf(LController.Entries, 'AllowedActions').Hint, 'fill_form');
    LController.Save;
  finally
    LController.Free;
  end;
  LDoc := TJSONObject.ParseJSONValue(TFile.ReadAllText(FFile, TEncoding.UTF8));
  try
    Assert.AreEqual('["forms","crm_extra"]', LDoc.GetValue<TJSONValue>('Skills').ToJSON,
      'an array of names, never the captions');
  finally
    LDoc.Free;
  end;
end;

procedure TConfigControllerTests.ResetComponentValue_GivesTheLibraryValueBack;
var
  LController: THelpChatConfigController;
begin
  LController := NewController('');
  try
    LController.ComponentAssistantName := 'Bob';
    LController.SetComponentValue('Claude.MaxTokens', '4096');
    Assert.IsTrue(EntryOf(LController.Entries, 'DocIndexFile').InComponent);
    Assert.IsTrue(EntryOf(LController.Entries, 'Claude.MaxTokens').InComponent);
    Assert.IsTrue(EntryOf(LController.Entries, 'AssistantName').InComponent);
    // A file prevails, and the component still sets it: what the button
    // offers to take away is the component's, whoever is in use.
    Assert.IsTrue(EntryOf(LController.Entries, 'Language').InRoot);
    Assert.IsFalse(EntryOf(LController.Entries, 'Language').InComponent);
    LController.ResetComponentValue('DocIndexFile');
    LController.ResetComponentValue('Claude.MaxTokens');
    LController.ResetComponentValue('AssistantName');
    Assert.AreEqual('', FComponent.DocIndexFile);
    Assert.AreEqual(HELPCHAT_MODEL_DEF_MAXTOKENS, FComponent.Claude.MaxTokens);
    Assert.AreEqual('', LController.ComponentAssistantName);
    Assert.IsFalse(EntryOf(LController.Entries, 'DocIndexFile').InComponent);
    Assert.AreEqual(Ord(csrDefault), Ord(EntryOf(LController.Entries, 'Claude.MaxTokens').Source));
    Assert.WillRaise(
      procedure
      begin
        LController.ResetComponentValue('Claude.ApiKey');
      end, EHelpChatConfigError);
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.Secrets_AreMasked_AndNeverGoToTheFormFile;
var
  LController: THelpChatConfigController;
  LEntry: THelpChatConfigEntry;
begin
  LController := NewController('');
  try
    LEntry := EntryOf(LController.Entries, 'Claude.ApiKey');
    Assert.DoesNotContain(LEntry.InUse, 'sk-ant-0123', 'masked');
    Assert.EndsWith('cdef (23 characters)', LEntry.InUse);
    Assert.DoesNotContain(LEntry.RootValue, 'sk-ant');
    Assert.WillRaise(
      procedure
      begin
        LController.SetComponentValue('Claude.ApiKey', 'sk-in-the-dfm');
      end, EHelpChatConfigError);
    LController.SetComponentValue('Greeting', 'Hello from the DFM');
    Assert.AreEqual('Hello from the DFM', FComponent.Greeting);
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.Profiles_AddRenameDelete;
var
  LController: THelpChatConfigController;
  LProfiles: TArray<string>;
begin
  LController := NewController('Orders');
  try
    LController.AddProfile('Planning');
    LController.AddProfile('planning'); // already there, case apart
    LProfiles := LController.Profiles;
    Assert.AreEqual(2, Length(LProfiles));
    LController.RenameProfile('Orders', 'Sales');
    Assert.AreEqual('Sales', LController.Profile, 'the assistant follows its profile');
    Assert.AreEqual('Sales', LController.Profiles[0]);
    LController.DeleteProfile('Planning');
    Assert.AreEqual(1, Length(LController.Profiles));
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.Models_KeepTheEncryptedKey;
var
  LController: THelpChatConfigController;
  LModels: TArray<THelpChatConfigModel>;
  LSaved: string;
begin
  LController := NewController('Orders');
  try
    LModels := LController.Models;
    Assert.AreEqual(1, Length(LModels));
    SetLength(LModels, 2);
    LModels[1] := Default(THelpChatConfigModel);
    LModels[1].Name := 'Gemma';
    LModels[1].Provider := 'openai';
    LModels[1].Model := 'gemma4';
    LController.SetModels(LModels);
    LController.SetProfileModelNames(['Gemma']);
    Assert.AreEqual('Gemma', LController.ProfileModelNames[0]);
    Assert.AreEqual('', LController.Validate, 'a name of the catalogue is valid');
    LController.Save;
  finally
    LController.Free;
  end;
  LSaved := TFile.ReadAllText(FFile, TEncoding.UTF8);
  Assert.Contains(LSaved, 'enc:m', 'the model kept its encrypted key');
end;

procedure TConfigControllerTests.Models_ARenamedOne_KeepsWhatTheEditorDoesNotShow;
var
  LController: THelpChatConfigController;
  LModels: TArray<THelpChatConfigModel>;
  LSaved: string;
begin
  TFile.WriteAllText(FFile,
    '{"Models": [{"Name": "Claude", "Provider": "claude", "ApiKeyEncrypted": "enc:m", ' +
    '"Note": "by hand"}]}', TEncoding.UTF8);
  LController := NewController('');
  try
    LModels := LController.Models;
    Assert.AreEqual('Claude', LModels[0].Original);
    // What a view does on Update: a new record from its edit boxes, with the
    // name the model was read with.
    LModels[0].Name := 'Anthropic';
    LModels[0].Model := 'claude-other';
    LController.SetModels(LModels);
    LController.Save;
  finally
    LController.Free;
  end;
  LSaved := TFile.ReadAllText(FFile, TEncoding.UTF8);
  Assert.Contains(LSaved, '"Anthropic"');
  Assert.Contains(LSaved, 'claude-other');
  Assert.Contains(LSaved, 'enc:m', 'the encrypted key follows the rename');
  Assert.Contains(LSaved, 'by hand', 'and so does a key the editor does not know');
  Assert.DoesNotContain(LSaved, '"Name": "Claude"', 'one model, under its new name');
end;

procedure TConfigControllerTests.ProfileModels_InlineAndForeignOnes_AreNotLost;
var
  LController: THelpChatConfigController;
  LChoices: TArray<string>;
  LSaved: string;
begin
  // The profile offers a model of the catalogue of another file ("Shared")
  // and one it defines by itself; the catalogue of this file has "Claude".
  TFile.WriteAllText(FFile,
    '{"Models": [{"Name": "Claude", "Provider": "claude"}], "Profiles": {"Orders": {"Models": ' +
    '["Shared", {"Name": "Local", "Provider": "openai", "BaseUrl": "http://localhost:11434"}]}}}',
    TEncoding.UTF8);
  LController := NewController('Orders');
  try
    LChoices := LController.ProfileModelChoices;
    Assert.AreEqual(3, Length(LChoices), 'the catalogue, then what the profile has from elsewhere');
    Assert.AreEqual('Claude', LChoices[0]);
    Assert.AreEqual('Shared', LChoices[1]);
    Assert.AreEqual('Local', LChoices[2]);
    // A view writes back what is ticked: everything, plus Claude.
    LController.SetProfileModelNames(['Claude', 'Shared', 'Local']);
    LController.Save;
  finally
    LController.Free;
  end;
  LSaved := TFile.ReadAllText(FFile, TEncoding.UTF8);
  Assert.Contains(LSaved, 'localhost:11434', 'the inline model is still an object');
  Assert.Contains(LSaved, '"Shared"');
end;

procedure TConfigControllerTests.Validate_NamesTheProblem;
var
  LController: THelpChatConfigController;
begin
  LController := NewController('Orders');
  try
    LController.SetProfileModelNames(['Nobody']);
    Assert.Contains(LController.Validate, 'Nobody');
    LController.SetProfileModelNames([]);
    Assert.AreEqual('', LController.Validate);
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.MalformedFile_IsReported_AndNeverOverwritten;
const
  BROKEN = '{"Provider": "claude", }';
var
  LController: THelpChatConfigController;
begin
  // A comma too many, written by hand: the editor shows the file empty, and
  // must neither say that all is well nor replace it with what it shows.
  TFile.WriteAllText(FFile, BROKEN, TEncoding.UTF8);
  LController := NewController('');
  try
    Assert.AreNotEqual('', LController.LoadError);
    LController.Entries;
    Assert.AreNotEqual('', LController.LastError, 'still said after the entries were read');
    Assert.AreNotEqual('', LController.Validate);
    LController.SetValue('Provider', ccsRoot, 'openai');
    Assert.IsFalse(LController.Save, 'nothing is written over a file that was not read');
    Assert.AreEqual(BROKEN, TFile.ReadAllText(FFile, TEncoding.UTF8));
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.FirstFile_IsTheOneTheConfigurationComesFrom;
var
  LFiles: TArray<THelpChatConfigFile>;

  procedure Put(const AIndex: Integer; const AJson: string);
  begin
    if AJson = '' then
      TFile.Delete(LFiles[AIndex].FileName)
    else
      TFile.WriteAllText(LFiles[AIndex].FileName, AJson, TEncoding.UTF8);
  end;

begin
  // The three files of a component that names none, all in the temporary
  // folder: the real shared file of the developer is never read here.
  SetLength(LFiles, 3);
  LFiles[0].Kind := cfkShared;
  LFiles[0].FileName := TPath.Combine(FFolder, 'shared.json');
  LFiles[1].Kind := cfkApplication;
  LFiles[1].FileName := TPath.Combine(FFolder, 'app.json');
  LFiles[2].Kind := cfkUser;
  LFiles[2].FileName := TPath.Combine(FFolder, 'user.json');
  Assert.AreEqual(1, THelpChatConfigController.ConfiguringFile(LFiles, ''),
    'no file at all: the application one, which ships');
  // The CRM demo: everything in the shared file, the per-user one holding
  // the encrypted key the application wrote, nothing next to the executable.
  Put(0, '{"Provider": "claude", "Claude": {"ApiKey": "sk-ant-x"}}');
  Put(2, '{"Claude": {"ApiKeyEncrypted": "enc:x"}}');
  Assert.AreEqual(0, THelpChatConfigController.ConfiguringFile(LFiles, ''),
    'the shared file, where the configuration is - not the empty application one');
  Put(1, '{"DocIndexFile": "Help/help-index.json"}');
  Assert.AreEqual(1, THelpChatConfigController.ConfiguringFile(LFiles, ''),
    'the last file read that sets something wins');
  Put(0, '{"Provider": "claude", "Profiles": {"Orders": {"DocAreas": ["Orders"]}}}');
  Assert.AreEqual(0, THelpChatConfigController.ConfiguringFile(LFiles, 'orders'),
    'the file that defines the profile of the assistant');
  Assert.AreEqual(1, THelpChatConfigController.ConfiguringFile(LFiles, 'Sales'),
    'a profile nobody defines: where the rest is');
  Put(0, '{"Claude": {"ApiKey": "sk-ant-x"}}');
  Put(1, '');
  Assert.AreEqual(0, THelpChatConfigController.ConfiguringFile(LFiles, ''),
    'only keys: the file with a key of the catalogue, not the encrypted one of the application');
  Put(0, '{ not json');
  Assert.AreEqual(1, THelpChatConfigController.ConfiguringFile(LFiles, ''),
    'a file that does not parse counts as empty');
  Assert.AreEqual(0, THelpChatConfigController.ConfiguringFile(Copy(LFiles, 2, 1), ''),
    'one file: that one');
end;

procedure TConfigControllerTests.Entries_ComponentByName_ThenTheProviders;
var
  LController: THelpChatConfigController;
  LEntries: TArray<THelpChatConfigEntry>;
  I: Integer;
  LSeenModel: Boolean;
begin
  LController := NewController('');
  try
    LEntries := LController.Entries;
    LSeenModel := False;
    for I := 0 to High(LEntries) do
    begin
      // Once the providers start, nothing of the component follows.
      if LEntries[I].IsModel then
        LSeenModel := True
      else
        Assert.IsFalse(LSeenModel, LEntries[I].Path + ' after the providers');
      if (I > 0) and (LEntries[I].IsModel = LEntries[I - 1].IsModel) then
        Assert.IsTrue(CompareText(LEntries[I - 1].Path, LEntries[I].Path) < 0,
          LEntries[I - 1].Path + ' before ' + LEntries[I].Path);
      Assert.IsTrue(LEntries[I].Pages <> [], LEntries[I].Path + ' is on no page');
    end;
    Assert.IsTrue(LSeenModel);
    // The settings the list did not have.
    Assert.IsTrue(ccpSettings in EntryOf(LEntries, 'ConversationFile').Pages);
    Assert.IsTrue(ccpDocuments in EntryOf(LEntries, 'Pdf.Paper').Pages);
    Assert.IsTrue(ccpPrompt in EntryOf(LEntries, 'IdentityRule').Pages);
    Assert.AreEqual(2, Length(EntryOf(LEntries, 'Pdf.Orientation').Choices));
    Assert.IsTrue(EntryOf(LEntries, 'OpenAI.AzureDeployment').IsModel);
    // The Prompt page reads like the prompt: in the order it is written.
    LEntries := THelpChatConfigController.EntriesOfPage(LController.Entries, ccpPrompt);
    Assert.AreEqual('AssistantName', LEntries[0].Path);
    Assert.AreEqual('IdentityRule', LEntries[1].Path);
    Assert.AreEqual('Expertise', LEntries[2].Path);
    Assert.AreEqual('ExpertiseIntro', LEntries[3].Path);
    Assert.AreEqual('SystemPrompt', LEntries[4].Path);
    Assert.AreEqual('ExpertiseRule', LEntries[5].Path);
    Assert.AreEqual('Instructions', LEntries[6].Path);
    Assert.AreEqual('Language', LEntries[7].Path);
    Assert.AreEqual('DocLanguageRule', LEntries[10].Path);
    // The search in the language of the manual: with the languages.
    Assert.AreEqual('TranslateSearch', LEntries[11].Path);
    Assert.AreEqual('SearchTermsPrompt', LEntries[12].Path);
    // Now goes with the question (claude), next to the excerpts.
    Assert.AreEqual('NowRule', LEntries[13].Path);
    Assert.AreEqual('Claude.GroundingMaxPages', LEntries[14].Path);
    Assert.AreEqual('Gemini.GroundingMaxChars', LEntries[High(LEntries)].Path);
    // The other pages keep the order of the names.
    LEntries := THelpChatConfigController.EntriesOfPage(LController.Entries, ccpSettings);
    Assert.AreEqual('AllowedActions', LEntries[0].Path);
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.PromptTexts_ShowTheirText_AndResetToIt;
var
  LController: THelpChatConfigController;
  LEntry: THelpChatConfigEntry;
begin
  LController := NewController('');
  try
    // Left to the library: the text itself, in use and in the edit box.
    LEntry := EntryOf(LController.Entries, 'SystemPrompt');
    Assert.AreEqual(HELPCHAT_MODEL_DEF_SYSTEMPROMPT, LEntry.InUse);
    Assert.AreEqual(HELPCHAT_MODEL_DEF_SYSTEMPROMPT, LEntry.Value);
    Assert.AreEqual(csrDefault, LEntry.Source);
    Assert.IsFalse(LEntry.InComponent);
    // Written into the component: blue, and named after its property.
    LController.SetComponentValue('IdentityRule', 'I am %0:s.');
    LEntry := EntryOf(LController.Entries, 'IdentityRule');
    Assert.AreEqual('I am %0:s.', LEntry.InUse);
    Assert.AreEqual(csrComponent, LEntry.Source);
    Assert.AreEqual('Component: Settings.IdentityRule', LEntry.Origin);
    Assert.IsTrue(LEntry.InComponent);
    // Reset: the library's text again, not an empty one.
    // A string left to the library is in the edit box as it is used, so
    // that a correction is not a value typed again.
    LEntry := EntryOf(LController.Entries, 'Greeting');
    Assert.AreEqual(LEntry.InUse, LEntry.Value);
    Assert.AreNotEqual('', LEntry.Value);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_MODEL, EntryOf(LController.Entries, 'Claude.Model').Value);
    Assert.AreEqual('', EntryOf(LController.Entries, 'DocAreas').Value, 'nothing replaces it');
    LController.ResetComponentValue('IdentityRule');
    Assert.AreEqual(HELPCHAT_MODEL_DEF_IDENTITY_RULE, FComponent.IdentityRule);
    Assert.IsFalse(EntryOf(LController.Entries, 'IdentityRule').InComponent);
    // A file that writes one.
    LController.SetValue('LanguageRule', ccsRoot, 'Speak %0:s.');
    LEntry := EntryOf(LController.Entries, 'LanguageRule');
    Assert.AreEqual('Speak %0:s.', LEntry.InUse);
    Assert.AreEqual(csrFile, LEntry.Source);
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.PromptPreview_IsWhatTheModelWouldRead;
var
  LController: THelpChatConfigController;
  LPrompt: string;
begin
  LController := NewController('Orders');
  try
    FComponent.Expertise := 'order management';
    LController.SetValue('Instructions', ccsProfile, 'Be brief.');
    LPrompt := LController.PromptPreview;
    // The name of the profile in the file, the expertise of the component,
    // the instructions not saved yet, a sample screen and excerpt.
    Assert.StartsWith('Your name is Giulio.', LPrompt);
    Assert.Contains(LPrompt, 'Your field of expertise is order management.');
    Assert.Contains(LPrompt, 'Be brief.');
    Assert.Contains(LPrompt, 'Customers');
    Assert.Contains(LPrompt, '[Customers](Customers.md)');
    Assert.Contains(LPrompt, 'not customizable');
    Assert.DoesNotContain(LPrompt, HELPCHAT_MODEL_ACTIONS_RULE);
    // What each setting writes, found in the prompt as it is.
    Assert.AreEqual('Be brief.', LController.PromptFragment('Instructions'));
    Assert.Contains(LPrompt, LController.PromptFragment('SystemPrompt'));
    Assert.Contains(LPrompt, LController.PromptFragment('ExpertiseRule'));
    Assert.StartsWith('Your name is Giulio.', LController.PromptFragment('AssistantName'));
    Assert.Contains(LPrompt, LController.PromptFragment('Language'));
    Assert.Contains(LController.PromptFragment('Claude.GroundingMaxPages'), '[Customers](Customers.md)');
    Assert.AreEqual('', LController.PromptFragment('DocLanguageRule'), 'no manual in another language');
  finally
    LController.Free;
  end;
end;

procedure TConfigControllerTests.AppearancePreview_IsThePanelWithASampleConversation;
var
  LController: THelpChatConfigController;
  LPage, LError, LCss: string;
begin
  LController := NewController('Orders');
  try
    LPage := LController.AppearancePreview(True, '', '', [hccHelp, hccClear], LError);
    Assert.AreEqual('', LError);
    // The panel of the library, its conversation already in it and no
    // request to replace it.
    Assert.Contains(LPage, '<main id="hc-body" class="hc-chat-body">');
    Assert.DoesNotContain(LPage, 'hx-get="/api/history"');
    Assert.Contains(LPage, 'How do I add a new customer?');
    Assert.Contains(LPage, '<strong>Customers</strong>');
    Assert.Contains(LPage, 'hc-chat-system');
    Assert.Contains(LPage, '/help');
    Assert.Contains(LPage, '/clear');
    Assert.DoesNotContain(LPage, '/search', 'only the commands asked for');
    // The name of the profile in the file, in the header.
    Assert.Contains(LPage, 'Giulio');
    Assert.Contains(LPage, THelpChatTheme.Dark.Background);
    Assert.Contains(LController.AppearancePreview(False, '', '', [hccHelp], LError),
      THelpChatTheme.Light.Background);
    // A style sheet of the component, relative to the executable; a missing
    // one is said, not raised.
    LCss := TPath.Combine(FFolder, 'panel-custom.css');
    TFile.WriteAllText(LCss, '.hc-chat-title { letter-spacing: 3px; }');
    LPage := LController.AppearancePreview(False, '', 'panel-custom.css', [hccHelp], LError);
    Assert.AreEqual('', LError);
    Assert.Contains(LPage, 'letter-spacing: 3px');
    LController.AppearancePreview(False, '', 'missing.css', [hccHelp], LError);
    Assert.Contains(LError, 'missing.css');
  finally
    LController.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TConfigControllerTests);

end.
