unit HelpChatAI.Tests.Server;

interface

uses
  DUnitX.TestFramework,
  System.Net.HttpClient,
  System.Net.URLClient,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Theme,
  HelpChatAI.Engine,
  HelpChatAI.Transport,
  HelpChatAI.Server;

type
  /// <summary>Drives the local server over real HTTP with THTTPClient.</summary>
  [TestFixture]
  TServerTests = class
  strict private
    FSettings: THelpChatSettings;
    FEngine: THelpChatEngine;
    FServer: THelpChatLocalServer;
    FTransport: IHelpChatTransport; // keeps FServer alive
    FClient: THTTPClient;
    function Url(const APath: string): string;
    function Headers: TNetHeaders;
    function Get(const APath: string; const AWithToken: Boolean = True): IHTTPResponse;
    function Post(const APath, ABody: string; const AWithToken: Boolean = True): IHTTPResponse;
    function ExtractMsgIds(const AHtml: string): TArray<string>;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Start_BindsLocalhost_FreePort_Token;
    [Test] procedure Page_RequiresTokenInQuery;
    [Test] procedure Api_RequiresTokenHeader;
    [Test] procedure History_IsGreeting_WhenEmpty;
    [Test] procedure Send_Poll_Clear_RoundTrip;
    [Test] procedure Send_Empty_ReturnsNothing;
    [Test] procedure Send_UsesNativeContext_AndDecodesUtf8;
    [Test] procedure Poll_UnknownId_IsEmpty;
    [Test] procedure Cancel_ReturnsBubble;
    [Test] procedure Unknown_Is404;
    [Test] procedure UiCommand_ReachesHandler_OnMainThread;
    [Test] procedure FormField_Decoding;
    [Test] procedure Stop_Start_Again;
    [Test] procedure Page_CarriesTheHostTheme;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.NetEncoding,
  System.RegularExpressions,
  HelpChatAI.Messages,
  HelpChatAI.Panel,
  HelpChatAI.Tests.Helpers;

procedure TServerTests.Setup;
begin
  FSettings := THelpChatSettings.Create;
  FSettings.Language := hclEnglish;
  FSettings.PersistConversation := False;
  FSettings.DocIndexFile := 'Z:\no\index.json';
  FSettings.Provider := TEST_PROVIDER_ECHO;
  FEngine := THelpChatEngine.Create(FSettings);
  FServer := THelpChatLocalServer.Create(FEngine, False);
  FTransport := FServer;
  FTransport.Start;
  FClient := THTTPClient.Create;
  FClient.ConnectionTimeout := 5000;
  FClient.ResponseTimeout := 5000;
end;

procedure TServerTests.TearDown;
begin
  FClient.Free;
  FTransport.Stop;
  FTransport := nil;
  FServer := nil;
  FEngine.Free;
  FSettings.Free;
end;

function TServerTests.Url(const APath: string): string;
begin
  Result := FTransport.GetPanelOrigin + APath;
end;

function TServerTests.Headers: TNetHeaders;
begin
  Result := [TNetHeader.Create(HELPCHAT_TOKEN_HEADER, FServer.Token)];
end;

function TServerTests.Get(const APath: string; const AWithToken: Boolean): IHTTPResponse;
begin
  if AWithToken then
    Result := FClient.Get(Url(APath), nil, Headers)
  else
    Result := FClient.Get(Url(APath));
end;

function TServerTests.Post(const APath, ABody: string; const AWithToken: Boolean): IHTTPResponse;
var
  LSource: TStringStream;
  LHeaders: TNetHeaders;
begin
  LSource := TStringStream.Create(ABody, TEncoding.ASCII);
  try
    LHeaders := [TNetHeader.Create('Content-Type', 'application/x-www-form-urlencoded')];
    if AWithToken then
      LHeaders := LHeaders + Headers;
    Result := FClient.Post(Url(APath), LSource, nil, LHeaders);
  finally
    LSource.Free;
  end;
end;

function TServerTests.ExtractMsgIds(const AHtml: string): TArray<string>;
var
  LMatch: TMatch;
begin
  Result := nil;
  LMatch := TRegEx.Match(AHtml, 'data-msgid="([^"]+)"');
  while LMatch.Success do
  begin
    Result := Result + [LMatch.Groups[1].Value];
    LMatch := LMatch.NextMatch;
  end;
end;

procedure TServerTests.Start_BindsLocalhost_FreePort_Token;
begin
  Assert.IsTrue(FTransport.IsActive);
  Assert.IsTrue(FServer.BoundPort >= HELPCHAT_SERVER_PORT_MIN);
  Assert.StartsWith('http://127.0.0.1:', FTransport.GetPanelOrigin);
  Assert.AreEqual(32, FServer.Token.Length, 'a GUID without braces and dashes');
  Assert.AreEqual(FTransport.GetPanelOrigin + '/?t=' + FServer.Token, FTransport.GetPanelUrl);
  Assert.AreSame(FEngine, FTransport.GetEngine);
  Assert.IsTrue(FEngine.Active, 'Start starts the engine');
end;

