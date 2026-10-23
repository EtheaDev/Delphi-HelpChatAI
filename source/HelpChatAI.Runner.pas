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
///  Worker pool that produces assistant replies off the caller's thread. A
///  call to a remote model lasts seconds: it must never run on the UI thread
///  nor block whoever submitted it. <c>Submit</c> enqueues and returns at once;
///  the worker resolves the provider by name, feeds it the history and the
///  context, appends each streamed token to the store and finally completes
///  (or fails) the pending assistant message. The result is retrieved from the
///  store, never awaited: this is what makes streaming independent of the
///  transport.
///
///  Shutdown is the delicate part. Every request is cancellable (the provider
///  aborts its HTTP stream), <c>Shutdown</c> waits for the workers with a time
///  limit, and the workers only ever reach the store through a shared,
///  reference-counted state that is detached before the store is freed: a
///  worker still blocked in a network call when the application closes can
///  finish later without touching freed memory.
/// </summary>
unit HelpChatAI.Runner;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Actions,
  HelpChatAI.Store;

const
  HELPCHAT_DEF_SHUTDOWN_TIMEOUT_MS = 3000;
  HELPCHAT_QUEUE_DEPTH = 1000;

type
  /// <summary>One unit of work: which conversation, which pending message,
  /// which provider, with a private settings snapshot.</summary>
  THelpChatRequest = class
  public
    Key: string;
    AssistantId: string;
    ProviderName: string;
    Context: THelpChatContext;
    MaxHistory: Integer;
    /// <summary>Owned snapshot: the caller may change its settings freely while
    /// the request runs.</summary>
    Settings: THelpChatSettings;
    /// <summary>What the assistant may do in the application; nil = nothing.</summary>
    Actions: IHelpChatActionInvoker;
    Cancel: IHelpChatCancelToken;
    destructor Destroy; override;
  end;

  THelpChatRunner = class
  strict private
    FShared: IInterface;
    FWorkers: TList<TThread>;
    FPoolSize: Integer;
    FShutDown: Boolean;
  public
    /// <summary>The store is not owned and must outlive <c>Shutdown</c>; the
    /// retriever may be nil.</summary>
    constructor Create(const AStore: THelpChatStore; const ARetriever: IHelpChatRetriever;
      const APoolSize: Integer);
    /// <summary>Calls <c>Shutdown</c> with the default timeout.</summary>
    destructor Destroy; override;

    /// <summary>Enqueues a request and returns its cancellation token. Never
    /// blocks. <c>ASettings</c> is copied. Raises when shutting down.</summary>
    function Submit(const AKey, AAssistantId, AProviderName: string;
      const AContext: THelpChatContext; const AMaxHistory: Integer;
      const ASettings: THelpChatSettings;
      const AActions: IHelpChatActionInvoker = nil): IHelpChatCancelToken;
    /// <summary>Cancels the request producing <c>AAssistantId</c>; True if it was active.</summary>
    function Cancel(const AAssistantId: string): Boolean;
    /// <summary>Cancels every queued or running request.</summary>
    procedure CancelAll;
    /// <summary>Requests queued or running.</summary>
    function ActiveCount: Integer;
    /// <summary>Cancels everything, wakes the workers and waits up to
    /// <c>ATimeoutMs</c> for them to exit. Returns False if some worker was still
    /// busy (typically inside a network call): it is detached and will end on its
    /// own without touching the store. Idempotent.</summary>
    function Shutdown(const ATimeoutMs: Integer = HELPCHAT_DEF_SHUTDOWN_TIMEOUT_MS): Boolean;

    property PoolSize: Integer read FPoolSize;
    property IsShutDown: Boolean read FShutDown;
  end;

implementation

uses
  System.Diagnostics,
  HelpChatAI.Messages,
  HelpChatAI.Provider;

