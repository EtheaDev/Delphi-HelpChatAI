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
///  The HelpChat server: the same engine, the same page and the same endpoints
///  as the desktop case, serving many clients instead of one process. What it
///  adds to <see cref="THelpChatHttpServerBase" /> is sessions — a client opens
///  one with <c>POST /session</c> presenting the key of its application, and
///  gets back the secret every later call carries.
///
///  Why it exists: on a desktop the model's API key sits on the user's machine
///  and the documentation index ships with the application. Point the clients
///  here instead and the key never leaves the server, the index is updated in
///  one place, quotas and logs are per user, and a mobile application needs no
///  local server at all.
///
///  One engine serves everybody: the store keys conversations, the worker pool
///  is shared and bounded, the index is loaded once. A session is a
///  conversation key — <c>u:&lt;user&gt;</c> when the client says who is asking
///  (so the same person continues where they left off, from any device),
///  <c>s:&lt;session&gt;</c> when it does not. With disk storage the
///  conversation outlives the session and the server restart.
///
///  One engine also means one profile: a session carries who is asking, the
///  screen, the colours and the name of the assistant, but not the
///  <c>Profile</c> of the component that opened it. Instructions, areas of the
///  manual and models are those of the server's own configuration, whatever
///  profile the client names in its own.
///
///  Threads: every route runs on a connection thread of Indy, the expiry on
///  the sweeper's; <c>OnAuthenticate</c> and <c>OnLog</c> are called from both,
///  never from the main thread. The properties are meant to be set before
///  <c>Start</c>.
/// </summary>
unit HelpChatAI.Server.Remote;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  IdCustomHTTPServer,
  HelpChatAI.Types,
  HelpChatAI.Engine,
  HelpChatAI.Panel,
  HelpChatAI.Server;

const
  /// <summary>Port a remote server listens on unless told otherwise: fixed,
  /// unlike the local server, because clients have to be configured with
  /// it.</summary>
  HELPCHAT_REMOTE_DEF_PORT = 8080;
  /// <summary>Default of <c>IdleMinutes</c>: a session nobody called for two
  /// hours is ended.</summary>
  HELPCHAT_REMOTE_DEF_IDLE_MINUTES = 120;
  /// <summary>Default of <c>MaxSessions</c>: beyond it <c>POST /session</c>
  /// answers 503 until a session ends or expires.</summary>
  HELPCHAT_REMOTE_DEF_MAX_SESSIONS = 500;
  /// <summary>How often the sweeper looks for idle sessions: an expiry is
  /// late by at most this much.</summary>
  HELPCHAT_REMOTE_SWEEP_SECONDS = 30;
  /// <summary>How long a session that ended is kept before it is freed: a
  /// request that found it a moment earlier may still be using it (a
  /// <c>/run</c> waits for its host up to a minute).</summary>
  HELPCHAT_REMOTE_RETIRE_SECONDS = 300;
  /// <summary>Prefix of the conversation key of a known user
  /// (<c>u:&lt;user&gt;</c>): the same person finds the same conversation from
  /// any session.</summary>
  HELPCHAT_KEY_USER_PREFIX = 'u:';
  /// <summary>Prefix of the conversation key of an anonymous session
  /// (<c>s:&lt;session id&gt;</c>): the conversation is that session's alone
  /// and cannot be found again once it ended.</summary>
  HELPCHAT_KEY_SESSION_PREFIX = 's:';

