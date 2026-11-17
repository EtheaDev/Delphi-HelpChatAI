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
///  The log: the level of the settings and its JSON, the filter, what an
///  entry carries, the handler and the global hook, and the entries a real
///  reply of the engine writes at each level.
/// </summary>
unit HelpChatAI.Tests.Log;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Log,
  HelpChatAI.Settings,
  HelpChatAI.Engine;

type
  [TestFixture]
  TLogTests = class
  strict private
    FEntries: TList<THelpChatLogEntry>;
    FSender: TObject;
    procedure Collect(Sender: TObject; const AEntry: THelpChatLogEntry);
    procedure Raising(Sender: TObject; const AEntry: THelpChatLogEntry);
    function Count: Integer;
    function HasText(const APrefix: string): Boolean;
    function EntryWith(const APrefix: string; out AEntry: THelpChatLogEntry): Boolean;
    /// <summary>One reply of the stub at ALevel; the entries end up in FEntries.</summary>
    procedure RunReply(const ALevel: THelpChatLogLevel);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Settings_DefaultIsInfo_AndRoundTripsInJson;
    [Test] procedure ConfigToLevel_AcceptsNamesAndPrefix;
    [Test] procedure Assign_CopiesLevelHandlerAndContext;
    [Test] procedure Logs_FiltersByLevel;
    [Test] procedure None_LogsNothing_ErrorsIncluded;
    [Test] procedure Entry_CarriesProfileContextAndSender;
    [Test] procedure Handler_ThatRaises_IsSwallowed;
    [Test] procedure GlobalHook_ReceivesEntries;
    [Test] procedure ToString_IsOneLine;
    [Test] procedure Engine_Info_LogsQuestionAndReplyButNotTheText;
    [Test] procedure Engine_Detail_LogsTheWholeQuestion;
    [Test] procedure Engine_Debug_LogsTheReply;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  HelpChatAI.Messages,
  HelpChatAI.Tests.Helpers;

procedure TLogTests.Setup;
begin
  FEntries := TList<THelpChatLogEntry>.Create;
  FSender := nil;
  HelpChatOnLog := nil;
end;

procedure TLogTests.TearDown;
begin
  HelpChatOnLog := nil;
  FEntries.Free;
end;

procedure TLogTests.Collect(Sender: TObject; const AEntry: THelpChatLogEntry);
begin
  TMonitor.Enter(FEntries);
  try
    FEntries.Add(AEntry);
    FSender := Sender;
  finally
    TMonitor.Exit(FEntries);
  end;
end;

procedure TLogTests.Raising(Sender: TObject; const AEntry: THelpChatLogEntry);
begin
  raise Exception.Create('a log handler that fails');
end;

function TLogTests.Count: Integer;
begin
  TMonitor.Enter(FEntries);
  try
    Result := FEntries.Count;
  finally
    TMonitor.Exit(FEntries);
  end;
end;

function TLogTests.EntryWith(const APrefix: string; out AEntry: THelpChatLogEntry): Boolean;
var
  LEntry: THelpChatLogEntry;
begin
  TMonitor.Enter(FEntries);
  try
    for LEntry in FEntries do
      if LEntry.Text.StartsWith(APrefix) then
      begin
        AEntry := LEntry;
        Exit(True);
      end;
  finally
    TMonitor.Exit(FEntries);
  end;
  Result := False;
end;

function TLogTests.HasText(const APrefix: string): Boolean;
var
  LEntry: THelpChatLogEntry;
begin
  Result := EntryWith(APrefix, LEntry);
end;

procedure TLogTests.Settings_DefaultIsInfo_AndRoundTripsInJson;
var
  LSettings, LCopy: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    Assert.AreEqual(llInfo, LSettings.LogLevel);
    LSettings.LogLevel := llDebug;
    Assert.Contains(LSettings.SaveToJSON, '"LogLevel"');
    LCopy.LoadFromJSON(LSettings.SaveToJSON);
    Assert.AreEqual(llDebug, LCopy.LogLevel);
    // A file that does not name it keeps what was there.
    LCopy.LoadFromJSON('{"Provider":"stub"}');
    Assert.AreEqual(llDebug, LCopy.LogLevel);
    LCopy.LoadFromJSON('{"LogLevel":"none"}');
    Assert.AreEqual(llNone, LCopy.LogLevel);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TLogTests.ConfigToLevel_AcceptsNamesAndPrefix;
