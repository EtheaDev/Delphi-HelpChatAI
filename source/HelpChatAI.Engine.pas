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
///  The engine: the one object a transport or a component talks to. It owns
///  the store, the documentation index and the runner, wires them together
///  from the settings and exposes the whole conversation API: send a message
///  (returns at once with the user bubble and the pending assistant bubble),
///  read messages, cancel, clear, render HTML fragments, persist to disk.
///  Pure RTL: the VCL and FMX components are thin wrappers around it, and so is
///  the local HTTP server.
///
///  <c>OnMessageChanged</c> fires on the thread that performed the change: a
///  runner worker for assistant tokens and completions. A UI layer marshals it
///  with <c>TThread.Queue</c>; a polling transport may ignore it altogether.
///
///  Since 1.7 a component does not create its engine: it asks
///  <see cref="THelpChatEngines" /> for the engine of its profile, which the
///  assistants of that profile share. Three consequences shape this unit:
///  the engine owns a <i>copy</i> of the settings (what the user changes in
///  the panel - model, language - is written on that copy, not on the
///  component's); the actions are not the engine's but travel with each
///  question (<c>Send</c> with <c>AActions</c>); and the files it writes -
///  conversation, state - carry the profile in their name. Code that drives
///  an engine by itself (the console server, a test) still creates one with
///  <c>THelpChatEngine.Create</c> and may set <c>Actions</c> once.
///
///  Threads: <c>Start</c>, <c>Stop</c> and the registry are called on the
///  main thread; <c>Send</c>, the readers, <c>SelectModel</c> and
///  <c>SelectLanguage</c> also on the HTTP threads of the panel; the workers
///  only ever reach the store, through the runner.
/// </summary>
unit HelpChatAI.Engine;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Store,
  HelpChatAI.DocIndex,
  HelpChatAI.DocPages,
  HelpChatAI.Actions,
  HelpChatAI.Attachments,
  HelpChatAI.Runner;