type
  /// <summary>Where the conversations live between one session and the next.</summary>
  THelpChatSessionStorage = (
    /// <summary>In memory only, for as long as the session lives: when the last
    /// session on a conversation ends or expires, that conversation is gone.</summary>
    hssMemory,
    /// <summary>One JSON file per conversation, written when the session ends
    /// or expires and read back when the same user returns.</summary>
    hssDisk);

  /// <summary>
  ///  Lets the application decide who may open a session and on which
  ///  conversation. Without a handler the application key alone is checked.
  ///  <c>AConversationKey</c> arrives with the default and can be replaced (to
  ///  key conversations by tenant, say).
  ///
  ///  <c>AUserId</c> is what the client declared, trimmed, empty for an
  ///  anonymous session; <c>AUserToken</c> is the credential it sent with it,
  ///  which nothing in the library looks at. So without a handler a client
  ///  holding a valid application key gets the conversation of whichever user
  ///  it names: an application whose conversations are private must check the
  ///  token here. Setting <c>AAllowed</c> to False, or emptying the key,
  ///  answers 403. Called on a connection thread, possibly several at once,
  ///  outside the lock of the server: the handler must be thread-safe and
  ///  must not touch the UI.
  /// </summary>
  THelpChatAuthenticateEvent = procedure(Sender: TObject; const AAppKey, AUserId,
    AUserToken: string; var AAllowed: Boolean; var AConversationKey: string) of object;

  /// <summary>One line of the server's log (listening, session opened,
  /// refused, closed, expired, a conversation file that could not be read or
  /// written). Called on connection threads and on the sweeper's, and now and
  /// then with the lock of the sessions held: write the line and return, never
  /// call back into the server.</summary>
  THelpChatServerLogEvent = procedure(Sender: TObject; const AText: string) of object;

  THelpChatRemoteServer = class;

  /// <summary>Expires idle sessions without the server having to be called:
  /// a thread that sleeps <c>HELPCHAT_REMOTE_SWEEP_SECONDS</c> at a time and
  /// calls <see cref="THelpChatRemoteServer.Sweep" />. Created by
  /// <c>Start</c> and freed by <c>Stop</c> of the server; not for other
  /// use.</summary>
  THelpChatSessionSweeper = class(TThread)
  strict private
    FServer: THelpChatRemoteServer;
    FWakeUp: TEvent;
  protected
    /// <summary>Sleeps on the event rather than with <c>Sleep</c>, so that
    /// <c>Stop</c> ends it at once. An exception of a sweep is swallowed: the
    /// next round tries again.</summary>
    procedure Execute; override;
  public
    /// <summary>Starts running at once. <c>AServer</c> is not owned and must
    /// outlive the thread.</summary>
    constructor Create(const AServer: THelpChatRemoteServer);
    destructor Destroy; override;
    /// <summary>Asks the thread to end and wakes it; does not wait. The
    /// caller then calls <c>WaitFor</c> and frees it.</summary>
    procedure Stop;
  end;

  /// <summary>
  ///  The multi-session server. A session is opened by <c>POST /session</c>
  ///  (application key in <c>X-HelpChat-Key</c> or in the form field
  ///  <c>appKey</c>; optional <c>user</c>, <c>userToken</c>, <c>uiBase</c>,
  ///  <c>uiToken</c>, <c>themeCss</c>, <c>assistantName</c>,
  ///  <c>assistantIcon</c>), closed by <c>POST /session/end</c> with its token,
  ///  and expires by itself when idle. <c>GET /health</c> needs no key and
  ///  tells version, open sessions, provider and size of the index.
  ///
  ///  The sessions live in a dictionary keyed by their token and owned by it,
  ///  guarded by one lock. What the base class does with a session it found
  ///  happens outside that lock, so a session that ends is not freed at
  ///  once: it is retired, and freed <c>HELPCHAT_REMOTE_RETIRE_SECONDS</c>
  ///  later or when the listener has stopped.
  /// </summary>
  THelpChatRemoteServer = class(THelpChatHttpServerBase)
  strict private
    FSessions: TObjectDictionary<string, THelpChatServerSession>;
    // Sessions that ended, with the moment they did: no token finds them any
    // more, but a request already running may hold one.
    FRetired: TList<TPair<TDateTime, THelpChatServerSession>>;
    FLock: TCriticalSection;
    FAppKeys: TStringList;
    FStorage: THelpChatSessionStorage;
    FSessionFolder: string;
    FIdleSeconds: Integer;
    FMaxSessions: Integer;
    FSweeper: THelpChatSessionSweeper;
    FOnAuthenticate: THelpChatAuthenticateEvent;
    FOnLog: THelpChatServerLogEvent;
    function GetIdleMinutes: Integer;
    procedure SetIdleMinutes(const Value: Integer);
    /// <summary>Exact, case-sensitive match against <c>AppKeys</c>; an empty
    /// key never matches.</summary>
    function CheckAppKey(const AKey: string): Boolean;
    function ConversationFile(const AConversationKey: string): string;
    /// <summary>True when a session other than <c>AExceptToken</c> works on
    /// that conversation. Called with the lock held.</summary>
    function KeyInUse(const AConversationKey, AExceptToken: string): Boolean;
    /// <summary>Reads the conversation back from disk, unless it is already
    /// in memory. Never raises: a file that cannot be read is logged and the
    /// user starts from an empty conversation.</summary>
    procedure LoadConversation(const AConversationKey: string);
    /// <summary>Writes the conversation to its file when storage is on disk.
    /// Never raises: a failure is logged.</summary>
    procedure SaveConversation(const AConversationKey: string);
    /// <summary>What happens to a conversation when a session on it ends:
    /// saved (on disk) and removed from memory, replies in flight cancelled -
    /// unless another session still uses it. Called with the lock held, after
    /// the session was removed.</summary>
    procedure ReleaseConversation(const AConversationKey, AExceptToken: string);
    /// <summary>The whole of <c>POST /session</c>: False with a short English
    /// reason in <c>AError</c> ("unknown application key", "not authorized",
    /// "too many sessions"), True with the JSON the client reads (session id,
    /// token, polling parameters, language of the server).</summary>
    function OpenSession(ARequestInfo: TIdHTTPRequestInfo; out AJson: string;
      out AError: string): Boolean;
    /// <summary>Removes and frees the session of that token and releases its
    /// conversation; an unknown token does nothing.</summary>
    procedure CloseSession(const AToken: string);
    /// <summary>Takes the session of that token out of the dictionary
    /// without freeing it and puts it among the retired ones. Called with
    /// the lock held.</summary>
    procedure Retire(const AToken: string);
    /// <summary>Frees the retired sessions older than
    /// <c>HELPCHAT_REMOTE_RETIRE_SECONDS</c>, or all of them. Called with
    /// the lock held.</summary>
    procedure PurgeRetired(const AAll: Boolean);
    /// <summary>What <c>Stop</c> does, not virtual: the destructor calls
    /// it.</summary>
    procedure Shutdown;
  strict protected
    /// <summary>Looks the token up in the dictionary, under the lock. The
    /// session returned is used outside it: one that ends meanwhile is
    /// retired, not freed, so the request that found it can finish.</summary>
    function SessionByToken(const AToken: string): THelpChatServerSession; override;
    /// <summary>The three routes of a server: <c>POST /session</c> (200 with
    /// the session, 403 refused, 503 full - the body is
    /// <c>{"error": reason}</c>), <c>POST /session/end</c> (always 200) and
    /// <c>GET /health</c>.</summary>
    function HandleRoute(const ADocument: string; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo): Boolean; override;
    /// <summary>The host of the page is a client somewhere else: its own channel
    /// answers these, never the server.</summary>
    function HandleUiCommand(const ASession: THelpChatServerSession;
      const ACommand: string): Boolean; override;
    /// <summary>The engine is shared by every session: no client may switch
    /// its model for everybody. The list is still served, read-only
    /// (<c>GET /api/assistants</c>, a path that kept its name of before 1.7),
    /// and <c>POST /api/assistant/select</c> answers 403.</summary>
    function CanSelectModel: Boolean; override;
    /// <summary>False, for the same reason: the language is a setting of the
    /// one engine, and the page of every session is rendered in it.</summary>
    function CanSelectLanguage: Boolean; override;
    /// <summary>Hands a line to <c>OnLog</c>, on the calling thread; nothing
    /// when no handler is set.</summary>
    procedure Log(const AText: string); overload;
    procedure Log(const AFormat: string; const AArgs: array of const); overload;
  public
    /// <summary>Port 8080 on every interface (<c>0.0.0.0</c>), memory storage,
    /// the session folder <c>sessions</c> next to the executable. The engine
    /// is the one every session will share; it is started by
    /// <c>Start</c>.</summary>
    constructor Create(const AEngine: THelpChatEngine; const AOwnsEngine: Boolean = False); override;
    /// <summary>Stops the server, saving the open conversations, before the
    /// sessions are freed.</summary>
    destructor Destroy; override;

    /// <summary>Starts the engine, the listener and the sweeper. Raises
    /// <c>EHelpChatError</c> when no application key is configured - a server
    /// open to whoever finds it would spend the model budget of its owner -
    /// or when the port cannot be bound. Creates the session folder when
    /// storage is on disk.</summary>
    procedure Start; override;
    /// <summary>Stops the sweeper and the listener, then saves every open
    /// conversation (disk storage) and drops the sessions. The engine is left
    /// running, and the conversations stay in its store. Safe to call
    /// twice.</summary>
    procedure Stop; override;
    /// <summary>Ends the sessions idle for longer than <c>IdleMinutes</c>,
    /// persisting their conversation first when storage is on disk. The
    /// sweeper calls it; it may be called from any thread.</summary>
    procedure Sweep;
    /// <summary>Sessions currently open.</summary>
    function SessionCount: Integer;
    /// <summary>Keys accepted from clients; empty = the server refuses to start.
    /// One key per application, not the model's API key. Compared exactly,
    /// case included. Fill it before <c>Start</c>: the list itself is not
    /// locked against a change made while requests are served.</summary>
    property AppKeys: TStringList read FAppKeys;
    /// <summary>Whether a conversation survives the last session on it: see
    /// <see cref="THelpChatSessionStorage" />. Only conversations keyed by
    /// user can be found again; an anonymous one is saved too, under a key
    /// nobody will present twice.</summary>
    property Storage: THelpChatSessionStorage read FStorage write FStorage default hssMemory;
    /// <summary>Folder of the conversation files when Storage is hssDisk.</summary>
    property SessionFolder: string read FSessionFolder write FSessionFolder;
    /// <summary>A session untouched for this long is ended (0 = never).</summary>
    property IdleMinutes: Integer read GetIdleMinutes write SetIdleMinutes default HELPCHAT_REMOTE_DEF_IDLE_MINUTES;
    /// <summary>The same limit in seconds, which is how it is kept.</summary>
    property IdleSeconds: Integer read FIdleSeconds write FIdleSeconds;
    /// <summary>Sessions open at once before <c>POST /session</c> answers
    /// 503; 0 = no limit. Counts sessions, not users: the same user on two
    /// devices is two.</summary>
    property MaxSessions: Integer read FMaxSessions write FMaxSessions default HELPCHAT_REMOTE_DEF_MAX_SESSIONS;
    /// <summary>Who may open a session, and on which conversation: see
    /// <see cref="THelpChatAuthenticateEvent" />. Without it the application
    /// key alone is checked and the user id is taken on trust.</summary>
    property OnAuthenticate: THelpChatAuthenticateEvent read FOnAuthenticate write FOnAuthenticate;
    /// <summary>Receives the log lines, on the thread that produced them: see
    /// <see cref="THelpChatServerLogEvent" />.</summary>
    property OnLog: THelpChatServerLogEvent read FOnLog write FOnLog;
  end;

