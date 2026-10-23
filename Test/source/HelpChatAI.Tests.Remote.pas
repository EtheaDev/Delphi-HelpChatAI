{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Tests of the remote setup: the multi-session server, the host channel   }
{       of the client and the transport that ties them together, all over      }
{       real HTTP on 127.0.0.1.                                                }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
unit HelpChatAI.Tests.Remote;

interface

uses
  DUnitX.TestFramework,
  System.Net.HttpClient,
  System.Net.URLClient,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider,
  HelpChatAI.Engine,
  HelpChatAI.Transport,
  HelpChatAI.Server,
  HelpChatAI.Server.Remote;

const
  /// <summary>Replies with the screen context it was given: proves the context
  /// posted by a remote client reaches the provider.</summary>
  TEST_PROVIDER_CONTEXT = 'test-context';
  TEST_APP_KEY = 'test-app-key';

type
  TContextProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  [TestFixture]
  TRemoteTests = class
  strict private
    FSettings: THelpChatSettings;
    FEngine: THelpChatEngine;
    FServer: THelpChatRemoteServer;
    FClient: THTTPClient;
    FFolder: string;
    procedure StartServer(const AStorage: THelpChatSessionStorage = hssMemory);
    procedure StopServer;
    function Url(const APath: string): string;
    function OpenSession(const AUser: string; const AAppKey: string = TEST_APP_KEY;
      const AExtra: string = ''): string;
    function Get(const APath, AToken: string): IHTTPResponse;
    function Post(const APath, ABody, AToken: string): IHTTPResponse;
    function Ask(const AToken, AText: string): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Start_WithoutAppKey_Raises;
    [Test] procedure Session_RequiresKnownAppKey;
    [Test] procedure Page_RequiresSessionToken;
    [Test] procedure Sessions_AreIsolated;
    [Test] procedure InMemory_TheConversationEndsWithTheSession;
    [Test] procedure Context_ReachesTheProvider;
    [Test] procedure Theme_TravelsAsCss;
    [Test] procedure UiCommand_IsNotTheServersBusiness;
    [Test] procedure Health_ReportsTheServer;
    [Test] procedure Sweep_EndsIdleSessions;
    [Test] procedure Disk_KeepsTheConversation;
    [Test] procedure KeyToFileName_IsSafeAndStable;
    [Test] procedure HostChannel_DeliversCommands_WithCorsAndToken;
    [Test] procedure Transport_EndToEnd;
    [Test] procedure Transport_UnreachableServer_Raises;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.RegularExpressions,
  HelpChatAI.Messages,
  HelpChatAI.Panel,
  HelpChatAI.Theme,
  HelpChatAI.Server.HostChannel,
  HelpChatAI.Transport.Remote,
  HelpChatAI.Tests.Helpers;

{ TContextProvider }

function TContextProvider.GetName: string;
begin
  Result := TEST_PROVIDER_CONTEXT;
end;

function TContextProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
begin
  Result := Format('ctx:%s|%s|%s', [AContext.ScreenLabel, AContext.HelpKeyword,
    LastUserMessage(AHistory)]);
end;

{ TRemoteTests }

procedure TRemoteTests.Setup;
begin
  FSettings := THelpChatSettings.Create;
  FSettings.Language := hclEnglish;
  FSettings.PersistConversation := False; // the server persists, not the engine
  FSettings.DocIndexFile := 'Z:\no\index.json';
  FSettings.Provider := TEST_PROVIDER_ECHO;
  FEngine := THelpChatEngine.Create(FSettings);
  FClient := THTTPClient.Create;
  FClient.ConnectionTimeout := 5000;
  FClient.ResponseTimeout := 5000;
  FFolder := TPath.Combine(TPath.GetTempPath, 'helpchat-remote-' + TGUID.NewGuid.ToString.Trim(['{', '}']));
end;

procedure TRemoteTests.TearDown;
begin
  StopServer;
  FClient.Free;
  FEngine.Free;
  FSettings.Free;
  if TDirectory.Exists(FFolder) then
    TDirectory.Delete(FFolder, True);
end;

procedure TRemoteTests.StartServer(const AStorage: THelpChatSessionStorage);
begin
  FServer := THelpChatRemoteServer.Create(FEngine, False);
  FServer.BindIP := HELPCHAT_SERVER_HOST; // tests never open a port to the network
  FServer.Port := 0;                      // a free one
  FServer.AppKeys.Add(TEST_APP_KEY);
  FServer.Storage := AStorage;
  FServer.SessionFolder := FFolder;
  FServer.Start;
end;