procedure TServerTests.Page_RequiresTokenInQuery;
var
  LResponse: IHTTPResponse;
begin
  LResponse := FClient.Get(FTransport.GetPanelUrl);
  Assert.AreEqual(200, LResponse.StatusCode);
  Assert.StartsWith('text/html', LResponse.MimeType);
  Assert.Contains(LResponse.ContentAsString, '<title>Assistant</title>');
  Assert.Contains(LResponse.ContentAsString, '"token":"' + FServer.Token + '"');
  Assert.DoesNotContain(LResponse.ContentAsString, '{{');

  LResponse := FClient.Get(Url('/'));
  Assert.AreEqual(404, LResponse.StatusCode, 'no token, no page');
  LResponse := FClient.Get(Url('/?t=wrong'));
  Assert.AreEqual(404, LResponse.StatusCode);
end;

procedure TServerTests.Api_RequiresTokenHeader;
begin
  Assert.AreEqual(403, Get(HELPCHAT_API_HISTORY, False).StatusCode);
  Assert.AreEqual(403, Post(HELPCHAT_API_SEND, 'message=hi', False).StatusCode);
  Assert.AreEqual(403, Post(HELPCHAT_API_CLEAR, '', False).StatusCode);
  Assert.AreEqual(200, Get(HELPCHAT_API_HISTORY, True).StatusCode);
end;

procedure TServerTests.History_IsGreeting_WhenEmpty;
var
  LResponse: IHTTPResponse;
begin
  LResponse := Get(HELPCHAT_API_HISTORY);
  Assert.AreEqual(200, LResponse.StatusCode);
  Assert.Contains(LResponse.ContentAsString, 'hc-chat-greeting');
  Assert.Contains(LResponse.ContentAsString, HelpChatMsg(hcmGreeting, hclEnglish));
  Assert.Contains(LResponse.HeaderValue['Cache-Control'], 'no-store');
end;

procedure TServerTests.Send_Poll_Clear_RoundTrip;
var
  LResponse: IHTTPResponse;
  LIds: TArray<string>;
  LHtml: string;
begin
  LResponse := Post(HELPCHAT_API_SEND, 'message=hello+server');
  Assert.AreEqual(200, LResponse.StatusCode);
  LHtml := LResponse.ContentAsString;
  LIds := ExtractMsgIds(LHtml);
  Assert.AreEqual(2, Integer(Length(LIds)), 'user bubble + pending assistant bubble');
  Assert.Contains(LHtml, 'hc-chat-user');
  Assert.Contains(LHtml, 'hello server', '+ decoded as space');
  Assert.Contains(LHtml, 'data-pending="1"');

  Assert.IsTrue(WaitFor(
    function: Boolean
    begin
      LHtml := Get(HELPCHAT_API_POLL + LIds[1]).ContentAsString;
      Result := (LHtml <> '') and not LHtml.Contains('data-pending');
    end), 'the poll endpoint eventually returns the completed bubble');
  Assert.Contains(LHtml, 'echo:hello server|n=1');
  Assert.Contains(LHtml, 'data-msgid="' + LIds[1] + '"');

  LHtml := Get(HELPCHAT_API_HISTORY).ContentAsString;
  Assert.AreEqual(2, Integer(Length(ExtractMsgIds(LHtml))));
  Assert.DoesNotContain(LHtml, 'hc-chat-greeting');

  LResponse := Post(HELPCHAT_API_CLEAR, '');
  Assert.AreEqual(200, LResponse.StatusCode);
  Assert.Contains(LResponse.ContentAsString, 'hc-chat-greeting');
  Assert.AreEqual(0, Integer(Length(FEngine.Messages)));
end;

procedure TServerTests.Send_Empty_ReturnsNothing;
var
  LResponse: IHTTPResponse;
begin
  LResponse := Post(HELPCHAT_API_SEND, 'message=+++');
  Assert.AreEqual(200, LResponse.StatusCode);
  Assert.AreEqual('', LResponse.ContentAsString);
  Assert.AreEqual(0, Integer(Length(FEngine.Messages)));
end;

procedure TServerTests.Send_UsesNativeContext_AndDecodesUtf8;
var
  LContext: THelpChatContext;
  LIds: TArray<string>;
  LHtml: string;
begin
  // The context is set by the native side; the page never sends it.
  LContext := Default(THelpChatContext);
  LContext.ScreenLabel := 'Ordini';
  FTransport.SetContext(LContext);
  Assert.AreEqual('Ordini', FTransport.GetContext.ScreenLabel);

  LIds := ExtractMsgIds(Post(HELPCHAT_API_SEND,
    'message=' + TNetEncoding.URL.Encode('città è più')).ContentAsString);
  Assert.AreEqual(2, Integer(Length(LIds)));
  Assert.IsTrue(WaitFor(
    function: Boolean
    begin
      LHtml := Get(HELPCHAT_API_POLL + LIds[1]).ContentAsString;
      Result := (LHtml <> '') and not LHtml.Contains('data-pending');
    end));
  Assert.Contains(LHtml, 'echo:città è più|n=1', 'UTF-8 survives the form encoding and the response');