/// <summary>A file name for an arbitrary conversation key: readable when it can
/// be, always unambiguous (a hash is appended when characters were replaced).</summary>
function HelpChatKeyToFileName(const AKey: string): string;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.DateUtils,
  HelpChatAI.Messages,
  HelpChatAI.Store;

// The hash below wraps around on purpose: overflow checking off just here.
{$IFOPT Q+}{$DEFINE HC_QON}{$ENDIF}
{$Q-}
function HelpChatKeyToFileName(const AKey: string): string;
const
  CMaxLen = 60;
var
  LChar: Char;
  LHash: Cardinal;
  LClean: string;
  LChanged: Boolean;
begin
  LClean := '';
  LChanged := False;
  LHash := 2166136261; // FNV-1a over the original key
  for LChar in AKey do
  begin
    LHash := (LHash xor Cardinal(Ord(LChar))) * 16777619;
    // No dot survives either: '..' in a file name is never worth the argument.
    if CharInSet(LChar, ['a'..'z', 'A'..'Z', '0'..'9', '-', '_']) then
      LClean := LClean + LChar
    else
    begin
      LClean := LClean + '_';
      LChanged := True;
    end;
  end;
  if LClean.Length > CMaxLen then
  begin
    LClean := LClean.Substring(0, CMaxLen);
    LChanged := True;
  end;
  Result := LClean.ToLower;
  if LChanged then
    Result := Result + '-' + IntToHex(LHash, 8).ToLower;
  Result := Result + '.json';
