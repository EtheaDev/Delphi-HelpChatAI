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
///  In-memory conversation store. Keyed by conversation (a user name, or the
///  single <see cref="HELPCHAT_DEFAULT_CONVERSATION" /> of a desktop app),
///  thread-safe: the UI/transport thread appends messages and reads them, the
///  runner threads complete the pending assistant messages. The pending
///  message is the pivot of the asynchronous model: created empty with
///  <c>Pending = True</c>, its id is returned at once and later filled token by
///  token, then completed or failed. Unlike its KittoX ancestor it prunes old
///  messages and serializes to/from JSON for on-disk persistence.
///
///  An engine owns one store, and since there is one engine per profile two
///  windows of the same assistant read and write the same conversation here:
///  both poll the same key, and a message is identified by its id, never by
///  its position, so neither can mistake the other's question for its own.
///  Which file a conversation is saved to is the engine's business
///  (<c>Settings.ResolveConversationFile</c>, one per profile); the store
///  only reads and writes the file it is given.
/// </summary>
unit HelpChatAI.Store;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  HelpChatAI.Types;

const
  /// <summary>Conversation key of a single-user desktop application.</summary>
  HELPCHAT_DEFAULT_CONVERSATION = 'default';
  /// <summary>Format version written in the persisted JSON.</summary>
  HELPCHAT_STORE_JSON_VERSION = 1;