type
  /// <summary>Fired after a message was added or changed (<c>AMessageId</c>
  /// empty after a clear or a load). See the unit summary for the thread.</summary>
  THelpChatMessageEvent = procedure(Sender: TObject; const AMessageId: string) of object;

  /// <summary>What <c>Send</c> returns: the recorded user message and the pending
  /// assistant message whose id the caller polls or watches.</summary>
  THelpChatSendResult = record
    UserMessage: THelpChatMessage;
    AssistantMessage: THelpChatMessage;
    /// <summary>False when the text was empty and nothing was sent.</summary>
    Sent: Boolean;
  end;

  /// <summary>The conversation engine of one assistant - or of the assistants
  /// of one profile, when it comes from <see cref="THelpChatEngines" />. It
  /// owns the store (the conversations, by key), the documentation index, the
  /// pages shown in the panel, the attachments and the worker pool, all
  /// created by <c>Start</c> from the settings and released by <c>Stop</c>.
  /// Every method that takes <c>AKey</c> works on that conversation; the ones
  /// without it work on <c>ConversationKey</c>, the single conversation of a
  /// desktop application.</summary>
  THelpChatEngine = class
  strict private
    FSettings: THelpChatSettings;
    FOwnsSettings: Boolean;
    FStore: THelpChatStore;
    FDocIndex: THelpChatDocIndex;
    FRetriever: IHelpChatRetriever;
    FDocPages: THelpChatDocPages;
    FDocPageFilter: THelpChatDocPageFilter;
    FRunner: THelpChatRunner;
    FAttachments: THelpChatAttachmentSet;
    FConversationKey: string;
    FActions: IHelpChatActionInvoker;
    FActive: Boolean;
    /// <summary>The code of the language the user chose (now or at a past
    /// start); empty while the configuration decides, so that a state file
    /// never freezes a language nobody picked.</summary>
    FChosenLanguage: string;
    FOnMessageChanged: THelpChatMessageEvent;
    /// <summary>The store changed (on the thread that changed it): persists
    /// the conversation once a message is complete - not at every streamed
    /// token - and fires <c>OnMessageChanged</c>.</summary>
    procedure StoreChanged(const AKey, AMessageId: string);
    procedure EnsureActive;
    /// <summary><c>Settings.ResolveStateFile</c>: next to the conversation,
    /// named after the profile.</summary>
    function StateFile: string;
    /// <summary>One value of the state file ("Model", "Language"); empty
    /// when the file is missing or damaged.</summary>
    function LoadState(const AName: string): string;
    /// <summary>Writes both choices of the user, always together, when the
    /// conversation is persisted; a failure to write is not an error.</summary>
    procedure SaveState;
    /// <summary>The model remembered in the state file if it is still in the
    /// list, else the one the configuration names.</summary>
    procedure ApplyModelState;
    /// <summary>The language remembered in the state file, if it is still
    /// offered.</summary>
    procedure ApplyLanguageState;
  public
    /// <summary>With <c>ASettings = nil</c> the engine creates and owns its own
    /// settings; otherwise it uses the given instance (owned when AOwnsSettings).</summary>
    constructor Create(const ASettings: THelpChatSettings = nil;
      const AOwnsSettings: Boolean = False);
    destructor Destroy; override;

    /// <summary>Applies the language and the model the user picked last time
    /// (the state file of the profile), loads the documentation index narrowed
    /// to <c>Settings.DocAreas</c> and the persisted conversation, starts the
    /// worker pool. Idempotent; called implicitly by the first <c>Send</c>.</summary>
    procedure Start;
    /// <summary>Cancels running requests, waits for the workers up to
    /// <c>ATimeoutMs</c>, persists the conversation, releases everything.</summary>
    procedure Stop(const ATimeoutMs: Integer = HELPCHAT_DEF_SHUTDOWN_TIMEOUT_MS);

    /// <summary>Records the user message (trimmed and capped to
    /// <c>Settings.MessageMaxLength</c>), creates the pending assistant message,
    /// hands the provider call to the runner and returns immediately.</summary>
    function Send(const AText: string; const AContext: THelpChatContext): THelpChatSendResult; overload;
    /// <summary>The same, with no screen context: a question asked from
    /// code.</summary>
    function Send(const AText: string): THelpChatSendResult; overload;
    /// <summary>Same, on an explicit conversation: what a multi-user server
    /// uses, one key per session, sharing store, index and worker pool.</summary>
    function Send(const AKey, AText: string; const AContext: THelpChatContext): THelpChatSendResult; overload;
    /// <summary>Same, with the actions of the assistant that asks: an engine
    /// shared by the assistants of one profile runs, for each question, the
    /// actions of the panel it came from. nil = <c>Actions</c>.</summary>
    function Send(const AKey, AText: string; const AContext: THelpChatContext;
      const AActions: IHelpChatActionInvoker): THelpChatSendResult; overload;
    /// <summary>Copy of the message AId, if it exists in this conversation.</summary>
    function TryGetMessage(const AId: string; out AMessage: THelpChatMessage): Boolean; overload;
    /// <summary>The same, in the conversation AKey (a server with many).</summary>
    function TryGetMessage(const AKey, AId: string;
      out AMessage: THelpChatMessage): Boolean; overload;
    /// <summary>The whole conversation, in order.</summary>
    function Messages: TArray<THelpChatMessage>; overload;
    /// <summary>The whole conversation AKey, in order.</summary>
    function Messages(const AKey: string): TArray<THelpChatMessage>; overload;
    /// <summary>True while at least one assistant reply is being produced.</summary>
    function IsBusy: Boolean;
    /// <summary>Cancels the reply AId; True if it was running or queued.</summary>
    function Cancel(const AId: string): Boolean;
    /// <summary>Cancels every reply being produced or queued, in every
    /// conversation. The replies keep what had arrived, or say they were
    /// cancelled.</summary>
    procedure CancelAll;
    /// <summary>Cancels everything and empties the conversation.</summary>
    procedure Clear; overload;
    /// <summary>Cancels the pending replies of AKey and empties that conversation.</summary>
    procedure Clear(const AKey: string); overload;

    /// <summary>Takes a file the user attached to the conversation AKey.
    /// False with a localized sentence in AError when the type is not one a
    /// model reads, or a limit of <c>Settings.Attachments</c> is reached.
    /// Every attachment is sent again with every question until the
    /// conversation is cleared - which is what makes a second question about
    /// the same document work, and what the size limits are there for.</summary>
    function AddAttachment(const AKey, AFileName: string; const AData: TBytes;
      out AAttachment: THelpChatAttachment; out AError: string): Boolean;
    /// <summary>Drops one attachment of the conversation.</summary>
    function RemoveAttachment(const AKey, AId: string): Boolean;

    /// <summary>The models the panel may switch between, with the icon each
    /// one shows: the configured list, or the one implicit model of
    /// <c>Settings.Provider</c>. See <c>THelpChatSettings.ResolveModels</c>.</summary>
    function Models: TArray<THelpChatModelInfo>;
    /// <summary>The one in use.</summary>
    function ActiveModelInfo: THelpChatModelInfo;
    /// <summary>Makes AName the model in use for the questions that follow
    /// (a reply being produced keeps the settings it started with), and
    /// remembers the choice for the next start when the conversation is
    /// persisted. False when no model has that name. On a shared engine the
    /// switch is for every assistant of the profile: it is one expert, and
    /// the user changed what it answers with.</summary>
    function SelectModel(const AName: string): Boolean;
    /// <summary>True when there is more than one model to choose from.</summary>
    function CanSelectModel: Boolean;

    /// <summary>The languages the panel offers (<c>Settings.Languages</c>),
    /// in the order of the enumeration.</summary>
    function Languages: TArray<THelpChatLanguage>;
    /// <summary>The language the chat speaks now, never <c>hclAuto</c>.</summary>
    function ActiveLanguage: THelpChatLanguage;
    /// <summary>Makes ALanguage the language of the chat: the strings of the
    /// panel (on its next load) and of the engine, and the language the
    /// model replies in from the next question on. Remembered for the next
    /// start when the conversation is persisted, like the model. False
    /// when the language is not one of <c>Settings.Languages</c>. It also
    /// becomes <c>HelpChatDefaultLanguage</c>, which is one for the whole
    /// process: with several assistants the last choice made in any panel is
    /// what every <c>hclAuto</c> resolves to.</summary>
    function SelectLanguage(const ALanguage: THelpChatLanguage): Boolean;
    /// <summary>True when there is more than one language to choose from.</summary>
    function CanSelectLanguage: Boolean;

    /// <summary>The greeting bubble text (settings or localized default).</summary>
    function Greeting: string;
    /// <summary>The localized question the contextual help (F1) pre-fills for a screen.</summary>
    function ContextQuestion(const AContext: THelpChatContext): string;
    /// <summary>HTML fragment of the whole conversation (greeting when empty).</summary>
    function RenderHistoryHtml: string; overload;
    /// <summary>The same for the conversation AKey.</summary>
    function RenderHistoryHtml(const AKey: string): string; overload;
    /// <summary>HTML fragment of one bubble, or empty when AId is unknown.</summary>
    function RenderMessageHtml(const AId: string): string; overload;
    /// <summary>The same in the conversation AKey: what a poll of the panel
    /// returns, with <c>data-pending</c> on the bubble while the reply is
    /// being written.</summary>
    function RenderMessageHtml(const AKey, AId: string): string; overload;
    /// <summary>Renders a page of <c>Settings.DocFolder</c> (a link as written in
    /// a reply or in another page). False when there is no folder or the link
    /// is not one of its pages. Thread-safe: the HTTP server calls it.</summary>
    function RenderDocPage(const APage: string; out ADoc: THelpChatRenderedDoc): Boolean;

    /// <summary>Writes the conversation to <c>Settings.ResolveConversationFile</c>
    /// when persistence is enabled.</summary>
    procedure SaveConversation;
    /// <summary>Reloads the conversation from disk (discarding an expired one).</summary>
    function LoadConversation: Boolean;

    /// <summary>The settings this engine runs with. For an engine of <see
    /// cref="THelpChatEngines" /> they are a copy of the settings of the first
    /// assistant that acquired it, and the place where the model and the
    /// language the user picks are written: a component reads these, not its
    /// own, for anything that changes at run time. Every request works on a
    /// snapshot of them taken by <c>Send</c>.</summary>
    property Settings: THelpChatSettings read FSettings;
    /// <summary>The conversations; nil until <c>Start</c> and after
    /// <c>Stop</c>.</summary>
    property Store: THelpChatStore read FStore;
    /// <summary>The documentation index, already narrowed to
    /// <c>Settings.DocAreas</c>; nil until <c>Start</c> and after <c>Stop</c>
    /// - and never created at all in an application whose engine is remote, so
    /// a caller must check.</summary>
    property DocIndex: THelpChatDocIndex read FDocIndex;
    /// <summary>The documentation pages shown in the panel; nil when
    /// <c>Settings.DocFolder</c> is empty (created by Start).</summary>
    property DocPages: THelpChatDocPages read FDocPages;
    /// <summary>Adjusts the Markdown of a page before it is rendered (set it
    /// before the panel opens; called on HTTP threads).</summary>
    property DocPageFilter: THelpChatDocPageFilter read FDocPageFilter write FDocPageFilter;
    /// <summary>The index as the providers see it: the contract a different
    /// retriever (an embedding search, say) would implement. nil when the
    /// engine is not started.</summary>
    property Retriever: IHelpChatRetriever read FRetriever;
    /// <summary>What the user attached, per conversation. Lives here and not
    /// in the store because the bytes of a PDF have no business in the JSON
    /// the conversation is persisted to: attachments last as long as the
    /// conversation is open.</summary>
    property Attachments: THelpChatAttachmentSet read FAttachments;
    /// <summary>The worker pool; nil until <c>Start</c> and after
    /// <c>Stop</c>.</summary>
    property Runner: THelpChatRunner read FRunner;
    /// <summary>What the assistant may do when the question names no actions
    /// of its own (<c>Send</c> with <c>AActions</c>). The components pass
    /// theirs with every question instead, through the transport: the engine
    /// of a profile is shared. nil = it can only answer.</summary>
    property Actions: IHelpChatActionInvoker read FActions write FActions;
    /// <summary>True between <c>Start</c> and <c>Stop</c>. An engine acquired
    /// for an assistant whose engine is remote is never started: it only
    /// carries the settings.</summary>
    property Active: Boolean read FActive;
    /// <summary>Key of the conversation this engine works on (default: the single
    /// desktop conversation). A multi-user server uses one engine per user or
    /// changes the key per request.</summary>
    property ConversationKey: string read FConversationKey write FConversationKey;
    /// <summary>Fired after a message of <c>ConversationKey</c> was added or
    /// changed (see the unit summary for the thread). One handler: an engine
    /// shared by several assistants is not the place to hang a per-window
    /// event - the panels poll.</summary>
    property OnMessageChanged: THelpChatMessageEvent read FOnMessageChanged write FOnMessageChanged;
  end;

  /// <summary>
  ///  One engine per profile, shared by every assistant that names it. Two
  ///  instances of the same form - two orders open at once - are two
  ///  components with the same profile: one engine means the index is loaded
  ///  once, the worker pool is one, and the user talks to "the order expert"
  ///  in one conversation whichever window asks. The empty profile, the
  ///  default assistant, is a profile like the others.
  ///
  ///  The engine owns a copy of the settings of the first assistant that
  ///  acquired it: the components keep theirs, and read the engine's for what
  ///  the user changes at run time (model, language). The secret handler of
  ///  that copy asks the assistants still holding the engine, so that none of
  ///  them leaves a handler of a freed component behind. What each assistant
  ///  may do travels with its questions (<c>THelpChatEngine.Send</c> with
  ///  <c>AActions</c>), never with the engine.
  /// </summary>
  THelpChatEngines = class
  public
    /// <summary>The engine of the profile of ASettings (the name, case
    /// apart; the empty one included), created on first use with a copy of
    /// ASettings - so the settings of the first assistant of a profile are
    /// the ones the engine runs with, and those of the assistants that join
    /// later are only asked for their secret handler. AHolder is who will
    /// release it, and ASettings must stay alive until it does. Not started:
    /// the holder calls <c>Start</c>, unless its engine is remote. Main
    /// thread.</summary>
    class function Acquire(const AHolder: TObject;
      const ASettings: THelpChatSettings): THelpChatEngine; static;
    /// <summary>AHolder no longer uses AEngine: the last one to release it
    /// frees it (which stops its workers, with a bounded wait, and saves the
    /// conversation); the next <c>Acquire</c> of that profile creates a new
    /// one, with the settings of whoever asks. An engine this registry does
    /// not know is simply freed. AEngine is set to nil.</summary>
    class procedure Release(const AHolder: TObject; var AEngine: THelpChatEngine); static;
    /// <summary>How many assistants hold AEngine; 0 for one this registry
    /// does not know.</summary>
    class function HolderCount(const AEngine: THelpChatEngine): Integer; static;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.SyncObjs,
  System.Generics.Collections,
  HelpChatAI.Html,
  HelpChatAI.Icons;