end;

procedure TServerTests.Poll_UnknownId_IsEmpty;
var
  LResponse: IHTTPResponse;
begin
  LResponse := Get(HELPCHAT_API_POLL + 'does-not-exist');
  Assert.AreEqual(200, LResponse.StatusCode);
  Assert.AreEqual('', LResponse.ContentAsString, 'empty body tells the client to stop polling');
end;

procedure TServerTests.Cancel_ReturnsBubble;
var
  LIds: TArray<string>;
  LHtml: string;
begin
  FSettings.Provider := TEST_PROVIDER_SLOW;
  LIds := ExtractMsgIds(Post(HELPCHAT_API_SEND, 'message=go').ContentAsString);
  Assert.AreEqual(2, Integer(Length(LIds)));
  LHtml := Post(HELPCHAT_API_CANCEL + LIds[1], '').ContentAsString;
  Assert.Contains(LHtml, 'data-msgid="' + LIds[1] + '"');
  Assert.IsTrue(WaitFor(
    function: Boolean
    begin
      LHtml := Get(HELPCHAT_API_POLL + LIds[1]).ContentAsString;
      Result := (LHtml <> '') and not LHtml.Contains('data-pending');
    end, 3000), 'a cancelled reply completes quickly');
  Assert.DoesNotContain(LHtml, StringOfChar('x', 40), 'not the whole reply');
end;

procedure TServerTests.UiCommand_ReachesHandler_OnMainThread;
var
  LGot: string;
  LOnMainThread: Boolean;
  I: Integer;
begin
  LGot := '';
  LOnMainThread := False;
  FServer.SetOnUiCommand(
    procedure(const ACommand: string)
    begin
      LGot := ACommand;
      LOnMainThread := TThread.CurrentThread.ThreadID = MainThreadID;
    end);
  Assert.AreEqual(200, Post(HELPCHAT_API_UI + 'Close', '').StatusCode);
  Assert.AreEqual(403, Post(HELPCHAT_API_UI + 'close', '', False).StatusCode, 'token required');
  Assert.AreEqual(404, Get(HELPCHAT_API_UI + 'close').StatusCode, 'POST only');
  // Delivered with TThread.Queue: a console has to pump it.
  for I := 1 to 200 do
  begin
    CheckSynchronize(10);
    if LGot <> '' then
      Break;
  end;
  Assert.AreEqual('close', LGot, 'lower-cased command');
  Assert.IsTrue(LOnMainThread, 'delivered on the main thread');
  FServer.SetOnUiCommand(nil);
end;

procedure TServerTests.Unknown_Is404;
begin
  Assert.AreEqual(404, Get('/nothing-here').StatusCode);
  Assert.AreEqual(404, Get('/api/nothing').StatusCode);
  Assert.AreEqual(404, Post(HELPCHAT_API_HISTORY, '').StatusCode, 'wrong verb');
  Assert.AreEqual(404, Get(HELPCHAT_API_CLEAR).StatusCode, 'wrong verb');
end;

procedure TServerTests.FormField_Decoding;
begin
  Assert.AreEqual('hello world', THelpChatLocalServer.FormField('a=1&message=hello+world&b=2', 'message'));
  Assert.AreEqual('città è più', THelpChatLocalServer.FormField('message=citt%C3%A0+%C3%A8+pi%C3%B9', 'message'));
  Assert.AreEqual('a+b=c&d', THelpChatLocalServer.FormField('message=a%2Bb%3Dc%26d', 'message'));
  Assert.AreEqual('', THelpChatLocalServer.FormField('other=x', 'message'));
  Assert.AreEqual('x', THelpChatLocalServer.FormField('MESSAGE=x', 'message'), 'field names are case-insensitive');
end;

procedure TServerTests.Page_CarriesTheHostTheme;
var
  LPage: string;
begin
  LPage := FClient.Get(FTransport.GetPanelUrl).ContentAsString;
  Assert.Contains(LPage, '<style id="hc-theme"></style>', 'no theme set: page defaults');
  FTransport.SetTheme(THelpChatTheme.Dark);
  Assert.IsTrue(FTransport.GetTheme.IsDark);
  LPage := FClient.Get(FTransport.GetPanelUrl).ContentAsString;
  Assert.Contains(LPage, '<style id="hc-theme">:root{--hc-bg:#17191d;');
  Assert.Contains(LPage, 'color-scheme:dark;');
end;

procedure TServerTests.Stop_Start_Again;
var
  LOrigin: string;
begin
  LOrigin := FTransport.GetPanelOrigin;
  FTransport.Stop;
  Assert.IsFalse(FTransport.IsActive);
  Assert.AreEqual('', FTransport.GetPanelUrl);
  FTransport.Start;
  Assert.IsTrue(FTransport.IsActive);
  Assert.AreEqual(200, Get(HELPCHAT_API_HISTORY).StatusCode);
  Assert.AreNotEqual(LOrigin + 'x', FTransport.GetPanelOrigin + 'x'); // no-op sanity: origins are comparable strings
end;

end.
