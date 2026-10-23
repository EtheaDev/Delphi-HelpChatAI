{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
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
{  See the License for the specific language governing permissions and        }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  Actions: what the assistant may <i>do</i> in the application, beyond
///  answering. The application registers them by name with a description and
///  their parameters; a provider that supports tools (today Claude) offers them
///  to the model, and when the model calls one this unit runs it and hands the
///  result back so the model can continue.
///
///  Three rules shape the design:
///
///  <list type="bullet">
///  <item>Only what is registered exists. There is no generic "run this" entry
///  point: the model can call the actions of that application and nothing
///  else, with the parameters they declare.</item>
///  <item>An action runs where the application lives, on its main thread — it
///  opens forms and fills fields — while the model call runs on a worker. So a
///  request is queued, the host is woken up, and the worker waits for the
///  answer with a timeout and with cancellation honoured
///  (<see cref="THelpChatActionBroker" />). The same queue is what will carry
///  actions to a client of a remote server, where the model is on one machine
///  and the window to fill on another.</item>
///  <item>Anything that changes data asks first: an action marked
///  <c>Confirm</c> is executed only after the host says yes.</item>
///  </list>
/// </summary>
unit HelpChatAI.Actions;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  HelpChatAI.Types;

const
  /// <summary>How long a model call waits for an action to run, confirmation
  /// included. Beyond it the model is told the action timed out.</summary>
  HELPCHAT_DEF_ACTION_TIMEOUT_MS = 60000;
  /// <summary>Characters of an action result handed back to the model.</summary>
  HELPCHAT_DEF_ACTION_RESULT_MAXCHARS = 2000;

type
  /// <summary>Type of a parameter, as declared to the model.</summary>
  THelpChatActionParamKind = (apkString, apkInteger, apkNumber, apkBoolean);

  THelpChatActionParam = record
    Name: string;
    Description: string;
    Kind: THelpChatActionParamKind;
    Required: Boolean;
    class function Create(const AName, ADescription: string;
      const AKind: THelpChatActionParamKind = apkString;
      const ARequired: Boolean = True): THelpChatActionParam; static;
  end;

  /// <summary>What the model passed, by parameter name. Reading a parameter
  /// that was not sent gives the default, never an exception: a model may omit
  /// an optional one, or get a name wrong.</summary>
  THelpChatActionArgs = class
  strict private
    FValues: TDictionary<string, string>;
    FRawJson: string;
  public
    constructor Create(const AJson: string);
    destructor Destroy; override;
    function Has(const AName: string): Boolean;
    function AsString(const AName: string; const ADefault: string = ''): string;
    function AsInteger(const AName: string; const ADefault: Integer = 0): Integer;
    function AsFloat(const AName: string; const ADefault: Double = 0): Double;
    function AsBoolean(const AName: string; const ADefault: Boolean = False): Boolean;
    /// <summary>Names actually received.</summary>
    function Names: TArray<string>;
    /// <summary>"name=value, name=value": what a confirmation dialog shows.</summary>
    function ToDisplayString: string;
    /// <summary>The JSON object as the model sent it.</summary>
    property RawJson: string read FRawJson;
  end;

  /// <summary>What an action does. Runs on the main thread of the application;
  /// <c>AResult</c> is what the model is told (empty means "done").</summary>
  THelpChatActionProc = reference to procedure(const AArgs: THelpChatActionArgs;
    var AResult: string);

  THelpChatAction = class
  strict private
    FName: string;
    FDescription: string;
    FParams: TArray<THelpChatActionParam>;
    FConfirm: Boolean;
    FHandler: THelpChatActionProc;
  public
    constructor Create(const AName, ADescription: string;
      const AParams: TArray<THelpChatActionParam>; const AHandler: THelpChatActionProc;
      const AConfirm: Boolean);
    /// <summary>The JSON schema of this action as an Anthropic tool.</summary>
    function ToToolJson: string;
    property Name: string read FName;
    property Description: string read FDescription;
    property Params: TArray<THelpChatActionParam> read FParams;
    /// <summary>The host asks the user before running it.</summary>
    property Confirm: Boolean read FConfirm;
    property Handler: THelpChatActionProc read FHandler;
  end;

  /// <summary>How an action call ended. Anything but <c>aoDone</c> is reported
  /// to the model as text, so that it can explain itself or try something
  /// else instead of pretending it worked.</summary>
  THelpChatActionOutcome = (
    aoDone,
    /// <summary>The user said no.</summary>
    aoDenied,
    /// <summary>No action with that name is registered.</summary>
    aoUnknown,
    /// <summary>The handler raised.</summary>
    aoFailed,
    /// <summary>Nobody executed it in time (no host listening, or a very slow one).</summary>
    aoTimeout,
    /// <summary>The reply was cancelled while the action was waiting.</summary>
    aoCancelled);

  /// <summary>What a provider needs: the tools to declare and a way to call
  /// one. Implemented by <see cref="THelpChatActionBroker" />; a provider never
  /// sees the registry or the threading behind it.</summary>
  IHelpChatActionInvoker = interface
    ['{2F7A9C41-8D63-4B05-9E12-3A6C8B4D7E90}']
    /// <summary>True when there is at least one action to offer.</summary>
    function HasActions: Boolean;
    /// <summary>The registered actions as an Anthropic <c>tools</c> array.</summary>
    function ToolsJson: string;
    /// <summary>Runs the action and waits for its result. Called on a worker
    /// thread; never raises.</summary>
    function Invoke(const AName, AArgsJson: string;
      const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;
  end;

  THelpChatActionBroker = class;

  /// <summary>One call in flight, from the queue to the answer.</summary>
  THelpChatActionRequest = class
  strict private
    FId: string;
    FName: string;
    FArgsJson: string;
    FDone: TEvent;
    FResult: string;
    FOutcome: THelpChatActionOutcome;
  public
    constructor Create(const AName, AArgsJson: string);
    destructor Destroy; override;
    procedure Complete(const AOutcome: THelpChatActionOutcome; const AResult: string);
    property Id: string read FId;
    property Name: string read FName;
    property ArgsJson: string read FArgsJson;
    property Done: TEvent read FDone;
    property Result: string read FResult;
    property Outcome: THelpChatActionOutcome read FOutcome;
  end;

  /// <summary>Asks the host whether an action may run (it is about to change
  /// something). Called on the thread that executes the action.</summary>
  THelpChatActionConfirmEvent = procedure(Sender: TObject; const AName: string;
    const AArgs: THelpChatActionArgs; var AAllow: Boolean) of object;
  /// <summary>Fired after an action ran, for a log or a status bar.</summary>
  THelpChatActionExecutedEvent = procedure(Sender: TObject; const AName: string;
    const AOutcome: THelpChatActionOutcome; const AResult: string) of object;

  /// <summary>
  ///  The registry and the queue in one object: the application registers its
  ///  actions here, a provider invokes them through
  ///  <see cref="IHelpChatActionInvoker" />, and the host (the VCL or FMX
  ///  component) executes what the queue hands it, on the main thread.
  /// </summary>
  THelpChatActionBroker = class(TInterfacedObject, IHelpChatActionInvoker)
  strict private
    FLock: TCriticalSection;
    FActions: TObjectDictionary<string, THelpChatAction>;
    FOrder: TList<string>;
    FPending: TObjectList<THelpChatActionRequest>;
    FEnabled: Boolean;
    FTimeoutMs: Integer;
    FResultMaxChars: Integer;
    FOnPending: TNotifyEvent;
    FOnConfirm: THelpChatActionConfirmEvent;
    FOnExecuted: THelpChatActionExecutedEvent;
    function TakePending: TArray<THelpChatActionRequest>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Declares an action the assistant may call.</summary>
    procedure Add(const AName, ADescription: string;
      const AParams: array of THelpChatActionParam;
      const AHandler: THelpChatActionProc; const AConfirm: Boolean = False); overload;
    /// <summary>An action without parameters.</summary>
    procedure Add(const AName, ADescription: string;
      const AHandler: THelpChatActionProc; const AConfirm: Boolean = False); overload;
    procedure Remove(const AName: string);
    procedure Clear;
    function Find(const AName: string): THelpChatAction;
    function Count: Integer;
    /// <summary>Registered names, in registration order.</summary>
    function Names: TArray<string>;

    // IHelpChatActionInvoker
    function HasActions: Boolean;
    function ToolsJson: string;
    function Invoke(const AName, AArgsJson: string;
      const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;

    /// <summary>Runs every queued call on the calling thread: the host calls
    /// this from its main thread when <see cref="OnPending" /> woke it up.</summary>
    procedure ExecutePending;
    /// <summary>Calls waiting to be executed.</summary>
    function PendingCount: Integer;

    /// <summary>False keeps the actions registered but hides them from the
    /// model: nothing is declared and nothing can be called.</summary>
    property Enabled: Boolean read FEnabled write FEnabled;
    /// <summary>How long <see cref="Invoke" /> waits for the host.</summary>
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs;
    /// <summary>Longer results are cut before reaching the model.</summary>
    property ResultMaxChars: Integer read FResultMaxChars write FResultMaxChars;
    /// <summary>"there is something to execute": fired on the worker thread,
    /// the host marshals to its own and calls <see cref="ExecutePending" />.</summary>
    property OnPending: TNotifyEvent read FOnPending write FOnPending;
    property OnConfirm: THelpChatActionConfirmEvent read FOnConfirm write FOnConfirm;
    property OnExecuted: THelpChatActionExecutedEvent read FOnExecuted write FOnExecuted;
  end;

/// <summary>The outcome as the sentence the model reads.</summary>
function HelpChatActionOutcomeText(const AOutcome: THelpChatActionOutcome;
  const AName, AResult: string): string;

implementation

uses
  System.JSON,
  System.DateUtils,
  HelpChatAI.Messages;

function HelpChatActionOutcomeText(const AOutcome: THelpChatActionOutcome;
  const AName, AResult: string): string;
begin
  case AOutcome of
    aoDone:
      if Trim(AResult) <> '' then
        Result := AResult
      else
        Result := Format('The action "%s" was executed.', [AName]);
    aoDenied:    Result := Format('The user did not allow the action "%s".', [AName]);
    aoUnknown:   Result := Format('There is no action named "%s" in this application.', [AName]);
    aoFailed:    Result := Format('The action "%s" failed: %s', [AName, AResult]);
    aoTimeout:   Result := Format('The action "%s" did not answer in time.', [AName]);
    aoCancelled: Result := Format('The action "%s" was cancelled.', [AName]);
  else
    Result := AResult;
  end;
end;

function ParamKindName(const AKind: THelpChatActionParamKind): string;
begin
  case AKind of
    apkInteger: Result := 'integer';
    apkNumber:  Result := 'number';
    apkBoolean: Result := 'boolean';
  else
    Result := 'string';
  end;
end;

{ THelpChatActionParam }

class function THelpChatActionParam.Create(const AName, ADescription: string;
  const AKind: THelpChatActionParamKind; const ARequired: Boolean): THelpChatActionParam;
begin
  Result.Name := AName;
  Result.Description := ADescription;
  Result.Kind := AKind;
  Result.Required := ARequired;
end;

{ THelpChatActionArgs }

constructor THelpChatActionArgs.Create(const AJson: string);
var
  LValue: TJSONValue;
  LPair: TJSONPair;
begin
  inherited Create;
  FValues := TDictionary<string, string>.Create;
  FRawJson := AJson;
  if Trim(AJson) = '' then
    Exit;
  try
    LValue := TJSONObject.ParseJSONValue(AJson);
  except
    LValue := nil; // a model can send nonsense: no arguments, not an exception
  end;
  if LValue = nil then
    Exit;
  try
    if LValue is TJSONObject then
      for LPair in TJSONObject(LValue) do
        // Everything is kept as text and converted on read: a model may send
        // 3, "3" or true for the same parameter.
        FValues.AddOrSetValue(LPair.JsonString.Value.ToLower, LPair.JsonValue.Value);
  finally
    LValue.Free;
  end;
end;

destructor THelpChatActionArgs.Destroy;
begin
  FValues.Free;
  inherited;
end;

function THelpChatActionArgs.Has(const AName: string): Boolean;
begin
  Result := FValues.ContainsKey(AName.ToLower);
end;

function THelpChatActionArgs.AsString(const AName, ADefault: string): string;
begin
  if not FValues.TryGetValue(AName.ToLower, Result) then
    Result := ADefault;
end;

function THelpChatActionArgs.AsInteger(const AName: string; const ADefault: Integer): Integer;
begin
  Result := StrToIntDef(Trim(AsString(AName)), ADefault);
end;

function THelpChatActionArgs.AsFloat(const AName: string; const ADefault: Double): Double;
var
  LText: string;
begin
  LText := Trim(AsString(AName)).Replace(',', '.');
  Result := StrToFloatDef(LText, ADefault, TFormatSettings.Invariant);
end;

function THelpChatActionArgs.AsBoolean(const AName: string; const ADefault: Boolean): Boolean;
var
  LText: string;
begin
  LText := Trim(AsString(AName)).ToLower;
  if (LText = 'true') or (LText = '1') or (LText = 'yes') then
    Result := True
  else if (LText = 'false') or (LText = '0') or (LText = 'no') then
    Result := False
  else
    Result := ADefault;
end;

function THelpChatActionArgs.Names: TArray<string>;
begin
  Result := FValues.Keys.ToArray;
end;

function THelpChatActionArgs.ToDisplayString: string;
var
  LPair: TPair<string, string>;
begin
  Result := '';
  for LPair in FValues do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + LPair.Key + '=' + LPair.Value;
  end;
end;

{ THelpChatAction }

constructor THelpChatAction.Create(const AName, ADescription: string;
  const AParams: TArray<THelpChatActionParam>; const AHandler: THelpChatActionProc;
  const AConfirm: Boolean);
begin
  inherited Create;
  FName := AName;
  FDescription := ADescription;
  FParams := AParams;
  FHandler := AHandler;
  FConfirm := AConfirm;
end;

function THelpChatAction.ToToolJson: string;
var
  LRoot, LSchema, LProperties, LParam: TJSONObject;
  LRequired: TJSONArray;
  I: Integer;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('name', FName);
    LRoot.AddPair('description', FDescription);
    LSchema := TJSONObject.Create;
    LRoot.AddPair('input_schema', LSchema);
    LSchema.AddPair('type', 'object');
    LProperties := TJSONObject.Create;
    LSchema.AddPair('properties', LProperties);
    LRequired := TJSONArray.Create;
    for I := Low(FParams) to High(FParams) do
    begin
      LParam := TJSONObject.Create;
      LParam.AddPair('type', ParamKindName(FParams[I].Kind));
      LParam.AddPair('description', FParams[I].Description);
      LProperties.AddPair(FParams[I].Name, LParam);
      if FParams[I].Required then
        LRequired.Add(FParams[I].Name);
    end;
    // An empty "required" is allowed but noise: only add it when it says something.
    if LRequired.Count > 0 then
      LSchema.AddPair('required', LRequired)
    else
      LRequired.Free;
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

{ THelpChatActionRequest }

constructor THelpChatActionRequest.Create(const AName, AArgsJson: string);
var
  LGuid: TGUID;
begin
  inherited Create;
  CreateGUID(LGuid);
  FId := GUIDToString(LGuid).Trim(['{', '}']);
  FName := AName;
  FArgsJson := AArgsJson;
  FDone := TEvent.Create(nil, True, False, '');
  FOutcome := aoTimeout; // until somebody says otherwise
end;

destructor THelpChatActionRequest.Destroy;
begin
  FDone.Free;
  inherited;
end;

procedure THelpChatActionRequest.Complete(const AOutcome: THelpChatActionOutcome;
  const AResult: string);
begin
  FOutcome := AOutcome;
  FResult := AResult;
  FDone.SetEvent;
end;

{ THelpChatActionBroker }

constructor THelpChatActionBroker.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FActions := TObjectDictionary<string, THelpChatAction>.Create([doOwnsValues]);
  FOrder := TList<string>.Create;
  // The requests are freed by whoever created them (Invoke), not by the list.
  FPending := TObjectList<THelpChatActionRequest>.Create(False);
  FEnabled := True;
  FTimeoutMs := HELPCHAT_DEF_ACTION_TIMEOUT_MS;
  FResultMaxChars := HELPCHAT_DEF_ACTION_RESULT_MAXCHARS;
end;

destructor THelpChatActionBroker.Destroy;
var
  LRequest: THelpChatActionRequest;
begin
  // Whoever is waiting must not wait for a broker that no longer exists.
  FLock.Enter;
  try
    for LRequest in FPending do
      LRequest.Complete(aoCancelled, '');
    FPending.Clear;
  finally
    FLock.Leave;
  end;
  FPending.Free;
  FOrder.Free;
  FActions.Free;
  FLock.Free;
  inherited;
end;

procedure THelpChatActionBroker.Add(const AName, ADescription: string;
  const AParams: array of THelpChatActionParam; const AHandler: THelpChatActionProc;
  const AConfirm: Boolean);
var
  LParams: TArray<THelpChatActionParam>;
  LKey: string;
  I: Integer;
begin
  if Trim(AName) = '' then
    raise EHelpChatError.Create('HelpChat action: the name is required');
  if not Assigned(AHandler) then
    raise EHelpChatError.CreateFmt('HelpChat action "%s": no handler', [AName]);
  SetLength(LParams, Length(AParams));
  for I := Low(AParams) to High(AParams) do
    LParams[I - Low(AParams)] := AParams[I];
  LKey := AName.Trim.ToLower;
  FLock.Enter;
  try
    if not FActions.ContainsKey(LKey) then
      FOrder.Add(LKey);
    FActions.AddOrSetValue(LKey, THelpChatAction.Create(AName.Trim, ADescription,
      LParams, AHandler, AConfirm));
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.Add(const AName, ADescription: string;
  const AHandler: THelpChatActionProc; const AConfirm: Boolean);
begin
  Add(AName, ADescription, [], AHandler, AConfirm);
end;

procedure THelpChatActionBroker.Remove(const AName: string);
var
  LKey: string;
begin
  LKey := AName.Trim.ToLower;
  FLock.Enter;
  try
    FActions.Remove(LKey);
    FOrder.Remove(LKey);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.Clear;
begin
  FLock.Enter;
  try
    FActions.Clear;
    FOrder.Clear;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.Find(const AName: string): THelpChatAction;
begin
  FLock.Enter;
  try
    if not FActions.TryGetValue(AName.Trim.ToLower, Result) then
      Result := nil;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.Count: Integer;
begin
  FLock.Enter;
  try
    Result := FActions.Count;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.Names: TArray<string>;
var
  I: Integer;
  LAction: THelpChatAction;
begin
  FLock.Enter;
  try
    SetLength(Result, FOrder.Count);
    for I := 0 to FOrder.Count - 1 do
      if FActions.TryGetValue(FOrder[I], LAction) then
        Result[I] := LAction.Name;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.HasActions: Boolean;
begin
  Result := FEnabled and (Count > 0);
end;

function THelpChatActionBroker.ToolsJson: string;
var
  LArray: TJSONArray;
  LValue: TJSONValue;
  LName: string;
  LAction: THelpChatAction;
begin
  LArray := TJSONArray.Create;
  try
    if FEnabled then
      for LName in Names do
      begin
        LAction := Find(LName);
        if LAction = nil then
          Continue;
        LValue := TJSONObject.ParseJSONValue(LAction.ToToolJson);
        if LValue <> nil then
          LArray.AddElement(LValue);
      end;
    Result := LArray.ToJSON;
  finally
    LArray.Free;
  end;
end;

function THelpChatActionBroker.PendingCount: Integer;
begin
  FLock.Enter;
  try
    Result := FPending.Count;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.TakePending: TArray<THelpChatActionRequest>;
begin
  FLock.Enter;
  try
    Result := FPending.ToArray;
    FPending.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.ExecutePending;
var
  LRequest: THelpChatActionRequest;
  LAction: THelpChatAction;
  LArgs: THelpChatActionArgs;
  LResult: string;
  LOutcome: THelpChatActionOutcome;
  LAllow: Boolean;
begin
  for LRequest in TakePending do
  begin
    LAction := Find(LRequest.Name);
    if (LAction = nil) or not FEnabled then
    begin
      LRequest.Complete(aoUnknown, '');
      Continue;
    end;
    LResult := '';
    LOutcome := aoDone;
    LArgs := THelpChatActionArgs.Create(LRequest.ArgsJson);
    try
      LAllow := True;
      // Anything that changes something asks first.
      if LAction.Confirm and Assigned(FOnConfirm) then
        FOnConfirm(Self, LAction.Name, LArgs, LAllow);
      if not LAllow then
        LOutcome := aoDenied
      else
        try
          LAction.Handler(LArgs, LResult);
          if (FResultMaxChars > 0) and (LResult.Length > FResultMaxChars) then
            LResult := LResult.Substring(0, FResultMaxChars);
        except
          on E: Exception do
          begin
            // The application's bug is the model's information, not a crash.
            LOutcome := aoFailed;
            LResult := E.Message;
          end;
        end;
      if Assigned(FOnExecuted) then
        FOnExecuted(Self, LAction.Name, LOutcome, LResult);
    finally
      LArgs.Free;
    end;
    LRequest.Complete(LOutcome, LResult);
  end;
end;

function THelpChatActionBroker.Invoke(const AName, AArgsJson: string;
  const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;
var
  LRequest: THelpChatActionRequest;
  LDeadline: TDateTime;
  LWait: TWaitResult;
begin
  AResult := '';
  if not FEnabled then
    Exit(aoUnknown);
  if Find(AName) = nil then
    Exit(aoUnknown);

  LRequest := THelpChatActionRequest.Create(AName, AArgsJson);
  try
    FLock.Enter;
    try
      FPending.Add(LRequest);
    finally
      FLock.Leave;
    end;
    // The host is somewhere else (the main thread of the application, or a
    // client of the server): wake it up and wait for its answer.
    if Assigned(FOnPending) then
      FOnPending(Self);

    LDeadline := IncMillisecond(Now, FTimeoutMs);
    repeat
      // Short waits so that a cancelled reply does not keep a worker parked.
      LWait := LRequest.Done.WaitFor(100);
      if LWait = wrSignaled then
        Break;
      if Assigned(ACancel) and ACancel.IsCancelled then
      begin
        FLock.Enter;
        try
          FPending.Remove(LRequest);
        finally
          FLock.Leave;
        end;
        Exit(aoCancelled);
      end;
    until Now > LDeadline;

    if LWait <> wrSignaled then
    begin
      FLock.Enter;
      try
        FPending.Remove(LRequest);
      finally
        FLock.Leave;
      end;
      Exit(aoTimeout);
    end;
    AResult := LRequest.Result;
    Result := LRequest.Outcome;
  finally
    LRequest.Free;
  end;
end;

end.