{ THelpChatEngine }

constructor THelpChatEngine.Create(const ASettings: THelpChatSettings;
  const AOwnsSettings: Boolean);
begin
  inherited Create;
  if Assigned(ASettings) then
  begin
    FSettings := ASettings;
    FOwnsSettings := AOwnsSettings;
  end
  else
  begin
    FSettings := THelpChatSettings.Create;
    FOwnsSettings := True;
  end;
  FConversationKey := HELPCHAT_DEFAULT_CONVERSATION;
  // Created with the engine and not by Start: the panel may offer the paper
  // clip before the first question has started anything.
  FAttachments := THelpChatAttachmentSet.Create;
end;

destructor THelpChatEngine.Destroy;
begin
  Stop;
  FreeAndNil(FDocPages);
  FreeAndNil(FAttachments);
  if FOwnsSettings then
    FSettings.Free;
  inherited;
end;

procedure THelpChatEngine.Start;
var
  LIndexFile: string;
begin
  if FActive then
    Exit;
  // The language the user picked last time, if it is still offered; then
  // the one every hclAuto of this process resolves to.
  ApplyLanguageState;
  HelpChatDefaultLanguage := FSettings.ResolveLanguage;
  // The model in use decides the provider and the section before anything
  // below reads them (the excerpt size of the index comes from the section).
  ApplyModelState;

  FDocIndex := THelpChatDocIndex.Create;
  FRetriever := FDocIndex; // keeps it alive
  FDocIndex.BaseUrl := FSettings.DocBaseUrl;
  FDocIndex.ExcerptMaxChars := FSettings.ActiveModel.GroundingMaxChars;
  // The part of the manual this assistant is the expert of.
  FDocIndex.Areas := FSettings.ResolveDocAreas;
  LIndexFile := FSettings.ResolveDocIndexFile;
  if TFile.Exists(LIndexFile) then
    FDocIndex.LoadFromFile(LIndexFile);
  // Kept until the destructor: a page request may still be running on an
  // HTTP thread while the engine stops.
  if not Assigned(FDocPages) and (FSettings.ResolveDocFolder <> '') then
    FDocPages := THelpChatDocPages.Create(FSettings.ResolveDocFolder);

  FStore := THelpChatStore.Create;
  FStore.MaxMessages := FSettings.MaxStoredMessages;
  if FSettings.PersistConversation then
    LoadConversation;
  FStore.OnChange := StoreChanged;

  FRunner := THelpChatRunner.Create(FStore, FRetriever, FSettings.PoolSize);
  FActive := True;
