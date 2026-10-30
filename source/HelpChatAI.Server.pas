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
///  The HTTP side of HelpChat: an Indy server that serves the panel page and
///  the endpoints returning HTML fragments (never JSON): history, send, poll,
///  cancel, clear, plus context and theme from the native client and the host
///  commands of the page. Every API call carries a secret in
///  <c>X-HelpChat-Token</c> that identifies a <see cref="THelpChatServerSession" />,
///  and a session is one conversation of the engine.
///
///  <see cref="THelpChatLocalServer" /> is the desktop case: bound to 127.0.0.1
///  on a free port, one session for the whole process, and it is itself the
///  transport the component talks to. <see cref="HelpChatAI.Server.Remote" />
///  derives the multi-session server from the same base.
///
///  The request thread never waits on the model: <c>send</c> records the
///  question and returns the pending bubble, <c>poll</c> returns the growing
///  partial. The screen context comes from the native side, so it is never lost
///  the way it was in the original client-side design.
/// </summary>
unit HelpChatAI.Server;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  IdHTTPServer,
  IdCustomHTTPServer,
  IdContext,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Theme,
  HelpChatAI.Engine,
  HelpChatAI.DocPages,
  HelpChatAI.Transport,
  HelpChatAI.Panel,
  HelpChatAI.Attachments,
  HelpChatAI.Provider;

const
  HELPCHAT_SERVER_HOST = '127.0.0.1';
  /// <summary>Ports tried, from a random start, when Port = 0.</summary>
  HELPCHAT_SERVER_PORT_MIN = 20000;
  HELPCHAT_SERVER_PORT_SPAN = 20000;
  HELPCHAT_SERVER_PORT_ATTEMPTS = 40;