type
  /// <summary>State shared by the runner and its workers, reference-counted so
  /// a detached worker keeps it alive after the runner is gone. Once detached,
  /// every store access becomes a no-op.</summary>
  IHelpChatRunnerShared = interface
    ['{B4E2A9D1-3C7F-4E60-8A15-6D9F0C2B7E48}']
    function Queue: TThreadedQueue<THelpChatRequest>;
    function IsShuttingDown: Boolean;
    procedure Detach;
    function Retriever: IHelpChatRetriever;
    function GetHistory(const AKey: string; const AMax: Integer): TArray<THelpChatMessage>;
    function TryGetMessage(const AKey, AId: string; out AMessage: THelpChatMessage): Boolean;
    procedure AppendToken(const AKey, AId, AToken: string);
    procedure Complete(const AKey, AId, AContent: string);
    procedure Fail(const AKey, AId, AError: string);
    procedure RegisterActive(const AId: string; const AToken: IHelpChatCancelToken);
    procedure UnregisterActive(const AId: string);
    function CancelActive(const AId: string): Boolean;
    procedure CancelAllActive;
    function ActiveCount: Integer;
  end;

  THelpChatRunnerShared = class(TInterfacedObject, IHelpChatRunnerShared)
  strict private
    FLock: TCriticalSection;
    FStore: THelpChatStore;
    FRetriever: IHelpChatRetriever;
    FQueue: TThreadedQueue<THelpChatRequest>;
    FActive: TDictionary<string, IHelpChatCancelToken>;
    FShuttingDown: Boolean;
  public
    constructor Create(const AStore: THelpChatStore; const ARetriever: IHelpChatRetriever);
    destructor Destroy; override;
    function Queue: TThreadedQueue<THelpChatRequest>;
    function IsShuttingDown: Boolean;
    procedure Detach;
    function Retriever: IHelpChatRetriever;
    function GetHistory(const AKey: string; const AMax: Integer): TArray<THelpChatMessage>;
    function TryGetMessage(const AKey, AId: string; out AMessage: THelpChatMessage): Boolean;
    procedure AppendToken(const AKey, AId, AToken: string);
    procedure Complete(const AKey, AId, AContent: string);
    procedure Fail(const AKey, AId, AError: string);
    procedure RegisterActive(const AId: string; const AToken: IHelpChatCancelToken);
    procedure UnregisterActive(const AId: string);
    function CancelActive(const AId: string): Boolean;
    procedure CancelAllActive;
    function ActiveCount: Integer;
  end;

  THelpChatWorker = class(TThread)
  strict private
    FShared: IHelpChatRunnerShared;
    procedure RunRequest(const ARequest: THelpChatRequest);
  protected
    procedure Execute; override;
  public
    constructor Create(const AShared: IHelpChatRunnerShared);
  end;

{ THelpChatRequest }

destructor THelpChatRequest.Destroy;
begin
  Settings.Free;
  inherited;
end;

{ THelpChatRunnerShared }

constructor THelpChatRunnerShared.Create(const AStore: THelpChatStore;
  const ARetriever: IHelpChatRetriever);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FStore := AStore;
  FRetriever := ARetriever;
  FQueue := TThreadedQueue<THelpChatRequest>.Create(HELPCHAT_QUEUE_DEPTH, INFINITE, INFINITE);
  FActive := TDictionary<string, IHelpChatCancelToken>.Create;
end;

destructor THelpChatRunnerShared.Destroy;
var
  LRequest: THelpChatRequest;
begin
  // Drain whatever was never picked up.
  if Assigned(FQueue) then
  begin
    while FQueue.QueueSize > 0 do
      if FQueue.PopItem(LRequest) = wrSignaled then
        LRequest.Free
      else
        Break;
    FQueue.Free;
  end;
  FActive.Free;
  FLock.Free;
  inherited;
end;

function THelpChatRunnerShared.Queue: TThreadedQueue<THelpChatRequest>;
begin
  Result := FQueue;
end;

function THelpChatRunnerShared.IsShuttingDown: Boolean;
begin
  FLock.Enter;
  try
    Result := FShuttingDown;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRunnerShared.Detach;
begin
  FLock.Enter;
  try
    FShuttingDown := True;
    FStore := nil;
    FRetriever := nil;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRunnerShared.Retriever: IHelpChatRetriever;
begin
  FLock.Enter;
  try
    Result := FRetriever;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRunnerShared.GetHistory(const AKey: string; const AMax: Integer): TArray<THelpChatMessage>;
begin
  FLock.Enter;
  try
    if Assigned(FStore) then
      Result := FStore.GetHistory(AKey, AMax)
    else
      Result := nil;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRunnerShared.TryGetMessage(const AKey, AId: string; out AMessage: THelpChatMessage): Boolean;
begin
  FLock.Enter;
  try
    Result := Assigned(FStore) and FStore.TryGetMessage(AKey, AId, AMessage);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRunnerShared.AppendToken(const AKey, AId, AToken: string);
begin
  FLock.Enter;
  try
    if Assigned(FStore) and not FShuttingDown then
      FStore.AppendAssistantToken(AKey, AId, AToken);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRunnerShared.Complete(const AKey, AId, AContent: string);
