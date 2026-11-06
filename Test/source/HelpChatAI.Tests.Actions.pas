{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Tests of the actions: the registry, the schema handed to the model,    }
{       and the round trip that takes a call from a worker thread to the       }
{       thread of the application and brings the answer back.                  }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
unit HelpChatAI.Tests.Actions;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider,
  HelpChatAI.Engine,
  HelpChatAI.Actions;

const
  /// <summary>A provider that does nothing but call the action named in the
  /// question ("do:name:{json}"): it stands for the model asking for a tool.</summary>
  TEST_PROVIDER_ACTOR = 'test-actor';

type
  /// <summary>Stands for the worker a provider runs on: calls the broker and
  /// keeps what came back. A plain thread, so the out parameter and the result
  /// are ordinary fields.</summary>
  TInvokeWorker = class(TThread)
  strict private
    FBroker: THelpChatActionBroker;
    FName: string;
    FArgsJson: string;
    FCancel: IHelpChatCancelToken;
    FOutcome: THelpChatActionOutcome;
    FResult: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const ABroker: THelpChatActionBroker; const AName, AArgsJson: string;
      const ACancel: IHelpChatCancelToken = nil);
    property Outcome: THelpChatActionOutcome read FOutcome;
    property Result: string read FResult;
  end;

  TActorProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function SupportsActions: Boolean; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  [TestFixture]
  TActionsTests = class
  strict private
    FBroker: THelpChatActionBroker;
    FBrokerRef: IHelpChatActionInvoker; // keeps the broker alive
    FRan: TStringList;
    /// <summary>Plays the part of the application: runs what the broker has
    /// queued, on this thread, until <c>ACondition</c> holds or time runs out.</summary>
    FConfirmAsked: string;
    FExecuted: string;
    function PumpUntil(const ACondition: TFunc<Boolean>;
      const ATimeoutMs: Integer = 5000): Boolean;
    procedure AddOpenScreen;
    /// <summary>The application refusing an action.</summary>
    procedure DenyConfirm(Sender: TObject; const AName: string;
      const AArgs: THelpChatActionArgs; var AAllow: Boolean);
    /// <summary>A user who reads the dialog for longer than the model call
    /// can wait, and then says yes.</summary>
    procedure SlowAllowConfirm(Sender: TObject; const AName: string;
      const AArgs: THelpChatActionArgs; var AAllow: Boolean);
    procedure RecordExecuted(Sender: TObject; const AName: string;
      const AOutcome: THelpChatActionOutcome; const AResult: string);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Registry_AddFindNamesRemove;
    [Test] procedure Registry_AsksByDefault;
    [Test] procedure Args_LabelledLines_FollowTheDeclaration;
    [Test] procedure Registry_RefusesNamelessOrHandlerless;
    [Test] procedure ToolsJson_IsTheAnthropicSchema;
    [Test] procedure ToolsJson_EmptyWhenDisabledOrEmpty;
    [Test] procedure Args_ReadsTypesAndMissingOnes;
    [Test] procedure Args_MalformedJsonIsNoArguments;
    [Test] procedure Invoke_RunsOnTheHostThread_AndReturnsTheResult;
    [Test] procedure Invoke_UnknownActionIsToldSo;
    [Test] procedure Invoke_TimesOutWhenNobodyExecutes;
    [Test] procedure Invoke_DeniedByTheUser;
    [Test] procedure Invoke_ConfirmedAfterTheTimeout_DoesNotRun;
    [Test] procedure Args_DisplayValues_AreOneLineAndShort;
    [Test] procedure ConfirmText_SaysWhoWroteWhat;
    [Test] procedure Invoke_HandlerThatRaisesIsReported;
    [Test] procedure Invoke_CancelledWhileWaiting;
    [Test] procedure OutcomeText_ExplainsWhatHappened;
    [Test] procedure Engine_ProviderCallsAnActionOfTheApplication;
    [Test] procedure Engine_ARefusalEndsTheChain;
  end;

implementation

uses
  System.JSON,
  System.DateUtils,
  System.SyncObjs,
  HelpChatAI.Messages,
  HelpChatAI.Tests.Helpers;

{ TInvokeWorker }