procedure TRemoteTests.StopServer;
begin
  if Assigned(FServer) then
  begin
    FServer.Stop;
    FreeAndNil(FServer);
  end;
end;

function TRemoteTests.Url(const APath: string): string;
begin
  Result := Format('http://%s:%d%s', [HELPCHAT_SERVER_HOST, FServer.BoundPort, APath]);
end;

function TRemoteTests.Get(const APath, AToken: string): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(HELPCHAT_TOKEN_HEADER, AToken)];
  Result := FClient.Get(Url(APath), nil, LHeaders);
end;

function TRemoteTests.Post(const APath, ABody, AToken: string): IHTTPResponse;
var
  LHeaders: TNetHeaders;
  LBody: TStringStream;
begin
  LHeaders := [TNetHeader.Create(HELPCHAT_TOKEN_HEADER, AToken),
    TNetHeader.Create('Content-Type', 'application/x-www-form-urlencoded')];
  LBody := TStringStream.Create(ABody, TEncoding.UTF8);
  try
    Result := FClient.Post(Url(APath), LBody, nil, LHeaders);
  finally
    LBody.Free;
  end;
end;

function TRemoteTests.OpenSession(const AUser, AAppKey, AExtra: string): string;
var
  LHeaders: TNetHeaders;
  LBody: TStringStream;
  LResponse: IHTTPResponse;
  LValue: TJSONValue;
begin
  Result := '';
  LHeaders := [TNetHeader.Create(HELPCHAT_KEY_HEADER, AAppKey),
    TNetHeader.Create('Content-Type', 'application/x-www-form-urlencoded')];
  LBody := TStringStream.Create('user=' + AUser + AExtra, TEncoding.UTF8);
  try
    LResponse := FClient.Post(Url(HELPCHAT_SESSION_PATH), LBody, nil, LHeaders);
  finally
    LBody.Free;
  end;
  if LResponse.StatusCode <> 200 then
    Exit;
  LValue := TJSONObject.ParseJSONValue(LResponse.ContentAsString(TEncoding.UTF8));
  try
    if LValue is TJSONObject then
      Result := TJSONObject(LValue).GetValue<string>('token', '');
  finally
    LValue.Free;
  end;
end;

function TRemoteTests.Ask(const AToken, AText: string): string;
var
  LHtml, LId: string;
  LMatch: TMatch;
begin
  // Send and wait for the reply of that conversation to be complete.
  LHtml := Post(HELPCHAT_API_SEND, 'message=' + AText, AToken).ContentAsString(TEncoding.UTF8);
  LMatch := TRegEx.Match(LHtml, 'data-msgid="([^"]+)"[^>]*data-pending');
  Assert.IsTrue(LMatch.Success, 'the send returns a pending assistant bubble: ' + LHtml);
  LId := LMatch.Groups[1].Value;
  Assert.IsTrue(WaitFor(
    function: Boolean
    begin
      LHtml := Get(HELPCHAT_API_POLL + LId, AToken).ContentAsString(TEncoding.UTF8);
      Result := (LHtml <> '') and not LHtml.Contains('data-pending');
    end), 'the reply completes');
  Result := LHtml;
end;

procedure TRemoteTests.Start_WithoutAppKey_Raises;
begin
  FServer := THelpChatRemoteServer.Create(FEngine, False);
  FServer.BindIP := HELPCHAT_SERVER_HOST;
  FServer.Port := 0;
  // An open server would spend the model budget of whoever finds it.
  Assert.WillRaise(
    procedure
    begin
      FServer.Start;
    end, EHelpChatError);
  Assert.IsFalse(FServer.IsActive);
end;

procedure TRemoteTests.Session_RequiresKnownAppKey;
begin
  StartServer;
  Assert.AreEqual('', OpenSession('', 'not-a-key'), 'unknown application key');
  Assert.AreEqual(0, FServer.SessionCount);
  Assert.IsTrue(OpenSession('') <> '', 'the configured key opens a session');
  Assert.AreEqual(1, FServer.SessionCount);
end;

procedure TRemoteTests.Page_RequiresSessionToken;
var
  LToken, LPage: string;
begin
  StartServer;
  LToken := OpenSession('');
  Assert.AreEqual(404, Integer(FClient.Get(Url('/?' + HELPCHAT_TOKEN_QUERY + '=wrong')).StatusCode));
  LPage := FClient.Get(Url('/?' + HELPCHAT_TOKEN_QUERY + '=' + LToken)).ContentAsString(TEncoding.UTF8);
  Assert.Contains(LPage, 'id="hc-body"', 'the panel page');
  Assert.Contains(LPage, LToken, 'the page carries its own secret');
end;