type
  /// <summary>Raised after every mutation, outside the lock, on the thread that
  /// performed it (a runner worker for assistant updates). <c>AMessageId</c> is
  /// empty for a clear/load.</summary>
  THelpChatStoreChangeEvent = procedure(const AKey, AMessageId: string) of object;

  /// <summary>
  ///  Every conversation of one engine, each a list of message records
  ///  under a key. Keys are compared exactly, case included. Every method
  ///  is safe from any thread and returns copies: a message handed out
  ///  never changes afterwards, the next read does. Nothing here raises for
  ///  a key or an id that does not exist - a reply that completes after its
  ///  conversation was cleared is simply dropped.
  /// </summary>
  THelpChatStore = class
  strict private
    FLock: TCriticalSection;
    FConversations: TObjectDictionary<string, TList<THelpChatMessage>>;
    FMaxMessages: Integer;
    FOnChange: THelpChatStoreChangeEvent;
    /// <summary>The list of AKey, created when missing. Under the lock.</summary>
    function EnsureList(const AKey: string): TList<THelpChatMessage>;
    /// <summary>Position of the message AId, -1 when it is not there.
    /// Searched from the end: the message being filled is the last or
    /// close to it. Under the lock.</summary>
    function IndexOfId(const AList: TList<THelpChatMessage>; const AId: string): Integer;
    /// <summary>Drops the oldest messages past <c>MaxMessages</c>, pending
    /// ones excepted. Under the lock.</summary>
    procedure PruneList(const AList: TList<THelpChatMessage>);
    /// <summary>The one writer of an existing message: replaces or appends
    /// to its content and sets its two flags. False, and nothing done, when
    /// the conversation or the message is gone. Takes the lock itself and
    /// fires nothing: the caller raises the change.</summary>
    function UpdateMessage(const AKey, AId: string; const AContent: string;
      const APending, AIsError, AAppend: Boolean): Boolean;
    /// <summary>Raises <c>OnChange</c>. Always called after the lock is
    /// released, so a handler may read the store.</summary>
    procedure DoChange(const AKey, AMessageId: string);
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Appends a user message and returns it.</summary>
    function AddUserMessage(const AKey, AContent: string): THelpChatMessage;
    /// <summary>Appends a system message (shown, never sent to the provider) and returns it.</summary>
    function AddSystemMessage(const AKey, AContent: string): THelpChatMessage;
    /// <summary>Appends an empty pending assistant message and returns its
    /// id: the handle the runner fills the reply through and the page polls
    /// with. Nothing is pruned here: the next user or system message
    /// does it.</summary>
    function AddPendingAssistant(const AKey: string): string;
    /// <summary>Appends a token to the pending assistant message, leaving it
    /// pending. Called by a runner worker for every piece of the stream; an
    /// empty token, or a message that is no longer there, changes nothing
    /// and raises no event.</summary>
    procedure AppendAssistantToken(const AKey, AId, AToken: string);
    /// <summary>Completes the pending assistant message with its final
    /// content, which replaces whatever the tokens had built: the provider
    /// returns the whole reply, and that is the one kept.</summary>
    procedure CompleteAssistant(const AKey, AId, AContent: string);
    /// <summary>Completes the pending assistant message as failed; AError becomes its content.</summary>
    procedure FailAssistant(const AKey, AId, AError: string);
    /// <summary>Returns a copy of the message AId, if present. This is what
    /// a panel polls while a reply is pending: two panels on the same
    /// conversation read the same growing content.</summary>
    function TryGetMessage(const AKey, AId: string; out AMessage: THelpChatMessage): Boolean;
    /// <summary>The whole conversation, in order: a copy, pending and failed
    /// messages included. Empty for a key that has none.</summary>
    function GetMessages(const AKey: string): TArray<THelpChatMessage>;
    /// <summary>Completed user/assistant messages to feed the provider, most recent
    /// AMaxMessages kept (0 = all). System, pending and failed messages are excluded.</summary>
    function GetHistory(const AKey: string; const AMaxMessages: Integer): TArray<THelpChatMessage>;
    /// <summary>Number of messages in the conversation.</summary>
    function Count(const AKey: string): Integer;
    /// <summary>Ids of the assistant messages still pending: more than one
    /// when a second question was sent, from this window or from another on
    /// the same conversation, before the first was answered.</summary>
    function PendingIds(const AKey: string): TArray<string>;
    /// <summary>Removes the conversation, pending messages included: the
    /// worker still filling one finds nothing to write to and its reply is
    /// lost, so the caller cancels the pending requests first. The change
    /// is raised even when there was nothing to remove.</summary>
    procedure Clear(const AKey: string);
    /// <summary>Removes every conversation, raising one change per key.</summary>
    procedure ClearAll;

    /// <summary>Serializes the conversation (pending messages excluded):
    /// version, key, the time it was saved and the messages with their ids,
    /// so that a reload keeps the links between a page and its
    /// messages.</summary>
    function ToJSON(const AKey: string): string;
    /// <summary>Replaces the conversation with the messages of AJson. Returns
    /// False (and leaves the store untouched) when the JSON is invalid or the
    /// snapshot is older than AMaxAgeDays (0 = no expiry; a snapshot that
    /// does not say when it was saved never expires). The key written in
    /// the JSON is not checked: the messages go under <c>AKey</c>. Messages
    /// of an unknown role are skipped, and the result is pruned to
    /// <c>MaxMessages</c>.</summary>
    function FromJSON(const AKey, AJson: string; const AMaxAgeDays: Integer = 0): Boolean;
    /// <summary>Writes ToJSON to AFileName (UTF-8), creating its folder.
    /// Failures are swallowed: a read-only folder must not break the chat.
    /// Two saves at the same instant - a worker completing a reply while an
    /// HTTP thread adds a question - may collide on the file, and the loser
    /// is silently skipped until the next change saves again.</summary>
    procedure SaveToFile(const AKey, AFileName: string);
    /// <summary>Loads AFileName if it exists. Returns True when a
    /// conversation was restored; False, never an exception, for a file
    /// that is missing, unreadable, malformed or too old.</summary>
    function LoadFromFile(const AKey, AFileName: string; const AMaxAgeDays: Integer = 0): Boolean;

    /// <summary>Messages kept per conversation; the oldest completed ones are
    /// dropped when exceeded (0 = unlimited). Pending messages are never
    /// pruned. To be set before the store is shared: it is read without the
    /// lock.</summary>
    property MaxMessages: Integer read FMaxMessages write FMaxMessages;
    /// <summary>The one listener of the store (the engine). Called outside
    /// the lock, on whichever thread made the change - a runner worker for
    /// every token - so the handler must be thread-safe and quick, and a UI
    /// layer behind it marshals. Assign it before the workers start and
    /// clear it after they stopped: the field itself is not protected.</summary>
    property OnChange: THelpChatStoreChangeEvent read FOnChange write FOnChange;
  end;

