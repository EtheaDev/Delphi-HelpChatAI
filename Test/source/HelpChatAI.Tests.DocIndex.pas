unit HelpChatAI.Tests.DocIndex;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.DocIndex;

type
  [TestFixture]
  TDocIndexTests = class
  strict private
    FIndex: THelpChatDocIndex;
    FRetriever: IHelpChatRetriever; // keeps FIndex alive
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Tokenize_DropsShortAndStopWords;
    [Test] procedure Tokenize_Italian;
    [Test] procedure StemToken_ByLength;
    [Test] procedure Search_MatchesInflectedForms;
    [Test] procedure Search_KeywordsWeighBetweenTitleAndBody;
    [Test] procedure Search_CommonWordDoesNotBuryTheRightPage;
    [Test] procedure Search_HintOutweighsAGenericQuestion;
    [Test] procedure Excerpt_WindowsAroundHits_WithinBudget;
    [Test] procedure LoadFromJSON_KeywordsArrayOrString;
    [Test] procedure CountOccurrences;
    [Test] procedure Load_Fixture;
    [Test] procedure Search_BestPageFirst_WithAbsoluteUrl;
    [Test] procedure Search_TitleWeighsMore;
    [Test] procedure Search_HintBiasesResult;
    [Test] procedure Search_NoMatch_IsEmpty;
    [Test] procedure Search_RespectsMaxPages;
    [Test] procedure Search_EmptyIndex_IsEmpty;
    [Test] procedure LoadFromFile_Missing_StaysEmpty;
    [Test] procedure LoadFromJSON_Malformed_Raises;
    [Test] procedure LoadFromJSON_AcceptsPagesWrapper;
    [Test] procedure BaseUrl_IsNormalized;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  HelpChatAI.Tests.Helpers;

procedure TDocIndexTests.Setup;
begin
  FIndex := THelpChatDocIndex.Create;
  FRetriever := FIndex;
  FIndex.BaseUrl := 'https://docs.example.com/app';
end;

procedure TDocIndexTests.TearDown;
begin
  FRetriever := nil;
  FIndex := nil;
end;

procedure TDocIndexTests.Tokenize_DropsShortAndStopWords;
var
  LTokens: TArray<string>;
begin
  LTokens := THelpChatDocIndex.Tokenize('How do I export the grid to Excel?');
  Assert.AreEqual(3, Integer(Length(LTokens)));
  Assert.AreEqual('export', LTokens[0]);
  Assert.AreEqual('grid', LTokens[1]);
  Assert.AreEqual('excel', LTokens[2]);
  Assert.AreEqual(0, Integer(Length(THelpChatDocIndex.Tokenize(''))));
  Assert.AreEqual(0, Integer(Length(THelpChatDocIndex.Tokenize('the and for'))));
end;

procedure TDocIndexTests.Tokenize_Italian;
var
  LTokens: TArray<string>;
begin
  LTokens := THelpChatDocIndex.Tokenize('Come esporto la griglia degli ordini?');
  Assert.Contains<string>(LTokens, 'esporto');
  Assert.Contains<string>(LTokens, 'griglia');
  Assert.Contains<string>(LTokens, 'ordini');
  Assert.DoesNotContain<string>(LTokens, 'come');
end;

procedure TDocIndexTests.StemToken_ByLength;
begin
  Assert.AreEqual('grid', THelpChatDocIndex.StemToken('grid'));
  Assert.AreEqual('excel', THelpChatDocIndex.StemToken('excel'));
  Assert.AreEqual('repor', THelpChatDocIndex.StemToken('report'));
  Assert.AreEqual('model', THelpChatDocIndex.StemToken('modelli'));
  Assert.AreEqual('espor', THelpChatDocIndex.StemToken('esporto'));
  Assert.AreEqual('config', THelpChatDocIndex.StemToken('configurazione'));
  Assert.AreEqual('schedu', THelpChatDocIndex.StemToken('scheduler'));
  Assert.AreEqual(2, Integer(Length(THelpChatDocIndex.TokenizeStems('Come esporto i modelli?'))),
    '"come" is a stop word, "i" is too short');
end;

