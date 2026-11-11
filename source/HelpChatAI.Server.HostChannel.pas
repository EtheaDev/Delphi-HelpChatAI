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
///  The channel a page uses to talk to the application hosting it, when the
///  conversation engine is somewhere else. With a local engine the page and the
///  host share a server, so <c>/api/ui/{command}</c> already reaches native
///  code; with a remote engine that call would land on the server, miles away
///  from the window that has to close. This is the missing half: a listener on
///  127.0.0.1, in the client process, that only answers host commands.
///
///  The page is served by the remote origin, so the calls are cross-origin: the
///  channel answers the preflight with that origin alone (never <c>*</c>),
///  including the header Chrome requires to reach a private network, and every
///  call still carries the channel's own secret.
///
///  Commands are delivered on the main thread. Today the page sends 'close';
///  the same channel is where file exchange between page and application will
///  live.
///
///  It knows nothing of the engine: its only tie to the rest is the contract
///  of the page (<c>/api/ui/{command}</c> and the token header, from
///  <c>HelpChatAI.Panel</c>) and the way the servers bind a port.
/// </summary>
unit HelpChatAI.Server.HostChannel;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  IdHTTPServer,
  IdCustomHTTPServer,
  IdContext,
  HelpChatAI.Transport,
  HelpChatAI.Panel;