begin
  FLock.Enter;
  try
    if Assigned(FStore) then
      FStore.CompleteAssistant(AKey, AId, AContent);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRunnerShared.Fail(const AKey, AId, AError: string);
begin
  FLock.Enter;
  try
    if Assigned(FStore) then
      FStore.FailAssistant(AKey, AId, AError);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRunnerShared.RegisterActive(const AId: string; const AToken: IHelpChatCancelToken);
begin
  FLock.Enter;
  try
    FActive.AddOrSetValue(AId, AToken);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRunnerShared.UnregisterActive(const AId: string);
begin
  FLock.Enter;
  try
    FActive.Remove(AId);
  finally
    FLock.Leave;
  end;
end;

function THelpChatRunnerShared.CancelActive(const AId: string): Boolean;
var
  LToken: IHelpChatCancelToken;
begin
  FLock.Enter;
  try
    Result := FActive.TryGetValue(AId, LToken);
  finally
    FLock.Leave;
  end;
  if Result then
    LToken.Cancel;
end;

procedure THelpChatRunnerShared.CancelAllActive;
var
  LTokens: TArray<IHelpChatCancelToken>;
  LToken: IHelpChatCancelToken;
begin
  FLock.Enter;
  try
    LTokens := FActive.Values.ToArray;
  finally
    FLock.Leave;
  end;
  for LToken in LTokens do
    LToken.Cancel;
end;

function THelpChatRunnerShared.ActiveCount: Integer;
begin
  FLock.Enter;
  try
    Result := FActive.Count;
  finally
    FLock.Leave;
  end;
end;

{ THelpChatWorker }

constructor THelpChatWorker.Create(const AShared: IHelpChatRunnerShared);
begin
  FShared := AShared;
  inherited Create(False);
end;

procedure THelpChatWorker.Execute;
var
  LRequest: THelpChatRequest;
begin
  NameThreadForDebugging('HelpChatWorker');
  while not Terminated do
  begin
    LRequest := nil;
    if FShared.Queue.PopItem(LRequest) <> wrSignaled then
      Break; // DoShutDown / abandoned
    // A nil item is the shutdown sentinel (some RTL versions unblock PopItem
    // with wrSignaled and a default item on DoShutDown).
    if LRequest = nil then
      Break;
    try
      if FShared.IsShuttingDown then
        FShared.Fail(LRequest.Key, LRequest.AssistantId,
          HelpChatMsg(hcmCancelled, LRequest.Settings.Language))
      else
        RunRequest(LRequest);
    finally
      FShared.UnregisterActive(LRequest.AssistantId);
      LRequest.Free;
    end;
  end;
end;

procedure THelpChatWorker.RunRequest(const ARequest: THelpChatRequest);
var
  LShared: IHelpChatRunnerShared;
  LProvider: IHelpChatProvider;
  LKey, LId, LReply: string;
  LCancel: IHelpChatCancelToken;
  LCancelled: Boolean;
  LPartial: THelpChatMessage;

  procedure FinishCancelled;
  begin
    // Keep whatever arrived before the cancellation; explain when nothing did.
    if LShared.TryGetMessage(LKey, LId, LPartial) and (Trim(LPartial.Content) <> '') then
      LShared.Complete(LKey, LId, LPartial.Content)
    else
      LShared.Fail(LKey, LId, HelpChatMsg(hcmCancelled, ARequest.Settings.Language));
  end;

begin
  // Locals: the token callback runs synchronously inside Generate and must not
  // depend on the const parameter or on Self surviving a detach.
  LShared := FShared;
  LKey := ARequest.Key;
  LId := ARequest.AssistantId;
  LCancel := ARequest.Cancel;
  LCancelled := False;
  try
    LProvider := THelpChatProviderRegistry.CreateProvider(ARequest.ProviderName,
      ARequest.Settings, LShared.Retriever, ARequest.Actions);
    LReply := LProvider.Generate(
      LShared.GetHistory(LKey, ARequest.MaxHistory),
      ARequest.Context,
      procedure(const AToken: string)
      begin
        if not LCancel.IsCancelled then
          LShared.AppendToken(LKey, LId, AToken);
      end,
      LCancel);
    if LCancel.IsCancelled then
      LCancelled := True
    else
      LShared.Complete(LKey, LId, LReply);
  except
    on E: EHelpChatCancelled do
      LCancelled := True;
    on E: Exception do
      // A worker never dies for a provider that raises.
      LShared.Fail(LKey, LId, E.Message);
  end;
  if LCancelled then
    FinishCancelled;
