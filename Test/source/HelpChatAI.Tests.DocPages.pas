unit HelpChatAI.Tests.DocPages;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.DocPages;

type
  /// <summary>The documentation pages shown in the panel: path rules, rendering,
  /// images, filter, and the /api/doc endpoint over real HTTP.</summary>
  [TestFixture]
  TDocPagesTests = class
  strict private
    FFolder: string;
    FPages: THelpChatDocPages;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure NormalizePage_AddsExtension_KeepsSubFolders;
    [Test] procedure NormalizePage_RejectsWhatIsNotAPageOfTheFolder;
    [Test] procedure Render_TitleAndSafeHtml;
    [Test] procedure Render_InlinesImagesOfTheFolder;
    [Test] procedure Render_AppliesTheFilter;
    [Test] procedure Render_MissingPage_IsFalse;
    [Test] procedure Server_DocEndpoint_And_PanelConfig;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.NetEncoding,
  System.Net.HttpClient,
  System.Net.URLClient,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Engine,
  HelpChatAI.Transport,
  HelpChatAI.Panel,
  HelpChatAI.Server,
  HelpChatAI.Tests.Helpers;

const
  // 1x1 transparent PNG
  PNG_1X1: array[0..66] of Byte = (
    $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52,
    $00, $00, $00, $01, $00, $00, $00, $01, $08, $06, $00, $00, $00, $1F, $15, $C4,
    $89, $00, $00, $00, $0A, $49, $44, $41, $54, $78, $9C, $63, $00, $01, $00, $00,
    $05, $00, $01, $0D, $0A, $2D, $B4, $00, $00, $00, $00, $49, $45, $4E, $44, $AE,
    $42, $60, $82);

procedure WriteUtf8(const AFileName, AText: string);
begin
  TDirectory.CreateDirectory(TPath.GetDirectoryName(AFileName));
  TFile.WriteAllText(AFileName, AText, TEncoding.UTF8);
end;

procedure TDocPagesTests.Setup;
var
  LBytes: TBytes;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'helpchat-docs-' + THelpChatMessage.NewId);
  WriteUtf8(TPath.Combine(FFolder, '110.md'),
    '# Primo utilizzo di AppName' + sLineBreak + sLineBreak +
    'Vedi il [menù](sub/menu.md) e la <script>alert(1)</script> [trappola](javascript:alert(1)).' + sLineBreak + sLineBreak +
    '![logo](/Images/logo.png)');
  WriteUtf8(TPath.Combine(FFolder, 'sub\menu.md'),
    'Il menù, senza titolo.' + sLineBreak + sLineBreak + '![logo](../Images/logo.png)');
  SetLength(LBytes, Length(PNG_1X1));
  Move(PNG_1X1[0], LBytes[0], Length(PNG_1X1));
  TDirectory.CreateDirectory(TPath.Combine(FFolder, 'Images'));
  TFile.WriteAllBytes(TPath.Combine(FFolder, 'Images\logo.png'), LBytes);
  WriteUtf8(TPath.GetTempPath + 'helpchat-outside.md', '# Outside');
  FPages := THelpChatDocPages.Create(FFolder);
end;

procedure TDocPagesTests.TearDown;
begin
  FPages.Free;
  TDirectory.Delete(FFolder, True);
  TFile.Delete(TPath.GetTempPath + 'helpchat-outside.md');
end;

procedure TDocPagesTests.NormalizePage_AddsExtension_KeepsSubFolders;
begin
  Assert.AreEqual('110.md', THelpChatDocPages.NormalizePage('110'));
  Assert.AreEqual('110.md', THelpChatDocPages.NormalizePage('/110.md'));
  Assert.AreEqual('110.md', THelpChatDocPages.NormalizePage('./110.md#section'));
  Assert.AreEqual('sub/menu.md', THelpChatDocPages.NormalizePage('sub\menu.md'));
  Assert.AreEqual('menu.md', THelpChatDocPages.NormalizePage('sub/../menu.md?x=1'));
  Assert.AreEqual('guide.markdown', THelpChatDocPages.NormalizePage('guide.markdown'));
end;

procedure TDocPagesTests.NormalizePage_RejectsWhatIsNotAPageOfTheFolder;
begin
  Assert.AreEqual('', THelpChatDocPages.NormalizePage(''));
  Assert.AreEqual('', THelpChatDocPages.NormalizePage('../helpchat-outside.md'), 'above the root');
  Assert.AreEqual('', THelpChatDocPages.NormalizePage('sub/../../x.md'), 'above the root');
  Assert.AreEqual('', THelpChatDocPages.NormalizePage('C:\Windows\win.ini'), 'drive');
  Assert.AreEqual('', THelpChatDocPages.NormalizePage('https://example.com/a.md'), 'scheme');
  Assert.AreEqual('', THelpChatDocPages.NormalizePage('//server/share/a.md'), 'UNC');
  Assert.AreEqual('', THelpChatDocPages.NormalizePage('Images/logo.png'), 'not Markdown');