end;
{$IFDEF HC_QON}{$Q+}{$UNDEF HC_QON}{$ENDIF}

{ THelpChatSessionSweeper }

constructor THelpChatSessionSweeper.Create(const AServer: THelpChatRemoteServer);
begin
  FServer := AServer;
  FWakeUp := TEvent.Create(nil, True, False, '');
  inherited Create(False);
end;

destructor THelpChatSessionSweeper.Destroy;
begin
  FWakeUp.Free;
  inherited;
end;

procedure THelpChatSessionSweeper.Stop;
begin
  Terminate;
  FWakeUp.SetEvent;
end;

procedure THelpChatSessionSweeper.Execute;
begin
  NameThreadForDebugging('HelpChat sessions');
  while not Terminated do
  begin
    if FWakeUp.WaitFor(HELPCHAT_REMOTE_SWEEP_SECONDS * 1000) = wrSignaled then
      Break;
    if Terminated then
      Break;
    try
      FServer.Sweep;
    except
      // A sweep that fails must never take the server down.
    end;
  end;
end;

{ THelpChatRemoteServer }

constructor THelpChatRemoteServer.Create(const AEngine: THelpChatEngine; const AOwnsEngine: Boolean);
begin
  inherited Create(AEngine, AOwnsEngine);
  FLock := TCriticalSection.Create;
  // The sessions own their objects; the dictionary is keyed by their secret.
  FSessions := TObjectDictionary<string, THelpChatServerSession>.Create([doOwnsValues]);
  FRetired := TList<TPair<TDateTime, THelpChatServerSession>>.Create;
  FAppKeys := TStringList.Create;
  FAppKeys.CaseSensitive := True;
  FStorage := hssMemory;
  FIdleSeconds := HELPCHAT_REMOTE_DEF_IDLE_MINUTES * 60;
  FMaxSessions := HELPCHAT_REMOTE_DEF_MAX_SESSIONS;
  Port := HELPCHAT_REMOTE_DEF_PORT;
  // A server is reached from outside; the local one stays on 127.0.0.1.
  BindIP := '0.0.0.0';
  FSessionFolder := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'sessions');