type
  /// <summary>
  ///  One conversation as the HTTP layer sees it: the secret its client sends,
  ///  the key of the conversation in the store, who owns it, the screen context
  ///  and the colours of that client. A desktop process has exactly one; a
  ///  server has one per connected client.
  /// </summary>
  THelpChatServerSession = class
  strict private
    FLock: TCriticalSection;
    FId: string;
    FToken: string;
    FUserId: string;
    FConversationKey: string;
    FUiBase: string;
    FUiToken: string;
    FContext: THelpChatContext;
    FThemeCss: string;
    FAssistantName: string;
    FAssistantIcon: string;
    FCreatedAt: TDateTime;
    FLastAccess: TDateTime;
    function GetLastAccess: TDateTime;
  public
    constructor Create(const AId, AToken, AUserId, AConversationKey: string);
    destructor Destroy; override;
    /// <summary>Marks the session as used now (idle expiry).</summary>
    procedure Touch;
    procedure SetContext(const AContext: THelpChatContext);
    function GetContext: THelpChatContext;
    /// <summary>The colours of this client, as the CSS rule the page loads with.</summary>
    procedure SetThemeCss(const ACss: string);
    function GetThemeCss: string;
    /// <summary>What this client calls its assistant, and the icon it draws
    /// next to the name (a data: URI). Empty name = the localized default.</summary>
    procedure SetAssistant(const AName, AIcon: string);
    function GetAssistantName: string;
    function GetAssistantIcon: string;
    /// <summary>Where this client listens for the commands of its page, and with
    /// which secret; empty = the page talks to the server it came from.</summary>
    procedure SetUiEndpoint(const ABase, AToken: string);
    property Id: string read FId;
    property Token: string read FToken;
    property UserId: string read FUserId;
    property ConversationKey: string read FConversationKey;
    property UiBase: string read FUiBase;
    property UiToken: string read FUiToken;
    property CreatedAt: TDateTime read FCreatedAt;
    property LastAccess: TDateTime read GetLastAccess;
  end;

  /// <summary>
  ///  The routing and the endpoints, shared by the local and the remote server.
  ///  A descendant only has to say how a token becomes a session.
  /// </summary>
  THelpChatHttpServerBase = class(TInterfacedObject)
  strict private
    FEngine: THelpChatEngine;
    FOwnsEngine: Boolean;
    FServer: TIdHTTPServer;
    FBindIP: string;
    FPort: Integer;
    FBoundPort: Integer;
    FPollIntervalMs: Integer;
    FMaxPolls: Integer;
    procedure HandleCommand(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure HandleApi(const ADocument: string; const ASession: THelpChatServerSession;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    /// <summary>Hands the engine the bytes of an upload and answers what the
    /// page needs to draw the chip - or the sentence that says why not.</summary>
    function AttachmentJson(const AKey, AFileName: string;
      const AStream: TStream): string;
    /// <summary>The attachments of the conversation, as the page draws them.</summary>
    function AttachmentListJson(const AKey: string): string;
  strict protected
    /// <summary>Closes the listener. Not virtual and idempotent: the destructor
    /// calls it, and a destructor must never dispatch to a descendant whose
    /// fields are already gone.</summary>
    procedure StopListening;
    procedure WriteHtml(AResponseInfo: TIdHTTPResponseInfo; const AHtml: string);
    procedure WriteJson(AResponseInfo: TIdHTTPResponseInfo; const AJson: string);
    procedure WriteStatus(AResponseInfo: TIdHTTPResponseInfo; const ACode: Integer);
    /// <summary>The session a secret belongs to, or nil. Called for the page
    /// (secret in the query) and for every API call (secret in the header).</summary>
    function SessionByToken(const AToken: string): THelpChatServerSession; virtual; abstract;
    /// <summary>Configuration of the page served to a session.</summary>
    function PanelOptionsFor(const ASession: THelpChatServerSession): THelpChatPanelOptions; virtual;
    /// <summary>Routes of the descendant (session handling, health): True when
    /// the request was answered.</summary>
    function HandleRoute(const ADocument: string; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo): Boolean; virtual;
    /// <summary>What the page asks of its host ('close'): True when delivered.
    /// Only a host that lives in this process can answer it.</summary>
    function HandleUiCommand(const ASession: THelpChatServerSession;
      const ACommand: string): Boolean; virtual;
    property Server: TIdHTTPServer read FServer;
  public
    /// <summary>The engine is started on Start if needed; owned when AOwnsEngine.</summary>
    constructor Create(const AEngine: THelpChatEngine; const AOwnsEngine: Boolean = False); virtual;
    destructor Destroy; override;

    procedure Start; virtual;
    procedure Stop; virtual;
    function IsActive: Boolean;
    /// <summary>scheme://host:port the pages and the API live at.</summary>
    function GetPanelOrigin: string; virtual;

    /// <summary>Decodes an application/x-www-form-urlencoded body (UTF-8).</summary>
    class function FormField(const ABody, AName: string): string; static;
    /// <summary>A URL-safe random secret (a GUID without punctuation).</summary>
    class function NewSecret: string; static;

    property Engine: THelpChatEngine read FEngine;
    /// <summary>Address to bind; 127.0.0.1 by default (a server opens it up).</summary>
    property BindIP: string read FBindIP write FBindIP;
    /// <summary>Port to listen on; 0 (default) picks a free one at Start.</summary>
    property Port: Integer read FPort write FPort;
    /// <summary>Port actually bound after Start.</summary>
    property BoundPort: Integer read FBoundPort;
    property PollIntervalMs: Integer read FPollIntervalMs write FPollIntervalMs;
    property MaxPolls: Integer read FMaxPolls write FMaxPolls;
  end;

  /// <summary>
  ///  The desktop transport: the engine, the page and the API in the same
  ///  process, reachable only from 127.0.0.1 and only with the secret generated
  ///  at Start. One session, one conversation.
  /// </summary>
  THelpChatLocalServer = class(THelpChatHttpServerBase, IHelpChatTransport)
  strict private
    FSession: THelpChatServerSession;
    FLock: TCriticalSection;
    FTheme: THelpChatTheme;
    FContext: THelpChatContext;
    FAssistantName: string;
    FAssistantIcon: string;
    FOnUiCommand: THelpChatUiCommandEvent;
  strict protected
    function SessionByToken(const AToken: string): THelpChatServerSession; override;
    function HandleUiCommand(const ASession: THelpChatServerSession;
      const ACommand: string): Boolean; override;
  public
    constructor Create(const AEngine: THelpChatEngine; const AOwnsEngine: Boolean = False); override;
    destructor Destroy; override;

    // IHelpChatTransport
    procedure Start; override;
    procedure Stop; override;
    function GetPanelUrl: string;
    procedure SetContext(const AContext: THelpChatContext);
    function GetContext: THelpChatContext;
    procedure SetTheme(const ATheme: THelpChatTheme);
    function GetTheme: THelpChatTheme;
    procedure SetAssistant(const AName, AIconDataUri: string);
    function GetAssistantName: string;
    function GetAssistantIcon: string;
    function GetEngine: THelpChatEngine;
    procedure SetOnUiCommand(const AHandler: THelpChatUiCommandEvent);

    /// <summary>Secret required in the token header (generated at Start).</summary>
    function Token: string;
  end;

/// <summary>Binds AServer to AIP:APort, or scans a range from a random start
/// when APort is 0. Returns the bound port, 0 when nothing could be bound.</summary>
function HelpChatBindServer(const AServer: TIdHTTPServer; const AIP: string;
  const APort: Integer): Integer;

implementation

uses
  System.NetEncoding,
  System.StrUtils,
  System.JSON,
  IdSocketHandle,
  IdGlobal,
  HelpChatAI.Html;

function HelpChatBindServer(const AServer: TIdHTTPServer; const AIP: string;
  const APort: Integer): Integer;

  function TryBind(const APortToTry: Integer): Boolean;
  var
    LBinding: TIdSocketHandle;
  begin
    AServer.Bindings.Clear;
    LBinding := AServer.Bindings.Add;
    LBinding.IP := AIP;
    LBinding.Port := APortToTry;
    try
      AServer.Active := True;
      Result := True;
    except
      AServer.Active := False;
      Result := False;
    end;
  end;

var
  I, LStart: Integer;
begin
  Result := 0;
  if APort > 0 then
  begin
    if TryBind(APort) then
      Result := AServer.Bindings[0].Port;
    Exit;
  end;
  Randomize;
  LStart := HELPCHAT_SERVER_PORT_MIN + Random(HELPCHAT_SERVER_PORT_SPAN);
  for I := 0 to HELPCHAT_SERVER_PORT_ATTEMPTS - 1 do
    if TryBind(LStart + I) then
      Exit(AServer.Bindings[0].Port);
end;

{ THelpChatServerSession }

constructor THelpChatServerSession.Create(const AId, AToken, AUserId, AConversationKey: string);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FId := AId;
  FToken := AToken;
  FUserId := AUserId;
  FConversationKey := AConversationKey;
  FCreatedAt := Now;
  FLastAccess := FCreatedAt;
end;

destructor THelpChatServerSession.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure THelpChatServerSession.Touch;
begin
  FLock.Enter;
  try
    FLastAccess := Now;
  finally
    FLock.Leave;
  end;
end;

function THelpChatServerSession.GetLastAccess: TDateTime;
begin
  FLock.Enter;
  try
    Result := FLastAccess;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatServerSession.SetContext(const AContext: THelpChatContext);
begin
  FLock.Enter;
  try
    FContext := AContext;
  finally
    FLock.Leave;
  end;
end;

function THelpChatServerSession.GetContext: THelpChatContext;
begin
  FLock.Enter;
  try
    Result := FContext;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatServerSession.SetThemeCss(const ACss: string);
begin
  FLock.Enter;
  try
    FThemeCss := ACss;
  finally
    FLock.Leave;
  end;
end;

function THelpChatServerSession.GetThemeCss: string;
begin
  FLock.Enter;
  try
    Result := FThemeCss;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatServerSession.SetAssistant(const AName, AIcon: string);
begin
  FLock.Enter;
  try
    FAssistantName := AName;
    FAssistantIcon := AIcon;
  finally
    FLock.Leave;
  end;
end;

function THelpChatServerSession.GetAssistantName: string;
begin
  FLock.Enter;
  try
    Result := FAssistantName;
  finally
    FLock.Leave;
  end;
end;

function THelpChatServerSession.GetAssistantIcon: string;
begin
  FLock.Enter;
  try
    Result := FAssistantIcon;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatServerSession.SetUiEndpoint(const ABase, AToken: string);
begin
  FLock.Enter;
  try
    FUiBase := ABase;
    FUiToken := AToken;
  finally
    FLock.Leave;
  end;
end;

{ THelpChatHttpServerBase }

constructor THelpChatHttpServerBase.Create(const AEngine: THelpChatEngine;
  const AOwnsEngine: Boolean);
begin
  inherited Create;
  FEngine := AEngine;
  FOwnsEngine := AOwnsEngine;
  FBindIP := HELPCHAT_SERVER_HOST;
  FPollIntervalMs := HELPCHAT_DEF_POLL_MS;
  FMaxPolls := HELPCHAT_DEF_MAX_POLLS;
end;

destructor THelpChatHttpServerBase.Destroy;
begin
  StopListening;
  if FOwnsEngine then
    FEngine.Free;
  inherited;
end;

class function THelpChatHttpServerBase.NewSecret: string;
var
  LGuid: TGUID;
begin
  CreateGUID(LGuid);
  Result := GUIDToString(LGuid).Trim(['{', '}']).Replace('-', '').ToLower;
end;

procedure THelpChatHttpServerBase.Start;
begin
  if IsActive then
    Exit;
  if not Assigned(FEngine) then
    raise EHelpChatError.Create('HelpChat server: no engine');
  FEngine.Start;

  FServer := TIdHTTPServer.Create(nil);
  FServer.ServerSoftware := 'HelpChat/' + HELPCHAT_VERSION;
  FServer.KeepAlive := True;
  FServer.ParseParams := False; // the body is decoded by hand, UTF-8 safe
  FServer.OnCommandGet := HandleCommand;
  FServer.OnCommandOther := HandleCommand;

  FBoundPort := HelpChatBindServer(FServer, FBindIP, FPort);
  if FBoundPort = 0 then
  begin
    FreeAndNil(FServer);
    if FPort > 0 then
      raise EHelpChatError.CreateFmt('HelpChat server: cannot listen on %s:%d', [FBindIP, FPort]);
    raise EHelpChatError.Create('HelpChat server: no free port found');
  end;
end;

procedure THelpChatHttpServerBase.Stop;
begin
  StopListening;
end;

procedure THelpChatHttpServerBase.StopListening;
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
end;

function THelpChatHttpServerBase.IsActive: Boolean;
begin
  Result := Assigned(FServer) and FServer.Active;
end;

function THelpChatHttpServerBase.GetPanelOrigin: string;
begin
  if IsActive then
    Result := Format('http://%s:%d', [FBindIP, FBoundPort])
  else
    Result := '';
end;

class function THelpChatHttpServerBase.FormField(const ABody, AName: string): string;
var
  LPair: string;
  P: Integer;
begin
  Result := '';
  for LPair in ABody.Split(['&']) do
  begin
    P := LPair.IndexOf('=');
    if P < 0 then
      Continue;
    if SameText(TNetEncoding.URL.Decode(LPair.Substring(0, P)), AName) then
      // '+' is a space in form encoding; a literal plus arrives as %2B.
      Exit(TNetEncoding.URL.Decode(LPair.Substring(P + 1).Replace('+', ' ')));
  end;
end;

procedure THelpChatHttpServerBase.WriteHtml(AResponseInfo: TIdHTTPResponseInfo; const AHtml: string);
begin
  AResponseInfo.ContentType := 'text/html';
  AResponseInfo.CharSet := 'utf-8';
  AResponseInfo.CacheControl := 'no-store';
  // A stream, not ContentText: with an empty ContentText Indy writes a default
  // "200 OK" HTML body, while an empty reply is part of the contract (unknown
  // poll id, empty message).
  AResponseInfo.ContentStream := TStringStream.Create(AHtml, TEncoding.UTF8);
  AResponseInfo.FreeContentStream := True;
end;

procedure THelpChatHttpServerBase.WriteJson(AResponseInfo: TIdHTTPResponseInfo; const AJson: string);
begin
  AResponseInfo.ContentType := 'application/json';
  AResponseInfo.CharSet := 'utf-8';
  AResponseInfo.CacheControl := 'no-store';
  AResponseInfo.ContentStream := TStringStream.Create(AJson, TEncoding.UTF8);
  AResponseInfo.FreeContentStream := True;
end;

procedure THelpChatHttpServerBase.WriteStatus(AResponseInfo: TIdHTTPResponseInfo; const ACode: Integer);
begin
  AResponseInfo.ResponseNo := ACode;
  WriteHtml(AResponseInfo, '');
end;

/// <summary>One attachment as the page wants it. Owned by the caller.</summary>
function AttachmentObject(const AAttachment: THelpChatAttachment): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', AAttachment.Id);
  Result.AddPair('name', AAttachment.FileName);
  Result.AddPair('ext', AAttachment.Extension);
  Result.AddPair('size', TJSONNumber.Create(AAttachment.OriginalSize));
  Result.AddPair('sizeText', HelpChatFormatSize(AAttachment.OriginalSize));
end;

function THelpChatHttpServerBase.AttachmentListJson(const AKey: string): string;
var
  LRoot: TJSONObject;
  LItems: TJSONArray;
  LAttachment: THelpChatAttachment;
begin
  LRoot := TJSONObject.Create;
  try
    LItems := TJSONArray.Create;
    LRoot.AddPair('items', LItems);
    for LAttachment in FEngine.Attachments.ItemsOf(AKey) do
      LItems.AddElement(AttachmentObject(LAttachment));
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

function THelpChatHttpServerBase.AttachmentJson(const AKey, AFileName: string;
  const AStream: TStream): string;
var
  LRoot: TJSONObject;
  LData: TBytes;
  LAttachment: THelpChatAttachment;
  LError: string;
begin
  LData := nil;
  if Assigned(AStream) and (AStream.Size > 0) then
  begin
    AStream.Position := 0;
    SetLength(LData, AStream.Size);
    AStream.ReadBuffer(LData[0], Length(LData));
  end;

  if FEngine.AddAttachment(AKey, AFileName, LData, LAttachment, LError) then
  begin
    LRoot := AttachmentObject(LAttachment);
    try
      Result := LRoot.ToJSON;
    finally
      LRoot.Free;
    end;
    Exit;
  end;

  LRoot := TJSONObject.Create;
  try
    if LError = '' then       // attachments are off: the page should not have asked
      LError := HelpChatMsg(hcmAttachFailed, FEngine.Settings.Language);
    LRoot.AddPair('error', LError);
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

function THelpChatHttpServerBase.PanelOptionsFor(
  const ASession: THelpChatServerSession): THelpChatPanelOptions;
begin
  Result := THelpChatPanelOptions.Default;
  Result.Token := ASession.Token;
  Result.Language := FEngine.Settings.Language;
  Result.PollIntervalMs := FPollIntervalMs;
  Result.MaxPolls := FMaxPolls;
  Result.ThemeCss := ASession.GetThemeCss;
  Result.UiBase := ASession.UiBase;
  Result.UiToken := ASession.UiToken;
  Result.HostCommands := True;
  Result.DocsAvailable := Assigned(FEngine.DocPages);
  Result.DocBaseUrl := FEngine.Settings.DocBaseUrl;
  Result.AssistantName := ASession.GetAssistantName;
  Result.AssistantIcon := ASession.GetAssistantIcon;
  // The clip is offered only when both halves agree: the application allows
  // attachments and the configured provider can actually read one.
  Result.AttachmentsEnabled := FEngine.Settings.Attachments.Enabled and
    THelpChatProviderRegistry.SupportsDocuments(FEngine.Settings.Provider);
  Result.AttachMaxKB := FEngine.Settings.Attachments.MaxSizeKB;
  Result.AttachAccept := HelpChatAcceptedExtensions;
end;

function THelpChatHttpServerBase.HandleRoute(const ADocument: string;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo): Boolean;
begin
  Result := False;
end;

function THelpChatHttpServerBase.HandleUiCommand(const ASession: THelpChatServerSession;
  const ACommand: string): Boolean;
begin
  Result := False;
end;

procedure THelpChatHttpServerBase.HandleCommand(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LDocument: string;
  LSession: THelpChatServerSession;
begin
  LDocument := ARequestInfo.Document;
  AResponseInfo.CustomHeaders.Values['X-Content-Type-Options'] := 'nosniff';
  try
    // Routes of the descendant first (session handling on a server).
    if HandleRoute(LDocument, ARequestInfo, AResponseInfo) then
      Exit;

    if (LDocument = '/') or (LDocument = '') then
    begin
      // The page itself: only with the secret in the URL (the WebView has it).
      // ParseParams is off, so the query string is decoded by hand.
      LSession := SessionByToken(FormField(ARequestInfo.QueryParams, HELPCHAT_TOKEN_QUERY));
      if LSession = nil then
      begin
        WriteStatus(AResponseInfo, 404);
        Exit;
      end;
      LSession.Touch;
      WriteHtml(AResponseInfo, THelpChatPanel.RenderPage(PanelOptionsFor(LSession)));
    end
    else if LDocument.StartsWith(HELPCHAT_API_PREFIX) then
    begin
      LSession := SessionByToken(ARequestInfo.RawHeaders.Values[HELPCHAT_TOKEN_HEADER]);
      if LSession = nil then
      begin
        WriteStatus(AResponseInfo, 403);
        Exit;
      end;
      LSession.Touch;
      HandleApi(LDocument, LSession, ARequestInfo, AResponseInfo);
    end
    else
      WriteStatus(AResponseInfo, 404);
  except
    on E: Exception do
    begin
      AResponseInfo.ResponseNo := 500;
      WriteHtml(AResponseInfo, HelpChatTextToHtml(E.Message));
    end;
  end;
end;

procedure THelpChatHttpServerBase.HandleApi(const ADocument: string;
  const ASession: THelpChatServerSession; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  LBody, LId, LKey, LMessage, LValue: string;
  LContext: THelpChatContext;
  LResult: THelpChatSendResult;
  LDoc: THelpChatRenderedDoc;
  LIsPost: Boolean;
begin
  LIsPost := ARequestInfo.CommandType = hcPOST;
  if LIsPost then
    LBody := ARequestInfo.FormParams
  else
    LBody := '';
  LKey := ASession.ConversationKey;

  if (ADocument = HELPCHAT_API_HISTORY) and not LIsPost then
    WriteHtml(AResponseInfo, FEngine.RenderHistoryHtml(LKey))

  else if (ADocument = HELPCHAT_API_SEND) and LIsPost then
  begin
    LMessage := FormField(LBody, HELPCHAT_FIELD_MESSAGE);
    // The screen context is the native one; a client may still send its own
    // fields, which win when present.
    LContext := ASession.GetContext;
    LValue := FormField(LBody, 'screenName');
    if LValue <> '' then
      LContext.ScreenName := LValue;
    LValue := FormField(LBody, 'screenLabel');
    if LValue <> '' then
      LContext.ScreenLabel := LValue;
    LValue := FormField(LBody, 'screenType');
    if LValue <> '' then
      LContext.ScreenType := LValue;
    LValue := FormField(LBody, 'helpKeyword');
    if LValue <> '' then
      LContext.HelpKeyword := LValue;
    LResult := FEngine.Send(LKey, LMessage, LContext);
    if LResult.Sent then
      WriteHtml(AResponseInfo, HelpChatRenderBubble(LResult.UserMessage) +
        HelpChatRenderBubble(LResult.AssistantMessage))
    else
      WriteHtml(AResponseInfo, '');
  end

  else if ADocument.StartsWith(HELPCHAT_API_POLL) and not LIsPost then
  begin
    LId := ADocument.Substring(HELPCHAT_API_POLL.Length);
    WriteHtml(AResponseInfo, FEngine.RenderMessageHtml(LKey, LId));
  end

  else if ADocument.StartsWith(HELPCHAT_API_CANCEL) and LIsPost then
  begin
    LId := ADocument.Substring(HELPCHAT_API_CANCEL.Length);
    // Only a reply of this conversation: a session cannot stop another's.
    if FEngine.RenderMessageHtml(LKey, LId) <> '' then
      FEngine.Cancel(LId);
    WriteHtml(AResponseInfo, FEngine.RenderMessageHtml(LKey, LId));
  end

  else if (ADocument = HELPCHAT_API_CLEAR) and LIsPost then
  begin
    FEngine.Clear(LKey);
    WriteHtml(AResponseInfo, HelpChatRenderGreeting(FEngine.Greeting));
  end

  else if (ADocument = HELPCHAT_API_DOC) and not LIsPost then
  begin
    // A page of the documentation folder, rendered like a reply (safe HTML).
    if FEngine.RenderDocPage(FormField(ARequestInfo.QueryParams, HELPCHAT_DOC_QUERY), LDoc) then
      WriteHtml(AResponseInfo, '<article class="' + HELPCHAT_CSS_PREFIX + '-doc-page"' +
        ' data-page="' + TNetEncoding.HTML.Encode(LDoc.Page) + '"' +
        ' data-title="' + TNetEncoding.HTML.Encode(LDoc.Title) + '">' + LDoc.Html + '</article>')
    else
      WriteStatus(AResponseInfo, 404);
  end

  else if (ADocument = HELPCHAT_API_CONTEXT) and LIsPost then
  begin
    // The native client tells the session which screen the user is on.
    LContext := Default(THelpChatContext);
    LContext.ScreenName := FormField(LBody, 'screenName');
    LContext.ScreenLabel := FormField(LBody, 'screenLabel');
    LContext.ScreenType := FormField(LBody, 'screenType');
    LContext.HelpKeyword := FormField(LBody, 'helpKeyword');
    LContext.HelpContext := StrToIntDef(FormField(LBody, 'helpContext'), 0);
    LContext.FocusedControl := FormField(LBody, 'focusedControl');
    ASession.SetContext(LContext);
    WriteHtml(AResponseInfo, '');
  end

  else if (ADocument = HELPCHAT_API_THEME) and LIsPost then
  begin
    // The colours are produced by the framework on the client (VCL styles, FMX
    // theme mode): they arrive already rendered as the CSS the page loads with.
    ASession.SetThemeCss(FormField(LBody, 'themeCss'));
    WriteHtml(AResponseInfo, '');
  end

  else if (ADocument = HELPCHAT_API_ASSISTANT) and LIsPost then
  begin
    // Same reasoning as the theme: the name of the assistant and its icon are
    // what the client decided, and the page is reloaded with them.
    ASession.SetAssistant(FormField(LBody, 'name'), FormField(LBody, 'icon'));
    WriteHtml(AResponseInfo, '');
  end

  else if (ADocument = HELPCHAT_API_ATTACH) and LIsPost then
  begin
    // The bytes are the whole body: a multipart form would have to be decoded
    // by hand here (Indy only parses the urlencoded kind), and the page sends
    // one file per call anyway. The name travels in the query string, where
    // it is already percent-encoded.
    WriteJson(AResponseInfo, AttachmentJson(LKey,
      FormField(ARequestInfo.QueryParams, HELPCHAT_ATTACH_NAME_QUERY),
      ARequestInfo.PostStream));
  end

  else if (ADocument = HELPCHAT_API_ATTACHMENTS) and not LIsPost then
    WriteJson(AResponseInfo, AttachmentListJson(LKey))

  else if (ADocument = HELPCHAT_API_ATTACH_REMOVE) and LIsPost then
  begin
    FEngine.RemoveAttachment(LKey, FormField(LBody, HELPCHAT_FIELD_ATTACH_ID));
    WriteHtml(AResponseInfo, '');
  end

  else if ADocument.StartsWith(HELPCHAT_API_UI) and LIsPost then
  begin
    LId := ADocument.Substring(HELPCHAT_API_UI.Length).Trim(['/']).ToLower;
    if (LId = '') or not HandleUiCommand(ASession, LId) then
      WriteStatus(AResponseInfo, 404)
    else
      WriteHtml(AResponseInfo, '');
  end

  else
    WriteStatus(AResponseInfo, 404);
end;

{ THelpChatLocalServer }

constructor THelpChatLocalServer.Create(const AEngine: THelpChatEngine; const AOwnsEngine: Boolean);
begin
  inherited Create(AEngine, AOwnsEngine);
  FLock := TCriticalSection.Create;
end;

destructor THelpChatLocalServer.Destroy;
begin
  Stop;
  FreeAndNil(FSession);
  FreeAndNil(FLock);
  inherited;
end;

procedure THelpChatLocalServer.Start;
begin
  if IsActive then
    Exit;
  inherited Start;
  // One session for the whole process, on the engine's own conversation.
  FreeAndNil(FSession);
  FSession := THelpChatServerSession.Create('local', NewSecret, '', Engine.ConversationKey);
  FSession.SetContext(GetContext);
  FSession.SetThemeCss(GetTheme.ToCss);
  FSession.SetAssistant(GetAssistantName, GetAssistantIcon);
  // The page talks to the host through this same server.
  FSession.SetUiEndpoint('', '');
end;

procedure THelpChatLocalServer.Stop;
begin
  inherited Stop;
end;

function THelpChatLocalServer.SessionByToken(const AToken: string): THelpChatServerSession;
begin
  if Assigned(FSession) and (AToken <> '') and (AToken = FSession.Token) then
    Result := FSession
  else
    Result := nil;
end;

function THelpChatLocalServer.Token: string;
begin
  if Assigned(FSession) then
    Result := FSession.Token
  else
    Result := '';
end;

function THelpChatLocalServer.GetPanelUrl: string;
begin
  if IsActive then
    Result := Format('%s/?%s=%s', [GetPanelOrigin, HELPCHAT_TOKEN_QUERY, Token])
  else
    Result := '';
end;

procedure THelpChatLocalServer.SetContext(const AContext: THelpChatContext);
begin
  // Kept here too: the component may set it before Start created the session.
  FLock.Enter;
  try
    FContext := AContext;
  finally
    FLock.Leave;
  end;
  if Assigned(FSession) then
    FSession.SetContext(AContext);
end;

function THelpChatLocalServer.GetContext: THelpChatContext;
begin
  FLock.Enter;
  try
    Result := FContext;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatLocalServer.SetTheme(const ATheme: THelpChatTheme);
begin
  FLock.Enter;
  try
    FTheme := ATheme;
  finally
    FLock.Leave;
  end;
  if Assigned(FSession) then
    FSession.SetThemeCss(ATheme.ToCss);
end;

function THelpChatLocalServer.GetTheme: THelpChatTheme;
begin
  FLock.Enter;
  try
    Result := FTheme;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatLocalServer.SetAssistant(const AName, AIconDataUri: string);
begin
  // Kept here too: the component sets them before Start created the session.
  FLock.Enter;
  try
    FAssistantName := AName;
    FAssistantIcon := AIconDataUri;
  finally
    FLock.Leave;
  end;
  if Assigned(FSession) then
    FSession.SetAssistant(AName, AIconDataUri);
end;

function THelpChatLocalServer.GetAssistantName: string;
begin
  FLock.Enter;
  try
    Result := FAssistantName;
  finally
    FLock.Leave;
  end;
end;

function THelpChatLocalServer.GetAssistantIcon: string;
begin
  FLock.Enter;
  try
    Result := FAssistantIcon;
  finally
    FLock.Leave;
  end;
end;

function THelpChatLocalServer.GetEngine: THelpChatEngine;
begin
  Result := Engine;
end;

procedure THelpChatLocalServer.SetOnUiCommand(const AHandler: THelpChatUiCommandEvent);
begin
  FLock.Enter;
  try
    FOnUiCommand := AHandler;
  finally
    FLock.Leave;
  end;
end;

function THelpChatLocalServer.HandleUiCommand(const ASession: THelpChatServerSession;
  const ACommand: string): Boolean;
var
  LHandler: THelpChatUiCommandEvent;
begin
  // The host is in this process: the command is handed to the UI layer on the
  // main thread and the request returns at once.
  FLock.Enter;
  try
    LHandler := FOnUiCommand;
  finally
    FLock.Leave;
  end;
  Result := Assigned(LHandler);
  if Result then
    TThread.Queue(nil,
      procedure
      begin
        LHandler(ACommand);
      end);
end;

end.