end;

procedure TDocPagesTests.Render_TitleAndSafeHtml;
var
  LDoc: THelpChatRenderedDoc;
begin
  Assert.IsTrue(FPages.Render('110', nil, LDoc));
  Assert.AreEqual('110.md', LDoc.Page);
  Assert.AreEqual('Primo utilizzo di AppName', LDoc.Title);
  Assert.Contains(LDoc.Html, '<h1>');
  Assert.Contains(LDoc.Html, 'href="sub/menu.md"', 'relative links are kept for the panel');
  Assert.DoesNotContain(LDoc.Html, '<script>', 'active HTML escaped');
  Assert.DoesNotContain(LDoc.Html, 'javascript:', 'unsafe URL dropped');

  Assert.IsTrue(FPages.Render('sub/menu', nil, LDoc));
  Assert.AreEqual('menu', LDoc.Title, 'no heading: the file name');
end;

procedure TDocPagesTests.Render_InlinesImagesOfTheFolder;
var
  LDoc: THelpChatRenderedDoc;
begin
  Assert.IsTrue(FPages.Render('110.md', nil, LDoc));
  Assert.Contains(LDoc.Html, 'src="data:image/png;base64,iVBORw0KGgo', 'root-relative image');
  Assert.IsTrue(FPages.Render('sub/menu.md', nil, LDoc));
  Assert.Contains(LDoc.Html, 'src="data:image/png;base64,', 'page-relative image');
end;

procedure TDocPagesTests.Render_AppliesTheFilter;
var
  LDoc: THelpChatRenderedDoc;
  LSeen: string;
begin
  Assert.IsTrue(FPages.Render('110',
    procedure(const APage: string; var AMarkdown: string)
    begin
      LSeen := APage;
      AMarkdown := AMarkdown.Replace('AppName', 'ISFPrimer');
    end, LDoc));
  Assert.AreEqual('110.md', LSeen);
  Assert.AreEqual('Primo utilizzo di ISFPrimer', LDoc.Title);
end;

procedure TDocPagesTests.Render_MissingPage_IsFalse;
var
  LDoc: THelpChatRenderedDoc;
begin
  Assert.IsFalse(FPages.Render('999', nil, LDoc));
  Assert.IsFalse(FPages.Render('../helpchat-outside', nil, LDoc));
  Assert.IsFalse(FPages.Render('Images/logo.png', nil, LDoc));
end;

procedure TDocPagesTests.Server_DocEndpoint_And_PanelConfig;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LServer: THelpChatLocalServer;
  LTransport: IHelpChatTransport;
  LClient: THTTPClient;
  LHeaders: TNetHeaders;
  LResponse: IHTTPResponse;

  function GetDoc(const APage: string): IHTTPResponse;
  begin
    Result := LClient.Get(LTransport.GetPanelOrigin + HELPCHAT_API_DOC + '?' +
      HELPCHAT_DOC_QUERY + '=' + TNetEncoding.URL.Encode(APage), nil, LHeaders);
  end;

begin
  LSettings := THelpChatSettings.Create;
  LClient := THTTPClient.Create;
  try
    LSettings.Language := hclEnglish;
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    LSettings.Provider := TEST_PROVIDER_ECHO;
    LSettings.DocFolder := FFolder;
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.DocPageFilter :=
        procedure(const APage: string; var AMarkdown: string)
        begin
          AMarkdown := AMarkdown.Replace('AppName', 'Demo');
        end;
      LServer := THelpChatLocalServer.Create(LEngine, False);
      LTransport := LServer;
      LTransport.Start;
      try
        LHeaders := [TNetHeader.Create(HELPCHAT_TOKEN_HEADER, LServer.Token)];

        LResponse := GetDoc('110');
        Assert.AreEqual(200, LResponse.StatusCode);
        Assert.Contains(LResponse.ContentAsString(TEncoding.UTF8),
          '<article class="hc-chat-doc-page" data-page="110.md" data-title="Primo utilizzo di Demo">');

        Assert.AreEqual(404, GetDoc('999').StatusCode, 'missing page');
        Assert.AreEqual(404, GetDoc('../helpchat-outside.md').StatusCode, 'outside the folder');
        Assert.AreEqual(403, LClient.Get(LTransport.GetPanelOrigin + HELPCHAT_API_DOC + '?page=110').StatusCode,
          'token required');

        Assert.Contains(LClient.Get(LTransport.GetPanelUrl).ContentAsString(TEncoding.UTF8), '"docs":true');
      finally
        LTransport.Stop;
        LTransport := nil;
      end;
    finally
      LEngine.Free;
    end;
  finally
    LClient.Free;
    LSettings.Free;
  end;
end;

end.