procedure TRemoteTests.Sessions_AreIsolated;
var
  LFirst, LSecond: string;
begin
  StartServer;
  LFirst := OpenSession('');
  LSecond := OpenSession('');
  Assert.AreNotEqual(LFirst, LSecond);

  Assert.Contains(Ask(LFirst, 'one'), 'echo:one|n=1');
  // The second client sees its own conversation, not the first one's.
  Assert.DoesNotContain(Get(HELPCHAT_API_HISTORY, LSecond).ContentAsString(TEncoding.UTF8), 'echo:one');
  Assert.Contains(Ask(LSecond, 'two'), 'echo:two|n=1', 'its history starts empty too');
end;

procedure TRemoteTests.InMemory_TheConversationEndsWithTheSession;
var
  LFirst, LSecond, LOther: string;
begin
  StartServer; // memory storage
  LFirst := OpenSession('bob');
  Assert.Contains(Ask(LFirst, 'hello'), 'echo:hello|n=1');

  // A second device of the same user joins the conversation that is live.
  LOther := OpenSession('bob');
  Assert.Contains(Get(HELPCHAT_API_HISTORY, LOther).ContentAsString(TEncoding.UTF8), 'hello');
  Post(HELPCHAT_SESSION_END_PATH, '', LOther);
  Assert.Contains(Get(HELPCHAT_API_HISTORY, LFirst).ContentAsString(TEncoding.UTF8), 'hello',
    'one device leaving does not wipe what the other is reading');

  // When the last one leaves, memory storage keeps nothing: only disk does.
  Post(HELPCHAT_SESSION_END_PATH, '', LFirst);
  Assert.AreEqual(0, FServer.SessionCount);
  LSecond := OpenSession('bob');
  Assert.DoesNotContain(Get(HELPCHAT_API_HISTORY, LSecond).ContentAsString(TEncoding.UTF8), 'hello');
end;

procedure TRemoteTests.Context_ReachesTheProvider;
var
  LToken: string;
begin
  FSettings.Provider := TEST_PROVIDER_CONTEXT;
  StartServer;
  LToken := OpenSession('');
  // What the native client posts before asking: the screen the user is on.
  Assert.AreEqual(200, Integer(Post(HELPCHAT_API_CONTEXT,
    'screenName=TMailForm&screenLabel=Server+di+posta&helpKeyword=Configurazione+e-mail',
    LToken).StatusCode));
  Assert.Contains(Ask(LToken, 'come+faccio'), 'ctx:Server di posta|Configurazione e-mail|come faccio');
end;

procedure TRemoteTests.Theme_TravelsAsCss;
var
  LToken, LPage, LCss: string;
begin
  StartServer;
  LToken := OpenSession('');
  LPage := FClient.Get(Url('/?' + HELPCHAT_TOKEN_QUERY + '=' + LToken)).ContentAsString(TEncoding.UTF8);
  Assert.Contains(LPage, '<style id="hc-theme"></style>', 'no colours yet: page defaults');

  // The colours are produced by the framework on the client and arrive as CSS.
  LCss := THelpChatTheme.Dark.ToCss;
  Assert.AreEqual(200, Integer(Post(HELPCHAT_API_THEME,
    'themeCss=' + HelpChatFormEncode(LCss), LToken).StatusCode));
  LPage := FClient.Get(Url('/?' + HELPCHAT_TOKEN_QUERY + '=' + LToken)).ContentAsString(TEncoding.UTF8);
  Assert.Contains(LPage, 'color-scheme:dark;');
end;

procedure TRemoteTests.UiCommand_IsNotTheServersBusiness;
var
  LToken: string;
begin
  StartServer;
  LToken := OpenSession('');
  // The window to close is on the client: its own channel answers, not this.
  Assert.AreEqual(404, Integer(Post(HELPCHAT_API_UI + 'close', '', LToken).StatusCode));
end;

procedure TRemoteTests.Health_ReportsTheServer;
var
  LValue: TJSONValue;
begin
  StartServer;
  OpenSession('');
  LValue := TJSONObject.ParseJSONValue(FClient.Get(Url('/health')).ContentAsString(TEncoding.UTF8));
  try
    Assert.IsTrue(LValue is TJSONObject);
    Assert.AreEqual('ok', TJSONObject(LValue).GetValue<string>('status'));
    Assert.AreEqual(1, TJSONObject(LValue).GetValue<Integer>('sessions'));
    Assert.AreEqual(TEST_PROVIDER_ECHO, TJSONObject(LValue).GetValue<string>('provider'));
  finally
    LValue.Free;
  end;
end;