end;

destructor THelpChatRemoteServer.Destroy;
begin
  // Not Stop: it is virtual, and a descendant's would run after its own
  // destructor freed what it uses.
  Shutdown;
  FreeAndNil(FRetired);
  FreeAndNil(FSessions);
  FreeAndNil(FAppKeys);
  FreeAndNil(FLock);
  inherited;
end;

function THelpChatRemoteServer.GetIdleMinutes: Integer;
begin
  Result := FIdleSeconds div 60;
end;

procedure THelpChatRemoteServer.SetIdleMinutes(const Value: Integer);
begin
  FIdleSeconds := Value * 60;
end;

procedure THelpChatRemoteServer.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure THelpChatRemoteServer.Log(const AFormat: string; const AArgs: array of const);
begin
  Log(Format(AFormat, AArgs));
end;

procedure THelpChatRemoteServer.Start;
begin
  if IsActive then
    Exit;
  if FAppKeys.Count = 0 then
    raise EHelpChatError.Create('HelpChat server: no application key configured. ' +
      'Add at least one key ("Keys" in the configuration file): without it any ' +
      'client on the network could use your model budget.');
  if FStorage = hssDisk then
    TDirectory.CreateDirectory(FSessionFolder);
  inherited Start;
  FSweeper := THelpChatSessionSweeper.Create(Self);
  // Said once, where whoever runs the server reads it: without a handler a
  // client holding an application key gets the conversation of whichever
  // user it names.
  if not Assigned(FOnAuthenticate) then
    Log('no OnAuthenticate handler: the user a client declares is taken on trust');
  if FStorage = hssDisk then
    Log('listening on %s:%d (%d application key(s), conversations in %s)',
      [BindIP, BoundPort, FAppKeys.Count, FSessionFolder])
  else
    Log('listening on %s:%d (%d application key(s), conversations in memory)',
      [BindIP, BoundPort, FAppKeys.Count]);