implementation

uses
  System.JSON,
  System.DateUtils,
  System.IOUtils;

const
  ROLE_NAMES: array[THelpChatRole] of string = ('user', 'assistant', 'system');

function RoleFromName(const AName: string; out ARole: THelpChatRole): Boolean;
var
  R: THelpChatRole;
begin
  for R := Low(THelpChatRole) to High(THelpChatRole) do
    if SameText(ROLE_NAMES[R], AName) then
    begin
      ARole := R;
      Exit(True);
    end;
  Result := False;
end;

{ THelpChatStore }

constructor THelpChatStore.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FConversations := TObjectDictionary<string, TList<THelpChatMessage>>.Create([doOwnsValues]);
end;

destructor THelpChatStore.Destroy;
begin
  FConversations.Free;
  FLock.Free;
  inherited;
end;

procedure THelpChatStore.DoChange(const AKey, AMessageId: string);
begin
  if Assigned(FOnChange) then
    FOnChange(AKey, AMessageId);
end;

function THelpChatStore.EnsureList(const AKey: string): TList<THelpChatMessage>;
begin
  if not FConversations.TryGetValue(AKey, Result) then
  begin
    Result := TList<THelpChatMessage>.Create;
    FConversations.Add(AKey, Result);
  end;
end;

function THelpChatStore.IndexOfId(const AList: TList<THelpChatMessage>; const AId: string): Integer;
var
  I: Integer;
begin
  for I := AList.Count - 1 downto 0 do
    if AList[I].Id = AId then
      Exit(I);
  Result := -1;
end;

procedure THelpChatStore.PruneList(const AList: TList<THelpChatMessage>);
var
  I: Integer;
begin
  if FMaxMessages <= 0 then
    Exit;
  I := 0;
  while (AList.Count > FMaxMessages) and (I < AList.Count) do
    if AList[I].Pending then
      Inc(I) // never drop a message the runner is still filling
    else
      AList.Delete(I);
end;

function THelpChatStore.AddUserMessage(const AKey, AContent: string): THelpChatMessage;
var
  LList: TList<THelpChatMessage>;
begin
  Result := Default(THelpChatMessage);
  Result.Id := THelpChatMessage.NewId;
  Result.Role := hcrUser;
  Result.Content := AContent;
  Result.Created := Now;
  FLock.Enter;
  try
    LList := EnsureList(AKey);
    LList.Add(Result);
    PruneList(LList);
  finally
    FLock.Leave;
  end;
  DoChange(AKey, Result.Id);
end;

function THelpChatStore.AddSystemMessage(const AKey, AContent: string): THelpChatMessage;
var
  LList: TList<THelpChatMessage>;
begin
  Result := Default(THelpChatMessage);
  Result.Id := THelpChatMessage.NewId;
  Result.Role := hcrSystem;
  Result.Content := AContent;
  Result.Created := Now;
  FLock.Enter;
  try
    LList := EnsureList(AKey);
    LList.Add(Result);
    PruneList(LList);
  finally
    FLock.Leave;
  end;
  DoChange(AKey, Result.Id);
end;

function THelpChatStore.AddPendingAssistant(const AKey: string): string;
var
  LMessage: THelpChatMessage;
begin
  LMessage := Default(THelpChatMessage);
  LMessage.Id := THelpChatMessage.NewId;
  LMessage.Role := hcrAssistant;
  LMessage.Created := Now;
  LMessage.Pending := True;
  FLock.Enter;
  try
    EnsureList(AKey).Add(LMessage);
  finally
    FLock.Leave;
  end;
  Result := LMessage.Id;
  DoChange(AKey, Result);
end;

function THelpChatStore.UpdateMessage(const AKey, AId, AContent: string;
  const APending, AIsError, AAppend: Boolean): Boolean;
var
  LList: TList<THelpChatMessage>;
  LIndex: Integer;
  LMessage: THelpChatMessage;
