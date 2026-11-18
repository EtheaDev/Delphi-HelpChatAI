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
///  What the review before 2.0 found, one test per defect, for the ones that
///  cross several units and belong to no fixture in particular: the state
///  file, the files of a profile, a configuration with a number that is not
///  whole, the worker and a handler that raises, the JSON a compatible
///  server really sends, a page name with a control character, what a page
///  writes inside a script, the printable document, the commands of a remote
///  session, the text of a light style.
/// </summary>
unit HelpChatAI.Tests.Regressions;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Engine;

type
  [TestFixture]
  TRegressionTests = class
  strict private
    FFolder: string;
    FHidden: Integer;
    FWatch: TObject;
    FCommands: Integer;
    procedure Hidden(Sender: TObject);
    procedure HiddenLetGo(Sender: TObject);
    procedure UiCommand(const ACommand: string);
    procedure RaisingHandler(Sender: TObject; const AMessageId: string);
    procedure RaisingPending(Sender: TObject);
    function NewSettings: THelpChatSettings;
    function IsDone(const AEngine: THelpChatEngine; const AId: string): Boolean;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure State_ALanguageChoice_DoesNotFreezeTheModel;
    [Test] procedure State_AModelChoice_IsRemembered;
    [Test] procedure ConversationFile_Relative_IsNextToTheExecutable;
    [Test] procedure ProfileFiles_OfTwoNonLatinProfiles_Differ;
    [Test] procedure Config_ANumberThatIsNotWhole_IsAConfigError;
    [Test] procedure Greeting_IsInTheLanguageOfTheChat_NotOfTheProcess;
    [Test] procedure Worker_SurvivesAHandlerThatRaises;
    [Test] procedure OpenAI_Stream_AcceptsNullToolCalls;
    [Test] procedure OpenAI_ApiError_MayBeAString;
    [Test] procedure Attachment_ABomBeforeOtherBytes_DoesNotRaise;
    [Test] procedure DocPage_AControlCharacter_IsNotAPage;
    [Test] procedure Page_AScriptEndInAName_DoesNotCloseTheScript;
    [Test] procedure Bubble_TheMessageId_IsEncoded;
    [Test] procedure PrintableDoc_LoadsNoImageFromOutside;
    [Test] procedure RemoteSession_DoesNotRunCheck;
    [Test] procedure VclStyles_TextIsReadableOnThePage;
    [Test] procedure SaveToJson_DoesNotFreezeTheDefaultsOfClaude;
    [Test] procedure OpenAI_Responses_KnowsARoundCutAtTheLimit;
    [Test] procedure ReplyCut_HasAMessageInEveryLanguage;
    [Test] procedure LifeToken_IsDeadAfterKill;
    [Test] procedure LocalServer_ACommandQueuedForAHandlerThatLeft_IsDropped;
    [Test] procedure HideWatch_TellsWhenTheFormIsHidden_AndGivesTheProcedureBack;
    [Test] procedure HideWatch_LetGoInsideItsOwnHandler;
    [Test] procedure Bubble_AFormReleasedThroughItsHook_IsNotReadAfterwards;
    [Test] procedure ConfirmDialog_TooManyValues_StaysOnTheScreen;
    [Test] procedure ConfirmDialog_AQuestionThatFits_DoesNotScroll_AndSpeaksTheLanguage;
    [Test] procedure ConfigEditor_ATextThatIsNotANumber_IsRefused_NotWrittenAsZero;
    [Test] procedure UrlPath_IsEncodedAndDecoded;
    [Test] procedure Index_APageWithSpacesInItsName_GetsALinkThatWorks;
    [Test] procedure Provider_ARedirect_IsNotFollowed_SoTheKeyStaysWhereItWasSent;
    [Test] procedure OpenAI_AModelWithoutEncryptedReasoning_IsAskedAgainWithoutIt;
    [Test] procedure OpenAI_OnlyARefusalOfTheEffort_RepeatsTheSearchTerms;
    [Test] procedure Claude_OnlyTheRefusalOfASystemMessage_IsTakenForOne;
    [Test] procedure Attachment_APicture_HasALimitOfItsOwn;
    [Test] procedure Models_AListThatNamesAnUnknownModel_LeavesTheListAsItWas;
    [Test] procedure FileInFolder_IsWhereTheApplicationWouldReadIt;
    [Test] procedure Html_AUrlInQuotes_IsLinkedWithoutTheQuote;
    [Test] procedure OpenAI_ItsEndpointWrittenWithTheVersion_IsStillOpenAI;
    [Test] procedure Actions_AHostThatCannotBeWoken_IsAFailedAction_NotAnException;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.HelpChatAI,
  Vcl.HelpChatAI.Bubble,
  HelpChatAI.Transport,
  HelpChatAI.Messages,
  HelpChatAI.Commands,
  HelpChatAI.Html,
  HelpChatAI.Panel,
  HelpChatAI.Theme,
  HelpChatAI.DocPages,
  HelpChatAI.Attachments,
  HelpChatAI.Server,
  HelpChatAI.Provider.OpenAI,
  Vcl.HelpChatAI.Theme,
  Vcl.StdCtrls,
  Vcl.HelpChatAI.ConfirmDialog,
  System.Generics.Collections,
  HelpChatAI.IndexBuilder,
  HelpChatAI.ConfigController,
  HelpChatAI.Provider,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.Gemini,
  HelpChatAI.Diagnostics,
  HelpChatAI.Actions,
  IdContext,
  IdCustomHTTPServer,
  IdHTTPServer,
  IdSocketHandle,
  HelpChatAI.Tests.Helpers;