end;

procedure THelpChatRemoteServer.Stop;
begin
  Shutdown;
end;

procedure THelpChatRemoteServer.Retire(const AToken: string);
var
  LPair: TPair<string, THelpChatServerSession>;
begin
  LPair := FSessions.ExtractPair(AToken);
  if Assigned(LPair.Value) then
    FRetired.Add(TPair<TDateTime, THelpChatServerSession>.Create(Now, LPair.Value));
end;

procedure THelpChatRemoteServer.PurgeRetired(const AAll: Boolean);
var
  I: Integer;
  LLimit: TDateTime;
begin
  LLimit := IncSecond(Now, -HELPCHAT_REMOTE_RETIRE_SECONDS);
  for I := FRetired.Count - 1 downto 0 do
    if AAll or (FRetired[I].Key < LLimit) then
    begin
      FRetired[I].Value.Free;
      FRetired.Delete(I);
    end;
end;

procedure THelpChatRemoteServer.Shutdown;
var
  LSession: THelpChatServerSession;
begin
  if not Assigned(FLock) then // already torn down
    Exit;
  // The sweeper first, and waited for: it must not expire a session while
  // the ones still open are being saved below.
  if Assigned(FSweeper) then
  begin
    FSweeper.Stop;
    FSweeper.WaitFor;
    FreeAndNil(FSweeper);
  end;
  StopListening;
  // Whatever is still open is persisted before the process goes away. The
  // listener has stopped, so no request holds a session any more.
  FLock.Enter;
  try
    if FStorage = hssDisk then
      for LSession in FSessions.Values do
        SaveConversation(LSession.ConversationKey);
    FSessions.Clear;
    PurgeRetired(True);
  finally
    FLock.Leave;
  end;
end;

function THelpChatRemoteServer.SessionCount: Integer;
begin
  FLock.Enter;
  try
    Result := FSessions.Count;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRemoteServer.CheckAppKey(const AKey: string): Boolean;
var
  I: Integer;
begin
  if AKey = '' then
    Exit(False);
  FLock.Enter;
  try
    for I := 0 to FAppKeys.Count - 1 do
      if FAppKeys[I] = AKey then
        Exit(True);
  finally
    FLock.Leave;
  end;
  Result := False;
end;

function THelpChatRemoteServer.ConversationFile(const AConversationKey: string): string;
begin
  Result := TPath.Combine(FSessionFolder, HelpChatKeyToFileName(AConversationKey));
end;

procedure THelpChatRemoteServer.LoadConversation(const AConversationKey: string);
begin
  // Only when nothing is in memory for that key: a second device of the same
  // user joins the live conversation instead of reloading an older copy.
  if (FStorage <> hssDisk) or (Engine.Store.Count(AConversationKey) > 0) then
    Exit;
  try
    Engine.Store.LoadFromFile(AConversationKey, ConversationFile(AConversationKey),
      Engine.Settings.ConversationMaxAgeDays);
  except
    on E: Exception do
      Log('cannot read the conversation %s: %s', [AConversationKey, E.Message]);
  end;
end;

procedure THelpChatRemoteServer.SaveConversation(const AConversationKey: string);
begin
  if FStorage <> hssDisk then
    Exit;
  try
    Engine.Store.SaveToFile(AConversationKey, ConversationFile(AConversationKey));
  except
    on E: Exception do
      Log('cannot write the conversation %s: %s', [AConversationKey, E.Message]);
  end;
end;

function THelpChatRemoteServer.KeyInUse(const AConversationKey, AExceptToken: string): Boolean;
var
  LPair: TPair<string, THelpChatServerSession>;
begin
  for LPair in FSessions do
    if (LPair.Key <> AExceptToken) and (LPair.Value.ConversationKey = AConversationKey) then
      Exit(True);
  Result := False;
end;

