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
///  The transport of a client whose engine lives on a HelpChat server: no
///  engine, no documentation index and no model key in this process, only the
///  panel pointed at the server. The component above it does not change — same
///  interface, same page, same screen context.
///
///  What it does: opens a session with the application key (and the user, when
///  the application knows who is asking), hands the screen context and the
///  colours to that session, and gives the panel the URL to load. Because the
///  page now lives on another origin it cannot reach its host any more, so the
///  transport also opens a <see cref="THelpChatHostChannel" /> on 127.0.0.1 and
///  tells the server where it is: that is how Escape in the page still closes
///  the window, and how page and application will exchange files.
///
///  Context, theme and assistant name are pushed synchronously, with the short
///  timeout of <c>Settings.Remote.TimeoutMs</c>: they must be on the server
///  before the question the user is about to ask, and a slow server must not
///  freeze the application. A push that fails is silent — the chat works, it
///  just does not know which screen the user is on. Opening the session is
///  not: a server that cannot be reached or refuses raises
///  <c>EHelpChatError</c>, at the moment the user asks for help.
///
///  What stays on the client and does not travel: the actions, the enabled
///  commands, the PDF handler and the <c>Profile</c> of the component. The
///  server answers with its own engine and its own configuration.
///
///  Every method is meant for the main thread, where the component calls it;
///  the HTTP calls block it for at most the timeout. The lock only guards the
///  values the getters hand out.
/// </summary>
unit HelpChatAI.Transport.Remote;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  HelpChatAI.Types,
  HelpChatAI.Theme,
  HelpChatAI.Settings,
  HelpChatAI.Engine,
  HelpChatAI.Commands,
  HelpChatAI.Actions,
  HelpChatAI.Transport,
  HelpChatAI.Server.HostChannel;

const
  /// <summary>A session the server was not called on for this long is
  /// checked (one short call) before the panel is shown again: the server
  /// may have expired it meanwhile.</summary>
  HELPCHAT_REMOTE_CHECK_SECONDS = 60;