constructor TInvokeWorker.Create(const ABroker: THelpChatActionBroker;
  const AName, AArgsJson: string; const ACancel: IHelpChatCancelToken);
begin
  FBroker := ABroker;
  FName := AName;
  FArgsJson := AArgsJson;
  FCancel := ACancel;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TInvokeWorker.Execute;
begin
  FOutcome := FBroker.Invoke(FName, FArgsJson, FCancel, FResult);
end;

{ TActorProvider }

function TActorProvider.GetName: string;
begin
  Result := TEST_PROVIDER_ACTOR;
end;

function TActorProvider.SupportsActions: Boolean;
begin
  Result := True;
end;

function TActorProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
var
  LCommand, LName, LArgs, LResult: string;
  LOutcome: THelpChatActionOutcome;
  P: Integer;
begin
  Result := '';
  if not LastUserMessage(AHistory).StartsWith('do:') then
    Exit('no action');
  if not Assigned(Actions) then
    Exit('no actions available');
  // "do:<name>:<json>", several of them separated by "|", like a model
  // chaining actions - split by hand: Split with a count drops the tail
  // instead of keeping it, and the tail here is the JSON.
  for LCommand in LastUserMessage(AHistory).Split(['|']) do
  begin
    P := LCommand.Substring(3).IndexOf(':');
    if P >= 0 then
    begin
      LName := LCommand.Substring(3, P);
      LArgs := LCommand.Substring(3 + P + 1);
    end
    else
    begin
      LName := LCommand.Substring(3);
      LArgs := '';
    end;
    LOutcome := InvokeAction(LName, LArgs, ACancel, LResult);
    if Result <> '' then
      Result := Result + sLineBreak;
    Result := Result + HelpChatActionOutcomeText(LOutcome, LName, LResult);
  end;
end;

{ TActionsTests }

procedure TActionsTests.Setup;
begin
  FBroker := THelpChatActionBroker.Create;
  FBrokerRef := FBroker; // reference counted from here on
  FRan := TStringList.Create;
end;

procedure TActionsTests.TearDown;
begin
  FRan.Free;
  FBroker := nil;
  FBrokerRef := nil;
end;

procedure TActionsTests.DenyConfirm(Sender: TObject; const AName: string;
  const AArgs: THelpChatActionArgs; var AAllow: Boolean);
begin
  FConfirmAsked := AName;
  AAllow := False;
end;

procedure TActionsTests.SlowAllowConfirm(Sender: TObject; const AName: string;
  const AArgs: THelpChatActionArgs; var AAllow: Boolean);
begin
  FConfirmAsked := AName;
  Sleep(700); // the broker of this test waits 300 ms
  AAllow := True;
end;

procedure TActionsTests.RecordExecuted(Sender: TObject; const AName: string;
  const AOutcome: THelpChatActionOutcome; const AResult: string);
begin
  FExecuted := AName + '=' + IntToStr(Ord(AOutcome));
end;