begin
  Assert.AreEqual(llDetail, HelpChatConfigToLogLevel('detail', llInfo));
  Assert.AreEqual(llDetail, HelpChatConfigToLogLevel(' llDetail ', llInfo));
  Assert.AreEqual(llDebug, HelpChatConfigToLogLevel('DEBUG', llInfo));
  Assert.AreEqual(llInfo, HelpChatConfigToLogLevel('verbose', llInfo), 'unknown: the default');
  Assert.AreEqual(llNone, HelpChatConfigToLogLevel('', llNone));
  Assert.AreEqual('detail', HelpChatLogLevelToConfig(llDetail));
end;

procedure TLogTests.Assign_CopiesLevelHandlerAndContext;
var
  LSettings, LCopy: THelpChatSettings;
  LEntry: THelpChatLogEntry;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LSettings.LogLevel := llDetail;
    LSettings.SetLogHandler(Collect, Self);
    LSettings.SetLogContext('u:carla', 'reply-1');
    LCopy.Assign(LSettings);
    Assert.AreEqual(llDetail, LCopy.LogLevel);
    LCopy.Log(llDetail, lsInfo, lcRequest, 'from the snapshot');
    Assert.AreEqual(1, Count, 'the snapshot logs through the same handler');
    Assert.IsTrue(EntryWith('from the snapshot', LEntry));
    Assert.AreEqual('u:carla', LEntry.ConversationKey);
    Assert.AreEqual('reply-1', LEntry.RequestId);
    Assert.AreSame(TObject(Self), FSender, 'the sender of the handler goes with it');
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TLogTests.Logs_FiltersByLevel;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.SetLogHandler(Collect);
    LSettings.LogLevel := llInfo;
    Assert.IsTrue(LSettings.Logs(llInfo));
    Assert.IsFalse(LSettings.Logs(llDetail));
    LSettings.Log(llInfo, lsInfo, lcEngine, 'info');
    LSettings.Log(llDetail, lsInfo, lcEngine, 'detail');
    LSettings.Log(llDebug, lsInfo, lcEngine, 'debug');
    Assert.AreEqual(1, Count);
    LSettings.LogLevel := llDebug;
    LSettings.Log(llDetail, lsInfo, lcEngine, 'detail');
    LSettings.Log(llDebug, lsInfo, lcEngine, 'debug');
    Assert.AreEqual(3, Count);
    // Nobody listening: nothing is worth building.
    LSettings.SetLogHandler(nil);
    Assert.IsFalse(LSettings.Logs(llInfo));
  finally
    LSettings.Free;
  end;
end;

procedure TLogTests.None_LogsNothing_ErrorsIncluded;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.SetLogHandler(Collect);
    LSettings.LogLevel := llNone;
    LSettings.Log(llInfo, lsError, lcProvider, 'the service refused');
    Assert.AreEqual(0, Count);
    Assert.IsFalse(LSettings.Logs(llNone), 'llNone is never a level an entry is written at');
  finally
    LSettings.Free;
  end;
end;

procedure TLogTests.Entry_CarriesProfileContextAndSender;
var
  LSettings: THelpChatSettings;
  LEntry: THelpChatLogEntry;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Profile := 'Sales';
    LSettings.SetLogHandler(Collect);
    LSettings.Log(llInfo, lsWarning, lcAttachment, 'refused', 'u:mario', 'r-9', '{"a":1}');
    Assert.IsTrue(EntryWith('refused', LEntry));
    Assert.AreEqual('Sales', LEntry.Profile);
    Assert.AreEqual('u:mario', LEntry.ConversationKey);
    Assert.AreEqual('r-9', LEntry.RequestId);
    Assert.AreEqual(lsWarning, LEntry.Severity);
    Assert.AreEqual(lcAttachment, LEntry.Category);
    Assert.AreEqual(llInfo, LEntry.Level);
    Assert.AreEqual('{"a":1}', LEntry.Data);
    Assert.AreEqual(TThread.CurrentThread.ThreadID, LEntry.ThreadId);
    Assert.AreSame(TObject(LSettings), FSender, 'no sender given: the settings');
  finally
    LSettings.Free;
  end;
end;