type
  /// <summary>
  ///  <see cref="IHelpChatTransport" /> over a HelpChat server. Reference
  ///  counted: the component holds the interface, and releasing it ends the
  ///  session and closes the host channel. One transport is one session on
  ///  the server, so two assistants of one application are two sessions - on
  ///  one conversation when the application declares a user
  ///  (<c>u:&lt;user&gt;</c>), on two unrelated ones when it does not.
  /// </summary>
  THelpChatRemoteTransport = class(TInterfacedObject, IHelpChatTransport)
  strict private
    FBaseUrl: string;
    FAppKey: string;
    FUserId: string;
    FUserToken: string;
    FTimeoutMs: Integer;
    FUseHostChannel: Boolean;
    FLock: TCriticalSection;
    FChannel: THelpChatHostChannel;
    FStarted: Boolean;
    FSessionId: string;
    FToken: string;
    FPollIntervalMs: Integer;
    FMaxPolls: Integer;
    FContext: THelpChatContext;
    FContextSent: Boolean;
    FTheme: THelpChatTheme;
    FThemeCssSent: string;
    FAssistantName: string;
    FAssistantIcon: string;
    FEnabledCommands: THelpChatCommands;
    FActions: IHelpChatActionInvoker;
    FAssistantSent: Boolean;
    // When the server last answered a call of this session: older than
    // HELPCHAT_REMOTE_CHECK_SECONDS and the session is checked before the
    // panel is shown again.
    FLastContact: TDateTime;
    FOnUiCommand: THelpChatUiCommandEvent;
    FOnPdfRequest: THelpChatPdfRequestEvent;
    /// <summary>One form-encoded POST to the server, with the application key
    /// and, once there is one, the session token. Returns the HTTP status and
    /// the body; raises what the HTTP client raises when the server cannot be
    /// reached or does not answer within <c>TimeoutMs</c>. A client per call:
    /// these are a handful of requests in the life of a panel.</summary>
    function Post(const APath, ABody: string; out AResponse: string): Integer;
    /// <summary>A call of the open session. A 403 means the server no longer
    /// knows the token (it expired the session, or was restarted): a new
    /// session is opened and the call made once more, so the transport never
    /// keeps a dead token. True when the server took the call; raises what
    /// <c>Post</c> and <c>OpenSession</c> raise.</summary>
    function SessionCall(const APath, ABody: string): Boolean;
    /// <summary>Starts the transport and opens the session when there is
    /// none. Raises <c>EHelpChatError</c> like <c>OpenSession</c>.</summary>
    procedure EnsureSession;
    /// <summary><c>POST /session</c>: user, theme, assistant name and icon and
    /// the address of the host channel go with it, so the first page is
    /// already complete. Raises <c>EHelpChatError</c> naming the server when
    /// it is unreachable, refuses (the reason it gave, or the status) or
    /// answers something else. The context is not in the body: it is marked
    /// as not sent, for the next <c>SetContext</c>.</summary>
    procedure OpenSession;
    /// <summary><c>POST /session/end</c>, best effort, then forgets the
    /// token whatever the server said.</summary>
    procedure EndSession;
    /// <summary>The three pushes: nothing without a session, and a failure
    /// of the call is swallowed. They go through <c>SessionCall</c>, so a
    /// session the server lost is opened again on the way.</summary>
    procedure PushContext;
    procedure PushTheme;
    procedure PushAssistant;
  public
    /// <summary>For code that has no settings object: the root URL of the
    /// server (trailing slashes dropped) and the application key, in clear.
    /// No user, the default timeout, host channel on. Touches no
    /// network.</summary>
    constructor Create(const ABaseUrl, AAppKey: string); overload;
    /// <summary>The usual way: everything comes from <c>Settings.Remote</c>, so
    /// an installed application moves to a server by editing helpchatai.json.
    /// The two secrets are resolved here, once, through
    /// <c>OnDecryptSecret</c> of the settings <c>ARemote</c> belongs to; the
    /// settings are not kept.</summary>
    constructor Create(const ARemote: THelpChatRemoteSettings); overload;
    /// <summary>Ends the session (one short call to the server, best effort)
    /// and closes the host channel.</summary>
    destructor Destroy; override;

    // IHelpChatTransport
    /// <summary>Opens the host channel and nothing else: no session, no
    /// network. An application whose help server is down still starts.
    /// Raises <c>EHelpChatError</c> only when there is no server URL; a
    /// channel that cannot listen is given up without a word.</summary>
    procedure Start;
    /// <summary>Ends the session and closes the host channel. What was set
    /// (context, theme, assistant) is kept for a later <c>Start</c>.</summary>
    procedure Stop;
    /// <summary>True once started - "ready", not "connected": see
    /// <see cref="HasSession" />.</summary>
    function IsActive: Boolean;
    /// <summary>Opens the session when there is none, so unlike the local
    /// transport it may block for the timeout and raises
    /// <c>EHelpChatError</c> when the server cannot be reached or refuses.
    /// The URL carries the session token, so it changes when the session had
    /// to be opened again (the server expired it): a host that shows the
    /// panel compares it with the URL its page was loaded from.</summary>
    function GetPanelUrl: string;
    /// <summary>The origin of the server, known without any call: the host
    /// channel allows this origin alone.</summary>
    function GetPanelOrigin: string;
    /// <summary>Posts the context to the session when it differs from the
    /// one sent last - one round trip per screen, not per opening. On a
    /// started transport this opens the session if needed, and so may raise
    /// like <see cref="GetPanelUrl" />.</summary>
    procedure SetContext(const AContext: THelpChatContext);
    function GetContext: THelpChatContext;
    /// <summary>Kept, and posted as CSS when a session is open and the CSS
    /// differs from what the server has. Without a session it travels with
    /// the request that opens one.</summary>
    procedure SetTheme(const ATheme: THelpChatTheme);
    function GetTheme: THelpChatTheme;
    /// <summary>Kept, and posted when a session is open and something
    /// changed; otherwise it travels with the request that opens one. The
    /// name goes unresolved: the server renders an empty one in the language
    /// of its page.</summary>
    procedure SetAssistant(const AName, AIconDataUri: string);
    /// <summary>Remembered and never sent: a session of the server accepts
    /// the commands the server gives every session.</summary>
    procedure SetEnabledCommands(const ACommands: THelpChatCommands);
    function GetEnabledCommands: THelpChatCommands;
    /// <summary>Remembered and never used: the model runs on the server and
    /// the calls of an action do not travel back yet, so actions registered
    /// on a component with a remote engine are never offered to the
    /// model.</summary>
    procedure SetActions(const AActions: IHelpChatActionInvoker);
    function GetActions: IHelpChatActionInvoker;
    function GetAssistantName: string;
    function GetAssistantIcon: string;
    /// <summary>Always nil: the engine is on the server.</summary>
    function GetEngine: THelpChatEngine;
    /// <summary>The handler the host channel delivers to, on the main
    /// thread. With no channel (disabled, or the port could not be bound) it
    /// is kept and never called.</summary>
    procedure SetOnUiCommand(const AHandler: THelpChatUiCommandEvent);
    /// <summary>Kept and never called: the server answers 501 to
    /// <c>/api/pdf</c>, since the document would be built where there is no
    /// screen to save it from.</summary>
    procedure SetOnPdfRequest(const AHandler: THelpChatPdfRequestEvent);

    /// <summary>True once a conversation is open on the server. It says what
    /// this side believes: a session the server expired or lost in a restart
    /// counts here until the next call finds out - <c>GetPanelUrl</c> checks
    /// one that was quiet for <c>HELPCHAT_REMOTE_CHECK_SECONDS</c>.</summary>
    function HasSession: Boolean;
    /// <summary>Id of the session on the server (diagnostics).</summary>
    property SessionId: string read FSessionId;
    /// <summary>The loopback channel of the page, nil when disabled or unavailable.</summary>
    property HostChannel: THelpChatHostChannel read FChannel;
    /// <summary>Who is asking; empty = anonymous. Read when the session is
    /// opened: a change afterwards applies to the next session.</summary>
    property UserId: string read FUserId write FUserId;
    /// <summary>The credential sent with <c>UserId</c>, for the
    /// <c>OnAuthenticate</c> of the server; in clear, already resolved.</summary>
    property UserToken: string read FUserToken write FUserToken;
    /// <summary>Connection, send and response timeout of every call to the
    /// server, each: the main thread waits that long at worst.</summary>
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs;
    /// <summary>False = no loopback listener: the page is served but nothing
    /// it asks of its host arrives. Read by <c>Start</c>.</summary>
    property UseHostChannel: Boolean read FUseHostChannel write FUseHostChannel;
  end;

