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
///  tells the server where it is: that is how the ✕ of the page still closes
///  the window, and how page and application will exchange files.
///
///  Context and theme are pushed synchronously, with the short timeout of
///  <c>Settings.Remote.TimeoutMs</c>: they must be on the server before the
///  question the user is about to ask, and a slow server must not freeze the
///  application. A failure is silent — the chat works, it just does not know
///  which screen the user is on.
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
  HelpChatAI.Transport,
  HelpChatAI.Server.HostChannel;

type
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
    FOnUiCommand: THelpChatUiCommandEvent;
    function Post(const APath, ABody: string; out AResponse: string): Integer;
    procedure EnsureSession;
    procedure OpenSession;
    procedure EndSession;
    procedure PushContext;
    procedure PushTheme;
  public
    constructor Create(const ABaseUrl, AAppKey: string); overload;
    /// <summary>The usual way: everything comes from <c>Settings.Remote</c>, so
    /// an installed application moves to a server by editing helpchatai.json.</summary>
    constructor Create(const ARemote: THelpChatRemoteSettings); overload;
    destructor Destroy; override;

    // IHelpChatTransport
    procedure Start;
    procedure Stop;
    function IsActive: Boolean;
    function GetPanelUrl: string;
    function GetPanelOrigin: string;
    procedure SetContext(const AContext: THelpChatContext);
    function GetContext: THelpChatContext;
    procedure SetTheme(const ATheme: THelpChatTheme);
    function GetTheme: THelpChatTheme;
    /// <summary>Always nil: the engine is on the server.</summary>
    function GetEngine: THelpChatEngine;
    procedure SetOnUiCommand(const AHandler: THelpChatUiCommandEvent);

    /// <summary>True once a conversation is open on the server.</summary>
    function HasSession: Boolean;
    /// <summary>Id of the session on the server (diagnostics).</summary>
    property SessionId: string read FSessionId;
    /// <summary>The loopback channel of the page, nil when disabled or unavailable.</summary>
    property HostChannel: THelpChatHostChannel read FChannel;
    property UserId: string read FUserId write FUserId;
    property UserToken: string read FUserToken write FUserToken;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs;
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
  Create(ARemote.NormalizedBaseUrl, ARemote.AppKey);
  FUserId := ARemote.ResolveUserId;
  FUserToken := ARemote.UserToken;
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
    '&themeCss=' + HelpChatFormEncode(FTheme.ToCss);
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
  FThemeCssSent := FTheme.ToCss;
  FContextSent := False;
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
    // Not being able to listen is not fatal: the page simply loses its ✕.
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
  LResponse: string;
begin
  if not HasSession then
    Exit;
  LContext := GetContext;
  try
    Post(HELPCHAT_API_CONTEXT,
      'screenName=' + HelpChatFormEncode(LContext.ScreenName) +
      '&screenLabel=' + HelpChatFormEncode(LContext.ScreenLabel) +
      '&screenType=' + HelpChatFormEncode(LContext.ScreenType) +
      '&helpKeyword=' + HelpChatFormEncode(LContext.HelpKeyword) +
      '&helpContext=' + IntToStr(LContext.HelpContext) +
      '&focusedControl=' + HelpChatFormEncode(LContext.FocusedControl), LResponse);
  except
    // The chat still works; it just does not know the screen.
  end;
end;

procedure THelpChatRemoteTransport.PushTheme;
var
  LCss, LResponse: string;
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
    Post(HELPCHAT_API_THEME, 'themeCss=' + HelpChatFormEncode(LCss), LResponse);
    FThemeCssSent := LCss;
  except
    // Cosmetic: a page loaded before the colours arrive still uses its defaults.
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

function THelpChatRemoteTransport.GetEngine: THelpChatEngine;
begin
  Result := nil;
end;

procedure THelpChatRemoteTransport.SetOnUiCommand(const AHandler: THelpChatUiCommandEvent);
begin
  FOnUiCommand := AHandler;
  if Assigned(FChannel) then
    FChannel.OnCommand := AHandler;
end;

end.
