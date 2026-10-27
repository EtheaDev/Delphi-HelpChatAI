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
  HELPCHAT_REMOTE_DEF_PORT = 8080;
  HELPCHAT_REMOTE_DEF_IDLE_MINUTES = 120;
  HELPCHAT_REMOTE_DEF_MAX_SESSIONS = 500;
  HELPCHAT_REMOTE_SWEEP_SECONDS = 30;
  /// <summary>Prefix of the conversation key of a known user, and of an
  /// anonymous session.</summary>
  HELPCHAT_KEY_USER_PREFIX = 'u:';
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
  /// </summary>
  THelpChatAuthenticateEvent = procedure(Sender: TObject; const AAppKey, AUserId,
    AUserToken: string; var AAllowed: Boolean; var AConversationKey: string) of object;

  THelpChatServerLogEvent = procedure(Sender: TObject; const AText: string) of object;

  THelpChatRemoteServer = class;

  /// <summary>Expires idle sessions without the server having to be called.</summary>
  THelpChatSessionSweeper = class(TThread)
  strict private
    FServer: THelpChatRemoteServer;
    FWakeUp: TEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(const AServer: THelpChatRemoteServer);
    destructor Destroy; override;
    procedure Stop;
  end;

  THelpChatRemoteServer = class(THelpChatHttpServerBase)
  strict private
    FSessions: TObjectDictionary<string, THelpChatServerSession>;
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
    function CheckAppKey(const AKey: string): Boolean;
    function ConversationFile(const AConversationKey: string): string;
    function KeyInUse(const AConversationKey, AExceptToken: string): Boolean;
    procedure LoadConversation(const AConversationKey: string);
    procedure SaveConversation(const AConversationKey: string);
    procedure ReleaseConversation(const AConversationKey, AExceptToken: string);
    function OpenSession(ARequestInfo: TIdHTTPRequestInfo; out AJson: string;
      out AError: string): Boolean;
    procedure CloseSession(const AToken: string);
  strict protected
    function SessionByToken(const AToken: string): THelpChatServerSession; override;
    function HandleRoute(const ADocument: string; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo): Boolean; override;
    /// <summary>The host of the page is a client somewhere else: its own channel
    /// answers these, never the server.</summary>
    function HandleUiCommand(const ASession: THelpChatServerSession;
      const ACommand: string): Boolean; override;
    procedure Log(const AText: string); overload;
    procedure Log(const AFormat: string; const AArgs: array of const); overload;
  public
    constructor Create(const AEngine: THelpChatEngine; const AOwnsEngine: Boolean = False); override;
    destructor Destroy; override;

    procedure Start; override;
    procedure Stop; override;
    /// <summary>Ends the sessions idle for longer than <c>IdleMinutes</c>,
    /// persisting their conversation first when storage is on disk.</summary>
    procedure Sweep;
    /// <summary>Sessions currently open.</summary>
    function SessionCount: Integer;
    /// <summary>Keys accepted from clients; empty = the server refuses to start.
    /// One key per application, not the model's API key.</summary>
    property AppKeys: TStringList read FAppKeys;
    property Storage: THelpChatSessionStorage read FStorage write FStorage default hssMemory;
    /// <summary>Folder of the conversation files when Storage is hssDisk.</summary>
    property SessionFolder: string read FSessionFolder write FSessionFolder;
    /// <summary>A session untouched for this long is ended (0 = never).</summary>
    property IdleMinutes: Integer read GetIdleMinutes write SetIdleMinutes default HELPCHAT_REMOTE_DEF_IDLE_MINUTES;
    /// <summary>The same limit in seconds, which is how it is kept.</summary>
    property IdleSeconds: Integer read FIdleSeconds write FIdleSeconds;
    property MaxSessions: Integer read FMaxSessions write FMaxSessions default HELPCHAT_REMOTE_DEF_MAX_SESSIONS;
    property OnAuthenticate: THelpChatAuthenticateEvent read FOnAuthenticate write FOnAuthenticate;
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
  Stop;
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
  if FStorage = hssDisk then
    Log('listening on %s:%d (%d application key(s), conversations in %s)',
      [BindIP, BoundPort, FAppKeys.Count, FSessionFolder])
  else
    Log('listening on %s:%d (%d application key(s), conversations in memory)',
      [BindIP, BoundPort, FAppKeys.Count]);
end;

procedure THelpChatRemoteServer.Stop;
var
  LSession: THelpChatServerSession;
begin
  if not Assigned(FLock) then // already torn down
    Exit;
  if Assigned(FSweeper) then
  begin
    FSweeper.Stop;
    FSweeper.WaitFor;
    FreeAndNil(FSweeper);
  end;
  inherited Stop;
  // Whatever is still open is persisted before the process goes away.
  FLock.Enter;
  try
    if FStorage = hssDisk then
      for LSession in FSessions.Values do
        SaveConversation(LSession.ConversationKey);
    FSessions.Clear;
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
    LRoot.AddPair('lang', HelpChatLanguageCode(Engine.Settings.Language));
    AJson := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
  // The host channel is worth logging: without it the page has no ✕, and that
  // is the first thing anyone will ask about.
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
    FSessions.Remove(AToken);      // the session object is owned and freed here
    ReleaseConversation(LKey, AToken);
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
  if FIdleSeconds <= 0 then
    Exit;
  LLimit := IncSecond(Now, -FIdleSeconds);
  FLock.Enter;
  try
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
      FSessions.Remove(LToken);
      ReleaseConversation(LKeys[I], LToken);
    end;
  finally
    FLock.Leave;
  end;
  if Length(LDead) > 0 then
    Log('%d idle session(s) expired', [Length(LDead)]);
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