type
  /// <summary>What a test answers a request of a provider with: the number
  /// of the request (from 1), its headers and body, the response to
  /// fill.</summary>
  TFakeServiceHandler = reference to procedure(const ACount: Integer;
    const ARequest: TIdHTTPRequestInfo; const ABody: string;
    const AResponse: TIdHTTPResponseInfo);

  /// <summary>A service on the loopback, for the provider under test to
  /// call: it counts the requests, keeps their bodies and lets the test
  /// answer each one.</summary>
  TFakeService = class
  private
    FServer: TIdHTTPServer;
    FHandler: TFakeServiceHandler;
    FCount: Integer;
    FBodies: TArray<string>;
    FKeySeen: Boolean;
    procedure Command(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure ParseAuthentication(AContext: TIdContext; const AAuthType, AAuthData: string;
      var VUsername, VPassword: string; var VHandled: Boolean);
  public
    constructor Create(const AHandler: TFakeServiceHandler);
    destructor Destroy; override;
    function Url: string;
    property Count: Integer read FCount;
    property Bodies: TArray<string> read FBodies;
    /// <summary>True when a request carried one of the headers a key
    /// travels in.</summary>
    property KeySeen: Boolean read FKeySeen;
  end;

constructor TFakeService.Create(const AHandler: TFakeServiceHandler);
var
  LBinding: TIdSocketHandle;
begin
  inherited Create;
  FHandler := AHandler;
  FServer := TIdHTTPServer.Create(nil);
  LBinding := FServer.Bindings.Add;
  LBinding.IP := '127.0.0.1';
  LBinding.Port := 0;               // whatever is free
  FServer.OnCommandGet := Command;
  FServer.OnCommandOther := Command;
  FServer.OnParseAuthentication := ParseAuthentication;
  FServer.Active := True;
end;

destructor TFakeService.Destroy;
begin
  FServer.Active := False;
  FServer.Free;
  inherited;
end;

function TFakeService.Url: string;
begin
  Result := Format('http://127.0.0.1:%d', [FServer.Bindings[0].Port]);
end;

procedure TFakeService.ParseAuthentication(AContext: TIdContext;
  const AAuthType, AAuthData: string; var VUsername, VPassword: string;
  var VHandled: Boolean);
begin
  // "Authorization: Bearer": Indy answers 401 by itself to a scheme nobody
  // says they handle.
  VHandled := True;
end;

procedure TFakeService.Command(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  LBody: string;
  LReader: TStreamReader;
  LCount: Integer;
begin
  LBody := '';
  if Assigned(ARequestInfo.PostStream) then
  begin
    ARequestInfo.PostStream.Position := 0;
    LReader := TStreamReader.Create(ARequestInfo.PostStream, TEncoding.UTF8);
    try
      LBody := LReader.ReadToEnd;
    finally
      LReader.Free;
    end;
  end;
  System.TMonitor.Enter(Self);
  try
    Inc(FCount);
    LCount := FCount;
    FBodies := FBodies + [LBody];
    if (ARequestInfo.RawHeaders.Values['x-api-key'] <> '') or
       (ARequestInfo.RawHeaders.Values['Authorization'] <> '') or
       (ARequestInfo.RawHeaders.Values['api-key'] <> '') or
       (ARequestInfo.RawHeaders.Values['x-goog-api-key'] <> '') then
      FKeySeen := True;
  finally
    System.TMonitor.Exit(Self);
  end;
  AResponseInfo.ResponseNo := 200;
  if Assigned(FHandler) then
    FHandler(LCount, ARequestInfo, LBody, AResponseInfo);
end;

procedure TRegressionTests.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'HelpChatAI-Regr-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FFolder);
end;

procedure TRegressionTests.TearDown;
begin
  if TDirectory.Exists(FFolder) then
    TDirectory.Delete(FFolder, True);
end;

procedure TRegressionTests.Hidden(Sender: TObject);
begin
  Inc(FHidden);
end;

procedure TRegressionTests.HiddenLetGo(Sender: TObject);
begin
  Inc(FHidden);
  // What the component does: the watch is let go from inside its own call.
  TVclHelpChatHideWatch(FWatch).LetGo;
  FWatch := nil;
end;

procedure TRegressionTests.UiCommand(const ACommand: string);
begin
  Inc(FCommands);
end;

procedure TRegressionTests.RaisingPending(Sender: TObject);
begin
  raise Exception.Create('the host could not be woken up');
end;

procedure TRegressionTests.RaisingHandler(Sender: TObject; const AMessageId: string);
begin
  raise Exception.Create('the handler of the application broke');
end;

function TRegressionTests.NewSettings: THelpChatSettings;
begin
  Result := THelpChatSettings.Create;
  Result.Language := hclEnglish;
  Result.Languages := [hclEnglish, hclItalian];
  Result.PersistConversation := True;
  Result.ConversationFile := TPath.Combine(FFolder, 'conversation.json');
  Result.DocIndexFile := 'Z:\no\index.json';
  with Result.Models.Add do
  begin
    Name := 'Locked';
    Provider := TEST_PROVIDER_UNCONFIGURED;
  end;
  with Result.Models.Add do
  begin
    Name := 'Echo';
    Provider := TEST_PROVIDER_ECHO;
  end;
  Result.SelectedModel := 'Locked';
end;

function TRegressionTests.IsDone(const AEngine: THelpChatEngine; const AId: string): Boolean;
var
  LMessage: THelpChatMessage;
begin
  Result := AEngine.TryGetMessage(AId, LMessage) and not LMessage.Pending;
end;

procedure TRegressionTests.State_ALanguageChoice_DoesNotFreezeTheModel;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LState: string;
begin
  // The configuration names Locked, which cannot answer: the start falls
  // back to Echo "and nothing is remembered". Then the user picks a
  // language - and the state file used to write the model in use with it,
  // so Echo stayed for good, Locked's key or not.
  LSettings := NewSettings;
  try
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.AreEqual('Echo', LEngine.ActiveModelInfo.Name);
      Assert.IsTrue(LEngine.SelectLanguage(hclItalian));
      LEngine.Stop;
    finally
      LEngine.Free;
    end;
    Assert.IsTrue(TFile.Exists(LSettings.ResolveStateFile), 'the language was remembered');
    LState := TFile.ReadAllText(LSettings.ResolveStateFile, TEncoding.UTF8);
    Assert.Contains(LState, '"Language"');
    Assert.DoesNotContain(LState, '"Model"', 'a model nobody picked is not written');
  finally
    LSettings.Free;
  end;
end;

procedure TRegressionTests.State_AModelChoice_IsRemembered;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
begin
  LSettings := NewSettings;
  try
    LSettings.SelectedModel := 'Echo';
    with LSettings.Models.Add do
    begin
      Name := 'Echo two';
      Provider := TEST_PROVIDER_ECHO;
    end;
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.IsTrue(LEngine.SelectModel('Echo two'));
      // And a language afterwards must not lose it.
      Assert.IsTrue(LEngine.SelectLanguage(hclItalian));
      LEngine.Stop;
    finally
      LEngine.Free;
    end;
    LSettings.SelectedModel := 'Echo';
    LSettings.Language := hclEnglish;
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.AreEqual('Echo two', LEngine.ActiveModelInfo.Name, 'what the user picked comes back');
      Assert.AreEqual(Ord(hclItalian), Ord(LEngine.ActiveLanguage));
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TRegressionTests.ConversationFile_Relative_IsNextToTheExecutable;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.ConversationFile := 'conv.json';
    Assert.IsFalse(TPath.IsRelativePath(LSettings.ResolveConversationFile),
      'not against the current directory, which every file dialog moves');
    Assert.AreEqual(
      IncludeTrailingPathDelimiter(TPath.GetDirectoryName(ParamStr(0))).ToLower,
      IncludeTrailingPathDelimiter(TPath.GetDirectoryName(LSettings.ResolveConversationFile)).ToLower);
    Assert.AreNotEqual('', TPath.GetDirectoryName(LSettings.ResolveStateFile),
      'the state file has a folder to be written in');
  finally
    LSettings.Free;
  end;
end;

procedure TRegressionTests.ProfileFiles_OfTwoNonLatinProfiles_Differ;
var
  LSales, LPurchases: THelpChatSettings;
begin
  LSales := THelpChatSettings.Create;
  LPurchases := THelpChatSettings.Create;
  try
    // "Sales" and "Purchases" in Russian, the same length: with ASCII only,
    // both became seven underscores and shared every file.
    LSales.Profile := #$041F#$0440#$043E#$0434#$0430#$0436#$0438;
    LPurchases.Profile := #$0417#$0430#$043A#$0443#$043F#$043A#$0438;
    Assert.AreNotEqual(LSales.ResolveConversationFile, LPurchases.ResolveConversationFile);
    Assert.AreNotEqual(LSales.ResolveStateFile, LPurchases.ResolveStateFile);
    // What a file name cannot hold is still replaced.
    LSales.Profile := 'Sales team/2';
    Assert.AreEqual('helpchatai-state-Sales_team_2.json', TPath.GetFileName(LSales.ResolveStateFile));
  finally
    LPurchases.Free;
    LSales.Free;
  end;
end;

procedure TRegressionTests.Config_ANumberThatIsNotWhole_IsAConfigError;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    // It used to leave as an EConvertError that named neither key nor file,
    // past every caller that turns a configuration error into a message.
    Assert.WillRaise(
      procedure
      begin
        LSettings.LoadFromJSON('{"PoolSize": 2.5}');
      end, EHelpChatConfigError);
    Assert.WillRaise(
      procedure
      begin
        LSettings.LoadFromJSON('{"Claude": {"MaxTokens": 99999999999}}');
      end, EHelpChatConfigError);
    LSettings.LoadFromJSON('{"PoolSize": 3, "HistoryMaxMessages": "20"}');
    Assert.AreEqual(3, LSettings.PoolSize);
    Assert.AreEqual(20, LSettings.HistoryMaxMessages, 'a number written as text is still read');
  finally
    LSettings.Free;
  end;
end;

procedure TRegressionTests.Greeting_IsInTheLanguageOfTheChat_NotOfTheProcess;
var
  LSettings: THelpChatSettings;
  LSaved: THelpChatLanguage;
begin
  LSaved := HelpChatDefaultLanguage;
  LSettings := THelpChatSettings.Create;
  try
    // An assistant that offers Spanish alone, in a process whose default
    // became Italian because another assistant started later.
    LSettings.Language := hclAuto;
    LSettings.Languages := [hclSpanish];
    HelpChatDefaultLanguage := hclItalian;
    Assert.AreEqual(HelpChatMsg(hcmGreeting, hclSpanish), LSettings.ResolveGreeting);
  finally
    HelpChatDefaultLanguage := LSaved;
    LSettings.Free;
  end;
end;

procedure TRegressionTests.Worker_SurvivesAHandlerThatRaises;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LFirst, LSecond: THelpChatSendResult;
  LMessage: THelpChatMessage;
begin
  // One worker, and an OnMessageChanged that raises on the worker thread:
  // the exception left the thread, and the second question stayed pending
  // for ever.
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclEnglish;
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    LSettings.Provider := TEST_PROVIDER_ECHO;
    LSettings.PoolSize := 1;
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.OnMessageChanged := RaisingHandler;
      LFirst := LEngine.Send('one');
      Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LEngine, LFirst.AssistantMessage.Id) end),
        'the first reply completes');
      LSecond := LEngine.Send('two');
      Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LEngine, LSecond.AssistantMessage.Id) end),
        'and the worker is still there for the second');
      LEngine.TryGetMessage(LSecond.AssistantMessage.Id, LMessage);
      Assert.IsFalse(LMessage.IsError, 'a reply is not an error because a listener broke');
      Assert.StartsWith('echo:two', LMessage.Content);
    finally
      LEngine.OnMessageChanged := nil;
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TRegressionTests.OpenAI_Stream_AcceptsNullToolCalls;
const
  // What several compatible gateways write on every chunk.
  CHUNK = 'data: {"choices":[{"index":0,"delta":{"content":"hi","tool_calls":null},' +
    '"finish_reason":null}],"usage":null}'#10#10;
  TAIL = 'data: {"choices":null}'#10'data: {"choices":[null]}'#10 +
    'data: {"choices":[{"delta":null}]}'#10#10;
