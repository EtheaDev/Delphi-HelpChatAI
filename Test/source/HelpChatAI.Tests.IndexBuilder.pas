unit HelpChatAI.Tests.IndexBuilder;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.IndexBuilder;

type
  [TestFixture]
  TIndexBuilderTests = class
  public
    [Test] procedure Utf8Validation;
    [Test] procedure ReadTextFile_DetectsEncoding;
    [Test] procedure FrontMatter_IsStrippedAndParsed;
    [Test] procedure Title_FromHeadingOfAnyLevel;
    [Test] procedure CleanTitle_RemovesMarkers;
    [Test] procedure PlainText_RemovesMarkup_KeepsWords;
    [Test] procedure Summary_FirstMeaningfulParagraph_Cut;
    [Test] procedure Toc_Hierarchy_And_Breadcrumbs;
    [Test] procedure Toc_TableRows;
    [Test] procedure Build_RealHelp_Pages;
    [Test] procedure Build_RealHelp_TitlesKeywordsUrls;
    [Test] procedure Build_Encodings_AreDecoded;
    [Test] procedure Build_RealHelp_TextIsClean;
    [Test] procedure Json_IsLoadableByDocIndex;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.DocIndex,
  HelpChatAI.Tests.Helpers;

function HelpFolder: string;
begin
  // Il manuale vero su cui gira il builder e' quello della demo CRM, sedici
  // pagine in inglese: "CRM Demo\Help", accanto a Test.
  Result := TPath.Combine(TPath.GetDirectoryName(TPath.GetDirectoryName(
    TPath.GetDirectoryName(TestDataFile('help-index.json')))), 'CRM Demo\Help');
  if not TDirectory.Exists(Result) then
    raise Exception.Create('Manual folder not found: ' + Result);
end;

function EncodingsFolder: string;
begin
  // Quattro file minuscoli: ANSI con accenti, UTF-8 con BOM, UTF-8 senza, e
  // uno senza intestazione. Il manuale della demo e' tutto UTF-8, e queste
  // sono le strade che resterebbero senza prova.
  Result := TPath.GetDirectoryName(TestDataFile('encodings\\Index.md'));
  if not TDirectory.Exists(Result) then
    raise Exception.Create('Encodings fixture not found: ' + Result);
end;

function BuildRealHelp: TArray<THelpChatIndexPage>;
var
  LBuilder: THelpChatIndexBuilder;
  LOptions: THelpChatIndexBuilderOptions;
begin
  LBuilder := THelpChatIndexBuilder.Create;
  try
    LOptions := THelpChatIndexBuilderOptions.Default;
    LOptions.SourceFolder := HelpFolder;
    Result := LBuilder.Build(LOptions);
  finally
    LBuilder.Free;
  end;
end;

function FindPage(const APages: TArray<THelpChatIndexPage>; const AId: string): THelpChatIndexPage;
var
  LPage: THelpChatIndexPage;
begin
  for LPage in APages do
    if SameText(LPage.Id, AId) then
      Exit(LPage);
  raise Exception.Create('page not found: ' + AId);
end;

procedure TIndexBuilderTests.Utf8Validation;
begin
  Assert.IsTrue(THelpChatIndexBuilder.IsValidUtf8(TEncoding.UTF8.GetBytes('città è però')));
  Assert.IsTrue(THelpChatIndexBuilder.IsValidUtf8(TEncoding.ASCII.GetBytes('plain ascii')));
  Assert.IsTrue(THelpChatIndexBuilder.IsValidUtf8(nil));
  Assert.IsFalse(THelpChatIndexBuilder.IsValidUtf8(TEncoding.ANSI.GetBytes('città è però')), 'cp1252 accents are invalid UTF-8');
  Assert.IsFalse(THelpChatIndexBuilder.IsValidUtf8(TBytes.Create($E0, $41)), 'truncated sequence');
end;

procedure TIndexBuilderTests.ReadTextFile_DetectsEncoding;
var
  LFile: string;
const
  TEXT = 'Il modo migliore è farlo così: più ordine.';