end;

procedure THelpChatEngine.Stop(const ATimeoutMs: Integer);
begin
  if not FActive then
    Exit;
  FActive := False;
  // Order matters: workers first (they write to the store), then the store.
  if Assigned(FRunner) then
  begin
    FRunner.Shutdown(ATimeoutMs);
    FreeAndNil(FRunner);
  end;
  if Assigned(FStore) then
  begin
    FStore.OnChange := nil;
    SaveConversation;
    FreeAndNil(FStore);
  end;
  FDocIndex := nil;
  FRetriever := nil;
end;

procedure THelpChatEngine.EnsureActive;
begin
  if not FActive then
    Start;
end;

procedure THelpChatEngine.StoreChanged(const AKey, AMessageId: string);
var
  LMessage: THelpChatMessage;
begin
  if AKey <> FConversationKey then
    Exit;
  // Persist on every completed change, not on every streamed token.
  if FSettings.PersistConversation and Assigned(FStore) then
    if (AMessageId = '') or (FStore.TryGetMessage(AKey, AMessageId, LMessage) and not LMessage.Pending) then
      FStore.SaveToFile(AKey, FSettings.ResolveConversationFile);
  if Assigned(FOnMessageChanged) then
    FOnMessageChanged(Self, AMessageId);
end;

function THelpChatEngine.Send(const AText: string): THelpChatSendResult;
begin
  Result := Send(AText, Default(THelpChatContext));