var
  LStream: THelpChatOpenAIStream;
  LBytes: TBytes;
begin
  LStream := THelpChatOpenAIStream.Create(nil);
  try
    LBytes := TEncoding.UTF8.GetBytes(CHUNK + TAIL);
    // "as TJSONArray" on a JSON null raised inside the HTTP client, and the
    // reply ended as "Invalid class typecast".
    Assert.WillNotRaise(
      procedure
      begin
        LStream.Write(LBytes[0], Length(LBytes));
      end);
    Assert.AreEqual('hi', LStream.Text);
    Assert.AreEqual('', LStream.Error);
  finally
    LStream.Free;
  end;
end;

procedure TRegressionTests.OpenAI_ApiError_MayBeAString;
var
  LSettings: THelpChatSettings;
  LStream: THelpChatOpenAIStream;
  LBytes: TBytes;
begin
  LSettings := THelpChatSettings.Create;
  try
    // Ollama and LM Studio answer {"error":"..."}: the message itself.
    Assert.AreEqual('model "x" not found', THelpChatOpenAIProvider.ExtractApiError(
      '{"error":"model \"x\" not found"}', 404, 'Not Found', LSettings));
    Assert.Contains(THelpChatOpenAIProvider.ExtractApiError('{"error":null}', 500,
      'Server Error', LSettings), '500', 'nothing to quote: the status');
  finally
    LSettings.Free;
  end;
  LStream := THelpChatOpenAIStream.Create(nil);
  try
    LBytes := TEncoding.UTF8.GetBytes('data: {"error":"overloaded"}'#10#10);
    LStream.Write(LBytes[0], Length(LBytes));
    Assert.AreEqual('overloaded', LStream.Error);
  finally
    LStream.Free;
  end;
end;

procedure TRegressionTests.Attachment_ABomBeforeOtherBytes_DoesNotRaise;
var
  LBytes: TBytes;
  LText: string;
begin
  // A UTF-8 BOM, then a byte that is not UTF-8 (an ANSI e-grave): the
  // decoder raises on it, and TryAdd - which calls this - never does.
  LBytes := TBytes.Create($EF, $BB, $BF, Ord('a'), $E8, Ord('b'));
  Assert.WillNotRaise(
    procedure
    begin
      LText := HelpChatDecodeText(LBytes);
    end);
  Assert.AreEqual(3, Length(LText), 'the text is whole');
  Assert.AreEqual('a', LText[1]);
  Assert.AreEqual('b', LText[3]);
end;

procedure TRegressionTests.DocPage_AControlCharacter_IsNotAPage;
var
  LPages: THelpChatDocPages;
  LDoc: THelpChatRenderedDoc;
begin
  // The file system stops reading a name at #0: "secret.txt"#0".md" passed
  // the ".md only" rule and opened secret.txt.
  Assert.AreEqual('', THelpChatDocPages.NormalizePage('secret.txt'#0'.md'));
  Assert.AreEqual('', THelpChatDocPages.NormalizePath('a'#9'b.md'));
  Assert.AreEqual('Page.md', THelpChatDocPages.NormalizePage('Page.md'), 'a plain name still is one');
  TFile.WriteAllText(TPath.Combine(FFolder, 'secret.txt'), 'not a page', TEncoding.UTF8);
  LPages := THelpChatDocPages.Create(FFolder);
  try
    Assert.IsFalse(LPages.Render('secret.txt'#0'.md', nil, LDoc));
  finally
    LPages.Free;
  end;
end;

procedure TRegressionTests.Page_AScriptEndInAName_DoesNotCloseTheScript;
var
  LOptions: THelpChatPanelOptions;
  LPage: string;
begin
  // The configuration of the page is JSON inside a <script>, and JSON does
  // not escape "<": a name holding the end tag closed the element there.
  LOptions := THelpChatPanelOptions.Default;
  LOptions.Token := 'tok';
  LOptions.Language := hclEnglish;
  LOptions.AssistantName := '</script><script>alert(1)</script>';
  LPage := THelpChatPanel.RenderPage(LOptions);
  Assert.DoesNotContain(LPage, '</script><script>alert(1)', 'not as markup, anywhere in the page');
end;

procedure TRegressionTests.Bubble_TheMessageId_IsEncoded;
var
  LMessage: THelpChatMessage;
begin
  // The id comes back from a conversation file: one edited by hand must not
  // become markup.
  LMessage := Default(THelpChatMessage);
  LMessage.Id := '"><img src=x onerror=alert(1)>';
  LMessage.Role := hcrUser;
  LMessage.Content := 'q';
  Assert.DoesNotContain(HelpChatRenderBubble(LMessage), '<img src=x');
end;

procedure TRegressionTests.PrintableDoc_LoadsNoImageFromOutside;
var
  LDoc: THelpChatPrintableDoc;
  LHtml: string;
begin
  // What is printed is what the model wrote: an image it names on another
  // site was fetched when the PDF was made, with whatever its address
  // carried. The panel has a policy for this; the document had none.
  LDoc := Default(THelpChatPrintableDoc);
  LDoc.Title := 'T';
  LDoc.BodyHtml := '<p><img src="https://example.invalid/p?d=secret"></p>';
  LHtml := LDoc.Render;
  Assert.Contains(LHtml, 'http-equiv="Content-Security-Policy"');
  Assert.Contains(LHtml, 'img-src data:');
  Assert.IsTrue(LHtml.IndexOf('Content-Security-Policy') < LHtml.IndexOf('<style>'),
    'before anything that could load something');
end;

procedure TRegressionTests.RemoteSession_DoesNotRunCheck;
var
  LSession: THelpChatServerSession;
begin
  // /check prints the folders, the files and the missing keys of the machine
  // the engine runs on: for a remote session that is the server.
  LSession := THelpChatServerSession.Create('id', 'token', '', 's:1');
  try
    Assert.IsFalse(hccCheck in LSession.GetEnabledCommands);
    Assert.IsFalse(hccRun in LSession.GetEnabledCommands);
    Assert.IsTrue(hccHelp in LSession.GetEnabledCommands);
  finally
    LSession.Free;
  end;
end;

procedure TRegressionTests.SaveToJson_DoesNotFreezeTheDefaultsOfClaude;
var
  LSettings, LCopy: THelpChatSettings;
  LJson: string;
begin
  // The Claude section starts with its model and endpoint written out, and
  // SaveToJSON wrote them as they were: a file saved once carried the model
  // of that day for ever. The other sections have always written "".
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LJson := LSettings.SaveToJSON;
    Assert.DoesNotContain(LJson, HELPCHAT_CLAUDE_DEF_MODEL);
    Assert.DoesNotContain(LJson, HELPCHAT_CLAUDE_DEF_BASEURL);
    // Read back, the section is what it was: code that reads Claude.Model
    // sees the same string.
    LCopy.LoadFromJSON(LJson);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_MODEL, LCopy.Claude.Model);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_BASEURL, LCopy.Claude.BaseUrl);
    // A model of one's own is still written.
    LSettings.Claude.Model := 'claude-of-mine';
    Assert.Contains(LSettings.SaveToJSON, 'claude-of-mine');
    LCopy.LoadFromJSON(LSettings.SaveToJSON);
    Assert.AreEqual('claude-of-mine', LCopy.Claude.Model);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TRegressionTests.OpenAI_Responses_KnowsARoundCutAtTheLimit;
var
  LStream: THelpChatOpenAIResponsesStream;
  LBytes: TBytes;
begin
  LStream := THelpChatOpenAIResponsesStream.Create(nil);
  try
    Assert.IsFalse(LStream.CutAtLimit);
    LBytes := TEncoding.UTF8.GetBytes(
      'data: {"type":"response.incomplete","response":{"status":"incomplete",' +
      '"incomplete_details":{"reason":"max_output_tokens"}}}'#10#10);
    LStream.Write(LBytes[0], Length(LBytes));
    Assert.IsTrue(LStream.CutAtLimit);
  finally
    LStream.Free;
  end;
end;

procedure TRegressionTests.ReplyCut_HasAMessageInEveryLanguage;
var
  LLanguage: THelpChatLanguage;
begin
  for LLanguage in HELPCHAT_ALL_LANGUAGES do
    Assert.AreNotEqual('', HelpChatMsg(hcmReplyCut, LLanguage));
  Assert.AreNotEqual(HelpChatMsg(hcmReplyCut, hclEnglish), HelpChatMsg(hcmReplyCut, hclItalian));
end;

procedure TRegressionTests.LifeToken_IsDeadAfterKill;
var
  LLife: IHelpChatLifeToken;
begin
  LLife := THelpChatLifeToken.Create;
  Assert.IsTrue(LLife.IsAlive);
  LLife.Kill;
  Assert.IsFalse(LLife.IsAlive);
end;

procedure TRegressionTests.LocalServer_ACommandQueuedForAHandlerThatLeft_IsDropped;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LServer: THelpChatLocalServer;
  LTransport: IHelpChatTransport;
  LClient: THTTPClient;
  LHeaders: TNetHeaders;
  LUrl: string;
  I: Integer;
begin
  // The page posts "close", the request queues the call for the main thread
  // - and before the loop gets to it the component deactivates, or is
  // freed. The call that was queued must find nobody.
  LSettings := THelpChatSettings.Create;
  LSettings.PersistConversation := False;
  LSettings.DocIndexFile := 'Z:\no\index.json';
  LEngine := THelpChatEngine.Create(LSettings);
  LServer := THelpChatLocalServer.Create(LEngine, False);
  LTransport := LServer;
  LClient := THTTPClient.Create;
  try
    LServer.Start;
    LServer.SetOnUiCommand(UiCommand);
    LHeaders := [TNetHeader.Create(HELPCHAT_TOKEN_HEADER, LServer.Token)];
    LUrl := Format('http://%s:%d%sclose', [HELPCHAT_SERVER_HOST, LServer.BoundPort, HELPCHAT_API_UI]);
    FCommands := 0;
    Assert.IsTrue(LClient.Post(LUrl, TStream(nil), nil, LHeaders).StatusCode < 300);
    for I := 1 to 20 do
      CheckSynchronize(10);
    Assert.AreEqual(1, FCommands, 'delivered while the handler is there');

    Assert.IsTrue(LClient.Post(LUrl, TStream(nil), nil, LHeaders).StatusCode < 300);
    LServer.SetOnUiCommand(nil);          // the component deactivates
    for I := 1 to 20 do
      CheckSynchronize(10);
    Assert.AreEqual(1, FCommands, 'and dropped once it left');
  finally
    LClient.Free;
    LTransport := nil;
    LEngine.Free;
    LSettings.Free;
  end;
end;

procedure TRegressionTests.HideWatch_TellsWhenTheFormIsHidden_AndGivesTheProcedureBack;
var
  LForm: TForm;
  LWatch: TVclHelpChatHideWatch;
  LProc: TWndMethod;
begin
  LForm := TForm.CreateNew(nil);
  try
    LForm.Position := poDesigned;
    LForm.SetBounds(-3000, 100, 200, 100);
    LForm.Show;
    LWatch := TVclHelpChatHideWatch.CreateFor(LForm, Hidden);
    LProc := LForm.WindowProc;
    Assert.IsTrue(TMethod(LProc).Data = Pointer(LWatch), 'the form is listened to');
    FHidden := 0;
    // What ShowModal does when it ends, whoever frees the form afterwards.
    LForm.Hide;
    Assert.AreEqual(1, FHidden);
    LForm.Show;
    Assert.AreEqual(1, FHidden, 'showing is not hiding');
    LWatch.LetGo;
    LProc := LForm.WindowProc;
    Assert.IsTrue(TMethod(LProc).Data = Pointer(LForm), 'and its own procedure is back');
    LForm.Hide;
    Assert.AreEqual(1, FHidden, 'nobody listens any more');
  finally
    LForm.Free;
  end;
end;

procedure TRegressionTests.HideWatch_LetGoInsideItsOwnHandler;
var
  LForm: TForm;
begin
  // The handler hands the chat window to another owner and lets the watch
  // go while the call of the watch that brought it there is on the stack.
  LForm := TForm.CreateNew(nil);
  try
    LForm.Position := poDesigned;
    LForm.SetBounds(-3000, 100, 200, 100);
    LForm.Show;
    FWatch := TVclHelpChatHideWatch.CreateFor(LForm, HiddenLetGo);
    FHidden := 0;
    Assert.WillNotRaise(
      procedure
      begin
        LForm.Hide;
        LForm.Show;
        LForm.Hide;
      end);
    Assert.AreEqual(1, FHidden, 'once: it let itself go');
    Assert.IsNull(FWatch);
  finally
    LForm.Free;
  end;
  // A watch whose form is freed goes with it (the leak check of the suite).
  LForm := TForm.CreateNew(nil);
  TVclHelpChatHideWatch.CreateFor(LForm, Hidden);
  LForm.Free;
end;

procedure TRegressionTests.Bubble_AFormReleasedThroughItsHook_IsNotReadAfterwards;
var
  LForm: TForm;
  LBubble: TVclHelpChatAIBubble;
begin
  // CM_RELEASE goes through the hook of the bubble, and the form - with the
  // hook - is freed inside the call the hook passed on: the hook then went
  // on to read its own list.
  LForm := TForm.CreateNew(nil);
  LForm.Position := poDesigned;
  LForm.SetBounds(-3000, 100, 300, 200);
  LBubble := TVclHelpChatAIBubble.Create(LForm);
  LBubble.Parent := LForm;
  LForm.HandleNeeded;
  Assert.WillNotRaise(
    procedure
    begin
      LForm.Release;
      Application.ProcessMessages;
      Application.ProcessMessages;
      Application.ProcessMessages;
    end);
  Assert.IsTrue(Screen.FormCount >= 0);
end;

procedure TRegressionTests.VclStyles_TextIsReadableOnThePage;
var
  I: Integer;
  LTheme: THelpChatTheme;
begin
  // Every row of the table: the text of a style is chosen for its panels,
  // and the page of a light style is white whatever the panels are - the
  // 'Raize Frost' rows gave white on white. The threshold is what tells
  // text from page, not a measure of comfort: the table is the styles'.
  for I := Low(HELPCHAT_VCL_STYLE_TABLE) to High(HELPCHAT_VCL_STYLE_TABLE) do
  begin
    LTheme := HelpChatThemeFromVclStyle(HELPCHAT_VCL_STYLE_TABLE[I].Name);
    Assert.IsTrue(
      Abs(HelpChatLuminance(LTheme.Text) - HelpChatLuminance(LTheme.Background)) >= 0.3,
      Format('%s: text %s on page %s', [HELPCHAT_VCL_STYLE_TABLE[I].Name, LTheme.Text,
        LTheme.Background]));
  end;
end;

procedure TRegressionTests.ConfirmDialog_TooManyValues_StaysOnTheScreen;
var
  LDialog: TVclHelpChatConfirmDialog;
  LRequest: TVclHelpChatConfirmRequest;
  LScroll: TScrollBox;
  I: Integer;
begin
  // Sixty parameters, each with a value that wraps: the form grew with them
  // and the buttons ended below the taskbar.
  LRequest := Default(TVclHelpChatConfirmRequest);
  LRequest.Caption := 'Assistant';
  LRequest.Title := 'The assistant wants to run create_order';
  LRequest.Description := 'Creates an order.';
  LRequest.Footer := 'The model wrote these values.';
  LRequest.Language := hclEnglish;
  SetLength(LRequest.Values, 60);
  for I := 0 to High(LRequest.Values) do
    LRequest.Values[I] := TPair<string, string>.Create('Parameter ' + IntToStr(I),
      StringOfChar('x', 30) + ' ' + StringOfChar('y', 30) + ' ' + StringOfChar('z', 30) +
      ' ' + StringOfChar('w', 30));
  LDialog := TVclHelpChatConfirmDialog.Create(nil);
  try
    LDialog.Prepare(LRequest);
    Assert.IsTrue(LDialog.Height <= LDialog.Monitor.WorkareaRect.Height,
      Format('%d pixels on a work area of %d', [LDialog.Height,
        LDialog.Monitor.WorkareaRect.Height]));
    LScroll := nil;
    for I := 0 to LDialog.ControlCount - 1 do
      if LDialog.Controls[I] is TScrollBox then
        LScroll := TScrollBox(LDialog.Controls[I]);
    Assert.IsNotNull(LScroll, 'the values scroll');
    Assert.AreSame(LScroll, LDialog.ValuesPanel.Parent);
    Assert.IsTrue(LDialog.ValuesPanel.Height > LScroll.ClientHeight, 'and there is something to scroll');
    // Still in order: header, values, footer, buttons.
    Assert.IsTrue(LScroll.Top >= LDialog.HeaderPanel.Top + LDialog.HeaderPanel.Height, 'under the header');
    Assert.IsTrue(LDialog.FooterPanel.Top >= LScroll.Top + LScroll.Height, 'above the footer');
    Assert.IsTrue(LDialog.ButtonsPanel.Top + LDialog.ButtonsPanel.Height <= LDialog.ClientHeight,
      'the buttons are inside the form');
    // No value runs under the scroll bar.
    for I := 0 to LDialog.ValuesPanel.ControlCount - 1 do
      Assert.IsTrue(LDialog.ValuesPanel.Controls[I].BoundsRect.Right <= LScroll.ClientWidth,
        'a value ends before the scroll bar');
  finally
    LDialog.Free;
  end;
end;

procedure TRegressionTests.ConfirmDialog_AQuestionThatFits_DoesNotScroll_AndSpeaksTheLanguage;
var
  LDialog: TVclHelpChatConfirmDialog;
  LRequest: TVclHelpChatConfirmRequest;
  I: Integer;
begin
  LRequest := Default(TVclHelpChatConfirmRequest);
  LRequest.Caption := 'Assistente';
  LRequest.Title := 'L''assistente vuole eseguire create_order';
  LRequest.Language := hclItalian;
  SetLength(LRequest.Values, 2);
  LRequest.Values[0] := TPair<string, string>.Create('Cliente', 'Rossi');
  LRequest.Values[1] := TPair<string, string>.Create('Importo', '120');
  LDialog := TVclHelpChatConfirmDialog.Create(nil);
  try
    LDialog.Prepare(LRequest);
    for I := 0 to LDialog.ControlCount - 1 do
      Assert.IsFalse(LDialog.Controls[I] is TScrollBox, 'nothing to scroll');
    Assert.AreSame(LDialog, LDialog.ValuesPanel.Parent);
    // The words of the chat, not those the RTL was built with.
    Assert.AreEqual(HelpChatMsg(hcmConfirmYes, hclItalian), LDialog.YesButton.Caption);
    Assert.AreEqual(HelpChatMsg(hcmConfirmNo, hclItalian), LDialog.NoButton.Caption);
    Assert.AreNotEqual(HelpChatMsg(hcmConfirmYes, hclEnglish), LDialog.YesButton.Caption);
  finally
    LDialog.Free;
  end;
end;

procedure TRegressionTests.ConfigEditor_ATextThatIsNotANumber_IsRefused_NotWrittenAsZero;
var
  LComponent: THelpChatSettings;
  LController: THelpChatConfigController;
  LFile, LText: string;
begin
  // An emptied box wrote "MaxTokens": 0 into the file.
  LFile := TPath.Combine(FFolder, 'numbers.json');
  TFile.WriteAllText(LFile, '{"Claude": {"MaxTokens": 2048}}', TEncoding.UTF8);
  LComponent := THelpChatSettings.Create;
  LController := THelpChatConfigController.Create(LComponent, '',
    TPath.Combine(FFolder, 'App.exe'), LFile);
  try
    Assert.WillRaise(
      procedure
      begin
        LController.SetValue('Claude.MaxTokens', ccsRoot, '');
      end, EHelpChatConfigError, 'an empty text');
    Assert.WillRaise(
      procedure
      begin
        LController.SetValue('Claude.MaxTokens', ccsRoot, '4k');
      end, EHelpChatConfigError, 'not a number');
    Assert.WillRaise(
      procedure
      begin
        LController.SetValue('OpenAI.MaxTokens', ccsRoot, '99999999999');
      end, EHelpChatConfigError, 'too large for the setting');
    Assert.WillRaise(
      procedure
      begin
        LController.SetComponentValue('Claude.MaxTokens', 'many');
      end, EHelpChatConfigError, 'into the component neither');
    Assert.IsTrue(LController.Save, LController.LastError);
    LText := TFile.ReadAllText(LFile, TEncoding.UTF8);
    Assert.Contains(LText, '2048', 'the value that was there');
    Assert.DoesNotContain(LText, 'OpenAI', 'and no section made for a value that was refused');
    LController.SetValue('Claude.MaxTokens', ccsRoot, ' 1024 ');
    Assert.IsTrue(LController.Save, LController.LastError);
    Assert.Contains(TFile.ReadAllText(LFile, TEncoding.UTF8), '1024');
  finally
    LController.Free;
    LComponent.Free;
  end;
end;

procedure TRegressionTests.UrlPath_IsEncodedAndDecoded;
const
  NAMES: array[0..5] of string = ('Leads', 'Sales/Draft-Proposal', 'My page (1)',
    '100% sure? #1', 'Città e perché', 'a+b [draft]');
var
  LName, LEncoded: string;
  LChar: Char;
begin
  Assert.AreEqual('Leads', HelpChatEncodeUrlPath('Leads'), 'a plain name is unchanged');
  Assert.AreEqual('Sales/Draft-Proposal', HelpChatEncodeUrlPath('Sales/Draft-Proposal'));
  Assert.AreEqual('My%20page%20%281%29', HelpChatEncodeUrlPath('My page (1)'));
  Assert.AreEqual('Città', HelpChatEncodeUrlPath('Città'), 'letters stay letters');
  for LName in NAMES do
  begin
    LEncoded := HelpChatEncodeUrlPath(LName);
    for LChar in ' ()[]<>#?' do
      Assert.AreEqual(0, Pos(LChar, LEncoded), LEncoded);
    Assert.AreEqual(LName, HelpChatDecodeUrlPath(LEncoded));
  end;
  // What another tool may have written, and what is not an encoding at all.
  Assert.AreEqual('Città', HelpChatDecodeUrlPath('Citt%C3%A0'));
  Assert.AreEqual('a+b', HelpChatDecodeUrlPath('a+b'));
  Assert.AreEqual('100%', HelpChatDecodeUrlPath('100%'));
  Assert.AreEqual('50%zz', HelpChatDecodeUrlPath('50%zz'));
end;

procedure TRegressionTests.Index_APageWithSpacesInItsName_GetsALinkThatWorks;
var
  LBuilder: THelpChatIndexBuilder;
  LOptions: THelpChatIndexBuilderOptions;
  LPages: TArray<THelpChatIndexPage>;
  LDocPages: TArray<THelpChatDocPage>;
  LSource: string;
begin
  // "[Price list](Price list (2026).md)" is not a link: the target ended at
  // the first space, and the reply showed the brackets.
  LSource := TPath.Combine(FFolder, 'manual');
  TDirectory.CreateDirectory(LSource);
  TFile.WriteAllText(TPath.Combine(LSource, 'Price list (2026).md'),
    '# Price list'#13#10#13#10'The prices of the year.'#13#10, TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(LSource, 'Leads.md'),
    '# Leads'#13#10#13#10'The board of the leads.'#13#10, TEncoding.UTF8);
  LBuilder := THelpChatIndexBuilder.Create;
  try
    LOptions := THelpChatIndexBuilderOptions.Default;
    LOptions.SourceFolder := LSource;
    LOptions.UrlExtension := '';
    LPages := LBuilder.Build(LOptions);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(2, Integer(Length(LPages)));
  SetLength(LDocPages, 2);
  LDocPages[0].Title := LPages[0].Title;
  LDocPages[0].Url := LPages[0].Url;
  LDocPages[1].Title := LPages[1].Title;
  LDocPages[1].Url := LPages[1].Url;
  if LDocPages[0].Title <> 'Price list' then
  begin
    LDocPages[0] := LDocPages[1];
    LDocPages[1].Title := LPages[0].Title;
    LDocPages[1].Url := LPages[0].Url;
  end;
  Assert.AreEqual('Price%20list%20%282026%29.md', LDocPages[0].Url);
  Assert.AreEqual('Leads.md', LDocPages[1].Url, 'a plain name as before');
  // The page the browser asks for is the file: what panel.js does with
  // decodeURIComponent before GET /api/doc.
  Assert.AreEqual('Price list (2026).md', HelpChatDecodeUrlPath(LDocPages[0].Url));
  // And a reply that names the file as the user reads it still gets its source.
  Assert.AreEqual('Source: [Price list](Price%20list%20%282026%29.md)', HelpChatSourcesLine(
    'See the file Price list (2026) for the amounts.', LDocPages, hclEnglish));
end;

procedure TRegressionTests.Provider_ARedirect_IsNotFollowed_SoTheKeyStaysWhereItWasSent;
const
  PROVIDERS: array[0..2] of string = (HELPCHAT_PROVIDER_CLAUDE, HELPCHAT_PROVIDER_OPENAI,
    HELPCHAT_PROVIDER_GEMINI);
var
  LFirst, LSecond: TFakeService;
  LSettings: THelpChatSettings;
  LProvider: IHelpChatProvider;
  LHistory: TArray<THelpChatMessage>;
  LName, LTarget: string;
begin
  // The HTTP client follows a redirect by itself and repeats the headers of
  // the request at the new address: an endpoint that answers 307 - a wrong
  // gateway, a mistyped domain somebody registered - was handed the key.
  SetLength(LHistory, 1);
  LHistory[0].Role := hcrUser;
  LHistory[0].Content := 'hi';
  for LName in PROVIDERS do
  begin
    LSecond := TFakeService.Create(nil);
    LTarget := LSecond.Url + '/elsewhere';
    LFirst := TFakeService.Create(
      procedure(const ACount: Integer; const ARequest: TIdHTTPRequestInfo;
        const ABody: string; const AResponse: TIdHTTPResponseInfo)
      begin
        AResponse.ResponseNo := 307;
        AResponse.CustomHeaders.Values['Location'] := LTarget;
      end);
    LSettings := THelpChatSettings.Create;
    try
      LSettings.Provider := LName;
      LSettings.DocIndexFile := 'Z:\no\index.json';
      LSettings.Claude.BaseUrl := LFirst.Url;
      LSettings.Claude.ApiKey := 'key-of-the-test';
      LSettings.OpenAI.BaseUrl := LFirst.Url;
      LSettings.OpenAI.ApiKey := 'key-of-the-test';
      LSettings.Gemini.BaseUrl := LFirst.Url;
      LSettings.Gemini.ApiKey := 'key-of-the-test';
      LProvider := THelpChatProviderRegistry.CreateProvider(LName, LSettings, nil);
      Assert.WillRaise(
        procedure
        begin
          LProvider.Generate(LHistory, Default(THelpChatContext), nil, nil);
        end, EHelpChatError, LName + ': a redirect is an error, not an empty reply');
      Assert.AreEqual(1, LFirst.Count, LName + ': asked once');
      Assert.IsTrue(LFirst.KeySeen, LName + ': the key went where it was sent');
      Assert.AreEqual(0, LSecond.Count, LName + ': nothing reached the other address');
      LProvider := nil;
    finally
      LSettings.Free;
      LFirst.Free;
      LSecond.Free;
    end;
  end;
end;

procedure TRegressionTests.OpenAI_AModelWithoutEncryptedReasoning_IsAskedAgainWithoutIt;
var
  LService: TFakeService;
  LSettings: THelpChatSettings;
  LProvider: IHelpChatProvider;
  LHistory: TArray<THelpChatMessage>;
  LModel, LReply: string;
begin
  // The Responses API is asked for the encrypted reasoning of every round;
  // a model that does not reason refuses the request, and every question
  // failed until somebody set Api = chat.
  LModel := 'plain-' + TGUID.NewGuid.ToString;   // the refusal is remembered per model
  Assert.IsTrue(THelpChatOpenAIProvider.AsksForNoEncryptedReasoning(
    'Encrypted content is not supported with this model.'));
  Assert.IsFalse(THelpChatOpenAIProvider.AsksForNoEncryptedReasoning('Incorrect API key provided'));
  Assert.IsFalse(THelpChatOpenAIProvider.RefusesEncryptedReasoning(LModel));
  SetLength(LHistory, 1);
  LHistory[0].Role := hcrUser;
  LHistory[0].Content := 'hi';
  LService := TFakeService.Create(
    procedure(const ACount: Integer; const ARequest: TIdHTTPRequestInfo;
      const ABody: string; const AResponse: TIdHTTPResponseInfo)
    begin
      if ACount = 1 then
      begin
        AResponse.ResponseNo := 400;
        AResponse.ContentType := 'application/json';
        AResponse.ContentText := '{"error":{"message":"Encrypted content is not ' +
          'supported with this model.","type":"invalid_request_error"}}';
      end
      else
      begin
        AResponse.ContentType := 'text/event-stream';
        AResponse.ContentText :=
          'data: {"type":"response.output_text.delta","delta":"hello"}'#10#10 +
          'data: {"type":"response.completed","response":{"model":"plain",' +
          '"usage":{"input_tokens":1,"output_tokens":1}}}'#10#10;
      end;
    end);
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := HELPCHAT_PROVIDER_OPENAI;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    LSettings.OpenAI.BaseUrl := LService.Url;
    LSettings.OpenAI.Api := 'responses';
    LSettings.OpenAI.Model := LModel;
    LSettings.OpenAI.ApiKey := 'key-of-the-test';
    LProvider := THelpChatProviderRegistry.CreateProvider(HELPCHAT_PROVIDER_OPENAI, LSettings, nil);
    LReply := LProvider.Generate(LHistory, Default(THelpChatContext), nil, nil);
    Assert.AreEqual('hello', LReply);
    Assert.AreEqual(2, LService.Count, 'the refused round, then the same round again');
    Assert.Contains(LService.Bodies[0], 'reasoning.encrypted_content');
    Assert.DoesNotContain(LService.Bodies[1], 'encrypted_content');
    Assert.IsTrue(THelpChatOpenAIProvider.RefusesEncryptedReasoning(LModel),
      'remembered: the next question does not ask again');
    // And it does not: one request.
    LReply := LProvider.Generate(LHistory, Default(THelpChatContext), nil, nil);
    Assert.AreEqual(3, LService.Count);
    LProvider := nil;
  finally
    LSettings.Free;
    LService.Free;
  end;
end;

procedure TRegressionTests.OpenAI_OnlyARefusalOfTheEffort_RepeatsTheSearchTerms;
begin
  // The request of the search terms was repeated for every error: a wrong
  // key or a rate limit cost a second failing request before each reply.
  Assert.IsTrue(THelpChatOpenAIProvider.RefusesReasoningEffort(
    'Unsupported parameter: ''reasoning_effort'' is not supported with this model.'));
  Assert.IsTrue(THelpChatOpenAIProvider.RefusesReasoningEffort(
    'Unsupported value: ''reasoning.effort'' does not support ''none''.'));
  Assert.IsTrue(THelpChatOpenAIProvider.RefusesReasoningEffort(
    '"gemma4" does not support thinking'));
  Assert.IsFalse(THelpChatOpenAIProvider.RefusesReasoningEffort('Incorrect API key provided'));
  Assert.IsFalse(THelpChatOpenAIProvider.RefusesReasoningEffort(
    'Rate limit reached for requests'));
end;

procedure TRegressionTests.Claude_OnlyTheRefusalOfASystemMessage_IsTakenForOne;
begin
  Assert.IsTrue(THelpChatClaudeProvider.IsSystemRoleRefusal(
    'messages.1.role: role ''system'' is not supported on this model'));
  // "system" and "role" alone used to be enough: the round was repeated, and
  // the model remembered as one that refuses, for the whole process.
  Assert.IsFalse(THelpChatClaudeProvider.IsSystemRoleRefusal(
    'Overloaded: the system is busy, role unavailable'));
  Assert.IsFalse(THelpChatClaudeProvider.IsSystemRoleRefusal(
    'system: text content blocks must be non-empty'));
  Assert.IsFalse(THelpChatClaudeProvider.IsSystemRoleRefusal('This feature is not supported'));
end;

procedure TRegressionTests.Attachment_APicture_HasALimitOfItsOwn;
var
  LSet: THelpChatAttachmentSet;
  LData: TBytes;
  LAttachment: THelpChatAttachment;
  LError: string;
begin
  // 4 MB: under the 8 MB of an attachment, over what a service takes for a
  // picture - and a refused picture made every later question fail, because
  // the attachments go up again with each of them.
  SetLength(LData, 4 * 1024 * 1024);
  FillChar(LData[0], Length(LData), 1);
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsFalse(LSet.TryAdd('k', 'photo.png', LData, THelpChatAttachmentLimits.Default,
      hclEnglish, LAttachment, LError), 'a picture of 4 MB is refused');
    Assert.Contains(LError, 'photo.png');
    Assert.IsTrue(LSet.TryAdd('k', 'manual.pdf', LData, THelpChatAttachmentLimits.Default,
      hclEnglish, LAttachment, LError), 'a PDF of 4 MB is not: ' + LError);
    SetLength(LData, 1024 * 1024);
    Assert.IsTrue(LSet.TryAdd('k', 'photo.png', LData, THelpChatAttachmentLimits.Default,
      hclEnglish, LAttachment, LError), 'a picture of 1 MB is taken: ' + LError);
  finally
    LSet.Free;
  end;
end;

procedure TRegressionTests.Models_AListThatNamesAnUnknownModel_LeavesTheListAsItWas;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.LoadFromJSON('{"Models":[{"Name":"A","Provider":"stub"},' +
      '{"Name":"B","Provider":"stub"}]}');
    Assert.AreEqual(2, LSettings.Models.Count);
    // The list was emptied before the names were looked up: whoever caught
    // the error went on with the part that had been read.
    Assert.WillRaise(
      procedure
      begin
        LSettings.LoadFromJSON('{"Models":["B","Nobody","A"]}');
      end, EHelpChatConfigError);
    Assert.AreEqual(2, LSettings.Models.Count, 'all of the list or none of it');
    Assert.AreEqual('A', LSettings.Models[0].Name);
    Assert.AreEqual('B', LSettings.Models[1].Name);
  finally
    LSettings.Free;
  end;
end;

procedure TRegressionTests.OpenAI_ItsEndpointWrittenWithTheVersion_IsStillOpenAI;
var
  LSettings: THelpChatSettings;
begin
  // "https://api.openai.com/v1" was taken for another service and spoken
  // to with Chat Completions, where the default model refuses the actions.
  LSettings := THelpChatSettings.Create;
  try
    Assert.IsTrue(LSettings.OpenAI.UsesResponses, 'the default endpoint');
    LSettings.OpenAI.BaseUrl := 'https://api.openai.com/v1/';
    Assert.IsTrue(LSettings.OpenAI.UsesResponses, 'the same one, with its version');
    LSettings.OpenAI.BaseUrl := 'http://localhost:11434/v1';
    Assert.IsFalse(LSettings.OpenAI.UsesResponses, 'another server');
    LSettings.OpenAI.BaseUrl := 'https://api.openai.com/v1';
    LSettings.OpenAI.Api := 'chat';
    Assert.IsFalse(LSettings.OpenAI.UsesResponses, 'Api still decides');
  finally
    LSettings.Free;
  end;
end;

procedure TRegressionTests.Html_AUrlInQuotes_IsLinkedWithoutTheQuote;
var
  LHtml: string;
begin
  // In HTML the quote after an address is an entity: the link took it in,
  // and pointed nowhere.
  LHtml := HelpChatAutoLinkUrls('<p>See &quot;https://example.com/a?b=1&amp;c=2&quot; or ' +
    '&lt;https://example.org/x&gt;</p>');
  Assert.Contains(LHtml, 'href="https://example.com/a?b=1&amp;c=2"');
  Assert.Contains(LHtml, 'href="https://example.org/x"');
  Assert.DoesNotContain(LHtml, 'quot;"');
  Assert.DoesNotContain(LHtml, 'gt;"');
end;

procedure TRegressionTests.Actions_AHostThatCannotBeWoken_IsAFailedAction_NotAnException;
var
  LBroker: THelpChatActionBroker;
  LInvoker: IHelpChatActionInvoker;
  LOutcome: THelpChatActionOutcome;
  LResult: string;
  LRan: Boolean;
begin
  // The providers call Invoke in the middle of a reply and rely on what its
  // contract says: nothing is raised.
  LBroker := THelpChatActionBroker.Create;
  LInvoker := LBroker;
  LBroker.Add('ping', 'Answers pong.',
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      LRan := True;
      AResult := 'pong';
    end, False);
  LBroker.OnPending := RaisingPending;
  LOutcome := aoDone;
  Assert.WillNotRaise(
    procedure
    begin
      LOutcome := LInvoker.Invoke('ping', '{}', nil, LResult);
    end);
  Assert.AreEqual(Ord(aoFailed), Ord(LOutcome));
  Assert.Contains(LResult, 'could not be woken up');
  // And nothing of that call is left in the queue.
  LBroker.OnPending := nil;
  LRan := False;
  LBroker.ExecutePending;
  Assert.IsFalse(LRan, 'the call that failed is not run later');
end;

procedure TRegressionTests.FileInFolder_IsWhereTheApplicationWouldReadIt;
begin
  // The preview inside the IDE resolved "css\chat.css" next to bds.exe.
  Assert.AreEqual('C:\App\css\chat.css', HelpChatFileInFolder('css\chat.css', 'C:\App'));
  Assert.AreEqual('D:\Shared\chat.css', HelpChatFileInFolder('D:\Shared\chat.css', 'C:\App'));
  Assert.AreEqual('', HelpChatFileInFolder('', 'C:\App'), 'no file is no file');
  Assert.AreEqual('chat.css', HelpChatFileInFolder('chat.css', ''), 'no folder: as written');
end;

end.