begin
  Result := False;
  FLock.Enter;
  try
    if FConversations.TryGetValue(AKey, LList) then
    begin
      LIndex := IndexOfId(LList, AId);
      if LIndex >= 0 then
      begin
        LMessage := LList[LIndex];
        if AAppend then
          LMessage.Content := LMessage.Content + AContent
        else
          LMessage.Content := AContent;
        LMessage.Pending := APending;
        LMessage.IsError := AIsError;
        LList[LIndex] := LMessage;
        Result := True;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatStore.AppendAssistantToken(const AKey, AId, AToken: string);
begin
  if AToken = '' then
    Exit;
  // Stays pending: the reader keeps polling and shows the growing partial.
  if UpdateMessage(AKey, AId, AToken, True, False, True) then
    DoChange(AKey, AId);
end;

procedure THelpChatStore.CompleteAssistant(const AKey, AId, AContent: string);
begin
  if UpdateMessage(AKey, AId, AContent, False, False, False) then
    DoChange(AKey, AId);
end;

procedure THelpChatStore.FailAssistant(const AKey, AId, AError: string);
begin
  if UpdateMessage(AKey, AId, AError, False, True, False) then
    DoChange(AKey, AId);
end;

function THelpChatStore.TryGetMessage(const AKey, AId: string; out AMessage: THelpChatMessage): Boolean;
var
  LList: TList<THelpChatMessage>;
  LIndex: Integer;
begin
  Result := False;
  FLock.Enter;
  try
    if FConversations.TryGetValue(AKey, LList) then
    begin
      LIndex := IndexOfId(LList, AId);
      if LIndex >= 0 then
      begin
        AMessage := LList[LIndex];
        Result := True;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

function THelpChatStore.GetMessages(const AKey: string): TArray<THelpChatMessage>;
var
  LList: TList<THelpChatMessage>;
begin
  FLock.Enter;
  try
    if FConversations.TryGetValue(AKey, LList) then
      Result := LList.ToArray
    else
      Result := nil;
  finally
    FLock.Leave;
  end;
end;

function THelpChatStore.GetHistory(const AKey: string; const AMaxMessages: Integer): TArray<THelpChatMessage>;
var
  LList: TList<THelpChatMessage>;
  LKept: TList<THelpChatMessage>;
  I: Integer;
begin
  Result := nil;
  FLock.Enter;
  try
    if not FConversations.TryGetValue(AKey, LList) then
      Exit;
    LKept := TList<THelpChatMessage>.Create;
    try
      for I := 0 to LList.Count - 1 do
        if LList[I].IsCompleted and (LList[I].Role <> hcrSystem) then
          LKept.Add(LList[I]);
      if (AMaxMessages > 0) and (LKept.Count > AMaxMessages) then
        LKept.DeleteRange(0, LKept.Count - AMaxMessages);
      Result := LKept.ToArray;
    finally
      LKept.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

function THelpChatStore.Count(const AKey: string): Integer;
var
  LList: TList<THelpChatMessage>;
begin
  FLock.Enter;
  try
    if FConversations.TryGetValue(AKey, LList) then
      Result := LList.Count
    else
      Result := 0;
  finally
    FLock.Leave;
  end;
end;

function THelpChatStore.PendingIds(const AKey: string): TArray<string>;
var
  LList: TList<THelpChatMessage>;
  LIds: TList<string>;
  I: Integer;
begin
  Result := nil;
  FLock.Enter;
  try
    if not FConversations.TryGetValue(AKey, LList) then
      Exit;
    LIds := TList<string>.Create;
    try
      for I := 0 to LList.Count - 1 do
        if LList[I].Pending then
          LIds.Add(LList[I].Id);
      Result := LIds.ToArray;
    finally
      LIds.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatStore.Clear(const AKey: string);
begin
  FLock.Enter;
  try
    FConversations.Remove(AKey);
  finally
    FLock.Leave;
  end;
  DoChange(AKey, '');
end;

procedure THelpChatStore.ClearAll;
var
  LKeys: TArray<string>;
  LKey: string;
begin
  FLock.Enter;
  try
    LKeys := FConversations.Keys.ToArray;
    FConversations.Clear;
  finally
    FLock.Leave;
  end;
  for LKey in LKeys do
    DoChange(LKey, '');
end;

