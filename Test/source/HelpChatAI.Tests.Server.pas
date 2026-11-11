unit HelpChatAI.Tests.Server;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Theme,
  HelpChatAI.Engine,
  HelpChatAI.Transport,
  HelpChatAI.Html,
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
    /// <summary>An upload: the bytes as the whole body, the name in the query.</summary>
    function PostFile(const AFileName: string; const AData: TBytes): IHTTPResponse;
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
    [Test] procedure Page_CarriesTheAssistant_SetAndPosted;
    [Test] procedure Attach_Upload_List_Remove;
    [Test] procedure Attach_RefusedType_AnswersWithTheSentence;
    [Test] procedure Attach_Disabled_IsRefused;
    [Test] procedure Attach_ClearTakesThemAway;
    [Test] procedure Pdf_Answer_ReachesTheHost;
    [Test] procedure Pdf_Conversation_HasBothSides;
    [Test] procedure Pdf_WithoutAHost_Says501;
    [Test] procedure Pdf_Disabled_Says403;
    [Test] procedure Assistants_List_AndSelect;
    [Test] procedure Assistants_Single_CannotSelect;
    [Test] procedure Languages_List_AndSelect;
    [Test] procedure Languages_Single_CannotSelect;
    [Test] procedure Commands_List_FollowsTheSession;
    [Test] procedure Command_Who_AndDisabledIs403;
  end;

implementation

uses
  System.Classes,
  System.NetEncoding,
  System.JSON,
  System.RegularExpressions,
  HelpChatAI.Messages,
  HelpChatAI.Panel,
  HelpChatAI.Commands,
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

function TServerTests.PostFile(const AFileName: string;
  const AData: TBytes): IHTTPResponse;
var
  LSource: TBytesStream;
  LHeaders: TNetHeaders;
begin
  LSource := TBytesStream.Create(AData);
  try
    LHeaders := [TNetHeader.Create('Content-Type', 'application/octet-stream')] + Headers;
    Result := FClient.Post(Url(HELPCHAT_API_ATTACH + '?' +
      HELPCHAT_ATTACH_NAME_QUERY + '=' + TNetEncoding.URL.Encode(AFileName)),
      LSource, nil, LHeaders);
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

procedure TServerTests.Attach_Upload_List_Remove;
var
  LResponse: IHTTPResponse;
  LRoot: TJSONValue;
  LId: string;
begin
  FSettings.Attachments.Enabled := True;
  LResponse := PostFile('invoice.pdf', TEncoding.UTF8.GetBytes('%PDF-1.7 pretend'));
  Assert.AreEqual(200, LResponse.StatusCode);
  LRoot := TJSONObject.ParseJSONValue(LResponse.ContentAsString(TEncoding.UTF8));
  try
    Assert.IsTrue(LRoot is TJSONObject, LResponse.ContentAsString(TEncoding.UTF8));
    LId := TJSONObject(LRoot).GetValue<string>('id', '');
    Assert.AreNotEqual('', LId, 'the chip needs an id to remove it with');
    Assert.AreEqual('invoice.pdf', TJSONObject(LRoot).GetValue<string>('name'));
    Assert.AreEqual('pdf', TJSONObject(LRoot).GetValue<string>('ext'));
    Assert.AreNotEqual('', TJSONObject(LRoot).GetValue<string>('sizeText'));
  finally
    LRoot.Free;
  end;

  // The page rebuilds its bar from here after a reload.
  LResponse := Get(HELPCHAT_API_ATTACHMENTS);
  Assert.IsTrue(LResponse.ContentAsString(TEncoding.UTF8).Contains('invoice.pdf'));
  Assert.AreEqual(1, FEngine.Attachments.Count(FEngine.ConversationKey));

  LResponse := Post(HELPCHAT_API_ATTACH_REMOVE, HELPCHAT_FIELD_ATTACH_ID + '=' + LId);
  Assert.AreEqual(200, LResponse.StatusCode);
  Assert.AreEqual(0, FEngine.Attachments.Count(FEngine.ConversationKey));
  Assert.IsFalse(Get(HELPCHAT_API_ATTACHMENTS).ContentAsString(TEncoding.UTF8)
    .Contains('invoice.pdf'));
end;

procedure TServerTests.Attach_RefusedType_AnswersWithTheSentence;
var
  LRoot: TJSONValue;
  LError: string;
