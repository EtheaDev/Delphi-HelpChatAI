unit HelpChatAI.Tests.Engine;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Engine;

type
  [TestFixture]
  TEngineTests = class
  strict private
    FSettings: THelpChatSettings;
    FEngine: THelpChatEngine;
    FChanged: TList<string>;
    FConversationFile: string;
    procedure OnMessageChanged(Sender: TObject; const AMessageId: string);
    function IsDone(const AId: string): Boolean;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Send_ReturnsBothBubbles_ThenCompletes;
    [Test] procedure Send_Empty_IsNotSent;
    [Test] procedure Send_TruncatesToMaxLength;
    [Test] procedure Send_UsesConfiguredProvider;
    [Test] procedure OnMessageChanged_Fires;
    [Test] procedure Clear_EmptiesAndRendersGreeting;
    [Test] procedure Render_Html;
    [Test] procedure Cancel_And_IsBusy;
    [Test] procedure Persistence_SurvivesRestart;
    [Test] procedure Persistence_Disabled_WritesNothing;
    [Test] procedure DocSearch_EndToEnd_WithIndexFile;
    [Test] procedure ContextQuestion_IsLocalized;
    [Test] procedure Stop_WithReplyInFlight_ReturnsQuickly;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Diagnostics,
  HelpChatAI.Messages,
  HelpChatAI.Html,
  HelpChatAI.Provider,
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Tests.Helpers;

procedure TEngineTests.Setup;
begin
  FConversationFile := TempFileName;
  FSettings := THelpChatSettings.Create;
  FSettings.Language := hclEnglish;
  FSettings.PersistConversation := False;
  FSettings.ConversationFile := FConversationFile;
  FSettings.DocIndexFile := 'Z:\no\index.json';
  FEngine := THelpChatEngine.Create(FSettings);
  FChanged := TList<string>.Create;
end;

procedure TEngineTests.TearDown;
begin
  FEngine.Free;
  FSettings.Free;
  FChanged.Free;
  if TFile.Exists(FConversationFile) then
    TFile.Delete(FConversationFile);
end;

procedure TEngineTests.OnMessageChanged(Sender: TObject; const AMessageId: string);
begin
  TMonitor.Enter(FChanged);
  try
    FChanged.Add(AMessageId);
  finally
    TMonitor.Exit(FChanged);
  end;
end;

function TEngineTests.IsDone(const AId: string): Boolean;
var
  LMessage: THelpChatMessage;
begin
  Result := FEngine.TryGetMessage(AId, LMessage) and not LMessage.Pending;
end;

procedure TEngineTests.Send_ReturnsBothBubbles_ThenCompletes;
var
  LResult: THelpChatSendResult;
  LMessage: THelpChatMessage;
begin
  Assert.IsFalse(FEngine.Active);
  LResult := FEngine.Send('  hello  ');
  Assert.IsTrue(FEngine.Active, 'first Send starts the engine');
  Assert.IsTrue(LResult.Sent);
  Assert.AreEqual('hello', LResult.UserMessage.Content, 'trimmed');
  Assert.AreEqual(hcrUser, LResult.UserMessage.Role);
  Assert.IsTrue(LResult.AssistantMessage.Pending);
  Assert.AreEqual(hcrAssistant, LResult.AssistantMessage.Role);
  Assert.AreEqual(2, Integer(Length(FEngine.Messages)));

  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end));
  FEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage);
  Assert.AreEqual(HelpChatMsg(hcmStubReply, hclEnglish), LMessage.Content);
  Assert.IsFalse(LMessage.IsError);
end;

procedure TEngineTests.Send_Empty_IsNotSent;
var
  LResult: THelpChatSendResult;
begin
  LResult := FEngine.Send('   ');
  Assert.IsFalse(LResult.Sent);
  Assert.AreEqual('', LResult.UserMessage.Id);
  Assert.AreEqual(0, Integer(Length(FEngine.Messages)));
end;

procedure TEngineTests.Send_TruncatesToMaxLength;
var
  LResult: THelpChatSendResult;
begin
  FSettings.MessageMaxLength := 5;
  LResult := FEngine.Send('1234567890');
  Assert.AreEqual('12345', LResult.UserMessage.Content);
end;

procedure TEngineTests.Send_UsesConfiguredProvider;
var
  LResult: THelpChatSendResult;
  LMessage: THelpChatMessage;
begin
  FSettings.Provider := TEST_PROVIDER_ECHO;
  LResult := FEngine.Send('ping');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end));
  FEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage);
  Assert.AreEqual('echo:ping|n=1', LMessage.Content);
end;

procedure TEngineTests.OnMessageChanged_Fires;
var
  LResult: THelpChatSendResult;
begin
  FEngine.OnMessageChanged := OnMessageChanged;
  LResult := FEngine.Send('x');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end));
  TMonitor.Enter(FChanged);
  try
    Assert.IsTrue(FChanged.Count >= 3, 'user added, pending added, completed');
    Assert.AreEqual(LResult.UserMessage.Id, FChanged[0]);
    Assert.AreEqual(LResult.AssistantMessage.Id, FChanged[1]);
    Assert.AreEqual(LResult.AssistantMessage.Id, FChanged[FChanged.Count - 1]);
  finally
    TMonitor.Exit(FChanged);
  end;
end;

procedure TEngineTests.Clear_EmptiesAndRendersGreeting;
var
  LResult: THelpChatSendResult;
