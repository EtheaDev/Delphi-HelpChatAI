unit HelpChatAI.Tests.Runner;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Store,
  HelpChatAI.Runner;

type
  [TestFixture]
  TRunnerTests = class
  strict private
    FStore: THelpChatStore;
    FSettings: THelpChatSettings;
    FRunner: THelpChatRunner;
    function Submit(const AProvider, AText: string): string;
    function IsDone(const AId: string): Boolean;
    function Message(const AId: string): THelpChatMessage;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Completes_OffThread_WithHistoryWithoutPending;
    [Test] procedure Streams_Tokens_WhilePending;
    [Test] procedure ProviderException_FailsMessage_WorkerSurvives;
    [Test] procedure Cancel_KeepsPartial;
    [Test] procedure Cancel_BeforeAnyToken_ReportsCancelled;
    [Test] procedure Cancel_Unknown_ReturnsFalse;
    [Test] procedure SettingsSnapshot_IsolatesRequest;
    [Test] procedure Shutdown_WaitsForCooperativeProvider;
    [Test] procedure Shutdown_TimesOut_OnStubbornProvider_ThenNoCrash;
    [Test] procedure Submit_AfterShutdown_Raises;
    [Test] procedure ParallelRequests_UseThePool;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  HelpChatAI.Messages,
  HelpChatAI.Provider,
  HelpChatAI.Tests.Helpers;

const
  K = HELPCHAT_DEFAULT_CONVERSATION;

procedure TRunnerTests.Setup;
begin
  FStore := THelpChatStore.Create;
  FSettings := THelpChatSettings.Create;
  FSettings.Language := hclEnglish;
  FRunner := THelpChatRunner.Create(FStore, nil, 2);
end;

procedure TRunnerTests.TearDown;
begin
  FRunner.Free;   // shuts down and joins the workers
  FStore.Free;
  FSettings.Free;
end;

function TRunnerTests.Submit(const AProvider, AText: string): string;
begin
  FStore.AddUserMessage(K, AText);
  Result := FStore.AddPendingAssistant(K);
  FRunner.Submit(K, Result, AProvider, Default(THelpChatContext), 0, FSettings);
end;

function TRunnerTests.IsDone(const AId: string): Boolean;
var
  LMessage: THelpChatMessage;
begin
  Result := FStore.TryGetMessage(K, AId, LMessage) and not LMessage.Pending;
end;

function TRunnerTests.Message(const AId: string): THelpChatMessage;
begin
  if not FStore.TryGetMessage(K, AId, Result) then
    raise Exception.Create('message not found: ' + AId);
end;

procedure TRunnerTests.Completes_OffThread_WithHistoryWithoutPending;
var
  LId: string;
begin
  LId := Submit(TEST_PROVIDER_ECHO, 'hello');
  Assert.IsTrue(Message(LId).Pending, 'Submit returns before the reply');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LId) end));
  // n=1: the history the provider sees holds the user message only (the
  // pending assistant is excluded).
  Assert.AreEqual('echo:hello|n=1', Message(LId).Content);
  Assert.IsFalse(Message(LId).IsError);
  Assert.IsTrue(WaitFor(function: Boolean begin Result := FRunner.ActiveCount = 0 end));
end;

procedure TRunnerTests.Streams_Tokens_WhilePending;
var
  LId: string;
  LMid: THelpChatMessage;
begin
  LId := Submit(TEST_PROVIDER_SLOW, 'go');
  Assert.IsTrue(WaitFor(
    function: Boolean
    begin
      Result := FStore.TryGetMessage(K, LId, LMid) and (LMid.Content.Length >= 3);
    end), 'tokens must arrive while the reply is pending');
  Assert.IsTrue(LMid.Pending);
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LId) end));
  Assert.AreEqual(StringOfChar('x', TEST_SLOW_STEPS), Message(LId).Content);
end;

procedure TRunnerTests.ProviderException_FailsMessage_WorkerSurvives;
var
  LId, LId2: string;
begin
  LId := Submit(TEST_PROVIDER_FAIL, 'x');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LId) end));
  Assert.IsTrue(Message(LId).IsError);
  Assert.AreEqual('boom', Message(LId).Content);
  // The pool is still alive after the exception.
  LId2 := Submit(TEST_PROVIDER_ECHO, 'still alive');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LId2) end));
  Assert.StartsWith('echo:still alive', Message(LId2).Content);
end;

procedure TRunnerTests.Cancel_KeepsPartial;
var
  LId: string;
  LMid: THelpChatMessage;