begin
  FSettings.Attachments.Enabled := True;
  LRoot := TJSONObject.ParseJSONValue(
    PostFile('contract.docx', TEncoding.UTF8.GetBytes('PK')).ContentAsString(TEncoding.UTF8));
  try
    LError := TJSONObject(LRoot).GetValue<string>('error', '');
    Assert.IsTrue(LError.Contains('DOCX'), 'the page shows this as it is: ' + LError);
  finally
    LRoot.Free;
  end;
  Assert.AreEqual(0, FEngine.Attachments.Count(FEngine.ConversationKey));
end;

procedure TServerTests.Attach_Disabled_IsRefused;
var
  LRoot: TJSONValue;
begin
  // Off is the default: a page that asks anyway gets an error, not a chip.
  LRoot := TJSONObject.ParseJSONValue(
    PostFile('invoice.pdf', TEncoding.UTF8.GetBytes('%PDF')).ContentAsString(TEncoding.UTF8));
  try
    Assert.AreNotEqual('', TJSONObject(LRoot).GetValue<string>('error', ''));
    Assert.AreEqual('', TJSONObject(LRoot).GetValue<string>('id', ''));
  finally
    LRoot.Free;
  end;
  Assert.AreEqual(0, FEngine.Attachments.Count(FEngine.ConversationKey));
end;

procedure TServerTests.Attach_ClearTakesThemAway;
begin
  FSettings.Attachments.Enabled := True;
  PostFile('invoice.pdf', TEncoding.UTF8.GetBytes('%PDF'));
  Assert.AreEqual(1, FEngine.Attachments.Count(FEngine.ConversationKey));
  Post(HELPCHAT_API_CLEAR, '');
  Assert.AreEqual(0, FEngine.Attachments.Count(FEngine.ConversationKey),
    'the documents went with the conversation');
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

// The document is built by the engine and handed to the host on the main
// thread: everything below the save dialog, which belongs to the components.
procedure TServerTests.Pdf_Answer_ReachesTheHost;
var
  LGot: THelpChatPrintableDoc;
  LOnMainThread: Boolean;
  LIds: TArray<string>;
  I: Integer;
begin
  LGot := Default(THelpChatPrintableDoc);
  LOnMainThread := False;
  FServer.SetOnPdfRequest(
    procedure(const ADoc: THelpChatPrintableDoc)
    begin
      LGot := ADoc;
      LOnMainThread := TThread.CurrentThread.ThreadID = MainThreadID;
    end);
  try
    LIds := ExtractMsgIds(Post(HELPCHAT_API_SEND,
      HELPCHAT_FIELD_MESSAGE + '=' + 'what is **this**').ContentAsString);
    Assert.IsTrue(Length(LIds) >= 2, 'a question and a reply');
    // The echo provider answers at once, but not synchronously.
    for I := 1 to 200 do
    begin
      if not Get(HELPCHAT_API_POLL + LIds[1]).ContentAsString.Contains('data-pending') then
        Break;
      Sleep(10);
    end;
    Assert.AreEqual(200, Post(HELPCHAT_API_PDF,
      HELPCHAT_FIELD_PDF_KIND + '=' + HELPCHAT_PDF_KIND_ANSWER + '&' +
      HELPCHAT_FIELD_PDF_ID + '=' + LIds[1]).StatusCode);
    for I := 1 to 200 do
    begin
      CheckSynchronize(10);
      if LGot.BodyHtml <> '' then
        Break;
    end;
    Assert.IsTrue(LOnMainThread, 'delivered on the main thread');
    Assert.IsTrue(LGot.BodyHtml.Contains('<strong>this</strong>'),
      'the reply as Markdown, like the bubble');
    Assert.AreEqual('', LGot.Css, 'the stylesheet is the client''s');
    Assert.IsTrue(LGot.Title <> '', 'a document has a title: it names the file');
    // An id nobody knows is not a document.
    Assert.AreEqual(404, Post(HELPCHAT_API_PDF,
      HELPCHAT_FIELD_PDF_KIND + '=' + HELPCHAT_PDF_KIND_ANSWER +
      '&' + HELPCHAT_FIELD_PDF_ID + '=nothing').StatusCode);
    Assert.AreEqual(404, Post(HELPCHAT_API_PDF,
      HELPCHAT_FIELD_PDF_KIND + '=nonsense').StatusCode, 'an unknown kind');
  finally
    FServer.SetOnPdfRequest(nil);
  end;
end;

procedure TServerTests.Pdf_Conversation_HasBothSides;
var
  LGot: THelpChatPrintableDoc;
  I: Integer;