procedure TLogTests.Handler_ThatRaises_IsSwallowed;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.SetLogHandler(Raising);
    LSettings.Log(llInfo, lsInfo, lcEngine, 'nothing breaks');
    Assert.Pass('a log never stops the assistant');
  finally
    LSettings.Free;
  end;
end;

procedure TLogTests.GlobalHook_ReceivesEntries;
var
  LSettings: THelpChatSettings;
  LTexts: TStringList;
begin
  LSettings := THelpChatSettings.Create;
  LTexts := TStringList.Create;
  try
    HelpChatOnLog :=
      procedure(const AEntry: THelpChatLogEntry)
      begin
        LTexts.Add(AEntry.Text);
      end;
    Assert.IsTrue(LSettings.Logs(llInfo), 'the hook is somebody listening');
    LSettings.Log(llInfo, lsInfo, lcEngine, 'to the hook');
    LSettings.Log(llDebug, lsInfo, lcEngine, 'filtered by the level');
    Assert.AreEqual(1, LTexts.Count);
    Assert.AreEqual('to the hook', LTexts[0]);
  finally
    HelpChatOnLog := nil;
    LTexts.Free;
    LSettings.Free;
  end;
end;

procedure TLogTests.ToString_IsOneLine;
var
  LEntry: THelpChatLogEntry;
  LLine: string;
begin
  LEntry := Default(THelpChatLogEntry);
  LEntry.Time := EncodeDate(2026, 11, 17) + EncodeTime(14, 3, 12, 345);
  LEntry.Severity := lsError;
  LEntry.Category := lcProvider;
  LEntry.Profile := 'Sales';
  LEntry.Text := 'claude: 429';
  LLine := LEntry.ToString;
  Assert.StartsWith('2026-11-17 14:03:12.345 ERROR provider', LLine);
  Assert.EndsWith('[Sales] claude: 429', LLine);
  Assert.AreEqual('a b c', HelpChatLogQuote('a'#13#10'b'#9'c'));
  Assert.AreEqual('abc...', HelpChatLogQuote('abcdef', 3));
end;

procedure TLogTests.RunReply(const ALevel: THelpChatLogLevel);
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LResult: THelpChatSendResult;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclEnglish;
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    LSettings.LogLevel := ALevel;
    LSettings.SetLogHandler(Collect);
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LResult := LEngine.Send('how do I add a company?');
      Assert.IsTrue(LResult.Sent);
      Assert.IsTrue(WaitFor(
        function: Boolean
        begin
          Result := HasText('Reply completed');
        end), 'the reply ends in the log');
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TLogTests.Engine_Info_LogsQuestionAndReplyButNotTheText;
var
  LEntry, LReply: THelpChatLogEntry;
  LItem: THelpChatLogEntry;
begin
  RunReply(llInfo);
  Assert.IsTrue(HasText('Engine started: provider stub'));
  Assert.IsTrue(HasText('Documentation index not found'), 'a warning at llInfo');
  Assert.IsTrue(EntryWith('Question sent: 23 characters', LEntry));
  Assert.IsTrue(EntryWith('Reply completed', LReply));
  Assert.AreEqual(LEntry.RequestId, LReply.RequestId, 'the entries of one reply share its id');
  Assert.AreNotEqual('', LReply.RequestId);
  Assert.AreEqual(LEntry.ConversationKey, LReply.ConversationKey);
  Assert.IsTrue(HasText('Engine stopped'));
  for LItem in FEntries do
    Assert.IsFalse(LItem.Text.Contains('company'), 'llInfo never carries what the user wrote');
end;

procedure TLogTests.Engine_Detail_LogsTheWholeQuestion;
begin
  RunReply(llDetail);
  Assert.IsTrue(HasText('Question: how do I add a company?'), 'whole, never cut');
  Assert.IsFalse(HasText('Reply: '), 'the reply is llDebug');
end;

procedure TLogTests.Engine_Debug_LogsTheReply;
var
  LEntry: THelpChatLogEntry;
begin
  RunReply(llDebug);
  Assert.IsTrue(HasText('Reply: '));
  Assert.IsTrue(HasText('Reply started: stub'));
  Assert.IsTrue(EntryWith('Settings in force', LEntry));
  Assert.Contains(LEntry.Data, '"LogLevel":"debug"', 'ToJSON, not formatted');
end;

end.