procedure TActionsTests.AddOpenScreen;
begin
  FBroker.Add('apri_schermata', 'Opens a screen of the application',
    [THelpChatActionParam.Create('nome', 'Name of the screen')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      FRan.Add('apri_schermata(' + AArgs.AsString('nome') + ')');
      AResult := 'Opened ' + AArgs.AsString('nome');
    end, False);
end;

function TActionsTests.PumpUntil(const ACondition: TFunc<Boolean>;
  const ATimeoutMs: Integer): Boolean;
var
  LStart: TDateTime;
begin
  LStart := Now;
  repeat
    FBroker.ExecutePending;
    Result := ACondition();
    if Result then
      Exit;
    Sleep(10);
    CheckSynchronize(10);
  until MilliSecondsBetween(Now, LStart) > ATimeoutMs;
  Result := ACondition();
end;

procedure TActionsTests.Registry_AddFindNamesRemove;
begin
  Assert.AreEqual(0, FBroker.Count);
  Assert.IsFalse(FBroker.HasActions);
  AddOpenScreen;
  FBroker.Add('salva', 'Saves the document', [],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
    end, True);
  Assert.AreEqual(2, FBroker.Count);
  Assert.IsTrue(FBroker.HasActions);
  Assert.AreEqual('apri_schermata', FBroker.Names[0], 'registration order is kept');
  Assert.AreEqual('salva', FBroker.Names[1]);
  Assert.IsTrue(FBroker.Find('APRI_SCHERMATA') <> nil, 'the name is case-insensitive');
  Assert.IsTrue(FBroker.Find('salva').Confirm);
  Assert.IsFalse(FBroker.Find('apri_schermata').Confirm);
  FBroker.Remove('salva');
  Assert.AreEqual(1, FBroker.Count);
  Assert.IsTrue(FBroker.Find('salva') = nil);
  FBroker.Clear;
  Assert.AreEqual(0, FBroker.Count);
end;

procedure TActionsTests.Registry_AsksByDefault;
begin
  FBroker.Add('salva', 'Saves the document', [],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
    end);
  FBroker.Add('aggiorna', 'Reloads the grid',
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
    end);
  Assert.IsTrue(FBroker.Find('salva').Confirm, 'an action asks unless told otherwise');
  Assert.IsTrue(FBroker.Find('aggiorna').Confirm);
  AddOpenScreen;
  Assert.IsFalse(FBroker.Find('apri_schermata').Confirm, 'and this one was told');
end;

procedure TActionsTests.Args_LabelledLines_FollowTheDeclaration;
var
  LAction: THelpChatAction;
  LArgs: THelpChatActionArgs;
  LLines: TArray<string>;
begin
  FBroker.Add('create_lead', 'Creates a lead.',
    [THelpChatActionParam.Create('name', 'Name of the person'),
     THelpChatActionParam.Create('account', 'Company name, as in the Accounts list', apkString, False),
     THelpChatActionParam.Create('items', 'The line items, one per line, written as "title x quantity @ price"'),
     THelpChatActionParam.Create('phone', '', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
    end);
  LAction := FBroker.Find('create_lead');
  Assert.AreEqual('Name of the person', LAction.ParamLabel('name'));
  Assert.AreEqual('Company name', LAction.ParamLabel('ACCOUNT'), 'cut at the first punctuation');
  Assert.AreEqual('The line items', LAction.ParamLabel('items'));
  Assert.AreEqual('phone', LAction.ParamLabel('phone'), 'no description: the name');
  Assert.AreEqual('extra', LAction.ParamLabel('extra'), 'not declared: the name');
  Assert.AreEqual('A very long description that goes on...',
    HelpChatShortLabel('A very long description that goes on and on without punctuation'));

  // The model sent them in another order, one of them nobody declared, and
  // left the optional company out.
  LArgs := THelpChatActionArgs.Create(
    '{"phone":"555","extra":"x","name":"Mario","items":"A x 1 @ 2\nB x 2 @ 3"}');
  try
    LLines := LArgs.ToDisplayLines(LAction).Split([sLineBreak]);
    Assert.AreEqual(4, Integer(Length(LLines)));
    Assert.AreEqual('Name of the person: Mario', LLines[0]);
    Assert.AreEqual('The line items: A x 1 @ 2 B x 2 @ 3', LLines[1], 'declaration order, one line');
    Assert.AreEqual('phone: 555', LLines[2]);
    Assert.AreEqual('extra: x', LLines[3], 'the undeclared one comes last, under its name');
    Assert.Contains(HelpChatActionConfirmText(LAction, LArgs, hclEnglish),
      'Values written by the assistant:' + sLineBreak + 'Name of the person: Mario');
    Assert.AreEqual(LArgs.ToDisplayLines, LArgs.ToDisplayLines(nil), 'no action: the plain form');
  finally
    LArgs.Free;
  end;
end;

procedure TActionsTests.Registry_RefusesNamelessOrHandlerless;
begin
  Assert.WillRaise(
    procedure
    begin
      FBroker.Add('  ', 'no name', [],
        procedure(const AArgs: THelpChatActionArgs; var AResult: string)
        begin
        end);
    end, EHelpChatError);
  Assert.WillRaise(
    procedure
    begin
      FBroker.Add('orfana', 'no handler', [], THelpChatActionProc(nil));
    end, EHelpChatError);
end;

procedure TActionsTests.ToolsJson_IsTheAnthropicSchema;
var
  LValue: TJSONValue;
  LTool, LSchema, LProperties, LParam: TJSONObject;
  LRequired: TJSONArray;
begin
  FBroker.Add('crea_report', 'Creates a report',
    [THelpChatActionParam.Create('nome', 'Name of the report'),
     THelpChatActionParam.Create('copie', 'How many copies', apkInteger, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
    end);
  LValue := TJSONObject.ParseJSONValue(FBroker.ToolsJson);
  try
    Assert.IsTrue(LValue is TJSONArray);
    Assert.AreEqual(1, TJSONArray(LValue).Count);
    LTool := TJSONArray(LValue).Items[0] as TJSONObject;
    Assert.AreEqual('crea_report', LTool.GetValue<string>('name'));
    Assert.AreEqual('Creates a report', LTool.GetValue<string>('description'));
    LSchema := LTool.GetValue('input_schema') as TJSONObject;
    Assert.AreEqual('object', LSchema.GetValue<string>('type'));
    LProperties := LSchema.GetValue('properties') as TJSONObject;
    LParam := LProperties.GetValue('nome') as TJSONObject;
    Assert.AreEqual('string', LParam.GetValue<string>('type'));
    LParam := LProperties.GetValue('copie') as TJSONObject;
    Assert.AreEqual('integer', LParam.GetValue<string>('type'));
    LRequired := LSchema.GetValue('required') as TJSONArray;
    Assert.AreEqual(1, LRequired.Count, 'only the required one');
    Assert.AreEqual('nome', LRequired.Items[0].Value);
  finally
    LValue.Free;
  end;
end;

procedure TActionsTests.ToolsJson_EmptyWhenDisabledOrEmpty;
begin
  Assert.AreEqual('[]', FBroker.ToolsJson, 'nothing registered');
  AddOpenScreen;
  Assert.AreNotEqual('[]', FBroker.ToolsJson);
  // The master switch hides them without unregistering.
  FBroker.Enabled := False;
  Assert.AreEqual('[]', FBroker.ToolsJson);
  Assert.IsFalse(FBroker.HasActions);
  Assert.AreEqual(1, FBroker.Count, 'still registered');
end;

procedure TActionsTests.Args_ReadsTypesAndMissingOnes;
var
  LArgs: THelpChatActionArgs;
begin
  LArgs := THelpChatActionArgs.Create('{"nome":"Città","copie":3,"scala":1.5,"subito":true}');
  try
    Assert.AreEqual('Città', LArgs.AsString('nome'));
    Assert.AreEqual('Città', LArgs.AsString('NOME'), 'names are case-insensitive');
    Assert.AreEqual(3, LArgs.AsInteger('copie'));
    Assert.AreEqual(1.5, LArgs.AsFloat('scala'), 0.001);
    Assert.IsTrue(LArgs.AsBoolean('subito'));
    Assert.IsTrue(LArgs.Has('nome'));
    Assert.IsFalse(LArgs.Has('assente'));
    Assert.AreEqual('niente', LArgs.AsString('assente', 'niente'));
    Assert.AreEqual(7, LArgs.AsInteger('assente', 7));
    Assert.IsTrue(LArgs.AsBoolean('assente', True));
    Assert.AreEqual(4, Integer(Length(LArgs.Names)));
    Assert.Contains(LArgs.ToDisplayString, 'nome=Città');
  finally
    LArgs.Free;
  end;
end;

procedure TActionsTests.Args_MalformedJsonIsNoArguments;
var
  LArgs: THelpChatActionArgs;
begin
  // A model can send anything: the action gets no arguments, not an exception.
  LArgs := THelpChatActionArgs.Create('{"nome": ');
  try
    Assert.AreEqual(0, Integer(Length(LArgs.Names)));
    Assert.AreEqual('', LArgs.AsString('nome'));
  finally
    LArgs.Free;
  end;
  LArgs := THelpChatActionArgs.Create('');
  try
    Assert.AreEqual(0, Integer(Length(LArgs.Names)));
  finally
    LArgs.Free;
  end;
end;

procedure TActionsTests.Invoke_RunsOnTheHostThread_AndReturnsTheResult;
var
  LWorker: TInvokeWorker;
  LHostThreadId: TThreadID;
  LThisThread: TThreadID;
begin
  LThisThread := TThread.CurrentThread.ThreadID;
  LHostThreadId := 0;
  FBroker.Add('apri_schermata', 'Opens a screen',
    [THelpChatActionParam.Create('nome', 'Name')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      LHostThreadId := TThread.CurrentThread.ThreadID;
      AResult := 'Opened ' + AArgs.AsString('nome');
    end);

  // The provider runs on a worker and waits; the application executes.
  LWorker := TInvokeWorker.Create(FBroker, 'apri_schermata', '{"nome":"Scheduler"}');
  try
    Assert.IsTrue(PumpUntil(
      function: Boolean
      begin
        Result := LWorker.Finished;
      end), 'the call came back');
    Assert.AreEqual(Ord(aoDone), Ord(LWorker.Outcome));
    Assert.AreEqual('Opened Scheduler', LWorker.Result);
  finally
    LWorker.WaitFor;
    LWorker.Free;
  end;
  Assert.AreEqual(Int64(LThisThread), Int64(LHostThreadId),
    'the handler ran on the thread that called ExecutePending, not on the worker');
end;

procedure TActionsTests.Invoke_UnknownActionIsToldSo;
var
  LResult: string;
begin
  AddOpenScreen;
  // Answered on the spot: nothing is queued for a name nobody registered.
  Assert.AreEqual(Ord(aoUnknown), Ord(FBroker.Invoke('vola', '{}', nil, LResult)));
  Assert.AreEqual(0, FBroker.PendingCount);
end;

procedure TActionsTests.Invoke_TimesOutWhenNobodyExecutes;
var
  LWorker: TInvokeWorker;
begin
  AddOpenScreen;
  FBroker.TimeoutMs := 300; // nobody will call ExecutePending
  LWorker := TInvokeWorker.Create(FBroker, 'apri_schermata', '{}');
  try
    LWorker.WaitFor;
    Assert.AreEqual(Ord(aoTimeout), Ord(LWorker.Outcome));
    Assert.AreEqual(0, FBroker.PendingCount, 'the request is not left in the queue');
    Assert.AreEqual(0, FRan.Count);
  finally
    LWorker.Free;
  end;
end;

procedure TActionsTests.Invoke_DeniedByTheUser;
var
  LWorker: TInvokeWorker;
begin
  FBroker.Add('cancella_tutto', 'Deletes everything', [],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      FRan.Add('cancella_tutto');
    end, True); // needs confirmation
  FBroker.OnConfirm := DenyConfirm;
  LWorker := TInvokeWorker.Create(FBroker, 'cancella_tutto', '{}');
  try
    Assert.IsTrue(PumpUntil(
      function: Boolean
      begin
        Result := LWorker.Finished;
      end));
    Assert.AreEqual(Ord(aoDenied), Ord(LWorker.Outcome));
    Assert.AreEqual('cancella_tutto', FConfirmAsked, 'the user was asked');
    Assert.AreEqual(0, FRan.Count, 'and the handler never ran');
  finally
    LWorker.WaitFor;
    LWorker.Free;
  end;
end;

procedure TActionsTests.Invoke_ConfirmedAfterTheTimeout_DoesNotRun;
var
  LWorker: TInvokeWorker;
begin
  // The model was told the action timed out while the dialog was still up:
  // a yes that arrives afterwards must not run it (a retry would run it
  // twice), and the request the worker gave up on must be freed exactly
  // once - which the leak check of the suite verifies.
  FBroker.Add('cancella_tutto', 'Deletes everything', [],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      FRan.Add('cancella_tutto');
    end, True);
  FBroker.OnConfirm := SlowAllowConfirm;
  FBroker.OnExecuted := RecordExecuted;
  FBroker.TimeoutMs := 300;
  LWorker := TInvokeWorker.Create(FBroker, 'cancella_tutto', '{}');
  try
    Assert.IsTrue(PumpUntil(
      function: Boolean
      begin
        Result := LWorker.Finished;
      end));
    Assert.AreEqual(Ord(aoTimeout), Ord(LWorker.Outcome));
    Assert.AreEqual('cancella_tutto', FConfirmAsked, 'the user was asked');
    Assert.AreEqual(0, FRan.Count, 'and the late yes ran nothing');
    Assert.AreEqual('cancella_tutto=' + IntToStr(Ord(aoTimeout)), FExecuted,
      'the application is told what happened');
    Assert.AreEqual(0, FBroker.PendingCount);
  finally
    LWorker.WaitFor;
    LWorker.Free;
  end;
end;

procedure TActionsTests.Args_DisplayValues_AreOneLineAndShort;
var
  LArgs: THelpChatActionArgs;
  LLines: string;
begin
  LArgs := THelpChatActionArgs.Create(
    '{"name":"Mario","notes":"first line\n\nAPPROVED BY THE ADMINISTRATOR\tx' +
    StringOfChar('y', 200) + '"}');
  try
    LLines := LArgs.ToDisplayLines;
    Assert.Contains(LLines, '  name = Mario');
    Assert.Contains(LLines, '  notes = first line  APPROVED BY THE ADMINISTRATOR x');
    Assert.AreEqual(2, Integer(Length(LLines.Split([sLineBreak]))), 'one line per value, and nothing else');
    Assert.Contains(LLines, 'yyy...', 'the long value is cut');
    Assert.AreEqual(HELPCHAT_ACTION_DISPLAY_MAXCHARS,
      Length(THelpChatActionArgs.DisplayValue(StringOfChar('y', 200))));
    Assert.IsTrue(Length(LLines) < 2 * HELPCHAT_ACTION_DISPLAY_MAXCHARS, 'and the lines stay short');
    Assert.IsFalse(LArgs.ToDisplayString.Contains(#10), 'the one-line form is one line too');
    Assert.AreEqual('', THelpChatActionArgs.DisplayValue(#13#10#9'  '));
    Assert.AreEqual('a b', THelpChatActionArgs.DisplayValue(' a'#10'b '));
  finally
    LArgs.Free;
  end;
end;

procedure TActionsTests.ConfirmText_SaysWhoWroteWhat;
var
  LArgs: THelpChatActionArgs;
  LText: string;
begin
  LArgs := THelpChatActionArgs.Create('{"name":"Mario Rossi"}');
  try
    LText := HelpChatActionConfirmText('create_lead', 'Creates a new lead.', LArgs, hclEnglish);
    Assert.StartsWith('The assistant wants to run "create_lead": Creates a new lead.', LText);
    Assert.Contains(LText, 'Values written by the assistant:' + sLineBreak + '  name = Mario Rossi');
    Assert.IsTrue(LText.EndsWith('Do you allow it?'));
    LText := HelpChatActionConfirmText('create_lead', 'Crea un lead.', LArgs, hclItalian);
    Assert.Contains(LText, 'Valori scritti dall''assistente:');
    Assert.IsTrue(LText.EndsWith('Consenti?'));
  finally
    LArgs.Free;
  end;
  // No values: no label for them.
  LText := HelpChatActionConfirmText('refresh', 'Reloads the grid.', nil, hclEnglish);
  Assert.IsFalse(LText.Contains('Values written'));
  Assert.IsTrue(LText.EndsWith('Reloads the grid.' + sLineBreak + sLineBreak + 'Do you allow it?'));
end;

procedure TActionsTests.Invoke_HandlerThatRaisesIsReported;
var
  LWorker: TInvokeWorker;
begin
  FBroker.Add('rompi', 'Raises', [],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      raise EHelpChatError.Create('database offline');
    end);
  LWorker := TInvokeWorker.Create(FBroker, 'rompi', '{}');
  try
    Assert.IsTrue(PumpUntil(
      function: Boolean
      begin
        Result := LWorker.Finished;
      end));
    // The application's failure is information for the model, not a crash.
    Assert.AreEqual(Ord(aoFailed), Ord(LWorker.Outcome));
    Assert.AreEqual('database offline', LWorker.Result);
    Assert.Contains(HelpChatActionOutcomeText(LWorker.Outcome, 'rompi', LWorker.Result),
      'database offline');
  finally
    LWorker.WaitFor;
    LWorker.Free;
  end;
end;

procedure TActionsTests.Invoke_CancelledWhileWaiting;
var
  LWorker: TInvokeWorker;
  LCancel: IHelpChatCancelToken;
begin
  AddOpenScreen;
  FBroker.TimeoutMs := 10000;
  LCancel := THelpChatCancelToken.Create;
  LWorker := TInvokeWorker.Create(FBroker, 'apri_schermata', '{}', LCancel);
  try
    // The user stopped the reply while the action was still queued.
    Sleep(150);
    LCancel.Cancel;
    Assert.IsTrue(WaitFor(
      function: Boolean
      begin
        Result := LWorker.Finished;
      end, 3000), 'a cancelled reply does not keep the worker parked');
    Assert.AreEqual(Ord(aoCancelled), Ord(LWorker.Outcome));
    Assert.AreEqual(0, FBroker.PendingCount);
  finally
    LWorker.WaitFor;
    LWorker.Free;
  end;
end;

procedure TActionsTests.OutcomeText_ExplainsWhatHappened;
begin
  Assert.AreEqual('Fatto', HelpChatActionOutcomeText(aoDone, 'x', 'Fatto'), 'the result wins');
  Assert.Contains(HelpChatActionOutcomeText(aoDone, 'apri', ''), 'apri');
  Assert.Contains(HelpChatActionOutcomeText(aoDenied, 'apri', ''), 'did not allow');
  Assert.Contains(HelpChatActionOutcomeText(aoUnknown, 'vola', ''), 'no action named');
  Assert.Contains(HelpChatActionOutcomeText(aoTimeout, 'apri', ''), 'in time');
  Assert.Contains(HelpChatActionOutcomeText(aoCancelled, 'apri', ''), 'cancelled');
end;

procedure TActionsTests.Engine_ProviderCallsAnActionOfTheApplication;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LResult: THelpChatSendResult;
  LMessage: THelpChatMessage;
begin
  // The whole chain: engine -> runner -> provider -> broker -> application.
  LSettings := THelpChatSettings.Create;
  LEngine := THelpChatEngine.Create(LSettings, True);
  try
    LSettings.Provider := TEST_PROVIDER_ACTOR;
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    AddOpenScreen;
    LEngine.Actions := FBroker;
    LEngine.Start;

    LResult := LEngine.Send('do:apri_schermata:{"nome":"Scheduler"}');
    Assert.IsTrue(LResult.Sent);
    Assert.IsTrue(PumpUntil(
      function: Boolean
      begin
        Result := LEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage) and
          not LMessage.Pending;
      end), 'the reply completes');
    Assert.AreEqual('Opened Scheduler', LMessage.Content);
    Assert.AreEqual(1, FRan.Count);
    Assert.AreEqual('apri_schermata(Scheduler)', FRan[0]);
  finally
    LEngine.Free;
  end;
end;

procedure TActionsTests.Engine_ARefusalEndsTheChain;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LResult: THelpChatSendResult;
  LMessage: THelpChatMessage;
begin
  // The user says no to the first action: the second one of the same reply
  // is not run and nobody is asked about it - the provider answers for it.
  LSettings := THelpChatSettings.Create;
  LEngine := THelpChatEngine.Create(LSettings, True);
  try
    LSettings.Provider := TEST_PROVIDER_ACTOR;
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    FBroker.Add('crea_azienda', 'Creates a company', [],
      procedure(const AArgs: THelpChatActionArgs; var AResult: string)
      begin
        FRan.Add('crea_azienda');
      end);
    AddOpenScreen; // asks nothing, and still must not run after a refusal
    FBroker.OnConfirm := DenyConfirm;
    LEngine.Actions := FBroker;
    LEngine.Start;

    LResult := LEngine.Send('do:crea_azienda:{}|do:apri_schermata:{"nome":"Leads"}');
    Assert.IsTrue(LResult.Sent);
    Assert.IsTrue(PumpUntil(
      function: Boolean
      begin
        Result := LEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage) and
          not LMessage.Pending;
      end), 'the reply completes');
    Assert.AreEqual(0, FRan.Count, 'nothing ran');
    Assert.AreEqual('crea_azienda', FConfirmAsked, 'the user was asked once');
    Assert.Contains(LMessage.Content, 'did not allow the action "crea_azienda"');
    Assert.Contains(LMessage.Content, 'The action "apri_schermata" was not run');
  finally
    LEngine.Free;
  end;
end;

initialization
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_ACTOR, TActorProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_ACTOR);

end.