begin
  LGot := Default(THelpChatPrintableDoc);
  FServer.SetOnPdfRequest(
    procedure(const ADoc: THelpChatPrintableDoc)
    begin
      LGot := ADoc;
    end);
  try
    // Nothing said yet: there is nothing to print, and that is a 404.
    Assert.AreEqual(404, Post(HELPCHAT_API_PDF,
      HELPCHAT_FIELD_PDF_KIND + '=' + HELPCHAT_PDF_KIND_CONVERSATION).StatusCode);
    Post(HELPCHAT_API_SEND, HELPCHAT_FIELD_MESSAGE + '=hello');
    for I := 1 to 200 do
    begin
      if not Get(HELPCHAT_API_HISTORY).ContentAsString.Contains('data-pending') then
        Break;
      Sleep(10);
    end;
    Assert.AreEqual(200, Post(HELPCHAT_API_PDF,
      HELPCHAT_FIELD_PDF_KIND + '=' + HELPCHAT_PDF_KIND_CONVERSATION).StatusCode);
    for I := 1 to 200 do
    begin
      CheckSynchronize(10);
      if LGot.BodyHtml <> '' then
        Break;
    end;
    Assert.IsTrue(LGot.BodyHtml.Contains('hc-doc-turn-user'), 'the question');
    Assert.IsTrue(LGot.BodyHtml.Contains('hc-doc-turn-assistant'), 'the reply');
    Assert.IsTrue(LGot.ShowTitle, 'a conversation gets a title block');
  finally
    FServer.SetOnPdfRequest(nil);
  end;
end;

procedure TServerTests.Pdf_WithoutAHost_Says501;
begin
  // No handler: nobody in this process can write a file. Not 404 - the page
  // says "not available here" instead of "there is nothing to print".
  Assert.AreEqual(501, Post(HELPCHAT_API_PDF,
    HELPCHAT_FIELD_PDF_KIND + '=' + HELPCHAT_PDF_KIND_CONVERSATION).StatusCode);
  Assert.AreEqual(403, Post(HELPCHAT_API_PDF, '', False).StatusCode, 'token required');
  Assert.AreEqual(404, Get(HELPCHAT_API_PDF).StatusCode, 'POST only');
end;

procedure TServerTests.Pdf_Disabled_Says403;
begin
  FSettings.Pdf.Enabled := False;
  FServer.SetOnPdfRequest(
    procedure(const ADoc: THelpChatPrintableDoc)
    begin
      Assert.Fail('nothing may be built when the application said no');
    end);
  try
    Assert.AreEqual(403, Post(HELPCHAT_API_PDF,
      HELPCHAT_FIELD_PDF_KIND + '=' + HELPCHAT_PDF_KIND_CONVERSATION).StatusCode);
    Assert.DoesNotContain(FClient.Get(FTransport.GetPanelUrl).ContentAsString,
      '"pdf":true', 'and the page is not offered the buttons');
  finally
    FServer.SetOnPdfRequest(nil);
  end;
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

procedure TServerTests.Page_CarriesTheAssistant_SetAndPosted;
var
  LPage: string;
begin
  LPage := FClient.Get(FTransport.GetPanelUrl).ContentAsString;
  Assert.Contains(LPage, '<title>Assistant</title>', 'nothing set: the localized default');
  Assert.DoesNotContain(LPage, '<img class="hc-chat-icon"',
    'no icon: no img at all - the class itself stays in the stylesheet');

  // The native side of the client, which is where an image list lives.
  FTransport.SetAssistant('Aida', 'data:image/png;base64,AAA');
  Assert.AreEqual('Aida', FTransport.GetAssistantName);
  LPage := FClient.Get(FTransport.GetPanelUrl).ContentAsString;
  Assert.Contains(LPage, '<title>Aida</title>');
  Assert.Contains(LPage, 'src="data:image/png;base64,AAA"');

  // And over HTTP, which is how a remote client says the same thing.
  Assert.AreEqual(200, Post(HELPCHAT_API_ASSISTANT, 'name=Eva&icon=').StatusCode);
  LPage := FClient.Get(FTransport.GetPanelUrl).ContentAsString;
  Assert.Contains(LPage, '<title>Eva</title>');
  Assert.DoesNotContain(LPage, '<img class="hc-chat-icon"',
    'no icon: no img at all - the class itself stays in the stylesheet');
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

procedure TServerTests.Assistants_List_AndSelect;
var
  LResponse: IHTTPResponse;
  LRoot: TJSONValue;