/// <summary>Percent-encodes a value for an application/x-www-form-urlencoded
/// body, the way the HelpChat servers decode it (a space is %20, never '+').</summary>
function HelpChatFormEncode(const AValue: string): string;
/// <summary>scheme://host:port of a URL (what a browser calls its origin).</summary>
function HelpChatUrlOrigin(const AUrl: string): string;

implementation

uses
  System.JSON,
  System.DateUtils,
  System.NetConsts,
  System.Net.HttpClient,
  System.Net.URLClient,
  HelpChatAI.Messages,
  HelpChatAI.Panel;

function HelpChatFormEncode(const AValue: string): string;
var
  LBytes: TBytes;
  I: Integer;
  LBuilder: TStringBuilder;
begin
  LBytes := TEncoding.UTF8.GetBytes(AValue);
  LBuilder := TStringBuilder.Create(Length(LBytes) * 2);
  try
    for I := 0 to High(LBytes) do
      // Unreserved characters of RFC 3986; everything else, space included,
      // travels as %XX so the decoder never has to guess.
      case LBytes[I] of
        Ord('A')..Ord('Z'), Ord('a')..Ord('z'), Ord('0')..Ord('9'),
        Ord('-'), Ord('_'), Ord('.'), Ord('~'):
          LBuilder.Append(Char(LBytes[I]));
      else
        LBuilder.Append('%').Append(IntToHex(LBytes[I], 2));
      end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function HelpChatUrlOrigin(const AUrl: string): string;
var
  P: Integer;
begin
  Result := AUrl.Trim;
  while Result.EndsWith('/') do
    Result := Result.Substring(0, Result.Length - 1);
  P := Result.IndexOf('//');
  if P < 0 then
    Exit;
  P := Result.IndexOf('/', P + 2);
  if P > 0 then
    Result := Result.Substring(0, P);
end;

// Field by field, and only the fields that are posted: a record with strings
// cannot be compared as memory.
function SameContext(const A, B: THelpChatContext): Boolean;
begin
  Result := (A.ScreenName = B.ScreenName) and (A.ScreenLabel = B.ScreenLabel) and
    (A.ScreenType = B.ScreenType) and (A.HelpKeyword = B.HelpKeyword) and
    (A.HelpContext = B.HelpContext) and (A.FocusedControl = B.FocusedControl);
end;

{ THelpChatRemoteTransport }

constructor THelpChatRemoteTransport.Create(const ABaseUrl, AAppKey: string);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FBaseUrl := ABaseUrl.Trim;
  while FBaseUrl.EndsWith('/') do
    FBaseUrl := FBaseUrl.Substring(0, FBaseUrl.Length - 1);
  FAppKey := AAppKey;
  FTimeoutMs := HELPCHAT_REMOTE_DEF_TIMEOUTMS;
  FUseHostChannel := True;
  FPollIntervalMs := HELPCHAT_DEF_POLL_MS;
  FMaxPolls := HELPCHAT_DEF_MAX_POLLS;