begin
  LId := Submit(TEST_PROVIDER_SLOW, 'go');
  Assert.IsTrue(WaitFor(
    function: Boolean
    begin
      Result := FStore.TryGetMessage(K, LId, LMid) and (LMid.Content.Length >= 2);
    end));
  Assert.IsTrue(FRunner.Cancel(LId));
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LId) end, 2000),
    'a cooperative provider stops within a step');
  Assert.IsFalse(Message(LId).IsError, 'the partial reply is kept, not flagged as error');
  Assert.IsTrue(Message(LId).Content.Length < TEST_SLOW_STEPS, 'not all tokens were produced');
  Assert.IsTrue(Message(LId).Content.Length >= 2);
end;

procedure TRunnerTests.Cancel_BeforeAnyToken_ReportsCancelled;
var
  LId: string;
begin
  LId := Submit(TEST_PROVIDER_SLOW, 'go');
  Assert.IsTrue(FRunner.Cancel(LId), 'cancel while queued or before the first token');
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LId) end, 2000));
  if Message(LId).IsError then
    Assert.AreEqual(HelpChatMsg(hcmCancelled, hclEnglish), Message(LId).Content)
  else
    Assert.IsTrue(Message(LId).Content.Length >= 1, 'or a token slipped in before the flag was seen');
end;

procedure TRunnerTests.Cancel_Unknown_ReturnsFalse;
begin
  Assert.IsFalse(FRunner.Cancel('nope'));
end;

procedure TRunnerTests.SettingsSnapshot_IsolatesRequest;
var
  LId: string;
begin
  FSettings.Language := hclItalian;
  LId := Submit(HELPCHAT_PROVIDER_STUB, 'ciao');
  FSettings.Language := hclEnglish; // changed after Submit: must not affect the request
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LId) end));
  Assert.AreEqual(HelpChatMsg(hcmStubReply, hclItalian), Message(LId).Content);
end;

procedure TRunnerTests.Shutdown_WaitsForCooperativeProvider;
var
  LId: string;
  LWatch: TStopwatch;
begin
  LId := Submit(TEST_PROVIDER_SLOW, 'go');
  TThread.Sleep(60);
  LWatch := TStopwatch.StartNew;
  Assert.IsTrue(FRunner.Shutdown(2000), 'a cooperative provider lets the worker exit in time');
  Assert.IsTrue(LWatch.ElapsedMilliseconds < 1500, 'shutdown did not wait for the whole reply');
  Assert.IsTrue(IsDone(LId), 'the pending message was closed before the store goes away');
  Assert.IsTrue(FRunner.IsShutDown);
  Assert.IsTrue(FRunner.Shutdown(10), 'idempotent');
end;

procedure TRunnerTests.Shutdown_TimesOut_OnStubbornProvider_ThenNoCrash;
var
  LId: string;
  LWatch: TStopwatch;
begin
  LId := Submit(TEST_PROVIDER_STUBBORN, 'go');
  TThread.Sleep(50);
  LWatch := TStopwatch.StartNew;
  Assert.IsFalse(FRunner.Shutdown(200), 'the stubborn worker is still busy');
  Assert.IsTrue(LWatch.ElapsedMilliseconds < 1000, 'shutdown returned at the timeout, not at the end of the call');
  Assert.IsTrue(Message(LId).Pending, 'nobody closed it: the worker is detached');
  // Free the runner and the store right away, then outlive the detached worker:
  // its late Complete must be a no-op on the detached shared state.
  FreeAndNil(FRunner);
  FreeAndNil(FStore);
  TThread.Sleep(TEST_STUBBORN_MS + 300);
  Assert.Pass('no access violation after the detached worker finished');
end;

procedure TRunnerTests.Submit_AfterShutdown_Raises;
begin
  FRunner.Shutdown;
  Assert.WillRaise(
    procedure
    begin
      Submit(TEST_PROVIDER_ECHO, 'x');
    end, EHelpChatError);
end;

procedure TRunnerTests.ParallelRequests_UseThePool;
var
  LId1, LId2: string;
  LWatch: TStopwatch;
begin
  LWatch := TStopwatch.StartNew;
  LId1 := Submit(TEST_PROVIDER_SLOW, 'a');
  LId2 := Submit(TEST_PROVIDER_SLOW, 'b');
  Assert.AreEqual(2, FRunner.ActiveCount);
  Assert.IsTrue(WaitFor(function: Boolean begin Result := IsDone(LId1) and IsDone(LId2) end));
  // Two workers: both replies (~800 ms each) complete in well under twice the time.
  Assert.IsTrue(LWatch.ElapsedMilliseconds < 2 * TEST_SLOW_STEPS * TEST_SLOW_STEP_MS - 200,
    'the two requests ran in parallel');
end;

end.
