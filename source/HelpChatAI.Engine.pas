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
    procedure StoreChanged(const AKey, AMessageId: string);
    procedure EnsureActive;
    function StateFile: string;
    function LoadState(const AName: string): string;
    procedure SaveState;
    procedure ApplyAssistantState;
    procedure ApplyLanguageState;
  public
    /// <summary>With <c>ASettings = nil</c> the engine creates and owns its own
    /// settings; otherwise it uses the given instance (owned when AOwnsSettings).</summary>
    constructor Create(const ASettings: THelpChatSettings = nil;
      const AOwnsSettings: Boolean = False);
    destructor Destroy; override;

    /// <summary>Loads the documentation index and the persisted conversation,
    /// starts the worker pool. Called implicitly by the first <c>Send</c>.</summary>
    procedure Start;
    /// <summary>Cancels running requests, waits for the workers up to
    /// <c>ATimeoutMs</c>, persists the conversation, releases everything.</summary>
    procedure Stop(const ATimeoutMs: Integer = HELPCHAT_DEF_SHUTDOWN_TIMEOUT_MS);

    /// <summary>Records the user message (trimmed and capped to
    /// <c>Settings.MessageMaxLength</c>), creates the pending assistant message,
    /// hands the provider call to the runner and returns immediately.</summary>
    function Send(const AText: string; const AContext: THelpChatContext): THelpChatSendResult; overload;
    function Send(const AText: string): THelpChatSendResult; overload;
    /// <summary>Same, on an explicit conversation: what a multi-user server
    /// uses, one key per session, sharing store, index and worker pool.</summary>
    function Send(const AKey, AText: string; const AContext: THelpChatContext): THelpChatSendResult; overload;
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

    /// <summary>The assistants the panel may switch between, with the icon
    /// each one shows: the configured list, or the one implicit assistant of
    /// <c>Settings.Provider</c>. See <c>THelpChatSettings.ResolveAssistants</c>.</summary>
    function Assistants: TArray<THelpChatAssistantInfo>;
    /// <summary>The one in use.</summary>
    function ActiveAssistant: THelpChatAssistantInfo;
    /// <summary>Makes AName the assistant in use for the questions that follow
    /// (a reply being produced keeps the settings it started with), and
    /// remembers the choice for the next start when the conversation is
    /// persisted. False when no assistant has that name.</summary>
    function SelectAssistant(const AName: string): Boolean;
    /// <summary>True when there is more than one assistant to choose from.</summary>
    function CanSelectAssistant: Boolean;

    /// <summary>The languages the panel offers (<c>Settings.Languages</c>),
    /// in the order of the enumeration.</summary>
    function Languages: TArray<THelpChatLanguage>;
    /// <summary>The language the chat speaks now, never <c>hclAuto</c>.</summary>
    function ActiveLanguage: THelpChatLanguage;
    /// <summary>Makes ALanguage the language of the chat: the strings of the
    /// panel (on its next load) and of the engine, and the language the
    /// model replies in from the next question on. Remembered for the next
    /// start when the conversation is persisted, like the assistant. False
    /// when the language is not one of <c>Settings.Languages</c>.</summary>
    function SelectLanguage(const ALanguage: THelpChatLanguage): Boolean;
    /// <summary>True when there is more than one language to choose from.</summary>
    function CanSelectLanguage: Boolean;

    /// <summary>The greeting bubble text (settings or localized default).</summary>
    function Greeting: string;
    /// <summary>The localized question the contextual help (F1) pre-fills for a screen.</summary>
    function ContextQuestion(const AContext: THelpChatContext): string;
    /// <summary>HTML fragment of the whole conversation (greeting when empty).</summary>
    function RenderHistoryHtml: string; overload;
    function RenderHistoryHtml(const AKey: string): string; overload;
    /// <summary>HTML fragment of one bubble, or empty when AId is unknown.</summary>
    function RenderMessageHtml(const AId: string): string; overload;
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

    property Settings: THelpChatSettings read FSettings;
    property Store: THelpChatStore read FStore;
    property DocIndex: THelpChatDocIndex read FDocIndex;
    /// <summary>The documentation pages shown in the panel; nil when
    /// <c>Settings.DocFolder</c> is empty (created by Start).</summary>
    property DocPages: THelpChatDocPages read FDocPages;
    /// <summary>Adjusts the Markdown of a page before it is rendered (set it
    /// before the panel opens; called on HTTP threads).</summary>
    property DocPageFilter: THelpChatDocPageFilter read FDocPageFilter write FDocPageFilter;
    property Retriever: IHelpChatRetriever read FRetriever;
    /// <summary>What the user attached, per conversation. Lives here and not
    /// in the store because the bytes of a PDF have no business in the JSON
    /// the conversation is persisted to: attachments last as long as the
    /// conversation is open.</summary>
    property Attachments: THelpChatAttachmentSet read FAttachments;
    property Runner: THelpChatRunner read FRunner;
    /// <summary>What the assistant may do in the application (the VCL and FMX
    /// components set this to their own broker). nil = it can only answer.</summary>
    property Actions: IHelpChatActionInvoker read FActions write FActions;
    property Active: Boolean read FActive;
    /// <summary>Key of the conversation this engine works on (default: the single
    /// desktop conversation). A multi-user server uses one engine per user or
    /// changes the key per request.</summary>
    property ConversationKey: string read FConversationKey write FConversationKey;
    property OnMessageChanged: THelpChatMessageEvent read FOnMessageChanged write FOnMessageChanged;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
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
  // The assistant in use decides the provider and the model before anything
  // below reads them (the excerpt size of the index comes from the model).
  ApplyAssistantState;

  FDocIndex := THelpChatDocIndex.Create;
  FRetriever := FDocIndex; // keeps it alive
  FDocIndex.BaseUrl := FSettings.DocBaseUrl;
  FDocIndex.ExcerptMaxChars := FSettings.ActiveModel.GroundingMaxChars;
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
var
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

  FRunner.Submit(AKey, LAssistantId, FSettings.Provider, AContext,
    FSettings.HistoryMaxMessages, FSettings, FActions,
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
    FSettings.Attachments.Limits, FSettings.Language, AAttachment, AError);