end;

constructor THelpChatRemoteTransport.Create(const ARemote: THelpChatRemoteSettings);
begin
  Create(ARemote.NormalizedBaseUrl, ARemote.ResolveAppKey);
  FUserId := ARemote.ResolveUserId;
  FUserToken := ARemote.ResolveUserToken;
  FUseHostChannel := ARemote.UseHostChannel;
  if ARemote.TimeoutMs > 0 then
    FTimeoutMs := ARemote.TimeoutMs;
end;

destructor THelpChatRemoteTransport.Destroy;
begin
  Stop;
  FLock.Free;
  inherited;
end;

function THelpChatRemoteTransport.Post(const APath, ABody: string; out AResponse: string): Integer;
var
  LClient: THTTPClient;
  LBody: TStringStream;
  LResponse: IHTTPResponse;
begin
  AResponse := '';
  LClient := THTTPClient.Create;
  try
    LClient.ConnectionTimeout := FTimeoutMs;
    LClient.ResponseTimeout := FTimeoutMs;
    LClient.SendTimeout := FTimeoutMs;
    LClient.CustomHeaders[HELPCHAT_KEY_HEADER] := FAppKey;
    if FToken <> '' then
      LClient.CustomHeaders[HELPCHAT_TOKEN_HEADER] := FToken;
    LClient.ContentType := 'application/x-www-form-urlencoded';
    LBody := TStringStream.Create(ABody, TEncoding.UTF8);
    try
      LResponse := LClient.Post(FBaseUrl + APath, LBody);
      Result := LResponse.StatusCode;
      AResponse := LResponse.ContentAsString(TEncoding.UTF8);
    finally
      LBody.Free;
    end;
  finally
    LClient.Free;
  end;
end;

procedure THelpChatRemoteTransport.OpenSession;
var
  LBody, LResponse, LError: string;
  LStatus: Integer;
  LValue: TJSONValue;
  LRoot: TJSONObject;
begin
  LBody := 'user=' + HelpChatFormEncode(FUserId) +
    '&userToken=' + HelpChatFormEncode(FUserToken) +
    '&themeCss=' + HelpChatFormEncode(FTheme.ToCss) +
    '&assistantName=' + HelpChatFormEncode(FAssistantName) +
    '&assistantIcon=' + HelpChatFormEncode(FAssistantIcon);
  if Assigned(FChannel) and FChannel.IsActive then
    LBody := LBody + '&uiBase=' + HelpChatFormEncode(FChannel.GetOrigin) +
      '&uiToken=' + HelpChatFormEncode(FChannel.Token);

  try
    LStatus := Post(HELPCHAT_SESSION_PATH, LBody, LResponse);
  except
    on E: Exception do
      raise EHelpChatError.CreateFmt('HelpChat server %s unreachable: %s', [FBaseUrl, E.Message]);
  end;

  if LStatus <> 200 then
  begin
    // A refusal carries its reason as JSON; anything else (a proxy, another
    // server on that port) is reported by its status code.
    LError := '';
    LValue := TJSONObject.ParseJSONValue(LResponse);
    try
      if LValue is TJSONObject then
        LError := TJSONObject(LValue).GetValue<string>('error', '');
    finally
      LValue.Free;
    end;
    if LError = '' then
      LError := IntToStr(LStatus);
    raise EHelpChatError.CreateFmt('HelpChat server %s refused the session: %s', [FBaseUrl, LError]);
  end;

  LValue := TJSONObject.ParseJSONValue(LResponse);
  try
    if not (LValue is TJSONObject) then
      raise EHelpChatError.CreateFmt('HelpChat server %s: unexpected answer', [FBaseUrl]);
    LRoot := TJSONObject(LValue);
    FSessionId := LRoot.GetValue<string>('session', '');
    FToken := LRoot.GetValue<string>('token', '');
    FPollIntervalMs := LRoot.GetValue<Integer>('pollMs', HELPCHAT_DEF_POLL_MS);
    FMaxPolls := LRoot.GetValue<Integer>('maxPolls', HELPCHAT_DEF_MAX_POLLS);
  finally
    LValue.Free;
  end;
  if FToken = '' then
    raise EHelpChatError.CreateFmt('HelpChat server %s: no session token', [FBaseUrl]);
  FLastContact := Now;
  FThemeCssSent := FTheme.ToCss;
  FAssistantSent := True;   // the session body carried them
  // A new session knows no screen: whatever was sent to the previous one has
  // to go again.
  FContextSent := False;