begin
  with FSettings.Models.Add do
  begin
    Name := 'Echo';
    Provider := TEST_PROVIDER_ECHO;
  end;
  with FSettings.Models.Add do
  begin
    Name := 'Slow';
    Provider := TEST_PROVIDER_SLOW;
  end;

  LResponse := Get(HELPCHAT_API_ASSISTANTS);
  Assert.AreEqual(200, LResponse.StatusCode);
  LRoot := TJSONObject.ParseJSONValue(LResponse.ContentAsString(TEncoding.UTF8));
  try
    Assert.IsTrue(LRoot is TJSONObject);
    Assert.IsTrue(TJSONObject(LRoot).GetValue<Boolean>('canSelect'));
    Assert.AreEqual(2, TJSONObject(LRoot).GetValue<TJSONArray>('items').Count);
    Assert.AreEqual('Echo', TJSONObject(LRoot).GetValue<string>('active'),
      'nothing chosen yet: the first of the list');
  finally
    LRoot.Free;
  end;

  LResponse := Post(HELPCHAT_API_ASSISTANT_SELECT, 'name=Slow');
  Assert.AreEqual(200, LResponse.StatusCode);
  LRoot := TJSONObject.ParseJSONValue(LResponse.ContentAsString(TEncoding.UTF8));
  try
    Assert.AreEqual('Slow', TJSONObject(LRoot).GetValue<string>('active'));
  finally
    LRoot.Free;
  end;
  Assert.AreEqual(TEST_PROVIDER_SLOW, FSettings.Provider, 'the switch reached the settings');

  Assert.AreEqual(404, Post(HELPCHAT_API_ASSISTANT_SELECT, 'name=Nobody').StatusCode);
  Assert.AreEqual(TEST_PROVIDER_SLOW, FSettings.Provider, 'an unknown name changes nothing');
end;

procedure TServerTests.Assistants_Single_CannotSelect;
var
  LResponse: IHTTPResponse;
  LRoot: TJSONValue;
begin
  // No list: the one implicit assistant of Settings.Provider, and no choice.
  LResponse := Get(HELPCHAT_API_ASSISTANTS);
  Assert.AreEqual(200, LResponse.StatusCode);
  LRoot := TJSONObject.ParseJSONValue(LResponse.ContentAsString(TEncoding.UTF8));
  try
    Assert.IsFalse(TJSONObject(LRoot).GetValue<Boolean>('canSelect'));
    Assert.AreEqual(1, TJSONObject(LRoot).GetValue<TJSONArray>('items').Count);
    Assert.AreEqual('', TJSONObject(LRoot).GetValue<TJSONArray>('items').Items[0]
      .GetValue<string>('icon'), 'a test provider has no icon to invent');
  finally
    LRoot.Free;
  end;
  Assert.AreEqual(403, Post(HELPCHAT_API_ASSISTANT_SELECT, 'name=' + TEST_PROVIDER_ECHO).StatusCode);
end;

procedure TServerTests.Languages_List_AndSelect;
var
  LResponse: IHTTPResponse;
  LRoot: TJSONValue;
  LItems: TJSONArray;
  LSaved: THelpChatLanguage;
begin
  LSaved := HelpChatDefaultLanguage;
  try
    FSettings.Languages := [hclEnglish, hclItalian, hclGerman];
    LResponse := Get(HELPCHAT_API_LANGUAGES);
    Assert.AreEqual(200, LResponse.StatusCode);
    LRoot := TJSONObject.ParseJSONValue(LResponse.ContentAsString(TEncoding.UTF8));
    try
      Assert.IsTrue(TJSONObject(LRoot).GetValue<Boolean>('canSelect'));
      Assert.AreEqual('en', TJSONObject(LRoot).GetValue<string>('active'));
      LItems := TJSONObject(LRoot).GetValue<TJSONArray>('items');
      Assert.AreEqual(3, LItems.Count, 'only the languages offered');
      Assert.AreEqual('it', LItems.Items[1].GetValue<string>('code'));
      Assert.AreEqual('Italiano', LItems.Items[1].GetValue<string>('name'), 'each in its own language');
      Assert.IsTrue(LItems.Items[2].GetValue<string>('svg').StartsWith('<svg'), 'the flag, inline');
    finally
      LRoot.Free;
    end;

    LResponse := Post(HELPCHAT_API_LANGUAGE_SELECT, 'code=it');
    Assert.AreEqual(200, LResponse.StatusCode);
    Assert.AreEqual(hclItalian, FSettings.Language, 'the switch reached the settings');
    Assert.Contains(FClient.Get(FTransport.GetPanelUrl).ContentAsString(TEncoding.UTF8),
      '<html lang="it">', 'the page is rendered in it');
    Assert.Contains(FClient.Get(FTransport.GetPanelUrl).ContentAsString(TEncoding.UTF8),
      '<title>Assistente</title>', 'and so is the default name of the assistant');

    Assert.AreEqual(404, Post(HELPCHAT_API_LANGUAGE_SELECT, 'code=fr').StatusCode,
      'French is not offered here');
    Assert.AreEqual(404, Post(HELPCHAT_API_LANGUAGE_SELECT, 'code=klingon').StatusCode);
    Assert.AreEqual(hclItalian, FSettings.Language, 'a refused code changes nothing');
  finally
    HelpChatDefaultLanguage := LSaved;
  end;
