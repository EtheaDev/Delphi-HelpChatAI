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
///  Profiles: one configuration file, a root everybody shares and a section
///  per assistant on top of it; the models named from the catalogue of the
///  root; the instructions of the assistant in the prompt whatever model
///  answers; one conversation, state and window file per assistant.
/// </summary>
unit HelpChatAI.Tests.Profiles;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  HelpChatAI.Settings;

type
  [TestFixture]
  TProfileTests = class
  public
    [Test]
    procedure Profile_IsAppliedOnTopOfTheRoot;
    [Test]
    procedure Profile_NoneOrUnknown_ReadsTheRootOnly;
    [Test]
    procedure Profile_IsNeverReadFromAFile;
    [Test]
    procedure Profile_LaterFileWins;
    [Test]
    procedure Models_ProfileNamesTheCatalogue;
    [Test]
    procedure Models_UnknownName_IsAnError;
    [Test]
    procedure Models_ProfileOfALaterFile_StillNamesTheCatalogue;
    [Test]
    procedure OldKeys_AreAnError;
    [Test]
    procedure SystemPrompt_InstructionsFollowTheRules;
    [Test]
    procedure SystemPrompt_ReplacesTheBuiltInOne;
    [Test]
    procedure Files_AreNamedAfterTheProfile;
    [Test]
    procedure AssistantName_ComesFromTheProfile;
  end;

implementation

uses
  System.IOUtils,
  HelpChatAI.Types,
  HelpChatAI.Messages;

const
  CONFIG =
    '{' +
    '  "Provider": "claude",' +
    '  "DocIndexFile": "Help\\help-index.json",' +
    '  "Instructions": "General.",' +
    '  "Models": [' +
    '    {"Name": "Claude Sonnet", "Provider": "claude", "Model": "claude-sonnet-x"},' +
    '    {"Name": "Gemma local", "Provider": "openai", "Model": "gemma4",' +
    '     "BaseUrl": "http://localhost:11434/v1"}' +
    '  ],' +
    '  "Profiles": {' +
    '    "Orders": {' +
    '      "AssistantName": "Giulio",' +
    '      "Instructions": "You are the expert of order entry.",' +
    '      "DocIndexFile": "Help\\orders-index.json",' +
    '      "Models": ["Gemma local"]' +
    '    }' +
    '  }' +
    '}';

function NewSettings(const AProfile: string): THelpChatSettings;
begin
  Result := THelpChatSettings.Create;
  Result.Profile := AProfile;
end;

procedure TProfileTests.Profile_IsAppliedOnTopOfTheRoot;
var
  LSettings: THelpChatSettings;
begin
  LSettings := NewSettings('Orders');
  try
    LSettings.LoadFromJSON(CONFIG);
    Assert.AreEqual('Help\orders-index.json', LSettings.DocIndexFile, 'the profile wins');
    Assert.AreEqual('claude', LSettings.Provider, 'what the profile does not say, the root does');
    Assert.AreEqual('You are the expert of order entry.', LSettings.Instructions);
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.Profile_NoneOrUnknown_ReadsTheRootOnly;
var
  LSettings: THelpChatSettings;
  LProfile: string;
begin
  for LProfile in ['', 'Planning'] do
  begin
    LSettings := NewSettings(LProfile);
    try
      LSettings.LoadFromJSON(CONFIG);
      Assert.AreEqual('Help\help-index.json', LSettings.DocIndexFile, LProfile);
      Assert.AreEqual('General.', LSettings.Instructions, LProfile);
      Assert.AreEqual(2, LSettings.Models.Count, LProfile);
    finally
      LSettings.Free;
    end;
  end;
end;

procedure TProfileTests.Profile_IsNeverReadFromAFile;
var
  LSettings: THelpChatSettings;
begin
  LSettings := NewSettings('Orders');
  try
    LSettings.LoadFromJSON('{"Profile": "Planning"}');
    Assert.AreEqual('Orders', LSettings.Profile, 'a profile cannot name itself');
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.Profile_LaterFileWins;
var
  LSettings: THelpChatSettings;
begin
  // The order of the default files: the shared one of the user, then the one
  // of the application. Within a file the profile beats the root; a later
  // file beats an earlier one, profile or root.
  LSettings := NewSettings('Orders');
  try
    LSettings.LoadFromJSON(CONFIG);
    LSettings.LoadFromJSON('{"Language": "it", "Profiles": {"Orders": {"Greeting": "Ciao"}}}');
    Assert.AreEqual(hclItalian, LSettings.Language);
    Assert.AreEqual('Ciao', LSettings.Greeting);
    Assert.AreEqual('Help\orders-index.json', LSettings.DocIndexFile, 'untouched by the second file');
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.Models_ProfileNamesTheCatalogue;
var
  LSettings: THelpChatSettings;