end;

function THelpChatRemoteTransport.SessionCall(const APath, ABody: string): Boolean;
var
  LResponse: string;
  LStatus: Integer;
begin
  LStatus := Post(APath, ABody, LResponse);
  if (LStatus = 403) and (FToken <> '') then
  begin
    // The token is unknown there: expired, or the server was restarted.
    FToken := '';
    FSessionId := '';
    OpenSession;
    LStatus := Post(APath, ABody, LResponse);
  end;
  Result := (LStatus >= 200) and (LStatus < 300);
  if Result then
    FLastContact := Now;
end;

procedure THelpChatRemoteTransport.EndSession;
var
  LResponse: string;
begin
  if FToken = '' then
    Exit;
  try
    Post(HELPCHAT_SESSION_END_PATH, '', LResponse);
  except
    // Closing is best effort: the session expires on its own anyway.
  end;
  FToken := '';
  FSessionId := '';
end;

procedure THelpChatRemoteTransport.Start;
begin
  if FStarted then
    Exit;
  if FBaseUrl = '' then
    raise EHelpChatError.Create('HelpChat remote transport: no server URL');

  if FUseHostChannel and not Assigned(FChannel) then
  begin
    FChannel := THelpChatHostChannel.Create;
    FChannel.AllowedOrigin := GetPanelOrigin;
    FChannel.OnCommand := FOnUiCommand;
    // Not being able to listen is not fatal: the page simply has nobody to
    // send its host commands to (Escape closes nothing).
    if not FChannel.Start then
      FreeAndNil(FChannel);
  end;
  FStarted := True;
  // No session yet, and no network touched: an application whose help server is
  // down, or that starts on a train, still starts. The conversation opens the
  // first time the user asks for help, which is also when a failure is worth
  // showing to them.
end;

procedure THelpChatRemoteTransport.EnsureSession;
begin
  if not FStarted then
    Start;
  if FToken = '' then
    OpenSession;
end;

procedure THelpChatRemoteTransport.Stop;
begin
  EndSession;
  FStarted := False;
  if Assigned(FChannel) then
  begin
    FChannel.OnCommand := nil;
    FreeAndNil(FChannel);
  end;
end;

function THelpChatRemoteTransport.IsActive: Boolean;
begin
  // Ready to be used; the conversation itself opens on first use.
  Result := FStarted;
end;

function THelpChatRemoteTransport.HasSession: Boolean;
begin
  Result := FToken <> '';
end;

function THelpChatRemoteTransport.GetPanelUrl: string;
begin
  // A session that was quiet for a while may be gone on the server: one
  // call tells, and opens a new one. Without it the page kept a token that
  // every request was answered 403 for, until the application restarted.
  if (FToken <> '') and (SecondsBetween(Now, FLastContact) >= HELPCHAT_REMOTE_CHECK_SECONDS) then
    PushContext;
  // The panel is about to be shown: the session must exist here, and an
  // unreachable server has to be reported instead of loading nothing.
  EnsureSession;
  Result := Format('%s/?%s=%s', [FBaseUrl, HELPCHAT_TOKEN_QUERY, FToken]);
end;

function THelpChatRemoteTransport.GetPanelOrigin: string;
begin
  Result := HelpChatUrlOrigin(FBaseUrl);
end;

procedure THelpChatRemoteTransport.PushContext;
var
  LContext: THelpChatContext;
begin
  if not HasSession then
    Exit;
  LContext := GetContext;
  try
    SessionCall(HELPCHAT_API_CONTEXT,
      'screenName=' + HelpChatFormEncode(LContext.ScreenName) +
      '&screenLabel=' + HelpChatFormEncode(LContext.ScreenLabel) +
      '&screenType=' + HelpChatFormEncode(LContext.ScreenType) +
      '&helpKeyword=' + HelpChatFormEncode(LContext.HelpKeyword) +
      '&helpContext=' + IntToStr(LContext.HelpContext) +
      '&focusedControl=' + HelpChatFormEncode(LContext.FocusedControl));
  except
    // The chat still works; it just does not know the screen.
  end;
end;

procedure THelpChatRemoteTransport.PushTheme;
var
  LCss: string;