procedure TDocIndexTests.Search_MatchesInflectedForms;
var
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.AddPage('Esportazione dei dati', 'export.html', 's', 'Per esportare la griglia usare il pulsante Esporta.');
  FIndex.AddPage('Modello del Report', 'model.html', 's', 'I modelli dei report si creano nel Layout Designer.');
  LPages := FRetriever.Search('come esporto la griglia?', '', 1);
  Assert.AreEqual(1, Integer(Length(LPages)));
  Assert.AreEqual('Esportazione dei dati', LPages[0].Title);
  LPages := FRetriever.Search('creare un modello', '', 1);
  Assert.AreEqual(1, Integer(Length(LPages)));
  Assert.AreEqual('Modello del Report', LPages[0].Title);
end;

procedure TDocIndexTests.Search_KeywordsWeighBetweenTitleAndBody;
var
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.AddPage('Scheduler dei Report', 'a.html', '', 'nothing', 'MANUALE MANAGER | REPORT PLAYER');
  FIndex.AddPage('Esecuzione Report', 'b.html', '', 'player player', '');
  FIndex.AddPage('Report Player', 'c.html', '', 'nothing', '');
  LPages := FRetriever.Search('player', '', 3);
  Assert.AreEqual(3, Integer(Length(LPages)));
  Assert.AreEqual('Report Player', LPages[0].Title, 'title hit: 6');
  Assert.AreEqual('Scheduler dei Report', LPages[1].Title, 'keyword hit: 3');
  Assert.AreEqual('Esecuzione Report', LPages[2].Title, 'two body hits: 2');
  Assert.AreEqual(HELPCHAT_KEYWORD_WEIGHT, LPages[1].Score);
end;

procedure TDocIndexTests.Search_CommonWordDoesNotBuryTheRightPage;
var
  LPages: TArray<THelpChatDocPage>;
  LLong: string;
begin
  // "report" is in every page of a report tool: it must not decide the ranking.
  LLong := DupeString('il report dei report per i report. ', 12);
  FIndex.AddPage('Modelli dei Report', 'models.html', '', LLong);
  FIndex.AddPage('Scheduler dei Report', 'sched.html', '',
    'Schedulazione del report: giorno della settimana, giorno del mese, ogni giorno alle ore.');
  FIndex.AddPage('Homepage', 'home.html', '', 'report e menu');
  LPages := FRetriever.Search('come pianifico un report ogni giorno?', '', 2);
  Assert.AreEqual(2, Integer(Length(LPages)));
  Assert.AreEqual('Scheduler dei Report', LPages[0].Title, 'rare token "giorno" (idf) and capped body hits win');
  Assert.AreEqual('Modelli dei Report', LPages[1].Title);
  Assert.IsTrue(LPages[1].Score > LPages[0].Score, 'the raw Score still counts every hit');
end;

procedure TDocIndexTests.Search_HintOutweighsAGenericQuestion;
var
  LPages: TArray<THelpChatDocPage>;
begin
  // The F1 question names the application ("Windows 10 CRM Demo") and the
  // main form keyword; the hint is the tab the user is on.
  FIndex.AddPage('Getting started', 'start.html', '', 'The Windows 10 CRM Demo opens on the dashboard.');
  FIndex.AddPage('MANUALE: LENDINGREPORT MANAGER', 'manual.html', '', 'Il manager: homepage, report, scheduler.');
  FIndex.AddPage('Leads', 'leads.html', '', 'The board where the work happens, four columns.');
  LPages := FRetriever.Search('How do I use the "Windows 10 CRM Demo" screen?', 'Leads', 1);
  Assert.AreEqual(1, Integer(Length(LPages)));
  Assert.AreEqual('Leads', LPages[0].Title, 'the screen hint decides');
end;

procedure TDocIndexTests.Excerpt_WindowsAroundHits_WithinBudget;
var
  LText: string;
  LPages: TArray<THelpChatDocPage>;