end;

function THelpChatEngine.Send(const AText: string; const AContext: THelpChatContext): THelpChatSendResult;
begin
  Result := Send(FConversationKey, AText, AContext);
end;

function THelpChatEngine.Send(const AKey, AText: string;
  const AContext: THelpChatContext): THelpChatSendResult;
begin
  Result := Send(AKey, AText, AContext, nil);
end;

function THelpChatEngine.Send(const AKey, AText: string; const AContext: THelpChatContext;
  const AActions: IHelpChatActionInvoker): THelpChatSendResult;
var
  LActions: IHelpChatActionInvoker;
  LText, LAssistantId: string;
begin
  Result := Default(THelpChatSendResult);
  LText := Trim(AText);
  if LText = '' then
    Exit;
  EnsureActive;
  if (FSettings.MessageMaxLength > 0) and (LText.Length > FSettings.MessageMaxLength) then
    LText := LText.Substring(0, FSettings.MessageMaxLength);

  Result.UserMessage := FStore.AddUserMessage(AKey, LText);
  LAssistantId := FStore.AddPendingAssistant(AKey);
  FStore.TryGetMessage(AKey, LAssistantId, Result.AssistantMessage);
  Result.Sent := True;

  LActions := AActions;
  if LActions = nil then
    LActions := FActions;
  // No provider name: the runner takes it from the snapshot of the settings
  // it makes, so name, endpoint and key are always of the same model.
  FRunner.Submit(AKey, LAssistantId, '', AContext,
    FSettings.HistoryMaxMessages, FSettings, LActions,
    FAttachments.ItemsOf(AKey));
end;

function THelpChatEngine.TryGetMessage(const AId: string; out AMessage: THelpChatMessage): Boolean;
begin
  Result := Assigned(FStore) and FStore.TryGetMessage(FConversationKey, AId, AMessage);
end;

function THelpChatEngine.TryGetMessage(const AKey, AId: string;
  out AMessage: THelpChatMessage): Boolean;
begin
  Result := Assigned(FStore) and FStore.TryGetMessage(AKey, AId, AMessage);
end;

function THelpChatEngine.Messages: TArray<THelpChatMessage>;
begin
  Result := Messages(FConversationKey);
end;

function THelpChatEngine.Messages(const AKey: string): TArray<THelpChatMessage>;
begin
  if Assigned(FStore) then
    Result := FStore.GetMessages(AKey)
  else
    Result := nil;
end;

function THelpChatEngine.IsBusy: Boolean;
begin
  Result := Assigned(FStore) and (Length(FStore.PendingIds(FConversationKey)) > 0);
end;