begin
  LFile := TempFileName('.md');
  try
    TFile.WriteAllText(LFile, TEXT, TEncoding.ANSI);
    Assert.AreEqual(TEXT, THelpChatIndexBuilder.ReadTextFile(LFile), 'ANSI without BOM');
    TFile.WriteAllBytes(LFile, TEncoding.UTF8.GetBytes(TEXT));
    Assert.AreEqual(TEXT, THelpChatIndexBuilder.ReadTextFile(LFile), 'UTF-8 without BOM');
    TFile.WriteAllText(LFile, TEXT, TEncoding.UTF8);
    Assert.AreEqual(TEXT, THelpChatIndexBuilder.ReadTextFile(LFile), 'UTF-8 with BOM');
    TFile.WriteAllText(LFile, TEXT, TEncoding.Unicode);
    Assert.AreEqual(TEXT, THelpChatIndexBuilder.ReadTextFile(LFile), 'UTF-16 with BOM');
  finally
    TFile.Delete(LFile);
  end;
end;

procedure TIndexBuilderTests.FrontMatter_IsStrippedAndParsed;
var
  LBody, LFront: string;
begin
  LBody := THelpChatIndexBuilder.StripFrontMatter('---'#10'title: "My Page"'#10'tags: [a]'#10'---'#10'# Heading'#10'Body', LFront);
  Assert.AreEqual('title: "My Page"'#10'tags: [a]', LFront);
  Assert.AreEqual('# Heading'#10'Body', LBody);
  Assert.AreEqual('My Page', THelpChatIndexBuilder.ExtractTitle(LBody, LFront), 'front matter wins over the heading');

  LBody := THelpChatIndexBuilder.StripFrontMatter('no front matter'#10'---'#10'rule', LFront);
  Assert.AreEqual('', LFront);
  Assert.AreEqual('no front matter'#10'---'#10'rule', LBody);
end;

procedure TIndexBuilderTests.Title_FromHeadingOfAnyLevel;
begin
  Assert.AreEqual('Homepage e navigazione', THelpChatIndexBuilder.ExtractTitle(#$FEFF'# Homepage e navigazione'#10'text', ''));
  Assert.AreEqual('Esecuzione Report', THelpChatIndexBuilder.ExtractTitle('## Esecuzione Report'#10#10'Il modo', ''));
  Assert.AreEqual('Deep', THelpChatIndexBuilder.ExtractTitle('intro'#10'### Deep ###', ''), 'closing hashes removed');
  Assert.AreEqual('', THelpChatIndexBuilder.ExtractTitle('just text'#10'#hashtag no space', ''));
end;

procedure TIndexBuilderTests.CleanTitle_RemovesMarkers;
begin
  Assert.AreEqual('DESCRIZIONE DEL PRODOTTO', THelpChatIndexBuilder.CleanTitle('**DESCRIZIONE DEL PRODOTTO**'));
  Assert.AreEqual('Configurazione Path', THelpChatIndexBuilder.CleanTitle('_Configurazione Path_'));
  Assert.AreEqual('REPORT_MAIL code', THelpChatIndexBuilder.CleanTitle('`REPORT_MAIL` code'), 'underscores inside words survive');
  Assert.AreEqual('A & B', THelpChatIndexBuilder.CleanTitle(' A &amp; B '));
end;

procedure TIndexBuilderTests.PlainText_RemovesMarkup_KeepsWords;
var
  LText: string;
begin
  LText := THelpChatIndexBuilder.MarkdownToPlainText(
    '## Esecuzione Report'#13#10#13#10 +
    'Il modo **migliore** per eseguire un _report_ è via [Report Runner](runner.md).'#13#10#13#10 +
    '![player](Images/player.png)'#13#10#13#10 +
    '1. Selezionare il report.'#13#10 +
    '    ![x](Images/x.png)'#13#10 +
    '1. Cliccare su "Esegui".'#13#10#13#10 +
    '| Col A | Col B |'#13#10'|---|---|'#13#10'| REPORT_MAIL | `code` |'#13#10#13#10 +
    '> quoted <b>bold</b> &amp; done'#13#10 +
    '```'#13#10'range_name'#13#10'```');
  Assert.StartsWith('Esecuzione Report'#10#10'Il modo migliore per eseguire un report è via Report Runner.', LText);
  Assert.DoesNotContain(LText, '![');
  Assert.DoesNotContain(LText, '](');
  Assert.DoesNotContain(LText, 'Images/');
  Assert.DoesNotContain(LText, '**');
  Assert.DoesNotContain(LText, '|');
  Assert.DoesNotContain(LText, '<b>');
  Assert.DoesNotContain(LText, '```');
  Assert.Contains(LText, 'Selezionare il report.');
  Assert.Contains(LText, 'Cliccare su "Esegui".');
  Assert.Contains(LText, 'Col A Col B');
  Assert.Contains(LText, 'REPORT_MAIL code', 'table cells and inline code kept as words');
  Assert.Contains(LText, 'quoted bold & done');
  Assert.Contains(LText, 'range_name', 'code block content kept');
  Assert.DoesNotContain(LText, #10#10#10, 'at most one blank line between paragraphs');

  // A heading after a blank line starts its own paragraph (a \s in the heading
  // pattern used to swallow the blank line and glue the two).
  LText := THelpChatIndexBuilder.MarkdownToPlainText('Intro paragraph.'#13#10#13#10'### Configurazione SMTP'#13#10#13#10'Steps.');
  Assert.AreEqual('Intro paragraph.'#10#10'Configurazione SMTP'#10#10'Steps.', LText);
  Assert.AreEqual('Intro paragraph.', THelpChatIndexBuilder.ExtractSummary(LText, '', 5, 320));
end;

procedure TIndexBuilderTests.Summary_FirstMeaningfulParagraph_Cut;
var
  LPlain, LSummary: string;
begin
  LPlain := 'Title'#10#10'Short.'#10#10'This is the first paragraph long enough to be a summary of the page.'#10#10'Second paragraph.';
  Assert.AreEqual('This is the first paragraph long enough to be a summary of the page.',
    THelpChatIndexBuilder.ExtractSummary(LPlain, 'Title', 40, 320));
  Assert.AreEqual('Short.', THelpChatIndexBuilder.ExtractSummary('Title'#10#10'Short.', 'Title', 40, 320),
    'nothing long enough: first non-title paragraph');
  LSummary := THelpChatIndexBuilder.ExtractSummary(LPlain, 'Title', 40, 30);
  Assert.IsTrue(LSummary.Length <= 31, 'cut to max plus the ellipsis');
  Assert.EndsWith(#$2026, LSummary);
  Assert.AreEqual('This is the first paragraph' + #$2026, LSummary, 'cut at a word boundary');
end;

procedure TIndexBuilderTests.Toc_TableRows;
var
  LToc: TDictionary<string, THelpChatTocEntry>;
  LEntry: THelpChatTocEntry;
begin
  // A table of contents written as a table: the link is in the first cell.
  LToc := THelpChatIndexBuilder.ParseToc(
    '# Index'#10#10 +
    '| Page | What you find |'#10 +
    '| - | - |'#10 +
    '| [Home](Home.md) | What the application is |'#10 +
    '| [Lead detail](Lead-Detail.md) | One lead, its documents |'#10 +
    '| [Online](https://ethea.it/) | not a page of the manual |');
  try
    Assert.AreEqual(2, Integer(LToc.Count), 'header, separator and external link are skipped');
    Assert.IsTrue(LToc.TryGetValue('home.md', LEntry));
    Assert.AreEqual('Home', LEntry.Title);
    Assert.AreEqual(0, Integer(Length(LEntry.Breadcrumb)), 'a table row is top level');
    Assert.IsTrue(LToc.TryGetValue('lead-detail.md', LEntry));
    Assert.AreEqual('Lead detail', LEntry.Title);
  finally
    LToc.Free;
  end;
end;

procedure TIndexBuilderTests.Toc_Hierarchy_And_Breadcrumbs;
var
  LToc: TDictionary<string, THelpChatTocEntry>;
  LEntry: THelpChatTocEntry;
begin
  LToc := THelpChatIndexBuilder.ParseToc(
    '## INDICE'#10 +
    '[**MANUALE MANAGER**](180.md)'#10#10 +
    '- _Accesso e autenticazione_'#10 +
    '- [HOMEPAGE E NAVIGAZIONE](100.md)'#10 +
    '- [REPORT PLAYER](Report_Player.md)'#10 +
    '    - [_Scheduler dei Report_](4040000.md)'#10 +
    '    - [_Coda invio mail_](310000.md)'#10#10 +
    '[**MANUALE RUNNER**](Runner.md)'#10 +
    '- [TECNOLOGIE](Tecnologie.md)');
  try
    Assert.AreEqual(7, Integer(LToc.Count), 'the entry without a link is skipped');
    Assert.IsTrue(LToc.TryGetValue('180.md', LEntry));
    Assert.AreEqual('MANUALE MANAGER', LEntry.Title);
    Assert.AreEqual(0, Integer(Length(LEntry.Breadcrumb)));
    Assert.IsTrue(LToc.TryGetValue('4040000.md', LEntry));
    Assert.AreEqual('Scheduler dei Report', LEntry.Title);
    Assert.AreEqual(2, Integer(Length(LEntry.Breadcrumb)));
    Assert.AreEqual('MANUALE MANAGER', LEntry.Breadcrumb[0]);
    Assert.AreEqual('REPORT PLAYER', LEntry.Breadcrumb[1]);
    Assert.IsTrue(LToc.TryGetValue('tecnologie.md', LEntry), 'keys are lower-case');
    Assert.AreEqual(1, Integer(Length(LEntry.Breadcrumb)));
    Assert.AreEqual('MANUALE RUNNER', LEntry.Breadcrumb[0], 'a new top-level section resets the stack');
  finally
    LToc.Free;
  end;
end;

procedure TIndexBuilderTests.Build_RealHelp_Pages;
var
  LPages: TArray<THelpChatIndexPage>;
  LPage: THelpChatIndexPage;
begin
  LPages := BuildRealHelp;
  Assert.AreEqual(15, Integer(Length(LPages)), 'every .md except Index.md');
  for LPage in LPages do
  begin
    Assert.IsNotEmpty(LPage.Id, LPage.SourceFile);
    Assert.IsNotEmpty(LPage.Title, LPage.SourceFile);
    Assert.IsNotEmpty(LPage.Text, LPage.SourceFile);
    Assert.IsNotEmpty(LPage.Summary, LPage.SourceFile);
    Assert.EndsWith('.html', LPage.Url);
    Assert.AreNotEqual('index', LPage.Id.ToLower);
  end;
end;

procedure TIndexBuilderTests.Build_RealHelp_TitlesKeywordsUrls;
var
  LPages: TArray<THelpChatIndexPage>;
  LPage: THelpChatIndexPage;
begin
  LPages := BuildRealHelp;

  // Il titolo viene dall'intestazione della pagina, non dal nome del file.
  LPage := FindPage(LPages, 'Leads');
  Assert.AreEqual('Leads', LPage.Title);
  Assert.AreEqual('Leads.html', LPage.Url);
  Assert.Contains(LPage.Text, 'four columns, one per status');
  // Il sommario lo chiama come la pagina: niente parola chiave doppia.
  Assert.DoesNotContain<string>(LPage.Keywords, 'Leads');

  LPage := FindPage(LPages, 'Data-Model');
  Assert.AreEqual('Data model', LPage.Title);
  Assert.AreEqual('Data-Model.html', LPage.Url);

  // Qui il sommario dice "Home" e l'intestazione dice altro: il nome del
  // sommario diventa una parola chiave della pagina.
  LPage := FindPage(LPages, 'Home');
  Assert.AreEqual('CRM Demo', LPage.Title);
  Assert.Contains<string>(LPage.Keywords, 'Home');
end;

procedure TIndexBuilderTests.Build_Encodings_AreDecoded;
var
  LBuilder: THelpChatIndexBuilder;
  LOptions: THelpChatIndexBuilderOptions;
  LPages: TArray<THelpChatIndexPage>;
  LPage: THelpChatIndexPage;
begin
  LBuilder := THelpChatIndexBuilder.Create;
  try
    LOptions := THelpChatIndexBuilderOptions.Default;
    LOptions.SourceFolder := EncodingsFolder;
    LPages := LBuilder.Build(LOptions);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(3, Integer(Length(LPages)), 'Index.md is the table of contents, not a page');

  // ANSI: gli accenti arrivano interi, non come punto interrogativo rovesciato.
  LPage := FindPage(LPages, 'ansi');
  Assert.AreEqual('Esecuzione del report', LPage.Title);
  Assert.Contains(LPage.Text, 'Il modo migliore per eseguire un report è farlo attraverso');
  Assert.Contains(LPage.Text, 'la città di destinazione può essere scelta più tardi');

  // UTF-8 con BOM: il BOM non finisce nel titolo.
  LPage := FindPage(LPages, 'bom');
  Assert.AreEqual('Impostazioni già salvate', LPage.Title);
  Assert.Contains(LPage.Text, 'perché');

  // Senza intestazione: il titolo lo da' il sommario.
  LPage := FindPage(LPages, 'senza-titolo');
  Assert.AreEqual('Pagina senza titolo', LPage.Title);

  for LPage in LPages do
    Assert.DoesNotContain(LPage.Text, #$FFFD, LPage.SourceFile + ': replacement char means a wrong encoding');
end;

procedure TIndexBuilderTests.Build_RealHelp_TextIsClean;
var
  LPages: TArray<THelpChatIndexPage>;
  LPage: THelpChatIndexPage;
begin
  LPages := BuildRealHelp;
  for LPage in LPages do
  begin
    Assert.DoesNotContain(LPage.Text, '![', LPage.SourceFile);
    Assert.DoesNotContain(LPage.Text, '](', LPage.SourceFile);
    Assert.DoesNotContain(LPage.Text, 'Images/', LPage.SourceFile);
    Assert.DoesNotContain(LPage.Text, '**', LPage.SourceFile);
    Assert.DoesNotContain(LPage.Text, #$FFFD, LPage.SourceFile + ': replacement char means a wrong encoding');
    Assert.IsTrue(LPage.Text.Length <= HELPCHAT_INDEXBUILDER_DEF_MAXTEXT, LPage.SourceFile);
    Assert.IsTrue(LPage.Summary.Length <= HELPCHAT_INDEXBUILDER_DEF_SUMMARYMAX + 1, LPage.SourceFile);
  end;
end;

procedure TIndexBuilderTests.Json_IsLoadableByDocIndex;
var
  LPages: TArray<THelpChatIndexPage>;
  LIndex: THelpChatDocIndex;
  LRetriever: IHelpChatRetriever;
  LFound: TArray<THelpChatDocPage>;
begin
  LPages := BuildRealHelp;
  LIndex := THelpChatDocIndex.Create;
  LRetriever := LIndex;
  try
    LIndex.BaseUrl := 'https://help.example.com/crm/';
    LIndex.LoadFromJSON(THelpChatIndexBuilder.ToJSON(LPages, False));
    Assert.AreEqual(Integer(Length(LPages)), LIndex.Count);
    LFound := LRetriever.Search('how do I export the mailing list?', '', 1);
    Assert.AreEqual(1, Integer(Length(LFound)));
    Assert.AreEqual('Marketing', LFound[0].Title);
    Assert.AreEqual('https://help.example.com/crm/Marketing.html', LFound[0].Url);
    // La parola chiave presa dal sommario fa trovare la pagina anche quando
    // il titolo non la contiene: "Home" sta nell'indice, non nel titolo.
    LFound := LRetriever.Search('home', '', 3);
    Assert.IsTrue(Length(LFound) >= 1);
    Assert.AreEqual('CRM Demo', LFound[0].Title);
  finally
    LRetriever := nil;
  end;
end;

end.