procedure THelpChatRemoteServer.ReleaseConversation(const AConversationKey, AExceptToken: string);
begin
  // Called with the lock held. Another live session on the same conversation
  // (the same user from a second device) keeps it in memory.
  if KeyInUse(AConversationKey, AExceptToken) then
    Exit;
  SaveConversation(AConversationKey);
  Engine.Clear(AConversationKey);
end;

function THelpChatRemoteServer.SessionByToken(const AToken: string): THelpChatServerSession;
begin
  Result := nil;
  if AToken = '' then
    Exit;
  FLock.Enter;
  try
    FSessions.TryGetValue(AToken, Result);
  finally
    FLock.Leave;
  end;
end;

function THelpChatRemoteServer.OpenSession(ARequestInfo: TIdHTTPRequestInfo;
  out AJson: string; out AError: string): Boolean;
var
  LBody, LAppKey, LUserId, LUserToken, LId, LToken, LKey: string;
  LAllowed: Boolean;
  LSession: THelpChatServerSession;
  LRoot: TJSONObject;
begin
  AJson := '';
  AError := '';
  LBody := ARequestInfo.FormParams;
  LAppKey := ARequestInfo.RawHeaders.Values[HELPCHAT_KEY_HEADER];
  if LAppKey = '' then
    LAppKey := FormField(LBody, 'appKey');
  if not CheckAppKey(LAppKey) then
  begin
    AError := 'unknown application key';
    Exit(False);
  end;

  LUserId := Trim(FormField(LBody, 'user'));
  LUserToken := FormField(LBody, 'userToken');
  // Two secrets on purpose: the id is what the log and the conversation key
  // of an anonymous session show, the token is what opens the session and is
  // never written anywhere.
  LId := NewSecret;
  LToken := NewSecret;
  if LUserId <> '' then
    LKey := HELPCHAT_KEY_USER_PREFIX + LUserId
  else
    LKey := HELPCHAT_KEY_SESSION_PREFIX + LId;

  // The application decides who may speak and on which conversation.
  LAllowed := True;
  if Assigned(FOnAuthenticate) then
    FOnAuthenticate(Self, LAppKey, LUserId, LUserToken, LAllowed, LKey);
  if not LAllowed or (LKey = '') then
  begin
    AError := 'not authorized';
    Exit(False);
  end;

  FLock.Enter;
  try
    if (FMaxSessions > 0) and (FSessions.Count >= FMaxSessions) then
    begin
      AError := 'too many sessions';
      Exit(False);
    end;
    LoadConversation(LKey);
    LSession := THelpChatServerSession.Create(LId, LToken, LUserId, LKey);
    // Where this client listens for what its page asks of it.
    LSession.SetUiEndpoint(FormField(LBody, 'uiBase'), FormField(LBody, 'uiToken'));
    LSession.SetThemeCss(FormField(LBody, 'themeCss'));
    LSession.SetAssistant(FormField(LBody, 'assistantName'),
      FormField(LBody, 'assistantIcon'));
    FSessions.Add(LToken, LSession);
  finally
    FLock.Leave;
  end;

  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('session', LId);
    LRoot.AddPair('token', LToken);
    LRoot.AddPair('pollMs', TJSONNumber.Create(PollIntervalMs));
    LRoot.AddPair('maxPolls', TJSONNumber.Create(MaxPolls));
    // The language of the server's engine: it is the one the page of this
    // session will be rendered in, whatever the client is configured with.
    LRoot.AddPair('lang', HelpChatLanguageCode(Engine.Settings.Language));
    AJson := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
  // The host channel is worth logging: without it nothing the page asks of
  // its host arrives (Escape closes nothing), and that is the first thing
  // anyone will ask about.
  if LSession.UiBase <> '' then
    Log('session %s opened (user "%s", conversation %s, host channel %s)',
      [LId, LUserId, LKey, LSession.UiBase])
  else
    Log('session %s opened (user "%s", conversation %s, no host channel)',
      [LId, LUserId, LKey]);
  Result := True;
end;

procedure THelpChatRemoteServer.CloseSession(const AToken: string);
var
  LSession: THelpChatServerSession;
  LKey, LId: string;