begin
  LSettings := NewSettings('Orders');
  try
    LSettings.LoadFromJSON(CONFIG);
    Assert.AreEqual(1, LSettings.Models.Count, 'the profile offers one model of the two');
    Assert.AreEqual('Gemma local', LSettings.Models[0].Name);
    Assert.AreEqual('openai', LSettings.Models[0].Provider, 'with everything the catalogue says');
    Assert.AreEqual('http://localhost:11434/v1', LSettings.Models[0].BaseUrl);
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.Models_ProfileOfALaterFile_StillNamesTheCatalogue;
var
  LSettings: THelpChatSettings;
begin
  // The first file narrows the profile to one model of its catalogue; the
  // file read after it (the per-user one, say) picks another one for the
  // same profile. The catalogue is still the root's two models: the profile
  // of the first file must not have eaten the one it did not name.
  LSettings := NewSettings('Orders');
  try
    LSettings.LoadFromJSON(CONFIG);
    Assert.AreEqual('Gemma local', LSettings.Models[0].Name);
    LSettings.LoadFromJSON('{"Profiles": {"Orders": {"Models": ["Claude Sonnet"]}}}');
    Assert.AreEqual(1, LSettings.Models.Count);
    Assert.AreEqual('Claude Sonnet', LSettings.Models[0].Name);
    Assert.AreEqual('claude-sonnet-x', LSettings.Models[0].Model,
      'with everything the catalogue of the first file says');
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.Models_UnknownName_IsAnError;
var
  LSettings: THelpChatSettings;
begin
  LSettings := NewSettings('');
  try
    Assert.WillRaise(
      procedure
      begin
        LSettings.LoadFromJSON('{"Models": ["Nobody"]}');
      end, EHelpChatConfigError);
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.OldKeys_AreAnError;
var
  LSettings: THelpChatSettings;
  LJson: string;
begin
  // What 1.6 read and 1.7 no longer does says so, instead of being ignored.
  for LJson in ['{"Assistants": []}', '{"Assistant": "Claude"}',
    '{"Profiles": {"Orders": {"Assistants": []}}}',
    '{"Claude": {"SystemPrompt": "You are Bob."}}'] do
  begin
    LSettings := NewSettings('Orders');
    try
      Assert.WillRaise(
        procedure
        begin
          LSettings.LoadFromJSON(LJson);
        end, EHelpChatConfigError, LJson);
    finally
      LSettings.Free;
    end;
  end;
end;

procedure TProfileTests.SystemPrompt_InstructionsFollowTheRules;
var
  LSettings: THelpChatSettings;
  LPrompt: string;
begin
  LSettings := NewSettings('Orders');
  try
    LSettings.LoadFromJSON(CONFIG);
    LPrompt := LSettings.ResolveSystemPrompt;
    Assert.StartsWith(HELPCHAT_MODEL_DEF_SYSTEMPROMPT, LPrompt, 'the rules first');
    Assert.EndsWith('You are the expert of order entry.', LPrompt, 'then the expert');
    // Whichever model answers: the prompt is the assistant's.
    LSettings.Provider := 'gemini';
    Assert.AreEqual(LPrompt, LSettings.ResolveSystemPrompt);
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.SystemPrompt_ReplacesTheBuiltInOne;
var
  LSettings: THelpChatSettings;
begin
  LSettings := NewSettings('');
  try
    LSettings.SystemPrompt := 'You are Bob.';
    LSettings.Instructions := 'Be brief.';
    Assert.AreEqual('You are Bob. Be brief.', LSettings.ResolveSystemPrompt);
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.Files_AreNamedAfterTheProfile;
var
  LSettings: THelpChatSettings;
begin
  LSettings := NewSettings('');
  try
    Assert.AreEqual(HELPCHAT_DEF_CONVERSATION_FILENAME,
      TPath.GetFileName(LSettings.ResolveConversationFile), 'the default assistant keeps the names');
    Assert.AreEqual(HELPCHAT_DEF_STATE_FILENAME, TPath.GetFileName(LSettings.ResolveStateFile));
    LSettings.Profile := 'Orders';
    Assert.AreEqual('helpchatai-conversation-Orders.json',
      TPath.GetFileName(LSettings.ResolveConversationFile));
    Assert.AreEqual('helpchatai-state-Orders.json', TPath.GetFileName(LSettings.ResolveStateFile));
    Assert.AreEqual('helpchatai-ui-Orders.json',
      TPath.GetFileName(LSettings.ProfileFileName('C:\x\helpchatai-ui.json')));
    LSettings.Profile := 'Sales team/2';
    Assert.AreEqual('helpchatai-state-Sales_team_2.json', TPath.GetFileName(LSettings.ResolveStateFile),
      'what a file name cannot hold is replaced');
    LSettings.ConversationFile := 'C:\data\mine.json';
    Assert.AreEqual('C:\data\mine.json', LSettings.ResolveConversationFile, 'a named file wins');
  finally
    LSettings.Free;
  end;
end;

procedure TProfileTests.AssistantName_ComesFromTheProfile;
var
  LSettings: THelpChatSettings;
begin
  LSettings := NewSettings('Orders');
  try
    LSettings.LoadFromJSON(CONFIG);
    Assert.AreEqual('Giulio', LSettings.AssistantName);
  finally
    LSettings.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TProfileTests);

end.