procedure TRemoteTests.Sweep_EndsIdleSessions;
var
  LToken: string;
begin
  StartServer;
  LToken := OpenSession('');
  FServer.IdleSeconds := 3600;
  FServer.Sweep;
  Assert.AreEqual(1, FServer.SessionCount, 'still fresh');

  FServer.IdleSeconds := 0;
  FServer.Sweep;
  Assert.AreEqual(1, FServer.SessionCount, '0 disables the expiry');

  FServer.IdleSeconds := 1;
  Sleep(1200);
  FServer.Sweep;
  Assert.AreEqual(0, FServer.SessionCount, 'idle for longer than the limit');
  Assert.AreEqual(403, Integer(Get(HELPCHAT_API_HISTORY, LToken).StatusCode), 'its secret is worthless now');
end;

procedure TRemoteTests.Disk_KeepsTheConversation;
var
  LToken: string;
  LFiles: TArray<string>;
begin
  StartServer(hssDisk);
  LToken := OpenSession('ann');
  Assert.Contains(Ask(LToken, 'remember'), 'echo:remember');
  StopServer;                       // saves what is open, like a shutdown
  LFiles := TDirectory.GetFiles(FFolder, '*.json');
  Assert.AreEqual(1, Integer(Length(LFiles)), 'one file for the conversation of ann');

  // A new server on the same folder, with an engine that knows nothing.
  FEngine.Free;
  FEngine := THelpChatEngine.Create(FSettings);
  StartServer(hssDisk);
  LToken := OpenSession('ann');
  Assert.Contains(Get(HELPCHAT_API_HISTORY, LToken).ContentAsString(TEncoding.UTF8), 'remember',
    'the conversation outlives the server');

  // An unknown user starts from the greeting.
  LToken := OpenSession('zoe');
  Assert.DoesNotContain(Get(HELPCHAT_API_HISTORY, LToken).ContentAsString(TEncoding.UTF8), 'remember');
end;

procedure TRemoteTests.KeyToFileName_IsSafeAndStable;
var
  LName: string;