begin
  FLock.Enter;
  try
    if not FSessions.TryGetValue(AToken, LSession) then
      Exit;
    LKey := LSession.ConversationKey;
    LId := LSession.Id;
    Retire(AToken);                // a request may still be using it
    ReleaseConversation(LKey, AToken);
    PurgeRetired(False);
  finally
    FLock.Leave;
  end;
  Log('session %s closed', [LId]);
end;

procedure THelpChatRemoteServer.Sweep;
var
  LPair: TPair<string, THelpChatServerSession>;
  LDead: TArray<string>;
  LKeys: TArray<string>;
  LToken: string;
  LLimit: TDateTime;
  I: Integer;
begin
  FLock.Enter;
  try
    PurgeRetired(False);
  finally
    FLock.Leave;
  end;
  if FIdleSeconds <= 0 then
    Exit;
  LLimit := IncSecond(Now, -FIdleSeconds);
  FLock.Enter;
  try
    // Collected first and removed after: a dictionary cannot lose entries
    // while it is being enumerated. The key is copied with the token because
    // the session leaves the dictionary.
    SetLength(LDead, 0);
    SetLength(LKeys, 0);
    for LPair in FSessions do
      if LPair.Value.LastAccess < LLimit then
      begin
        LDead := LDead + [LPair.Key];
        LKeys := LKeys + [LPair.Value.ConversationKey];
      end;
    for I := 0 to High(LDead) do
    begin
      LToken := LDead[I];
      Retire(LToken);
      ReleaseConversation(LKeys[I], LToken);
    end;
  finally
    FLock.Leave;
  end;
  if Length(LDead) > 0 then
    Log('%d idle session(s) expired', [Length(LDead)]);
end;

function THelpChatRemoteServer.CanSelectModel: Boolean;
begin
  Result := False;
end;

function THelpChatRemoteServer.CanSelectLanguage: Boolean;
begin
  // The language lives in the settings of the one engine every session
  // shares: a user switching it would switch it for everybody.
  Result := False;
end;

function THelpChatRemoteServer.HandleUiCommand(const ASession: THelpChatServerSession;
  const ACommand: string): Boolean;
begin
  // The window to close is on the client machine: its own host channel takes
  // these. Reaching the server means the client has no channel — nothing to do.
  Result := False;
end;

function THelpChatRemoteServer.HandleRoute(const ADocument: string;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo): Boolean;
var
  LJson, LError: string;
  LRoot: TJSONObject;
  LErrorJson: TJSONString;
begin
  Result := True;
  if (ADocument = HELPCHAT_SESSION_PATH) and (ARequestInfo.CommandType = hcPOST) then
  begin
    if OpenSession(ARequestInfo, LJson, LError) then
      WriteJson(AResponseInfo, LJson)
    else
    begin
      Log('session refused: %s', [LError]);
      if LError = 'too many sessions' then
        AResponseInfo.ResponseNo := 503
      else
        AResponseInfo.ResponseNo := 403;
      LErrorJson := TJSONString.Create(LError);
      try
        WriteJson(AResponseInfo, Format('{"error":%s}', [LErrorJson.ToJSON]));
      finally
        LErrorJson.Free;
      end;
    end;
  end

  else if (ADocument = HELPCHAT_SESSION_END_PATH) and (ARequestInfo.CommandType = hcPOST) then
  begin
    CloseSession(ARequestInfo.RawHeaders.Values[HELPCHAT_TOKEN_HEADER]);
    WriteJson(AResponseInfo, '{}');
  end

  else if (ADocument = '/health') and (ARequestInfo.CommandType = hcGET) then
  begin
    LRoot := TJSONObject.Create;
    try
      LRoot.AddPair('status', 'ok');
      LRoot.AddPair('version', HELPCHAT_VERSION);
      LRoot.AddPair('sessions', TJSONNumber.Create(SessionCount));
      LRoot.AddPair('provider', Engine.Settings.Provider);
      LRoot.AddPair('index', TJSONNumber.Create(Engine.DocIndex.Count));
      WriteJson(AResponseInfo, LRoot.ToJSON);
    finally
      LRoot.Free;
    end;
  end

  else
    Result := False;
end;

end.