function THelpChatStore.ToJSON(const AKey: string): string;
var
  LRoot, LItem: TJSONObject;
  LArray: TJSONArray;
  LMessage: THelpChatMessage;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('version', TJSONNumber.Create(HELPCHAT_STORE_JSON_VERSION));
    LRoot.AddPair('key', AKey);
    LRoot.AddPair('saved', DateToISO8601(Now, False));
    LArray := TJSONArray.Create;
    LRoot.AddPair('messages', LArray);
    for LMessage in GetMessages(AKey) do
    begin
      if LMessage.Pending then
        Continue; // an interrupted reply is not worth restoring
      LItem := TJSONObject.Create;
      LItem.AddPair('id', LMessage.Id);
      LItem.AddPair('role', ROLE_NAMES[LMessage.Role]);
      LItem.AddPair('content', LMessage.Content);
      LItem.AddPair('created', DateToISO8601(LMessage.Created, False));
      if LMessage.IsError then
        LItem.AddPair('error', TJSONBool.Create(True));
      LArray.AddElement(LItem);
    end;
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

function THelpChatStore.FromJSON(const AKey, AJson: string; const AMaxAgeDays: Integer): Boolean;
var
  LValue: TJSONValue;
  LRoot, LItem: TJSONObject;
  LArray: TJSONArray;
  LList: TList<THelpChatMessage>;
  LMessage: THelpChatMessage;
  LSaved, LCreated: TDateTime;
  LRole: THelpChatRole;
  I: Integer;
begin
  Result := False;
  LValue := nil;
  LList := TList<THelpChatMessage>.Create;
  try
    try
      LValue := TJSONObject.ParseJSONValue(AJson);
    except
      LValue := nil;
    end;
    if not (LValue is TJSONObject) then
      Exit;
    LRoot := TJSONObject(LValue);
    if (AMaxAgeDays > 0) and TryISO8601ToDate(LRoot.GetValue<string>('saved', ''), LSaved, False) then
      if DaysBetween(Now, LSaved) >= AMaxAgeDays then
        Exit;
    if not (LRoot.GetValue('messages') is TJSONArray) then
      Exit;
    LArray := TJSONArray(LRoot.GetValue('messages'));
    for I := 0 to LArray.Count - 1 do
    begin
      if not (LArray.Items[I] is TJSONObject) then
        Continue;
      LItem := TJSONObject(LArray.Items[I]);
      if not RoleFromName(LItem.GetValue<string>('role', ''), LRole) then
        Continue;
      LMessage := Default(THelpChatMessage);
      LMessage.Id := LItem.GetValue<string>('id', '');
      if LMessage.Id = '' then
        LMessage.Id := THelpChatMessage.NewId;
      LMessage.Role := LRole;
      LMessage.Content := LItem.GetValue<string>('content', '');
      if TryISO8601ToDate(LItem.GetValue<string>('created', ''), LCreated, False) then
        LMessage.Created := LCreated
      else
        LMessage.Created := Now;
      LMessage.IsError := LItem.GetValue<Boolean>('error', False);
      LList.Add(LMessage);
    end;
    FLock.Enter;
    try
      FConversations.Remove(AKey);
      FConversations.Add(AKey, LList);
      PruneList(LList);
      LList := nil; // now owned by the dictionary
    finally
      FLock.Leave;
    end;
    Result := True;
  finally
    LList.Free;
    LValue.Free;
  end;
  if Result then
    DoChange(AKey, '');
end;

procedure THelpChatStore.SaveToFile(const AKey, AFileName: string);
var
  LDir: string;
begin
  try
    LDir := TPath.GetDirectoryName(AFileName);
    if (LDir <> '') and not TDirectory.Exists(LDir) then
      TDirectory.CreateDirectory(LDir);
    TFile.WriteAllText(AFileName, ToJSON(AKey), TEncoding.UTF8);
  except
    // Persistence is best-effort by design.
  end;
end;

function THelpChatStore.LoadFromFile(const AKey, AFileName: string; const AMaxAgeDays: Integer): Boolean;
begin
  Result := False;
  if not TFile.Exists(AFileName) then
    Exit;
  try
    Result := FromJSON(AKey, TFile.ReadAllText(AFileName, TEncoding.UTF8), AMaxAgeDays);
  except
    Result := False;
  end;
end;

end.