end;

{ THelpChatRunner }

constructor THelpChatRunner.Create(const AStore: THelpChatStore;
  const ARetriever: IHelpChatRetriever; const APoolSize: Integer);
var
  I: Integer;
  LShared: IHelpChatRunnerShared;
begin
  inherited Create;
  FPoolSize := APoolSize;
  if FPoolSize < 1 then
    FPoolSize := 1;
  LShared := THelpChatRunnerShared.Create(AStore, ARetriever);
  FShared := LShared;
  FWorkers := TList<TThread>.Create;
  for I := 1 to FPoolSize do
    FWorkers.Add(THelpChatWorker.Create(LShared));
end;

destructor THelpChatRunner.Destroy;
begin
  Shutdown(HELPCHAT_DEF_SHUTDOWN_TIMEOUT_MS);
  FWorkers.Free;
  FShared := nil;
  inherited;
end;

function THelpChatRunner.Submit(const AKey, AAssistantId, AProviderName: string;
  const AContext: THelpChatContext; const AMaxHistory: Integer;
  const ASettings: THelpChatSettings;
  const AActions: IHelpChatActionInvoker): IHelpChatCancelToken;
var
  LShared: IHelpChatRunnerShared;
  LRequest: THelpChatRequest;
begin
  LShared := FShared as IHelpChatRunnerShared;
  if FShutDown or LShared.IsShuttingDown then
    raise EHelpChatError.Create('HelpChat runner is shutting down');
  LRequest := THelpChatRequest.Create;
  try
    LRequest.Key := AKey;
    LRequest.AssistantId := AAssistantId;
    LRequest.ProviderName := AProviderName;
    LRequest.Context := AContext;
    LRequest.MaxHistory := AMaxHistory;
    LRequest.Settings := THelpChatSettings.Create;
    if Assigned(ASettings) then
      LRequest.Settings.Assign(ASettings);
    LRequest.Actions := AActions;
    LRequest.Cancel := THelpChatCancelToken.Create;
    Result := LRequest.Cancel;
    LShared.RegisterActive(AAssistantId, Result);
    if LShared.Queue.PushItem(LRequest) <> wrSignaled then
    begin
      LShared.UnregisterActive(AAssistantId);
      raise EHelpChatError.Create('HelpChat runner queue is full');
    end;
  except
    LRequest.Free;
    raise;
  end;
end;

function THelpChatRunner.Cancel(const AAssistantId: string): Boolean;
begin
  Result := (FShared as IHelpChatRunnerShared).CancelActive(AAssistantId);
end;

procedure THelpChatRunner.CancelAll;
begin
  (FShared as IHelpChatRunnerShared).CancelAllActive;
end;

function THelpChatRunner.ActiveCount: Integer;
begin
  Result := (FShared as IHelpChatRunnerShared).ActiveCount;
end;

function THelpChatRunner.Shutdown(const ATimeoutMs: Integer): Boolean;
var
  LShared: IHelpChatRunnerShared;
  LThread: TThread;
  LWatch: TStopwatch;
  LAllDone: Boolean;
  I: Integer;
begin
  if FShutDown then
    Exit(True);
  FShutDown := True;
  LShared := FShared as IHelpChatRunnerShared;

  // 1. Nobody must start new work; running providers see the flag.
  LShared.CancelAllActive;
  // 2. Wake the workers blocked in PopItem; each sees Terminated and exits.
  for LThread in FWorkers do
    LThread.Terminate;
  LShared.Queue.DoShutDown;

  // 3. Wait, but not forever: a provider stuck in a network call must not
  //    freeze the application on close.
  LWatch := TStopwatch.StartNew;
  repeat
    LAllDone := True;
    for LThread in FWorkers do
      if not LThread.Finished then
      begin
        LAllDone := False;
        Break;
      end;
    if not LAllDone then
      TThread.Sleep(10);
  until LAllDone or (LWatch.ElapsedMilliseconds >= ATimeoutMs);

  // 4. From now on the store is off-limits for whoever is still running.
  LShared.Detach;

  // 5. Join the finished workers; detach the others (they free themselves and
  //    keep the shared state alive through their own reference).
  for I := 0 to FWorkers.Count - 1 do
  begin
    LThread := FWorkers[I];
    if LThread.Finished then
      LThread.Free
    else
      LThread.FreeOnTerminate := True;
  end;
  FWorkers.Clear;
  Result := LAllDone;
end;

end.