function THelpChatEngine.Cancel(const AId: string): Boolean;
begin
  Result := Assigned(FRunner) and FRunner.Cancel(AId);
end;

procedure THelpChatEngine.CancelAll;
begin
  if Assigned(FRunner) then
    FRunner.CancelAll;
end;

procedure THelpChatEngine.Clear;
begin
  Clear(FConversationKey);
end;

procedure THelpChatEngine.Clear(const AKey: string);
var
  LId: string;
begin
  if not FActive then
    Exit;
  // Only this conversation: on a server the other sessions keep working.
  for LId in FStore.PendingIds(AKey) do
    FRunner.Cancel(LId);
  FStore.Clear(AKey);
  // The attachments went with the conversation that is gone: keeping them
  // would send documents nobody can see any more with the next question.
  FAttachments.ClearKey(AKey);
end;

function THelpChatEngine.AddAttachment(const AKey, AFileName: string;
  const AData: TBytes; out AAttachment: THelpChatAttachment;
  out AError: string): Boolean;
begin
  AAttachment := Default(THelpChatAttachment);
  AError := '';
  if not FSettings.Attachments.Enabled then
    Exit(False);
  Result := FAttachments.TryAdd(AKey, AFileName, AData,
    FSettings.Attachments.Limits, ActiveLanguage, AAttachment, AError);
end;

function THelpChatEngine.RemoveAttachment(const AKey, AId: string): Boolean;
begin
  Result := FAttachments.Remove(AKey, AId);
end;

function THelpChatEngine.StateFile: string;
begin
  Result := FSettings.ResolveStateFile;
end;

function THelpChatEngine.LoadState(const AName: string): string;
var
  LValue: TJSONValue;
begin
  Result := '';
  if not TFile.Exists(StateFile) then
    Exit;
  try
    LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(StateFile, TEncoding.UTF8));
    try
      if LValue is TJSONObject then
        Result := TJSONObject(LValue).GetValue<string>(AName, '');
    finally
      LValue.Free;
    end;
  except
    // A damaged state file is not worth an error at start: the configuration decides.
    Result := '';
  end;
end;

procedure THelpChatEngine.SaveState;
var
  LRoot: TJSONObject;
begin
  if not FSettings.PersistConversation then
    Exit;
  LRoot := TJSONObject.Create;
  try
    // Both choices of the user, always together: writing one must not lose the other.
    LRoot.AddPair('Model', FSettings.ActiveModelName);
    if FChosenLanguage <> '' then
      LRoot.AddPair('Language', FChosenLanguage);
    try
      TDirectory.CreateDirectory(TPath.GetDirectoryName(StateFile));
      TFile.WriteAllText(StateFile, LRoot.Format(2), TEncoding.UTF8);
    except
      // A read-only profile must not break the switch: it is just not remembered.
    end;
  finally
    LRoot.Free;
  end;
end;

procedure THelpChatEngine.ApplyModelState;
var
  LName: string;
begin
  if FSettings.Models.Count = 0 then
    Exit;
  LName := '';
  if FSettings.PersistConversation then
    LName := LoadState('Model');
  // The remembered one, if it is still in the list; else what the configuration names.
  if (LName = '') or not FSettings.ApplyModel(LName) then
    FSettings.ApplyModel(FSettings.ActiveModelName);
end;

function THelpChatEngine.Models: TArray<THelpChatModelInfo>;
var
  I: Integer;
begin
  Result := FSettings.ResolveModels;
  for I := 0 to High(Result) do
    // An icon named in the configuration must exist; otherwise the model,
    // the endpoint and the provider say which one it is.
    if not HelpChatProviderIconExists(Result[I].Icon) then
      Result[I].Icon := HelpChatProviderIconFor(Result[I].Model, Result[I].BaseUrl,
        Result[I].Provider);
end;

function THelpChatEngine.ActiveModelInfo: THelpChatModelInfo;
var
  LList: TArray<THelpChatModelInfo>;
  I: Integer;
begin
  LList := Models;
  for I := 0 to High(LList) do
    if LList[I].Active then
      Exit(LList[I]);
  if Length(LList) > 0 then
    Result := LList[0]
  else
    Result := Default(THelpChatModelInfo);
end;

function THelpChatEngine.SelectModel(const AName: string): Boolean;
begin
  Result := FSettings.ApplyModel(AName);
  if not Result then
    Exit;
  if Assigned(FDocIndex) then
    FDocIndex.ExcerptMaxChars := FSettings.ActiveModel.GroundingMaxChars;
  SaveState;
end;

function THelpChatEngine.CanSelectModel: Boolean;
begin
  Result := FSettings.Models.Count > 1;
end;

procedure THelpChatEngine.ApplyLanguageState;
var
  LLanguage: THelpChatLanguage;