type
  /// <summary>
  ///  The loopback listener of one remote transport: created, started and
  ///  freed by <see cref="THelpChatRemoteTransport" />, one per assistant.
  ///  It answers <c>OPTIONS</c> (the preflight, 204) and
  ///  <c>POST /api/ui/{command}</c>: 204 when the command was handed to
  ///  <c>OnCommand</c>, 403 without the right token, 404 for anything else or
  ///  when nobody listens.
  /// </summary>
  THelpChatHostChannel = class
  strict private
    FServer: TIdHTTPServer;
    FLock: TCriticalSection;
    FToken: string;
    FBoundPort: Integer;
    FAllowedOrigin: string;
    FOnCommand: THelpChatUiCommandEvent;
    /// <summary>Every request, on a connection thread of Indy. The handler
    /// is copied and queued to the main thread; the request returns without
    /// waiting for it.</summary>
    procedure HandleCommand(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    /// <summary>The CORS headers, on every answer: the allowed origin and
    /// never <c>*</c>, whatever origin asked - a page from elsewhere reads
    /// an origin that is not its own and the browser stops it. Nothing at
    /// all without an <c>AllowedOrigin</c>.</summary>
    procedure WriteCors(AResponseInfo: TIdHTTPResponseInfo);
    procedure WriteEmpty(AResponseInfo: TIdHTTPResponseInfo; const ACode: Integer);
  public
    constructor Create;
    /// <summary>Stops listening first. A command already queued to the main
    /// thread is still delivered to the handler it was queued with.</summary>
    destructor Destroy; override;
    /// <summary>Binds a free port on 127.0.0.1 and generates the secret. Never
    /// raises: a client that cannot listen simply has no host channel, and
    /// what the page asks of its host (Escape to close) goes nowhere. True
    /// when listening, also when it already was.</summary>
    function Start: Boolean;
    /// <summary>Closes the listener and forgets port and secret: a later
    /// <c>Start</c> gets new ones, which a page already loaded does not
    /// know.</summary>
    procedure Stop;
    function IsActive: Boolean;
    /// <summary>http://127.0.0.1:port, or empty when not listening.</summary>
    function GetOrigin: string;
    /// <summary>Secret the page must send in <c>X-HelpChat-Token</c>: not the
    /// token of the session, which the server knows, but one only this
    /// process and its page share. Empty when not listening.</summary>
    property Token: string read FToken;
    /// <summary>The only origin allowed to call: the origin of the panel page.
    /// Set it before Start.</summary>
    property AllowedOrigin: string read FAllowedOrigin write FAllowedOrigin;
    /// <summary>Receives the command (lower case, without the path) on the
    /// main thread, through <c>TThread.Queue</c>: a console host has to call
    /// <c>CheckSynchronize</c> to get it. nil = every command is answered
    /// 404. Set it from the main thread.</summary>
    property OnCommand: THelpChatUiCommandEvent read FOnCommand write FOnCommand;
  end;

implementation

uses
  HelpChatAI.Server;

{ THelpChatHostChannel }

constructor THelpChatHostChannel.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
end;

destructor THelpChatHostChannel.Destroy;
begin
  Stop;
  FLock.Free;
  inherited;
end;

function THelpChatHostChannel.Start: Boolean;
begin
  if IsActive then
    Exit(True);
  FToken := THelpChatHttpServerBase.NewSecret;
  FServer := TIdHTTPServer.Create(nil);
  FServer.ServerSoftware := 'HelpChatHost';
  FServer.KeepAlive := True;
  // Nothing to parse: a command is its path, and it has no body.
  FServer.ParseParams := False;
  FServer.OnCommandGet := HandleCommand;
  FServer.OnCommandOther := HandleCommand;
  FBoundPort := HelpChatBindServer(FServer, HELPCHAT_SERVER_HOST, 0);
  Result := FBoundPort > 0;
  if not Result then
  begin
    FreeAndNil(FServer);
    FToken := '';
  end;
end;

procedure THelpChatHostChannel.Stop;
begin
  if Assigned(FServer) then
  begin
    try
      FServer.Active := False;
    except
      // Closing must never fail loudly.
    end;
    FreeAndNil(FServer);
  end;
  FBoundPort := 0;
  FToken := '';
end;

function THelpChatHostChannel.IsActive: Boolean;
begin
  Result := Assigned(FServer) and FServer.Active;
end;

function THelpChatHostChannel.GetOrigin: string;
begin
  if IsActive then
    Result := Format('http://%s:%d', [HELPCHAT_SERVER_HOST, FBoundPort])
  else
    Result := '';
end;

procedure THelpChatHostChannel.WriteCors(AResponseInfo: TIdHTTPResponseInfo);
begin
  if FAllowedOrigin = '' then
    Exit;
  AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Origin'] := FAllowedOrigin;
  AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Headers'] := HELPCHAT_TOKEN_HEADER + ', Content-Type';
  AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Methods'] := 'POST, OPTIONS';
  // Chrome's Private Network Access: a public page reaching 127.0.0.1 must be
  // let in explicitly, in the preflight.
  AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Private-Network'] := 'true';
  AResponseInfo.CustomHeaders.Values['Access-Control-Max-Age'] := '600';
  AResponseInfo.CustomHeaders.Values['Vary'] := 'Origin';
end;

procedure THelpChatHostChannel.WriteEmpty(AResponseInfo: TIdHTTPResponseInfo; const ACode: Integer);
begin
  AResponseInfo.ResponseNo := ACode;
  AResponseInfo.ContentType := 'text/plain';
  AResponseInfo.CharSet := 'utf-8';
  AResponseInfo.CacheControl := 'no-store';
  AResponseInfo.ContentStream := TStringStream.Create('', TEncoding.UTF8);
  AResponseInfo.FreeContentStream := True;
end;

procedure THelpChatHostChannel.HandleCommand(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LCommand: string;
  LHandler: THelpChatUiCommandEvent;
begin
  AResponseInfo.CustomHeaders.Values['X-Content-Type-Options'] := 'nosniff';
  WriteCors(AResponseInfo);
  // The preflight carries no token - a browser never sends custom headers
  // with it - so it is answered before the secret is asked for.
  if ARequestInfo.CommandType = hcOPTION then
  begin
    WriteEmpty(AResponseInfo, 204);
    Exit;
  end;
  if (ARequestInfo.CommandType <> hcPOST) or
     not ARequestInfo.Document.StartsWith(HELPCHAT_API_UI) then
  begin
    WriteEmpty(AResponseInfo, 404);
    Exit;
  end;
  if (FToken = '') or (ARequestInfo.RawHeaders.Values[HELPCHAT_TOKEN_HEADER] <> FToken) then
  begin
    WriteEmpty(AResponseInfo, 403);
    Exit;
  end;
  LCommand := ARequestInfo.Document.Substring(HELPCHAT_API_UI.Length).Trim(['/']).ToLower;
  FLock.Enter;
  try
    LHandler := FOnCommand;
  finally
    FLock.Leave;
  end;
  if (LCommand = '') or not Assigned(LHandler) then
  begin
    WriteEmpty(AResponseInfo, 404);
    Exit;
  end;
  TThread.Queue(nil,
    procedure
    begin
      LHandler(LCommand);
    end);
  WriteEmpty(AResponseInfo, 204);
end;

end.