end;

function THelpChatEngine.RemoveAttachment(const AKey, AId: string): Boolean;
begin
  Result := FAttachments.Remove(AKey, AId);
end;

function THelpChatEngine.StateFile: string;
begin
  Result := TPath.Combine(TPath.GetDirectoryName(FSettings.ResolveConversationFile),
    HELPCHAT_DEF_STATE_FILENAME);
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
    LRoot.AddPair('Assistant', FSettings.ActiveAssistantName);
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

procedure THelpChatEngine.ApplyAssistantState;
var
  LName: string;
begin
  if FSettings.Assistants.Count = 0 then
    Exit;
  LName := '';
  if FSettings.PersistConversation then
    LName := LoadState('Assistant');
  // The remembered one, if it is still in the list; else what the configuration names.
  if (LName = '') or not FSettings.ApplyAssistant(LName) then
    FSettings.ApplyAssistant(FSettings.ActiveAssistantName);
end;

function THelpChatEngine.Assistants: TArray<THelpChatAssistantInfo>;
var
  I: Integer;
begin
  Result := FSettings.ResolveAssistants;
  for I := 0 to High(Result) do
    // An icon named in the configuration must exist; otherwise the model,
    // the endpoint and the provider say which one it is.
    if not HelpChatProviderIconExists(Result[I].Icon) then
      Result[I].Icon := HelpChatProviderIconFor(Result[I].Model, Result[I].BaseUrl,
        Result[I].Provider);
end;

function THelpChatEngine.ActiveAssistant: THelpChatAssistantInfo;
var
  LList: TArray<THelpChatAssistantInfo>;
  I: Integer;
begin
  LList := Assistants;
  for I := 0 to High(LList) do
    if LList[I].Active then
      Exit(LList[I]);
  if Length(LList) > 0 then
    Result := LList[0]
  else
    Result := Default(THelpChatAssistantInfo);
end;

function THelpChatEngine.SelectAssistant(const AName: string): Boolean;
begin
  Result := FSettings.ApplyAssistant(AName);
  if not Result then
    Exit;
  if Assigned(FDocIndex) then
    FDocIndex.ExcerptMaxChars := FSettings.ActiveModel.GroundingMaxChars;
  SaveState;
end;

function THelpChatEngine.CanSelectAssistant: Boolean;
begin
  Result := FSettings.Assistants.Count > 1;
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
  Result := HelpChatMsgFmt(hcmContextQuestion, [AContext.DisplayName], FSettings.Language);
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

end.