begin
  if not FSettings.PersistConversation then
    Exit;
  // The remembered one, if it is still offered; else what the configuration says.
  if HelpChatLanguageFromCode(LoadState('Language'), LLanguage) and
     (LLanguage in FSettings.Languages * HELPCHAT_ALL_LANGUAGES) then
  begin
    FSettings.Language := LLanguage;
    FChosenLanguage := HelpChatLanguageCode(LLanguage);
  end;
end;

function THelpChatEngine.Languages: TArray<THelpChatLanguage>;
begin
  Result := HelpChatLanguageList(FSettings.Languages);
end;

function THelpChatEngine.ActiveLanguage: THelpChatLanguage;
begin
  // What every text this engine writes outside a reply is in (the page, a
  // command, the title of a PDF, the reason an attachment was refused):
  // never Settings.Language as it is, which may be hclAuto and would then
  // resolve to the default of the process - the language of whichever
  // engine started last, with several assistants.
  Result := FSettings.ResolveLanguage;
end;

function THelpChatEngine.SelectLanguage(const ALanguage: THelpChatLanguage): Boolean;
begin
  Result := ALanguage in FSettings.Languages * HELPCHAT_ALL_LANGUAGES;
  if not Result then
    Exit;
  // Written on the settings, not kept aside: every reader of the language
  // (the snapshot of a request, the strings of a dialog, the page) reads it
  // there. A reply being produced keeps the snapshot it started with.
  FSettings.Language := ALanguage;
  HelpChatDefaultLanguage := ALanguage;
  FChosenLanguage := HelpChatLanguageCode(ALanguage);
  SaveState;
end;

function THelpChatEngine.CanSelectLanguage: Boolean;
begin
  Result := Length(Languages) > 1;
end;

function THelpChatEngine.Greeting: string;
begin
  Result := FSettings.ResolveGreeting;
end;

function THelpChatEngine.ContextQuestion(const AContext: THelpChatContext): string;
begin
  Result := HelpChatMsgFmt(hcmContextQuestion, [AContext.DisplayName], ActiveLanguage);
end;

function THelpChatEngine.RenderHistoryHtml: string;
begin
  Result := RenderHistoryHtml(FConversationKey);
end;

function THelpChatEngine.RenderDocPage(const APage: string; out ADoc: THelpChatRenderedDoc): Boolean;
begin
  ADoc := Default(THelpChatRenderedDoc);
  Result := Assigned(FDocPages) and FDocPages.Render(APage, FDocPageFilter, ADoc);
end;

function THelpChatEngine.RenderHistoryHtml(const AKey: string): string;
var
  LMessages: TArray<THelpChatMessage>;
begin
  if Assigned(FStore) then
    LMessages := FStore.GetMessages(AKey)
  else
    LMessages := nil;
  Result := HelpChatRenderHistory(LMessages, Greeting);
end;

function THelpChatEngine.RenderMessageHtml(const AId: string): string;
begin
  Result := RenderMessageHtml(FConversationKey, AId);
end;

function THelpChatEngine.RenderMessageHtml(const AKey, AId: string): string;
var
  LMessage: THelpChatMessage;
begin
  if Assigned(FStore) and FStore.TryGetMessage(AKey, AId, LMessage) then
    Result := HelpChatRenderBubble(LMessage)
  else
    Result := '';
end;

procedure THelpChatEngine.SaveConversation;
begin
  if FSettings.PersistConversation and Assigned(FStore) then
    FStore.SaveToFile(FConversationKey, FSettings.ResolveConversationFile);
end;

function THelpChatEngine.LoadConversation: Boolean;
begin
  Result := Assigned(FStore) and FStore.LoadFromFile(FConversationKey,
    FSettings.ResolveConversationFile, FSettings.ConversationMaxAgeDays);
end;

{ THelpChatEngines }

type
  /// <summary>The engine of one profile, and who holds it. An entry outlives
  /// its engine: the settings of a reply in flight carry its Decrypt as their
  /// secret handler, and a worker may still be running when the last
  /// assistant goes, so the entries live as long as the process.</summary>
  TSharedEngine = class
  strict private
    FHolders: TList<TObject>;
    FHolderSettings: TList<THelpChatSettings>;
  public
    Key: string;
    Engine: THelpChatEngine;
    constructor Create(const AKey: string);
    destructor Destroy; override;
    procedure AddHolder(const AHolder: TObject; const ASettings: THelpChatSettings);
    /// <summary>Returns how many holders are left.</summary>
    function RemoveHolder(const AHolder: TObject): Integer;
    function HolderCount: Integer;
    procedure Decrypt(Sender: TObject; const AName, AValue: string;
      var AResult: string; var AHandled: Boolean);
  end;

var
  GSharedLock: TCriticalSection;
  GShared: TObjectList<TSharedEngine>;

