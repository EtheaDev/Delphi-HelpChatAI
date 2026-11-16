unit HelpChatAI.Tests.Conversation;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  IdContext,
  IdCustomHTTPServer,
  IdHTTPServer,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Engine,
  HelpChatAI.Actions;

type
  /// <summary>
  ///  One whole conversation of the CRM demo, end to end and without network:
  ///  "create a lead for Laura Bennett of Brightwater Supplies", asked on the
  ///  Leads screen, where Brightwater Supplies is not in the Accounts list yet.
  ///  The model tries create_lead first, reads the error of the handler ("create
  ///  it with create_account"), then asks for create_account and create_lead
  ///  together: three confirmations, three rounds.
  ///  Everything is the real code - the engine, the worker, the documentation
  ///  index of the demo manual, the claude provider with its SSE parser and its
  ///  tool loop, the action broker with the four skills of the demo - except
  ///  the far end of the HTTP call: a loopback server stands for
  ///  api.anthropic.com and answers the three rounds with the streams the real
  ///  service sent for this very question to the running demo
  ///  (Test\data\conversation\create-lead-round*.sse, recorded 2026-11-16 with
  ///  claude-haiku-5-5). The page "In depth: anatomy of a conversation" of the
  ///  documentation walks through the same trace.
  /// </summary>
  [TestFixture]
  TConversationTests = class
  strict private
    FServer: TIdHTTPServer;
    FLock: TCriticalSection;
    FRequests: TList<string>;
    FRounds: TArray<TBytes>;
    FConfirmed: TStringList;
    procedure ServeRound(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure Confirm(Sender: TObject; const AName: string;
      const AArgs: THelpChatActionArgs; var AAllow: Boolean);
    function Request(const AIndex: Integer): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure CreateLead_ForANewCompany_TheErrorLeadsTheWay;
    [Test] procedure CreateLead_TheSearchBehindThePrompt;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.Diagnostics,
  IdGlobal,
  HelpChatAI.DocIndex,
  HelpChatAI.Skills,
  HelpChatAI.Provider.Claude,
  Vcl.HelpChatAI.Skills,
  HelpChatAI.Tests.Helpers;

const
  QUESTION = 'Create a lead for Laura Bennett of Brightwater Supplies, e-mail laura.bennett@brightwatersupplies.com';
  // The Expertise of the demo's form file.
  EXPERTISE = 'B2B sales and customer relationship management: leads and the sales ' +
    'pipeline, accounts, proposals and invoicing, follow-up';

function DemoIndexFile: string;
begin
  // The manual of the demo, next to Test: "CRM Demo\Help\help-index.json".
  Result := TPath.Combine(TPath.GetDirectoryName(TPath.GetDirectoryName(TPath.GetDirectoryName(
    TestDataFile('help-index.json')))), 'CRM Demo\Help\help-index.json');
end;

procedure TConversationTests.Setup;
var
  I: Integer;
begin
  FLock := TCriticalSection.Create;
  FRequests := TList<string>.Create;
  FConfirmed := TStringList.Create;
  SetLength(FRounds, 3);
  for I := 0 to High(FRounds) do
    FRounds[I] := TFile.ReadAllBytes(TestDataFile(
      Format('conversation\create-lead-round%d.sse', [I + 1])));
  FServer := TIdHTTPServer.Create(nil);
  FServer.Bindings.Add.SetBinding('127.0.0.1', 0); // any free port
  FServer.OnCommandGet := ServeRound;
  FServer.Active := True;
end;

procedure TConversationTests.TearDown;
begin
  FServer.Active := False;
  FServer.Free;
  FConfirmed.Free;
  FRequests.Free;
  FLock.Free;
end;

procedure TConversationTests.ServeRound(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LBody: TBytes;
  LRound: Integer;
begin
  LBody := nil;
  if Assigned(ARequestInfo.PostStream) then
  begin
    ARequestInfo.PostStream.Position := 0;
    SetLength(LBody, ARequestInfo.PostStream.Size);
    if Length(LBody) > 0 then
      ARequestInfo.PostStream.ReadBuffer(LBody[0], Length(LBody));
  end;
  FLock.Enter;
  try
    FRequests.Add(TEncoding.UTF8.GetString(LBody));
    LRound := FRequests.Count - 1;
  finally
    FLock.Leave;
  end;
  if (ARequestInfo.Document <> '/v1/messages') or (LRound > High(FRounds)) then
  begin
    AResponseInfo.ResponseNo := 400;
    AResponseInfo.ContentType := 'application/json';
    AResponseInfo.ContentText := '{"type":"error","error":{"message":"unexpected request"}}';
    Exit;
  end;
  AResponseInfo.ResponseNo := 200;
  AResponseInfo.ContentType := 'text/event-stream';
  AResponseInfo.ContentStream := TBytesStream.Create(FRounds[LRound]);
end;

procedure TConversationTests.Confirm(Sender: TObject; const AName: string;
  const AArgs: THelpChatActionArgs; var AAllow: Boolean);
begin
  // The user reads the dialog and presses Yes.
  FConfirmed.Add(AName + ' ' + AArgs.RawJson);
  AAllow := True;
end;

function TConversationTests.Request(const AIndex: Integer): string;
begin
  FLock.Enter;
  try
    Result := FRequests[AIndex];
  finally
    FLock.Leave;
  end;
end;

procedure TConversationTests.CreateLead_ForANewCompany_TheErrorLeadsTheWay;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LBroker: THelpChatActionBroker;
  LInvoker: IHelpChatActionInvoker;
  LAccounts, LRan: TStringList;
  LCtx: THelpChatContext;
  LSend: THelpChatSendResult;
  LMsg: THelpChatMessage;
  LWatch: TStopwatch;
  LDone: Boolean;
  LJson: TJSONObject;
  LMessages: TJSONArray;
  LSystem, LTools, LContext: string;
  LSkills: THelpChatSkillSet;
begin
  LAccounts := TStringList.Create;
  LRan := TStringList.Create;
  LSettings := THelpChatSettings.Create;
  LSkills := THelpChatSkillSet.Create;
  try
    LAccounts.CaseSensitive := False;
    LAccounts.AddStrings(['Zeus Red Inc.', 'Hera Blue Inc.', 'Apollo Orange, LLC.']);
    LSettings.Provider := 'claude';
    LSettings.Language := hclEnglish;
    LSettings.Expertise := EXPERTISE;
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := DemoIndexFile;
    LSettings.Claude.ApiKey := 'test-key';
    LSettings.Claude.BaseUrl := Format('http://127.0.0.1:%d', [FServer.Bindings[0].Port]);

    // The actions of the demo, with its descriptions: they are what the model reads.
    LBroker := THelpChatActionBroker.Create;
    LInvoker := LBroker;
    LBroker.OnConfirm := Confirm;
    LBroker.Add('open_screen',
      'Brings one of the application screens to the front. Only when the user asks to ' +
      'go to a screen: never to show where something is while answering a question.',
      [THelpChatActionParam.Create('name',
        'Screen name: Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users.')],
      procedure(const AArgs: THelpChatActionArgs; var AResult: string)
      begin
        LRan.Add('open_screen');
        AResult := 'Opened the ' + AArgs.AsString('name') + ' screen.';
      end, False);
    LBroker.Add('create_account',
      'Creates a company in the Accounts list. Use it before create_lead when the ' +
      'company of the lead is not there yet.',
      [THelpChatActionParam.Create('name', 'Company name')],
      procedure(const AArgs: THelpChatActionArgs; var AResult: string)
      begin
        LRan.Add('create_account');
        LAccounts.Add(AArgs.AsString('name'));
        AResult := Format('Account "%s" created.', [AArgs.AsString('name')]);
      end);
    LBroker.Add('create_lead',
      'Creates a new lead for the active user and opens its detail window so the ' +
      'user can check it. Does not send anything to anybody. The company must ' +
      'exist in the Accounts list: if it does not, create it with create_account first.',
      [THelpChatActionParam.Create('name', 'Name of the person'),
       THelpChatActionParam.Create('account',
         'Company name, as in the Accounts list (it must exist)', apkString, False),
       THelpChatActionParam.Create('phone', 'Office phone', apkString, False),
       THelpChatActionParam.Create('email', 'E-mail address', apkString, False),
       THelpChatActionParam.Create('notes', 'Anything worth remembering', apkString, False)],
      procedure(const AArgs: THelpChatActionArgs; var AResult: string)
      begin
        LRan.Add('create_lead');
        // The order matters: the company had to be created first.
        if LAccounts.IndexOf(AArgs.AsString('account')) < 0 then
          raise Exception.CreateFmt('There is no account called "%s". Create it with ' +
            'create_account, then call create_lead again.', [AArgs.AsString('account')]);
        AResult := Format('Lead "%s" created with status New (id %d).', [AArgs.AsString('name'), 18]);
      end);
    // The demo names the four skills (Settings.Skills): their actions come
    // after the application's, and the model is offered all of them.
    LSkills.Attach(nil, LBroker, ['forms', 'commands', 'records', 'pages']);

    // What the demo's OnGetContext sends from the Leads page.
    LCtx := Default(THelpChatContext);
    LCtx.ScreenName := 'LeadsTab';
    LCtx.ScreenLabel := 'Leads';
    LCtx.ScreenType := 'TMainForm';
    LCtx.HelpKeyword := 'Leads';

    LEngine := THelpChatEngine.Create(LSettings, False);
    try
      LEngine.Actions := LInvoker;
      LEngine.Start;
      LSend := LEngine.Send(QUESTION, LCtx);
      // The application: runs on this thread what the broker queued.
      LWatch := TStopwatch.StartNew;
      LDone := False;
      repeat
        LBroker.ExecutePending;
        CheckSynchronize(10);
        LDone := LEngine.TryGetMessage(LSend.AssistantMessage.Id, LMsg) and not LMsg.Pending;
        if not LDone then
          TThread.Sleep(10);
      until LDone or (LWatch.ElapsedMilliseconds > 15000);
      LEngine.Stop;
    finally
      LEngine.Free;
    end;

    Assert.IsTrue(LDone, 'the reply never completed');
    Assert.IsFalse(LMsg.IsError, LMsg.Content);

    // Three confirmations, in the order the model chose: create_lead (which
    // fails, the company is missing), then create_account and create_lead
    // asked together in the second round.
    Assert.AreEqual(3, FConfirmed.Count, FConfirmed.Text);
    Assert.StartsWith('create_lead ', FConfirmed[0]);
    Assert.AreEqual('create_account {"name": "Brightwater Supplies"}', FConfirmed[1]);
    Assert.StartsWith('create_lead ', FConfirmed[2]);
    Assert.Contains(FConfirmed[2], '"account": "Brightwater Supplies"');
    Assert.Contains(FConfirmed[2], '"email": "laura.bennett@brightwatersupplies.com"');
    Assert.AreEqual('create_lead,create_account,create_lead', LRan.CommaText);

    // Three rounds: the question, then the question with the results.
    Assert.AreEqual(3, FRequests.Count);

    LJson := TJSONObject.ParseJSONValue(Request(0)) as TJSONObject;
    try
      Assert.IsTrue(LJson.GetValue<Boolean>('stream'));
      // The system prompt: what stays the same for every question - who, the
      // field, the instruction and the rule of the expertise, the actions
      // rule - one text block, a breakpoint of the prompt cache.
      LSystem := (LJson.GetValue<TJSONArray>('system').Items[0] as TJSONObject).GetValue<string>('text');
      Assert.AreEqual('ephemeral', (LJson.GetValue<TJSONArray>('system').Items[0] as TJSONObject)
        .GetValue<string>('cache_control.type'));
      Assert.AreEqual('Your name is Assistant. ' + 'Your field of expertise is ' + EXPERTISE + '. ' +
        'You are the in-app help assistant', Copy(LSystem, 1, Length('Your name is Assistant. ' +
        'Your field of expertise is ' + EXPERTISE + '. ' + 'You are the in-app help assistant')));
      Assert.Contains(LSystem, 'Use your expertise to understand what the user means');
      Assert.Contains(LSystem, 'If the user does not allow a tool, the plan ends there');
      Assert.DoesNotContain(LSystem, 'Now it is', 'now changes every minute: it goes with the question');
      Assert.DoesNotContain(LSystem, 'Relevant documentation excerpts:');
      LTools := LJson.GetValue('tools').ToJSON;
      Assert.Contains(LTools, '"name":"create_account"');
      Assert.Contains(LTools, '"name":"create_lead"');
      Assert.Contains(LTools, '"required":["name"]');
      // The skills of the demo are declared after the actions of the application.
      Assert.Contains(LTools, '"name":"describe_form"');
      Assert.Contains(LTools, '"name":"press_command"');
      Assert.Contains(LTools, '"name":"find_record"');
      Assert.Contains(LTools, '"name":"show_page"');
      Assert.IsTrue(Pos('"name":"create_lead"', LTools) < Pos('"name":"describe_form"', LTools));
      // The prompt cache: the last tool and the whole request are breakpoints.
      Assert.EndsWith('"cache_control":{"type":"ephemeral"}}]', LTools, 'the last tool');
      Assert.AreEqual('ephemeral', LJson.GetValue<string>('cache_control.type'));
      // The question, a breakpoint too, then its context as a system message:
      // now, the screen, the excerpts.
      LMessages := LJson.GetValue<TJSONArray>('messages');
      Assert.AreEqual(2, LMessages.Count, 'round 1: the question and its context');
      Assert.AreEqual('ephemeral', ((LMessages.Items[0] as TJSONObject).GetValue<TJSONArray>('content')
        .Items[0] as TJSONObject).GetValue<string>('cache_control.type'));
      Assert.AreEqual('system', (LMessages.Items[1] as TJSONObject).GetValue<string>('role'));
      LContext := (LMessages.Items[1] as TJSONObject).GetValue<string>('content');
      Assert.StartsWith('Now it is ', LContext);
      Assert.Contains(LContext, 'The user is currently on the "Leads" screen (type: TMainForm).');
      Assert.Contains(LContext, 'Relevant documentation excerpts:');
      Assert.IsTrue(Pos('Source: [Leads](Leads.md)', LContext) <
        Pos('Source: [Asking the assistant](Assistant.md)', LContext), 'the best page comes first');
      Assert.Contains(LContext, 'Source: [Data model](Data-Model.md)');
    finally
      LJson.Free;
    end;

    // Round 2 sends back the call of round 1 and its failure, under the same id.
    LJson := TJSONObject.ParseJSONValue(Request(1)) as TJSONObject;
    try
      LMessages := LJson.GetValue<TJSONArray>('messages');
      Assert.AreEqual(4, LMessages.Count);
      Assert.AreEqual(LContext, (LMessages.Items[1] as TJSONObject).GetValue<string>('content'),
        'the context stays where it was in every round');
      // The model thought before calling (claude-haiku-5-5 does by default):
      // the signed thinking block goes back first, before the call.
      Assert.StartsWith('{"role":"assistant","content":[{"type":"thinking","thinking":"","signature":"CAQS',
        LMessages.Items[2].ToJSON);
      Assert.Contains(LMessages.Items[2].ToJSON, '"type":"tool_use","id":"toolu_01MtH56odxtZTsa9WDC8JVz4","name":"create_lead"');
      Assert.Contains(LMessages.Items[3].ToJSON, '"tool_use_id":"toolu_01MtH56odxtZTsa9WDC8JVz4"');
      Assert.Contains(LMessages.Items[3].ToJSON, 'There is no account called \"Brightwater Supplies\". Create it with create_account');
      Assert.Contains(LMessages.Items[3].ToJSON, '"is_error":true');
      Assert.AreEqual(LSystem, (LJson.GetValue<TJSONArray>('system').Items[0] as TJSONObject)
        .GetValue<string>('text'), 'the prompt is the same in every round');
    finally
      LJson.Free;
    end;

    // Round 3: the two calls of round 2 in one assistant turn, their two
    // results in one user turn.
    LJson := TJSONObject.ParseJSONValue(Request(2)) as TJSONObject;
    try
      LMessages := LJson.GetValue<TJSONArray>('messages');
      Assert.AreEqual(6, LMessages.Count);
      Assert.Contains(LMessages.Items[4].ToJSON, '"id":"toolu_0172MU8WxeRYAx5pMG7HfUFo","name":"create_account"');
      Assert.Contains(LMessages.Items[4].ToJSON, '"id":"toolu_01H6xCDoeUfYq8QSH9rhzxLB","name":"create_lead"');
      Assert.Contains(LMessages.Items[5].ToJSON, 'Account \"Brightwater Supplies\" created.');
      Assert.Contains(LMessages.Items[5].ToJSON, 'Lead \"Laura Bennett\" created with status New (id 18).');
    finally
      LJson.Free;
    end;

    // The reply: only the last round wrote text (the first two were calls and
    // nothing else), and no Source line - a reply that ran an action gets none.
    Assert.AreEqual('I created the lead for Laura Bennett (id 18) with status New, and her ' +
      'e-mail is set to laura.bennett@brightwatersupplies.com. Brightwater Supplies was not ' +
      'in the Accounts list, so I added it first. The lead''s detail window is open so you ' +
      'can check it.',
      LMsg.Content);
    Assert.DoesNotContain(LMsg.Content, 'Source:');
  finally
    LSkills.Free;
    LSettings.Free;
    LRan.Free;
    LAccounts.Free;
    LInvoker := nil;
  end;
end;

procedure TConversationTests.CreateLead_TheSearchBehindThePrompt;
var
  LIndex: THelpChatDocIndex;
  LRetriever: IHelpChatRetriever;
  LPages: TArray<THelpChatDocPage>;
begin
  // The words the search works with: "e" of e-mail is too short, the
  // address is split on its punctuation, long words are cut to a stem.
  Assert.AreEqual('creat lead laura benne bright suppli mail laura benne bright com',
    string.Join(' ', THelpChatDocIndex.TokenizeStems(QUESTION)));

  LIndex := THelpChatDocIndex.Create;
  LRetriever := LIndex;
  Assert.IsTrue(LIndex.LoadFromFile(DemoIndexFile), LIndex.LastError);
  LPages := LIndex.Search(QUESTION, 'Leads', 3);
  // The names are in no page and weigh nothing: Leads wins on its title and
  // on the screen hint, the others on "create", "lead" and "mail".
  Assert.AreEqual(3, Length(LPages));
  Assert.AreEqual('Leads', LPages[0].Title);
  Assert.AreEqual('Asking the assistant', LPages[1].Title);
  Assert.AreEqual('Data model', LPages[2].Title);
end;

initialization
  TDUnitX.RegisterTestFixture(TConversationTests);

end.