end;

procedure TServerTests.Languages_Single_CannotSelect;
var
  LRoot: TJSONValue;
begin
  FSettings.Languages := [hclEnglish];
  LRoot := TJSONObject.ParseJSONValue(Get(HELPCHAT_API_LANGUAGES).ContentAsString(TEncoding.UTF8));
  try
    Assert.IsFalse(TJSONObject(LRoot).GetValue<Boolean>('canSelect'));
    Assert.AreEqual(1, TJSONObject(LRoot).GetValue<TJSONArray>('items').Count);
  finally
    LRoot.Free;
  end;
  Assert.AreEqual(403, Post(HELPCHAT_API_LANGUAGE_SELECT, 'code=en').StatusCode);
end;

procedure TServerTests.Commands_List_FollowsTheSession;
var
  LText: string;
begin
  // The local server starts with the default: everything but prompt and run.
  LText := Get(HELPCHAT_API_COMMANDS).ContentAsString(TEncoding.UTF8);
  Assert.IsTrue(LText.Contains('"name":"who","title":"Model in use"'), LText);
  Assert.IsTrue(TRegEx.IsMatch(LText, '"name":"search"[^}]*"enabled":true'), LText);
  Assert.IsTrue(TRegEx.IsMatch(LText, '"name":"prompt"[^}]*"enabled":false'), LText);
  Assert.IsTrue(TRegEx.IsMatch(LText, '"name":"run"[^}]*"enabled":false'), LText);
  Assert.IsTrue(LText.Contains('"local":true'), 'the page answers some by itself');

  // What the component enables reaches the session.
  FTransport.SetEnabledCommands([hccWho, hccPrompt]);
  LText := Get(HELPCHAT_API_COMMANDS).ContentAsString(TEncoding.UTF8);
  Assert.IsTrue(TRegEx.IsMatch(LText, '"name":"who"[^}]*"enabled":true'), LText);
  Assert.IsTrue(TRegEx.IsMatch(LText, '"name":"prompt"[^}]*"enabled":true'), LText);
  Assert.IsTrue(TRegEx.IsMatch(LText, '"name":"search"[^}]*"enabled":false'), LText);
end;

procedure TServerTests.Command_Who_AndDisabledIs403;
var
  LResponse: IHTTPResponse;
  LRoot: TJSONValue;
begin
  LResponse := Post(HELPCHAT_API_COMMAND, 'name=who');
  Assert.AreEqual(200, LResponse.StatusCode);
  LRoot := TJSONObject.ParseJSONValue(LResponse.ContentAsString(TEncoding.UTF8));
  try
    Assert.IsTrue(TJSONObject(LRoot).GetValue<string>('html').Contains(TEST_PROVIDER_ECHO),
      'the implicit assistant of the provider');
  finally
    LRoot.Free;
  end;
  Assert.AreEqual(403, Post(HELPCHAT_API_COMMAND, 'name=prompt').StatusCode, 'not enabled');
  Assert.AreEqual(200, Post(HELPCHAT_API_COMMAND, 'name=prompt&host=1').StatusCode,
    'the application of this process may run any');
  Assert.AreEqual(403, Post(HELPCHAT_API_COMMAND, 'name=nothing&host=1').StatusCode);
  Assert.AreEqual(403, Post(HELPCHAT_API_COMMAND, 'name=nothing').StatusCode, 'not a command');
  FTransport.SetEnabledCommands([hccPrompt]);
  Assert.AreEqual(403, Post(HELPCHAT_API_COMMAND, 'name=who').StatusCode, 'switched off');
  Assert.AreEqual(200, Post(HELPCHAT_API_COMMAND, 'name=prompt').StatusCode, 'switched on');
end;

end.