begin
  // A long page whose relevant passage is near the end: a prefix would miss it.
  LText := DupeString('Testo introduttivo generico sulla pagina dei dati del template. ', 60) +
    'Le bande fisse (Fixed Bands) sono intervalli che non si espandono con i dati. ' +
    DupeString('Altro testo di chiusura senza rilievo. ', 40);
  FIndex.AddPage('Pagina dei dati', 'p.html', 'summary', LText);
  FIndex.ExcerptMaxChars := 800;
  LPages := FRetriever.Search('cosa sono le bande fisse?', '', 1);
  Assert.AreEqual(1, Integer(Length(LPages)));
  Assert.Contains(LPages[0].Excerpt, 'bande fisse (Fixed Bands)');
  Assert.IsTrue(LPages[0].Excerpt.Length <= 800 + 6, 'budget plus ellipses');
  Assert.StartsWith(#$2026, LPages[0].Excerpt, 'an inner window starts with an ellipsis');

  // A short page is returned whole; excerpts can be switched off.
  FIndex.Clear;
  FIndex.AddPage('Short', 's.html', 'sum', 'Le bande fisse sono qui.');
  LPages := FRetriever.Search('bande fisse', '', 1);
  Assert.AreEqual('Le bande fisse sono qui.', LPages[0].Excerpt);
  FIndex.ExcerptMaxChars := 0;
  LPages := FRetriever.Search('bande fisse', '', 1);
  Assert.AreEqual('', LPages[0].Excerpt);
end;

procedure TDocIndexTests.LoadFromJSON_KeywordsArrayOrString;
var
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.LoadFromJSON('[{"title":"A","url":"a.html","keywords":["alpha one","beta"],"text":"x"},' +
    '{"title":"B","url":"b.html","keywords":"gamma","text":"x"},{"title":"C","url":"c.html","text":"x"}]');
  LPages := FRetriever.Search('beta', '', 1);
  Assert.AreEqual('A', LPages[0].Title);
  LPages := FRetriever.Search('gamma', '', 1);
  Assert.AreEqual('B', LPages[0].Title);
  Assert.AreEqual(0, Integer(Length(FRetriever.Search('delta', '', 1))));
end;

procedure TDocIndexTests.CountOccurrences;
begin
  Assert.AreEqual(2, THelpChatDocIndex.CountOccurrences('grid grid', 'grid'));
  Assert.AreEqual(0, THelpChatDocIndex.CountOccurrences('grid', 'grids'));
  Assert.AreEqual(0, THelpChatDocIndex.CountOccurrences('grid', ''));
  Assert.AreEqual(3, THelpChatDocIndex.CountOccurrences('aaa', 'a'));
  // Stems match at word starts only: "salesreport" is not a hit for "repor".
  Assert.AreEqual(2, THelpChatDocIndex.CountPrefixOccurrences('report dei reports: salesreport', 'repor'));
  Assert.AreEqual(1, THelpChatDocIndex.CountPrefixOccurrences('il "report"', 'repor'), 'punctuation is a boundary');
  Assert.AreEqual(0, THelpChatDocIndex.CountPrefixOccurrences('salesreport', 'repor'));
  Assert.AreEqual(0, THelpChatDocIndex.CountPrefixOccurrences('x', ''));
  Assert.AreEqual(13, THelpChatDocIndex.FindPrefix('salesreport report', 'repor'), 'the inner "report" is skipped');
  Assert.AreEqual(0, THelpChatDocIndex.FindPrefix('salesreport report', 'repor', 14));
  Assert.AreEqual(1, THelpChatDocIndex.FindPrefix('report salesreport', 'repor'));
end;

procedure TDocIndexTests.Load_Fixture;
begin
  Assert.IsTrue(FIndex.LoadFromFile(TestDataFile('help-index.json')), FIndex.LastError);
  Assert.AreEqual(5, FIndex.Count);
  Assert.IsTrue(FRetriever.IsAvailable);
  Assert.IsNotEmpty(FIndex.LoadedFrom);
end;

procedure TDocIndexTests.Search_BestPageFirst_WithAbsoluteUrl;
var
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.LoadFromFile(TestDataFile('help-index.json'));
  LPages := FRetriever.Search('How do I export the grid to Excel?', '', 3);
  Assert.IsTrue(Length(LPages) >= 1);
  Assert.AreEqual('Exporting the grid', LPages[0].Title);
  Assert.AreEqual('https://docs.example.com/app/grid/export.html', LPages[0].Url);
  Assert.IsTrue(LPages[0].Score > 0);
  Assert.IsNotEmpty(LPages[0].Summary);
end;

procedure TDocIndexTests.Search_TitleWeighsMore;
var
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.AddPage('Alpha', 'a.html', '', 'beta beta beta beta beta');
  FIndex.AddPage('Beta', 'b.html', '', 'nothing here');
  LPages := FRetriever.Search('beta', '', 2);
  Assert.AreEqual(2, Integer(Length(LPages)));
  Assert.AreEqual('Beta', LPages[0].Title, 'one title hit (x6) beats five body hits');
  Assert.AreEqual(6, LPages[0].Score);
  Assert.AreEqual(5, LPages[1].Score);
end;

procedure TDocIndexTests.Search_HintBiasesResult;
var
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.LoadFromFile(TestDataFile('help-index.json'));
  // A vague question plus the screen hint surfaces the page about that screen.
  LPages := FRetriever.Search('what can I do here?', 'Orders', 1);
  Assert.AreEqual(1, Integer(Length(LPages)));
  Assert.AreEqual('Orders', LPages[0].Title);
end;

procedure TDocIndexTests.Search_NoMatch_IsEmpty;
begin
  FIndex.LoadFromFile(TestDataFile('help-index.json'));
  Assert.AreEqual(0, Integer(Length(FRetriever.Search('zzzz qqqq', '', 3))));
  Assert.AreEqual(0, Integer(Length(FRetriever.Search('', '', 3))), 'no tokens, no result');
  Assert.AreEqual(0, Integer(Length(FRetriever.Search('the and', '', 3))), 'only stop words');
end;

procedure TDocIndexTests.Search_RespectsMaxPages;
begin
  FIndex.LoadFromFile(TestDataFile('help-index.json'));
  // "grid" and "toolbar" appear in several pages.
  Assert.AreEqual(1, Integer(Length(FRetriever.Search('grid toolbar list', '', 1))));
  Assert.AreEqual(2, Integer(Length(FRetriever.Search('grid toolbar list', '', 2))));
  Assert.IsTrue(Length(FRetriever.Search('grid toolbar list', '', 0)) <= HELPCHAT_DEFAULT_MAX_PAGES);
end;

procedure TDocIndexTests.Search_EmptyIndex_IsEmpty;
begin
  Assert.IsFalse(FRetriever.IsAvailable);
  Assert.AreEqual(0, Integer(Length(FRetriever.Search('grid', '', 3))));
end;

procedure TDocIndexTests.LoadFromFile_Missing_StaysEmpty;
begin
  Assert.IsFalse(FIndex.LoadFromFile('Z:\does\not\exist.json'));
  Assert.IsFalse(FRetriever.IsAvailable);
  Assert.IsNotEmpty(FIndex.LastError);
end;

procedure TDocIndexTests.LoadFromJSON_Malformed_Raises;
begin
  Assert.WillRaise(
    procedure
    begin
      FIndex.LoadFromJSON('{"not":"an array"}');
    end, EHelpChatError);
  Assert.WillRaise(
    procedure
    begin
      FIndex.LoadFromJSON('garbage');
    end, EHelpChatError);
end;

procedure TDocIndexTests.LoadFromJSON_AcceptsPagesWrapper;
begin
  FIndex.LoadFromJSON('{"pages":[{"title":"One","url":"one.html","summary":"s","text":"t"},{"url":"no-title.html"}]}');
  Assert.AreEqual(1, FIndex.Count, 'a page without title is skipped');
  Assert.AreEqual('One', FRetriever.Search('one', '', 1)[0].Title);
end;

procedure TDocIndexTests.BaseUrl_IsNormalized;
begin
  FIndex.BaseUrl := 'https://x.y/docs';
  Assert.AreEqual('https://x.y/docs/', FRetriever.GetBaseUrl);
  FIndex.BaseUrl := '';
  Assert.AreEqual('', FRetriever.GetBaseUrl);
  FIndex.AddPage('T', 'p.html', '', 'body');
  Assert.AreEqual('p.html', FRetriever.Search('body', '', 1)[0].Url, 'no base: relative url as is');
end;

end.