begin
  LName := HelpChatKeyToFileName('u:bob');
  Assert.IsTrue(LName.StartsWith('u_bob-'), 'readable when it can be: ' + LName);
  Assert.AreEqual(LName, HelpChatKeyToFileName('u:bob'), 'stable for the same key');
  LName := HelpChatKeyToFileName('u:../../etc/passwd');
  Assert.IsFalse(LName.Contains('/'), 'no path separator survives: ' + LName);
  Assert.IsFalse(LName.Contains('\'), 'no path separator survives: ' + LName);
  Assert.IsFalse(LName.Contains('..'), 'no traversal survives: ' + LName);
  Assert.AreNotEqual(HelpChatKeyToFileName('u:a b'), HelpChatKeyToFileName('u:a-b'),
    'different keys, different files');
  Assert.IsTrue(HelpChatKeyToFileName('u:bob').EndsWith('.json'));
end;

procedure TRemoteTests.HostChannel_DeliversCommands_WithCorsAndToken;
var
  LChannel: THelpChatHostChannel;
  LGot: string;
  LOnMainThread: Boolean;
  LHeaders: TNetHeaders;
  LResponse: IHTTPResponse;
  LBody: TStringStream;
  I: Integer;
begin
  LGot := '';
  LOnMainThread := False;
  LChannel := THelpChatHostChannel.Create;
  try
    LChannel.AllowedOrigin := 'https://help.example.com';
    LChannel.OnCommand :=
      procedure(const ACommand: string)
      begin
        LGot := ACommand;
        LOnMainThread := TThread.CurrentThread.ThreadID = MainThreadID;
      end;
    Assert.IsTrue(LChannel.Start, 'a loopback port is available');
    Assert.IsTrue(LChannel.GetOrigin.StartsWith('http://127.0.0.1:'));

    // The preflight the browser sends before a cross-origin call to 127.0.0.1.
    LResponse := FClient.Options(LChannel.GetOrigin + HELPCHAT_API_UI + 'close');
    Assert.AreEqual(204, Integer(LResponse.StatusCode));
    Assert.AreEqual('https://help.example.com',
      LResponse.HeaderValue['Access-Control-Allow-Origin'], 'the panel origin, never *');
    Assert.AreEqual('true', LResponse.HeaderValue['Access-Control-Allow-Private-Network']);

    LBody := TStringStream.Create('', TEncoding.UTF8);
    try
      LHeaders := [TNetHeader.Create(HELPCHAT_TOKEN_HEADER, 'wrong')];
      Assert.AreEqual(403, Integer(FClient.Post(LChannel.GetOrigin + HELPCHAT_API_UI + 'close',
        LBody, nil, LHeaders).StatusCode), 'the channel has its own secret');

      LBody.Position := 0;
      LHeaders := [TNetHeader.Create(HELPCHAT_TOKEN_HEADER, LChannel.Token)];
      Assert.AreEqual(204, Integer(FClient.Post(LChannel.GetOrigin + HELPCHAT_API_UI + 'Close',
        LBody, nil, LHeaders).StatusCode));
    finally
      LBody.Free;
    end;

    // Delivered with TThread.Queue: a console has to pump it.
    for I := 1 to 200 do
    begin
      CheckSynchronize(10);
      if LGot <> '' then
        Break;
    end;
    Assert.AreEqual('close', LGot, 'lower-cased command');
    Assert.IsTrue(LOnMainThread, 'delivered on the main thread');
  finally
    LChannel.Free;
  end;
end;

procedure TRemoteTests.Transport_EndToEnd;
var
  LTransport: IHelpChatTransport;
  LRemote: THelpChatRemoteTransport;
  LContext: THelpChatContext;
  LToken, LPage: string;
begin
  FSettings.Provider := TEST_PROVIDER_CONTEXT;
  StartServer;
  LRemote := THelpChatRemoteTransport.Create(Url(''), TEST_APP_KEY);
  LTransport := LRemote; // reference counted from here
  LRemote.UserId := 'carl';
  LTransport.Start;
  try
    Assert.IsTrue(LTransport.IsActive, 'ready to be used');
    Assert.IsTrue(LTransport.GetEngine = nil, 'no engine on this side');
    Assert.IsFalse(LRemote.HasSession, 'starting touches no network');
    Assert.AreEqual(0, FServer.SessionCount, 'the conversation opens on first use');
    Assert.AreEqual(Format('http://%s:%d', [HELPCHAT_SERVER_HOST, FServer.BoundPort]),
      LTransport.GetPanelOrigin);

    // The page loads from the server, with the secret of this session, which
    // is opened right here.
    LPage := FClient.Get(LTransport.GetPanelUrl).ContentAsString(TEncoding.UTF8);
    Assert.IsTrue(LRemote.HasSession);
    Assert.AreEqual(1, FServer.SessionCount);
    Assert.Contains(LPage, 'id="hc-body"');
    // ...and it knows where to reach its host: the loopback channel.
    Assert.IsTrue(Assigned(LRemote.HostChannel), 'the host channel is open');
    Assert.Contains(LPage, '"uiBase":"' + LRemote.HostChannel.GetOrigin + '"',
      'the page is told where its host listens');
    // ...and the page policy lets it call exactly that, or the browser would
    // drop the call before it reaches the network.
    Assert.Contains(LPage, 'connect-src ''self''  ' + LRemote.HostChannel.GetOrigin + ';',
      'the content security policy names the host channel');

    // The screen context travels to the session, natively, before any question.
    LContext := Default(THelpChatContext);
    LContext.ScreenLabel := 'Scheduler';
    LContext.HelpKeyword := 'Scheduler dei Report';
    LTransport.SetContext(LContext);
    Assert.AreEqual('Scheduler', LTransport.GetContext.ScreenLabel);

    LToken := LTransport.GetPanelUrl.Substring(LTransport.GetPanelUrl.IndexOf('=') + 1);
    Assert.Contains(Ask(LToken, 'ciao'), 'ctx:Scheduler|Scheduler dei Report|ciao');

    // The colours of the client reach the page it will load next.
    LTransport.SetTheme(THelpChatTheme.Dark);
    LPage := FClient.Get(LTransport.GetPanelUrl).ContentAsString(TEncoding.UTF8);
    Assert.Contains(LPage, 'color-scheme:dark;');
  finally
    LTransport.Stop;
  end;
  Assert.IsFalse(LTransport.IsActive);
  Assert.AreEqual(0, FServer.SessionCount, 'the session is closed, not left to expire');
end;

procedure TRemoteTests.Transport_UnreachableServer_Raises;
var
  LTransport: IHelpChatTransport;
begin
  LTransport := THelpChatRemoteTransport.Create('http://127.0.0.1:1', TEST_APP_KEY);
  // Nothing is listening there, but an application must still start: the
  // failure belongs to the moment the user asks for help, not to the splash
  // screen.
  LTransport.Start;
  Assert.IsTrue(LTransport.IsActive);
  Assert.WillRaise(
    procedure
    begin
      LTransport.GetPanelUrl;
    end, EHelpChatError, 'opening the panel says the server is unreachable');
end;

initialization
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_CONTEXT, TContextProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_CONTEXT);

end.