begin
  if not HasSession then
    Exit;
  FLock.Enter;
  try
    LCss := FTheme.ToCss;
  finally
    FLock.Leave;
  end;
  try
    if SessionCall(HELPCHAT_API_THEME, 'themeCss=' + HelpChatFormEncode(LCss)) then
      FThemeCssSent := LCss;
  except
    // Cosmetic: a page loaded before the colours arrive still uses its defaults.
  end;
end;

procedure THelpChatRemoteTransport.PushAssistant;
var
  LName, LIcon: string;
begin
  if not HasSession then
    Exit;
  FLock.Enter;
  try
    LName := FAssistantName;
    LIcon := FAssistantIcon;
  finally
    FLock.Leave;
  end;
  try
    if SessionCall(HELPCHAT_API_ASSISTANT, 'name=' + HelpChatFormEncode(LName) +
      '&icon=' + HelpChatFormEncode(LIcon)) then
      FAssistantSent := True;
  except
    // Cosmetic, like the theme: the header keeps the name it was loaded with.
  end;
end;

procedure THelpChatRemoteTransport.SetContext(const AContext: THelpChatContext);
var
  LChanged: Boolean;
begin
  FLock.Enter;
  try
    LChanged := not FContextSent or not SameContext(FContext, AContext);
    FContext := AContext;
    // Marked before the call, not after it succeeded: a push that fails is
    // not tried again until the screen changes.
    if LChanged then
      FContextSent := True;
  finally
    FLock.Leave;
  end;
  // Only when it actually changed: one round trip per screen, not per open.
  if LChanged and FStarted then
  begin
    EnsureSession;
    PushContext;
  end;
end;

function THelpChatRemoteTransport.GetContext: THelpChatContext;
begin
  FLock.Enter;
  try
    Result := FContext;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRemoteTransport.SetTheme(const ATheme: THelpChatTheme);
var
  LChanged: Boolean;
begin
  FLock.Enter;
  try
    FTheme := ATheme;
    LChanged := FTheme.ToCss <> FThemeCssSent;
  finally
    FLock.Leave;
  end;
  if LChanged and HasSession then
    PushTheme;
end;

function THelpChatRemoteTransport.GetTheme: THelpChatTheme;
begin
  FLock.Enter;
  try
    Result := FTheme;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRemoteTransport.SetAssistant(const AName, AIconDataUri: string);
var
  LChanged: Boolean;
begin
  FLock.Enter;
  try
    LChanged := not FAssistantSent or (AName <> FAssistantName) or
      (AIconDataUri <> FAssistantIcon);
    FAssistantName := AName;
    FAssistantIcon := AIconDataUri;
    if LChanged then
      FAssistantSent := False;
  finally
    FLock.Leave;
  end;
  if LChanged and HasSession then
    PushAssistant;
end;

procedure THelpChatRemoteTransport.SetActions(const AActions: IHelpChatActionInvoker);
begin
  // Actions are local for now: the model runs on the server and the calls do
  // not travel back yet. Kept so that the component can ask what it set.
  FLock.Enter;
  try
    FActions := AActions;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRemoteTransport.GetActions: IHelpChatActionInvoker;
begin
  FLock.Enter;
  try
    Result := FActions;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatRemoteTransport.SetEnabledCommands(const ACommands: THelpChatCommands);
begin
  // The server decides what its sessions accept: this is only remembered.
  FLock.Enter;
  try
    FEnabledCommands := ACommands;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRemoteTransport.GetEnabledCommands: THelpChatCommands;
begin
  FLock.Enter;
  try
    Result := FEnabledCommands;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRemoteTransport.GetAssistantName: string;
begin
  FLock.Enter;
  try
    Result := FAssistantName;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRemoteTransport.GetAssistantIcon: string;
begin
  FLock.Enter;
  try
    Result := FAssistantIcon;
  finally
    FLock.Leave;
  end;
end;

function THelpChatRemoteTransport.GetEngine: THelpChatEngine;
begin
  Result := nil;
end;

procedure THelpChatRemoteTransport.SetOnPdfRequest(const AHandler: THelpChatPdfRequestEvent);
begin
  // Kept, and never called: the document would be built by the server, and
  // the host channel carries commands, not documents. Like the actions, this
  // is local for now.
  FOnPdfRequest := AHandler;
end;

procedure THelpChatRemoteTransport.SetOnUiCommand(const AHandler: THelpChatUiCommandEvent);
begin
  FOnUiCommand := AHandler;
  if Assigned(FChannel) then
    FChannel.OnCommand := AHandler;
end;

end.