constructor TSharedEngine.Create(const AKey: string);
begin
  inherited Create;
  Key := AKey;
  FHolders := TList<TObject>.Create;
  FHolderSettings := TList<THelpChatSettings>.Create;
end;

destructor TSharedEngine.Destroy;
begin
  FHolderSettings.Free;
  FHolders.Free;
  inherited;
end;

procedure TSharedEngine.AddHolder(const AHolder: TObject; const ASettings: THelpChatSettings);
begin
  if FHolders.IndexOf(AHolder) >= 0 then
    Exit;
  FHolders.Add(AHolder);
  FHolderSettings.Add(ASettings);
end;

function TSharedEngine.RemoveHolder(const AHolder: TObject): Integer;
var
  LIndex: Integer;
begin
  LIndex := FHolders.IndexOf(AHolder);
  if LIndex >= 0 then
  begin
    FHolders.Delete(LIndex);
    FHolderSettings.Delete(LIndex);
  end;
  Result := FHolders.Count;
end;

function TSharedEngine.HolderCount: Integer;
begin
  Result := FHolders.Count;
end;

procedure TSharedEngine.Decrypt(Sender: TObject; const AName, AValue: string;
  var AResult: string; var AHandled: Boolean);
var
  LSettings: THelpChatSettings;
  LSender: TObject;
begin
  // The handler of an assistant still holding the engine, asked as if the
  // secret were its own; none left, the value stays as it is.
  GSharedLock.Enter;
  try
    for LSettings in FHolderSettings do
      if Assigned(LSettings.OnDecryptSecret) then
      begin
        LSender := LSettings.SecretSender;
        if LSender = nil then
          LSender := LSettings;
        LSettings.OnDecryptSecret(LSender, AName, AValue, AResult, AHandled);
        Exit;
      end;
  finally
    GSharedLock.Leave;
  end;
end;

function FindShared(const AKey: string): TSharedEngine;
var
  LEntry: TSharedEngine;
begin
  for LEntry in GShared do
    if LEntry.Key = AKey then
      Exit(LEntry);
  Result := nil;
end;

function FindSharedOf(const AEngine: THelpChatEngine): TSharedEngine;
var
  LEntry: TSharedEngine;
begin
  for LEntry in GShared do
    if Assigned(AEngine) and (LEntry.Engine = AEngine) then
      Exit(LEntry);
  Result := nil;
end;

class function THelpChatEngines.Acquire(const AHolder: TObject;
  const ASettings: THelpChatSettings): THelpChatEngine;
var
  LKey: string;
  LEntry: TSharedEngine;
  LSettings: THelpChatSettings;
begin
  LKey := LowerCase(Trim(ASettings.Profile));
  GSharedLock.Enter;
  try
    LEntry := FindShared(LKey);
    if LEntry = nil then
    begin
      LEntry := TSharedEngine.Create(LKey);
      GShared.Add(LEntry);
    end;
    if LEntry.Engine = nil then
    begin
      LSettings := THelpChatSettings.Create;
      LSettings.Assign(ASettings);
      LSettings.SetSecretHandler(LEntry.Decrypt, nil);
      LEntry.Engine := THelpChatEngine.Create(LSettings, True);
    end;
    LEntry.AddHolder(AHolder, ASettings);
    Result := LEntry.Engine;
  finally
    GSharedLock.Leave;
  end;
end;

class procedure THelpChatEngines.Release(const AHolder: TObject; var AEngine: THelpChatEngine);
var
  LEntry: TSharedEngine;
  LFree: THelpChatEngine;
begin
  if AEngine = nil then
    Exit;
  LFree := nil;
  GSharedLock.Enter;
  try
    LEntry := FindSharedOf(AEngine);
    if LEntry = nil then
      // Not one of ours: whoever created it frees it.
      LFree := AEngine
    else if LEntry.RemoveHolder(AHolder) = 0 then
    begin
      LFree := LEntry.Engine;
      LEntry.Engine := nil;
    end;
  finally
    GSharedLock.Leave;
  end;
  AEngine := nil;
  // Outside the lock: stopping waits for the workers, and a worker may be
  // asking the secret handler, which takes the lock.
  LFree.Free;
end;

class function THelpChatEngines.HolderCount(const AEngine: THelpChatEngine): Integer;
var
  LEntry: TSharedEngine;
begin
  GSharedLock.Enter;
  try
    LEntry := FindSharedOf(AEngine);
    if Assigned(LEntry) then
      Result := LEntry.HolderCount
    else
      Result := 0;
  finally
    GSharedLock.Leave;
  end;
end;

initialization
  GSharedLock := TCriticalSection.Create;
  GShared := TObjectList<TSharedEngine>.Create(True);

finalization
  FreeAndNil(GShared);
  FreeAndNil(GSharedLock);

end.