begin
  LResult := FEngine.Send('x');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end));
  FEngine.Clear;
  Assert.AreEqual(0, Integer(Length(FEngine.Messages)));
  Assert.Contains(FEngine.RenderHistoryHtml, HELPCHAT_CSS_PREFIX + '-greeting');
  Assert.Contains(FEngine.RenderHistoryHtml, HelpChatTextToHtml(FEngine.Greeting));
end;

procedure TEngineTests.Render_Html;
var
  LResult: THelpChatSendResult;
  LHtml: string;
begin
  FSettings.Greeting := 'Custom greeting';
  Assert.AreEqual('Custom greeting', FEngine.Greeting);
  LResult := FEngine.Send('<b>q</b>');
  LHtml := FEngine.RenderMessageHtml(LResult.AssistantMessage.Id);
  Assert.Contains(LHtml, 'data-pending="1"');
  Assert.AreEqual('', FEngine.RenderMessageHtml('unknown'));
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end));
  LHtml := FEngine.RenderHistoryHtml;
  Assert.Contains(LHtml, '&lt;b&gt;q&lt;/b&gt;');
  Assert.Contains(LHtml, 'data-msgid="' + LResult.AssistantMessage.Id + '"');
  Assert.DoesNotContain(LHtml, 'data-pending');
end;

procedure TEngineTests.Cancel_And_IsBusy;
var
  LResult: THelpChatSendResult;
begin
  FSettings.Provider := TEST_PROVIDER_SLOW;
  Assert.IsFalse(FEngine.IsBusy);
  LResult := FEngine.Send('go');
  Assert.IsTrue(FEngine.IsBusy);
  Assert.IsTrue(FEngine.Cancel(LResult.AssistantMessage.Id));
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end, 2000));
  Assert.IsFalse(FEngine.IsBusy);
  Assert.IsFalse(FEngine.Cancel(LResult.AssistantMessage.Id), 'already finished');
end;

procedure TEngineTests.Persistence_SurvivesRestart;
var
  LResult: THelpChatSendResult;
  LEngine2: THelpChatEngine;
  LMessages: TArray<THelpChatMessage>;
begin
  FSettings.PersistConversation := True;
  LResult := FEngine.Send('remember me');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end));
  FEngine.Stop;
  Assert.IsTrue(TFile.Exists(FConversationFile), 'saved on stop');

  LEngine2 := THelpChatEngine.Create(FSettings);
  try
    LEngine2.Start;
    LMessages := LEngine2.Messages;
    Assert.AreEqual(2, Integer(Length(LMessages)));
    Assert.AreEqual('remember me', LMessages[0].Content);
    Assert.AreEqual(LResult.AssistantMessage.Id, LMessages[1].Id);
    Assert.IsFalse(LMessages[1].Pending);
  finally
    LEngine2.Free;
  end;
end;

procedure TEngineTests.Persistence_Disabled_WritesNothing;
var
  LResult: THelpChatSendResult;
begin
  LResult := FEngine.Send('volatile');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end));
  FEngine.Stop;
  Assert.IsFalse(TFile.Exists(FConversationFile));
end;

procedure TEngineTests.DocSearch_EndToEnd_WithIndexFile;
var
  LResult: THelpChatSendResult;
  LMessage: THelpChatMessage;
  LContext: THelpChatContext;
begin
  FSettings.Provider := HELPCHAT_PROVIDER_DOCSEARCH;
  FSettings.DocIndexFile := TestDataFile('help-index.json');
  FSettings.DocBaseUrl := 'https://docs.example.com/app';
  LContext := Default(THelpChatContext);
  LContext.ScreenLabel := 'Orders';
  LResult := FEngine.Send('how do I export this grid?', LContext);
  Assert.IsTrue(FEngine.DocIndex.IsAvailable, FEngine.DocIndex.LastError);
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LResult.AssistantMessage.Id) end));
  FEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage);
  Assert.IsFalse(LMessage.IsError, LMessage.Content);
  Assert.StartsWith('**Exporting the grid**', LMessage.Content);
  Assert.Contains(LMessage.Content, '[Read more](https://docs.example.com/app/grid/export.html)');
  Assert.Contains(FEngine.RenderMessageHtml(LMessage.Id), 'href="https://docs.example.com/app/grid/export.html"');
end;

procedure TEngineTests.ContextQuestion_IsLocalized;
var
  LContext: THelpChatContext;
begin
  LContext := Default(THelpChatContext);
  LContext.ScreenName := 'OrdersForm';
  LContext.ScreenLabel := 'Orders';
  Assert.AreEqual('How do I use the "Orders" screen?', FEngine.ContextQuestion(LContext));
  FSettings.Language := hclItalian;
  Assert.AreEqual('Come si usa la schermata "Orders"?', FEngine.ContextQuestion(LContext));
end;

procedure TEngineTests.Stop_WithReplyInFlight_ReturnsQuickly;
var
  LWatch: TStopwatch;
begin
  FSettings.Provider := TEST_PROVIDER_SLOW;
  FEngine.Send('go');
  TThread.Sleep(50);
  LWatch := TStopwatch.StartNew;
  FEngine.Stop(1000);
  Assert.IsTrue(LWatch.ElapsedMilliseconds < 800, 'stop must not wait for the whole reply');
  Assert.IsFalse(FEngine.Active);
  Assert.AreEqual(0, Integer(Length(FEngine.Messages)), 'no store after stop');
end;

end.
