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
///  Documentation index with deterministic keyword retrieval, the default
///  <see cref="IHelpChatRetriever" />. Loads a JSON array of pages
///  (<c>{id, title, url, summary, keywords, areas, text}</c>, as produced by
///  the HelpChat index builder), scores the query terms against each page
///  (title weighted x6 over body, keywords x3) and returns the best pages.
///  No API key, no network. Tolerant: a missing or malformed index leaves it
///  empty and <c>IsAvailable = False</c>.
///
///  One index serves one engine, and since an engine is one assistant
///  (profile) the index carries that assistant's view of the manual:
///  <c>Areas</c> narrows it to the pages of some areas plus the pages of
///  none, before anything is scored.
///
///  Thread-safe: every reader takes a snapshot of the entries under the lock
///  and works on it outside, so HTTP threads and workers search while the
///  engine loads or changes the areas.
/// </summary>
unit HelpChatAI.DocIndex;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  HelpChatAI.Types;

const
  /// <summary>Weight of a hit in the title of a page: a page called like
  /// the question is the page about it.</summary>
  HELPCHAT_TITLE_WEIGHT = 6;
  /// <summary>Weight of a hit in the page keywords (table-of-contents breadcrumb,
  /// aliases): between title and body.</summary>
  HELPCHAT_KEYWORD_WEIGHT = 3;
  /// <summary>Body hits of one token counted at most this many times in the
  /// ranking, so a long page full of a common word ("report") does not bury the
  /// short page that actually answers the question.</summary>
  HELPCHAT_BODY_HITS_CAP = 5;
  /// <summary>Ranking multiplier of the tokens coming from the search hint
  /// (screen keyword/label): they name the page the user is on and must beat
  /// the words of a generic question ("how do I use this screen?").</summary>
  HELPCHAT_HINT_WEIGHT = 2.0;
  /// <summary>With <c>hsrNormalizeHint</c>, the distinct hint tokens that
  /// keep the whole <see cref="HELPCHAT_HINT_WEIGHT" />: a longer hint (a
  /// breadcrumb, "Area > Section > Group > Item") shares the weight of this
  /// many, so it cannot outweigh the words of the question.</summary>
  HELPCHAT_HINT_BUDGET = 2;
  /// <summary>With <c>hsrPhrase</c>: two consecutive words of the question
  /// found next to each other in the title add their rarity this many times
  /// over.</summary>
  HELPCHAT_PHRASE_WEIGHT = 3;
  /// <summary>With <c>hsrPhrase</c>: a title of two words or more (its last
  /// "&gt;" segment) written whole in the question adds the rarity of its
  /// words this many times over: the page called like the question.</summary>
  HELPCHAT_TITLE_MATCH_WEIGHT = 6;
  /// <summary>With <c>hsrExactMatch</c>: a word of the question that the
  /// stemming shortened, found unchanged in the title, adds its rarity this
  /// many times over - as much as a second hit in the title -, so
  /// "loading" prefers the page about loading to the one about "loaded".</summary>
  HELPCHAT_EXACT_WEIGHT = 6;
  /// <summary>Shorter words are not tokens: articles and prepositions of
  /// every language, without a list of them.</summary>
  HELPCHAT_MIN_TOKEN_LENGTH = 3;
  /// <summary>Pages returned by <c>Search</c> when the caller asks for zero
  /// or fewer.</summary>
  HELPCHAT_DEFAULT_MAX_PAGES = 3;
  /// <summary>Default size of the excerpt returned per page (characters).</summary>
  HELPCHAT_DEF_EXCERPT_MAX_CHARS = 2000;
  /// <summary>Default characters of context kept around each matching term
  /// (<c>ExcerptWindow</c>).</summary>
  HELPCHAT_EXCERPT_WINDOW = 600;

type
  /// <summary>What the ranking of <c>Search</c> adds to the counting of the
  /// words (issue #10). <c>hsrPhrase</c>: consecutive words of the question
  /// next to each other in the title, and a title of two words or more
  /// written whole in the question, weigh more. <c>hsrExactMatch</c>: a word
  /// the stemming shortened weighs more where the title has it unchanged.
  /// <c>hsrDistinctTitles</c>: the results take pages of different titles
  /// first (the last "&gt;" segment of the title, so "A &gt; Item" and
  /// "B &gt; Item" are one title), repeated ones only when nothing else
  /// scores. <c>hsrNormalizeHint</c>: the hint is counted once per word, and
  /// a long one shares the weight of <see cref="HELPCHAT_HINT_BUDGET" />
  /// words. <c>hsrPinHintPage</c>: the page whose title is the hint (or its
  /// last "&gt;" segment) is always the first result.</summary>
  THelpChatSearchRanking = (hsrPhrase, hsrExactMatch, hsrDistinctTitles,
    hsrNormalizeHint, hsrPinHintPage);
  /// <summary>A set of <see cref="THelpChatSearchRanking" />.</summary>
  THelpChatSearchRankings = set of THelpChatSearchRanking;

const
  /// <summary>The ranking of an index nobody configured, and the default of
  /// <c>THelpChatSettings.SearchRanking</c>: every member but the pinning,
  /// which gives the first place to the page of the screen also when the
  /// question is about something else (a docsearch reply shows that page
  /// alone).</summary>
  HELPCHAT_DEF_SEARCH_RANKING = [hsrPhrase, hsrExactMatch, hsrDistinctTitles,
    hsrNormalizeHint];
  /// <summary>How a configuration file names each member of
  /// <see cref="THelpChatSearchRanking" />.</summary>
  HELPCHAT_SEARCH_RANKING_NAMES: array[THelpChatSearchRanking] of string = (
    'phrase', 'exactMatch', 'distinctTitles', 'normalizeHint', 'pinHintPage');

type
  /// <summary>One indexed page, as the index file describes it. The index
  /// itself keeps its own record with the lowercased copies it scores on;
  /// this one is the public shape of an entry, for code that reads or
  /// writes an index by itself.</summary>
  THelpChatDocEntry = record
    /// <summary>Relative path of the page without its extension.</summary>
    Id: string;
    Title: string;
    /// <summary>Relative to the base URL of the documentation.</summary>
    Url: string;
    /// <summary>First meaningful paragraph of the page.</summary>
    Summary: string;
    /// <summary>The page as plain text, cut by the builder.</summary>
    Text: string;
  end;

  /// <summary>
  ///  The index of one engine. Reference counted: the engine keeps it
  ///  through <see cref="IHelpChatRetriever" /> and hands that interface to
  ///  the runner and to every provider, so a search in flight keeps it
  ///  alive past the engine's <c>Stop</c>. Loading replaces the entries in
  ///  one assignment under the lock; a search that started before works on
  ///  the entries it took.
  /// </summary>
  THelpChatDocIndex = class(TInterfacedObject, IHelpChatRetriever)
  strict private
  type
    /// <summary>A page with what the scoring needs next to what is
    /// returned: lowercasing once at load time is what keeps a search a
    /// matter of substring counting.</summary>
    TScoredEntry = record
      Title: string;
      Url: string;
      Summary: string;
      Text: string;      // original case, for excerpts
      LTitle: string;    // lowercased, for scoring
      LKeywords: string; // lowercased, joined
      LText: string;
      LAreas: string;    // lowercased, '|area|area|'; empty = every assistant's
      LLeaf: string;     // lowercased last '>' segment of the title, trimmed
      TitleWords: TArray<string>; // Tokenize of the title
      LeafWords: TArray<string>;  // Tokenize of the leaf
    end;
  strict private
    FLock: TCriticalSection;
    FEntries: TArray<TScoredEntry>;
    FBaseUrl: string;
    FLoadedFrom: string;
    FLastError: string;
    FExcerptMaxChars: Integer;
    FExcerptWindow: Integer;
    FAreas: TArray<string>;
    FAreaFilter: string;
    FRanking: THelpChatSearchRankings;
    procedure SetBaseUrl(const Value: string);
    function GetRanking: THelpChatSearchRankings;
    procedure SetRanking(const Value: THelpChatSearchRankings);
    /// <summary>Fills what the scoring derives from the title, the text and
    /// the keywords already set: the lowercased copies, the leaf, the words.</summary>
    class procedure PrepareEntry(var AEntry: TScoredEntry); static;
    procedure SetAreas(const Value: TArray<string>);
    function GetAreas: TArray<string>;
    /// <summary>The entries this assistant knows: those of its areas, and
    /// those of no area; all of them when no area is set. Called under the
    /// lock, and the array it returns is the caller's to read outside it:
    /// either the entries themselves (never modified in place, only
    /// replaced) or a filtered copy. The comparison is on the lowercased
    /// names, so "Orders" and "orders" are one area.</summary>
    function VisibleEntries: TArray<TScoredEntry>;
    /// <summary>The raw score of a page: occurrences of every token, at the
    /// start of a word, weighted by where they are. It decides whether a
    /// page is relevant at all (above zero) and is what
    /// <c>THelpChatDocPage.Score</c> reports; the order of the results comes
    /// from the ranking in <c>Search</c>, not from this.</summary>
    function ScoreEntry(const AEntry: TScoredEntry; const ATokens: TArray<string>): Integer;
    /// <summary>The passages of a page around the first occurrence of each
    /// token, overlapping windows merged, in the order of the page, within
    /// <c>AMaxChars</c>, each window <c>AWindow</c> characters around its
    /// token. The whole text when it fits, its beginning when no token is
    /// found in the body (a page that matched on its title).</summary>
    function BuildExcerpt(const AEntry: TScoredEntry; const ATokens: TArray<string>;
      const AMaxChars, AWindow: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Replaces the index with a JSON array of pages, or with the
    /// <c>pages</c> array of an object. An entry without a title is skipped;
    /// <c>keywords</c> may be an array or one string, and so may
    /// <c>areas</c> (a string is a list with commas); an entry with none
    /// belongs to every assistant.
    /// Raises <see cref="EHelpChatError" /> on malformed input, leaving the
    /// previous entries in place.</summary>
    procedure LoadFromJSON(const AJson: string);
    /// <summary>Loads AFileName (UTF-8). Returns False and stays empty when the
    /// file is missing or malformed; the reason is in <c>LastError</c>.
    /// Never raises.</summary>
    function LoadFromFile(const AFileName: string): Boolean;
    /// <summary>Adds one page (mainly for tests and programmatic indexes).
    /// AKeywords: aliases and breadcrumb, any separator. A page added this
    /// way has no area, so every assistant sees it whatever <c>Areas</c>
    /// says. A blank title adds nothing.</summary>
    procedure AddPage(const ATitle, AUrl, ASummary, AText: string; const AKeywords: string = '');
    /// <summary>Empties the index and forgets where it came from; the base
    /// URL and the areas stay.</summary>
    procedure Clear;
    /// <summary>Pages of the whole index, whatever the areas: what tells an
    /// index that is loaded from one that is not. The pages an assistant
    /// can actually get are <c>Pages</c>.</summary>
    function Count: Integer;
    /// <summary>Every page this assistant sees - the whole index, or the
    /// pages of its <c>Areas</c> and of no area - (title, url with the base,
    /// summary; no excerpt), in the order of the file: what /pages lists.</summary>
    function Pages: TArray<THelpChatDocPage>;

    // IHelpChatRetriever
    /// <summary>True when the index holds at least one page - of any area:
    /// an assistant whose areas match no page has an index that is
    /// available and searches that find nothing.</summary>
    function IsAvailable: Boolean;
    function GetBaseUrl: string;
    /// <summary>The best <c>AMaxPages</c> pages (three when zero or less)
    /// among those this assistant sees, best first, each with an excerpt
    /// around the matching terms and its raw score. <c>AHint</c> - the
    /// keyword and the label of the screen the user is on - is searched
    /// like the question and weighs double. <c>Ranking</c> says what else
    /// counts (phrases, exact words, distinct titles, the page of the
    /// screen first). Empty when nothing scores, when
    /// the question and the hint leave no token, or when there is no page.
    /// Safe from any thread; the scoring runs outside the lock.</summary>
    function Search(const AQuery, AHint: string; const AMaxPages: Integer): TArray<THelpChatDocPage>;

    /// <summary>Splits text into lowercase alphanumeric tokens of at least
    /// <see cref="HELPCHAT_MIN_TOKEN_LENGTH" /> characters, minus Italian and
    /// English stop words.</summary>
    class function Tokenize(const AText: string): TArray<string>; static;
    /// <summary>True for a word that carries no meaning in a question
    /// ("how", "with", "come", "della"). <c>AWord</c> must be lowercase
    /// already. The list is English and Italian only: in the other languages
    /// of the chat such words are tokens like any other, and it is the idf
    /// of the ranking that keeps them from deciding.</summary>
    class function IsStopWord(const AWord: string): Boolean; static;
    /// <summary>Non-overlapping occurrences of ANeedle anywhere in
    /// AHaystack, case-sensitive; zero for an empty needle.</summary>
    class function CountOccurrences(const AHaystack, ANeedle: string): Integer; static;
    /// <summary>Occurrences of ANeedle at the start of a word only ("repor" hits
    /// "report" and "reports", not "salesreport"): the right match for stems
    /// obtained by truncation. Used by the scoring.</summary>
    class function CountPrefixOccurrences(const AHaystack, ANeedle: string): Integer; static;
    /// <summary>1-based position of the first word starting with ANeedle at or
    /// after AStart, 0 when none.</summary>
    class function FindPrefix(const AHaystack, ANeedle: string; const AStart: Integer = 1): Integer; static;
    /// <summary>Light stemming by truncation, so "esporto" also hits "esportare"
    /// and "esportazione", "modelli" hits "modello": 8+ chars keep 6, 6-7 chars
    /// keep 5, shorter tokens are kept whole. Language-neutral by design.</summary>
    class function StemToken(const AToken: string): string; static;
    /// <summary>Tokenize followed by StemToken on every token (what Search uses).</summary>
    class function TokenizeStems(const AText: string): TArray<string>; static;

    /// <summary>Prefix of every page URL (normalized with a trailing slash).</summary>
    property BaseUrl: string read GetBaseUrl write SetBaseUrl;
    /// <summary>Size of the excerpt built for each returned page (0 = none).
    /// Windows of text around the matching terms, merged and joined by an
    /// ellipsis, so the model sees the passage that answers rather than the
    /// beginning of a long page.</summary>
    property ExcerptMaxChars: Integer read FExcerptMaxChars write FExcerptMaxChars;
    /// <summary>Characters of text kept around each matching term when a page
    /// is longer than <c>ExcerptMaxChars</c>: half before it, half after.
    /// Larger keeps a whole code sample, smaller fits more passages; 0 or
    /// less means <c>HELPCHAT_EXCERPT_WINDOW</c>.</summary>
    property ExcerptWindow: Integer read FExcerptWindow write FExcerptWindow;
    /// <summary>The areas of the manual this index answers from: a page
    /// belongs to the areas its entry names (<c>"areas"</c>, written by the
    /// index builder from the sub-folder or the front matter), and a page of
    /// no area belongs to everybody. Empty = the whole manual. The filter
    /// comes before the scoring, so the rarity of a word is measured on the
    /// area and not on the whole manual. Names are trimmed and compared
    /// without case; blank ones are dropped. A name that matches no page
    /// is not an error: the assistant is left with the pages of no area.
    /// May be set at any time, from any thread; a search already running
    /// keeps the view it started with.</summary>
    property Areas: TArray<string> read GetAreas write SetAreas;
    /// <summary>What the ranking adds to the counting of the words: see
    /// <see cref="THelpChatSearchRanking" />. <c>HELPCHAT_DEF_SEARCH_RANKING</c>
    /// by default; the empty set is the ranking of 2.2. May be set at any
    /// time, from any thread; a search already running keeps the one it
    /// started with.</summary>
    property Ranking: THelpChatSearchRankings read GetRanking write SetRanking;
    /// <summary>File the index was loaded from, if any.</summary>
    property LoadedFrom: string read FLoadedFrom;
    /// <summary>Why the last <c>LoadFromFile</c> left the index empty: the
    /// file is not there, or the message of the parser. Empty after a load
    /// that worked.</summary>
    property LastError: string read FLastError;
  end;

/// <summary>The names of the members of ARanking, in the order of the
/// enumeration (<see cref="HELPCHAT_SEARCH_RANKING_NAMES" />).</summary>
function HelpChatSearchRankingToNames(const ARanking: THelpChatSearchRankings): TArray<string>;
/// <summary>The set the names make, case ignored, the identifiers
/// ("hsrPhrase") accepted too; a name of no member is skipped.</summary>
function HelpChatNamesToSearchRanking(const ANames: TArray<string>): THelpChatSearchRankings;

implementation

uses
  System.StrUtils,
  System.Character,
  System.IOUtils,
  System.JSON,
  System.Generics.Defaults;

const
  STOPWORDS: TArray<string> = [
    // English
    'the', 'and', 'for', 'with', 'that', 'this', 'from', 'how', 'can', 'you',
    'are', 'what', 'when', 'where', 'which', 'your', 'not', 'use', 'does', 'have',
    'into', 'about', 'there', 'their', 'will', 'would', 'should', 'want', 'need',
    'please', 'could',
    // Italian
    'come', 'che', 'per', 'con', 'non', 'una', 'uno', 'gli', 'dei', 'del',
    'della', 'delle', 'degli', 'nel', 'nella', 'nelle', 'negli', 'sul', 'sulla',
    'sullo', 'alla', 'allo', 'alle', 'agli', 'dalla', 'dallo', 'dal', 'tra', 'fra',
    'cosa', 'quando', 'dove', 'quale', 'quali', 'questo', 'questa', 'questi', 'queste',
    'posso', 'puoi', 'devo', 'deve', 'vorrei', 'voglio', 'viene', 'essere', 'sono',
    'fare', 'anche', 'oppure', 'tutti', 'tutte', 'mio', 'mia'];

function HelpChatSearchRankingToNames(const ARanking: THelpChatSearchRankings): TArray<string>;
var
  LMember: THelpChatSearchRanking;
begin
  Result := nil;
  for LMember := Low(THelpChatSearchRanking) to High(THelpChatSearchRanking) do
    if LMember in ARanking then
      Result := Result + [HELPCHAT_SEARCH_RANKING_NAMES[LMember]];
end;

function HelpChatNamesToSearchRanking(const ANames: TArray<string>): THelpChatSearchRankings;
var
  LName: string;
  LMember: THelpChatSearchRanking;
begin
  Result := [];
  for LName in ANames do
    for LMember := Low(THelpChatSearchRanking) to High(THelpChatSearchRanking) do
      if SameText(Trim(LName), HELPCHAT_SEARCH_RANKING_NAMES[LMember]) or
         SameText(Trim(LName), 'hsr' + HELPCHAT_SEARCH_RANKING_NAMES[LMember]) then
        Include(Result, LMember);
end;

{ THelpChatDocIndex }

constructor THelpChatDocIndex.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FExcerptMaxChars := HELPCHAT_DEF_EXCERPT_MAX_CHARS;
  FExcerptWindow := HELPCHAT_EXCERPT_WINDOW;
  FRanking := HELPCHAT_DEF_SEARCH_RANKING;
end;

function THelpChatDocIndex.GetRanking: THelpChatSearchRankings;
begin
  FLock.Enter;
  try
    Result := FRanking;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatDocIndex.SetRanking(const Value: THelpChatSearchRankings);
begin
  FLock.Enter;
  try
    FRanking := Value;
  finally
    FLock.Leave;
  end;
end;

class procedure THelpChatDocIndex.PrepareEntry(var AEntry: TScoredEntry);
var
  P: Integer;
begin
  AEntry.LTitle := AEntry.Title.ToLower;
  AEntry.LText := AEntry.Text.ToLower;
  AEntry.LLeaf := AEntry.LTitle;
  P := AEntry.LLeaf.LastIndexOf('>');
  if P >= 0 then
    AEntry.LLeaf := AEntry.LLeaf.Substring(P + 1);
  AEntry.LLeaf := Trim(AEntry.LLeaf);
  AEntry.TitleWords := Tokenize(AEntry.LTitle);
  AEntry.LeafWords := Tokenize(AEntry.LLeaf);
end;

destructor THelpChatDocIndex.Destroy;
begin
  FLock.Free;
  inherited;
end;

class function THelpChatDocIndex.IsStopWord(const AWord: string): Boolean;
var
  S: string;
begin
  for S in STOPWORDS do
    if S = AWord then
      Exit(True);
  Result := False;
end;

class function THelpChatDocIndex.Tokenize(const AText: string): TArray<string>;
var
  LList: TList<string>;
  LCur: TStringBuilder;
  C: Char;

  procedure Flush;
  var
    LWord: string;
  begin
    if LCur.Length >= HELPCHAT_MIN_TOKEN_LENGTH then
    begin
      LWord := LCur.ToString;
      if not IsStopWord(LWord) then
        LList.Add(LWord);
    end;
    LCur.Clear;
  end;

begin
  LList := TList<string>.Create;
  LCur := TStringBuilder.Create;
  try
    for C in AText.ToLower do
      if C.IsLetterOrDigit then
        LCur.Append(C)
      else
        Flush;
    Flush;
    Result := LList.ToArray;
  finally
    LCur.Free;
    LList.Free;
  end;
end;

class function THelpChatDocIndex.CountOccurrences(const AHaystack, ANeedle: string): Integer;
var
  P: Integer;
begin
  Result := 0;
  if ANeedle = '' then
    Exit;
  P := PosEx(ANeedle, AHaystack, 1);
  while P > 0 do
  begin
    Inc(Result);
    P := PosEx(ANeedle, AHaystack, P + ANeedle.Length);
  end;
end;

class function THelpChatDocIndex.FindPrefix(const AHaystack, ANeedle: string; const AStart: Integer): Integer;
var
  P: Integer;
begin
  Result := 0;
  if ANeedle = '' then
    Exit;
  P := PosEx(ANeedle, AHaystack, AStart);
  while P > 0 do
  begin
    if (P = 1) or not AHaystack[P - 1].IsLetterOrDigit then
      Exit(P);
    P := PosEx(ANeedle, AHaystack, P + 1);
  end;
end;

class function THelpChatDocIndex.CountPrefixOccurrences(const AHaystack, ANeedle: string): Integer;
var
  P: Integer;
begin
  Result := 0;
  P := FindPrefix(AHaystack, ANeedle, 1);
  while P > 0 do
  begin
    Inc(Result);
    P := FindPrefix(AHaystack, ANeedle, P + ANeedle.Length);
  end;
end;

class function THelpChatDocIndex.StemToken(const AToken: string): string;
begin
  if AToken.Length >= 8 then
    Result := AToken.Substring(0, 6)
  else if AToken.Length >= 6 then
    Result := AToken.Substring(0, 5)
  else
    Result := AToken;
end;

class function THelpChatDocIndex.TokenizeStems(const AText: string): TArray<string>;
var
  I: Integer;
begin
  Result := Tokenize(AText);
  for I := 0 to High(Result) do
    Result[I] := StemToken(Result[I]);
end;

function THelpChatDocIndex.BuildExcerpt(const AEntry: TScoredEntry;
  const ATokens: TArray<string>; const AMaxChars, AWindow: Integer): string;
type
  TWindow = record
    Start, Stop: Integer; // 0-based, Stop exclusive
  end;
var
  LWindows: TList<TWindow>;
  LWindow, LOther: TWindow;
  LToken: string;
  P, I, LLen, LHalf, LBudget: Integer;
  LSb: TStringBuilder;
  LMerged: Boolean;
  LPiece: string;
begin
  Result := '';
  LLen := AEntry.Text.Length;
  if (AMaxChars <= 0) or (LLen = 0) then
    Exit;
  if LLen <= AMaxChars then
    Exit(AEntry.Text);
  // ToLower keeps the length for the alphabets we care about, so offsets found
  // in LText address Text; every access is bounds-checked anyway.
  if AWindow > 0 then
    LHalf := AWindow div 2
  else
    LHalf := HELPCHAT_EXCERPT_WINDOW div 2;
  LWindows := TList<TWindow>.Create;
  try
    for LToken in ATokens do
    begin
      P := FindPrefix(AEntry.LText, LToken);
      if P <= 0 then
        Continue;
      LWindow.Start := P - 1 - LHalf;
      if LWindow.Start < 0 then
        LWindow.Start := 0;
      LWindow.Stop := P - 1 + LToken.Length + LHalf;
      if LWindow.Stop > LLen then
        LWindow.Stop := LLen;
      // Merge with any overlapping window.
      LMerged := False;
      for I := 0 to LWindows.Count - 1 do
      begin
        LOther := LWindows[I];
        if (LWindow.Start <= LOther.Stop) and (LWindow.Stop >= LOther.Start) then
        begin
          if LWindow.Start < LOther.Start then
            LOther.Start := LWindow.Start;
          if LWindow.Stop > LOther.Stop then
            LOther.Stop := LWindow.Stop;
          LWindows[I] := LOther;
          LMerged := True;
          Break;
        end;
      end;
      if not LMerged then
        LWindows.Add(LWindow);
    end;
    if LWindows.Count = 0 then
      Exit(AEntry.Text.Substring(0, AMaxChars));
    LWindows.Sort(TComparer<TWindow>.Construct(
      function(const A, B: TWindow): Integer
      begin
        Result := A.Start - B.Start;
      end));

    LSb := TStringBuilder.Create;
    try
      LBudget := AMaxChars;
      for LWindow in LWindows do
      begin
        if LBudget <= 0 then
          Break;
        LPiece := AEntry.Text.Substring(LWindow.Start, LWindow.Stop - LWindow.Start);
        // Cut to whole words at both ends of an inner window.
        if LWindow.Start > 0 then
        begin
          P := LPiece.IndexOf(' ');
          if (P >= 0) and (P < 40) then
            LPiece := LPiece.Substring(P + 1);
        end;
        if LWindow.Stop < LLen then
        begin
          P := LPiece.LastIndexOf(' ');
          if (P >= 0) and (P > LPiece.Length - 40) then
            LPiece := LPiece.Substring(0, P);
        end;
        if LPiece.Length > LBudget then
          LPiece := LPiece.Substring(0, LBudget);
        if LSb.Length > 0 then
          LSb.Append(' '#$2026' ');
        if LWindow.Start > 0 then
          LSb.Append(#$2026);
        LSb.Append(LPiece.Trim);
        if LWindow.Stop < LLen then
          LSb.Append(#$2026);
        Dec(LBudget, LPiece.Length);
      end;
      Result := LSb.ToString;
    finally
      LSb.Free;
    end;
  finally
    LWindows.Free;
  end;
end;

function THelpChatDocIndex.ScoreEntry(const AEntry: TScoredEntry; const ATokens: TArray<string>): Integer;
var
  LToken: string;
begin
  Result := 0;
  for LToken in ATokens do
    Inc(Result, CountPrefixOccurrences(AEntry.LTitle, LToken) * HELPCHAT_TITLE_WEIGHT +
                CountPrefixOccurrences(AEntry.LKeywords, LToken) * HELPCHAT_KEYWORD_WEIGHT +
                CountPrefixOccurrences(AEntry.LText, LToken));
end;

procedure THelpChatDocIndex.SetBaseUrl(const Value: string);
begin
  FLock.Enter;
  try
    FBaseUrl := Trim(Value);
    if (FBaseUrl <> '') and not FBaseUrl.EndsWith('/') then
      FBaseUrl := FBaseUrl + '/';
  finally
    FLock.Leave;
  end;
end;

function THelpChatDocIndex.GetBaseUrl: string;
begin
  FLock.Enter;
  try
    Result := FBaseUrl;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatDocIndex.AddPage(const ATitle, AUrl, ASummary, AText: string;
  const AKeywords: string);
var
  LEntry: TScoredEntry;
begin
  if Trim(ATitle) = '' then
    Exit;
  LEntry.Title := ATitle;
  LEntry.Url := AUrl;
  LEntry.Summary := ASummary;
  LEntry.Text := AText;
  LEntry.LKeywords := AKeywords.ToLower;
  LEntry.LAreas := '';
  PrepareEntry(LEntry);
  // LAreas stays empty: a page added by code belongs to every assistant.
  FLock.Enter;
  try
    // A new array, never an append in place: a search holding the old one
    // keeps reading it.
    FEntries := FEntries + [LEntry];
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatDocIndex.SetAreas(const Value: TArray<string>);
var
  LArea: string;
begin
  FLock.Enter;
  try
    FAreas := Copy(Value);
    // The filter is the names lowercased and joined by the same bar the
    // entries use, so a name containing a bar would count as two areas.
    FAreaFilter := '';
    for LArea in Value do
      if Trim(LArea) <> '' then
        FAreaFilter := FAreaFilter + '|' + Trim(LArea).ToLower;
  finally
    FLock.Leave;
  end;
end;

function THelpChatDocIndex.GetAreas: TArray<string>;
begin
  FLock.Enter;
  try
    Result := Copy(FAreas);
  finally
    FLock.Leave;
  end;
end;

function THelpChatDocIndex.VisibleEntries: TArray<TScoredEntry>;
var
  LList: TList<TScoredEntry>;
  LEntry: TScoredEntry;
  LArea: string;
  LVisible: Boolean;
begin
  if FAreaFilter = '' then
    Exit(FEntries);
  LList := TList<TScoredEntry>.Create;
  try
    for LEntry in FEntries do
    begin
      // No area: everybody's. Else one area in common is enough; the bars
      // on both sides make "order" not match "orders".
      LVisible := LEntry.LAreas = '';
      if not LVisible then
        for LArea in FAreaFilter.Split(['|'], TStringSplitOptions.ExcludeEmpty) do
          if LEntry.LAreas.Contains('|' + LArea + '|') then
          begin
            LVisible := True;
            Break;
          end;
      if LVisible then
        LList.Add(LEntry);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

procedure THelpChatDocIndex.Clear;
begin
  FLock.Enter;
  try
    FEntries := nil;
    FLoadedFrom := '';
    FLastError := '';
  finally
    FLock.Leave;
  end;
end;

function THelpChatDocIndex.Count: Integer;
begin
  FLock.Enter;
  try
    Result := Length(FEntries);
  finally
    FLock.Leave;
  end;
end;

function THelpChatDocIndex.Pages: TArray<THelpChatDocPage>;
var
  LEntries: TArray<TScoredEntry>;
  LBase: string;
  I: Integer;
begin
  FLock.Enter;
  try
    LEntries := VisibleEntries;
    LBase := FBaseUrl;
  finally
    FLock.Leave;
  end;
  SetLength(Result, Length(LEntries));
  for I := 0 to High(LEntries) do
  begin
    Result[I] := Default(THelpChatDocPage);
    Result[I].Title := LEntries[I].Title;
    Result[I].Url := HelpChatJoinUrl(LBase, LEntries[I].Url);
    Result[I].Summary := LEntries[I].Summary;
  end;
end;

procedure THelpChatDocIndex.LoadFromJSON(const AJson: string);
var
  LValue, LKeywordsValue, LAreasValue: TJSONValue;
  LAreaName: string;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LList: TList<TScoredEntry>;
  LEntry: TScoredEntry;
  I, K: Integer;
begin
  LValue := TJSONObject.ParseJSONValue(AJson);
  if LValue = nil then
    raise EHelpChatError.Create('Invalid help index: not a JSON document');
  LList := TList<TScoredEntry>.Create;
  try
    // Accept either a bare array or {"pages":[...]}.
    if LValue is TJSONArray then
      LArray := TJSONArray(LValue)
    else if (LValue is TJSONObject) and (TJSONObject(LValue).GetValue('pages') is TJSONArray) then
      LArray := TJSONArray(TJSONObject(LValue).GetValue('pages'))
    else
      raise EHelpChatError.Create('Invalid help index: expected an array of pages');
    for I := 0 to LArray.Count - 1 do
    begin
      if not (LArray.Items[I] is TJSONObject) then
        Continue;
      LObj := TJSONObject(LArray.Items[I]);
      LEntry.Title := LObj.GetValue<string>('title', '');
      if Trim(LEntry.Title) = '' then
        Continue;
      LEntry.Url := LObj.GetValue<string>('url', '');
      LEntry.Summary := LObj.GetValue<string>('summary', '');
      // "keywords": an array of strings or a single string.
      LKeywordsValue := LObj.GetValue('keywords');
      LEntry.LKeywords := '';
      if LKeywordsValue is TJSONArray then
      begin
        for K := 0 to TJSONArray(LKeywordsValue).Count - 1 do
          LEntry.LKeywords := LEntry.LKeywords + ' | ' + TJSONArray(LKeywordsValue).Items[K].Value.ToLower;
      end
      else if LKeywordsValue is TJSONString then
        LEntry.LKeywords := LKeywordsValue.Value.ToLower;
      LEntry.Text := LObj.GetValue<string>('text', '');
      PrepareEntry(LEntry);
      // "areas": an array of names, kept as '|a|b|' so that membership is
      // one Contains. Missing or empty: no area. A string is read as a list
      // with commas - what an index written by hand, or by another tool,
      // says with "areas": "Orders" - instead of making the page everybody's
      // without a word.
      LAreasValue := LObj.GetValue('areas');
      LEntry.LAreas := '';
      if LAreasValue is TJSONArray then
      begin
        for K := 0 to TJSONArray(LAreasValue).Count - 1 do
          if Trim(TJSONArray(LAreasValue).Items[K].Value) <> '' then
            LEntry.LAreas := LEntry.LAreas + '|' + Trim(TJSONArray(LAreasValue).Items[K].Value).ToLower;
      end
      else if LAreasValue is TJSONString then
        for LAreaName in LAreasValue.Value.Split([',', ';']) do
          if Trim(LAreaName) <> '' then
            LEntry.LAreas := LEntry.LAreas + '|' + Trim(LAreaName).ToLower;
      if LEntry.LAreas <> '' then
        LEntry.LAreas := LEntry.LAreas + '|';
      LList.Add(LEntry);
    end;
    FLock.Enter;
    try
      FEntries := LList.ToArray;
      FLastError := '';
    finally
      FLock.Leave;
    end;
  finally
    LList.Free;
    LValue.Free;
  end;
end;

function THelpChatDocIndex.LoadFromFile(const AFileName: string): Boolean;
begin
  Result := False;
  if (AFileName = '') or not TFile.Exists(AFileName) then
  begin
    FLock.Enter;
    try
      FLastError := Format('Help index file not found: %s', [AFileName]);
    finally
      FLock.Leave;
    end;
    Exit;
  end;
  try
    LoadFromJSON(TFile.ReadAllText(AFileName, TEncoding.UTF8));
    FLock.Enter;
    try
      FLoadedFrom := AFileName;
    finally
      FLock.Leave;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      // A corrupt index must not break the chat: stay empty, remember why.
      FLock.Enter;
      try
        FEntries := nil;
        FLastError := E.Message;
      finally
        FLock.Leave;
      end;
    end;
  end;
end;

function THelpChatDocIndex.IsAvailable: Boolean;
begin
  Result := Count > 0;
end;

function THelpChatDocIndex.Search(const AQuery, AHint: string;
  const AMaxPages: Integer): TArray<THelpChatDocPage>;

  // Word W of a title matches the stem S the way the scoring does: W starts with S.
  function WordMatches(const AWord, AStem: string): Boolean;
  begin
    Result := AWord.StartsWith(AStem);
  end;

  function HasAdjacent(const AWords: TArray<string>; const AFirst, ASecond: string): Boolean;
  var
    K: Integer;
  begin
    for K := 0 to High(AWords) - 1 do
      if WordMatches(AWords[K], AFirst) and WordMatches(AWords[K + 1], ASecond) then
        Exit(True);
    Result := False;
  end;

  function HasWord(const AWords: TArray<string>; const AWord: string): Boolean;
  var
    W: string;
  begin
    for W in AWords do
      if W = AWord then
        Exit(True);
    Result := False;
  end;

var
  LEntries: TArray<TScoredEntry>;
  LBase: string;
  LRanking: THelpChatSearchRankings;
  LWords, LTokens, LHintTokens, LDistinct: TArray<string>;
  LScores: TArray<Integer>;
  LRank, LIdf: TArray<Double>;
  LUsed: TArray<Boolean>;
  LLeaves: TList<string>;
  LQueryCount, LMax, LBestIdx, LPinIdx, I, J, K, S, T, LDf, LTitleHits, LKeywordHits,
    LBodyHits, LExcerptChars, LExcerptWindow: Integer;
  LBestRank, LWeight, LHintWeight, LRunIdf: Double;
  LPages: TList<THelpChatDocPage>;
  LPage: THelpChatDocPage;
  LToken, LHint, LHintLeaf: string;
  LRun, LDistinctOnly: Boolean;
begin
  Result := nil;
  // Snapshot under the lock, score outside it (dynamic arrays are copy-on-write).
  FLock.Enter;
  try
    LEntries := VisibleEntries;
    LBase := FBaseUrl;
    LExcerptChars := FExcerptMaxChars;
    LExcerptWindow := FExcerptWindow;
    LRanking := FRanking;
  finally
    FLock.Leave;
  end;
  if Length(LEntries) = 0 then
    Exit;

  // Stems, not words: substring counting then matches the inflected forms.
  // Query tokens first, hint tokens after (they rank with HELPCHAT_HINT_WEIGHT).
  // LWords keeps the words of the question as they were, index by index.
  LWords := Tokenize(AQuery);
  LTokens := Copy(LWords);
  for I := 0 to High(LTokens) do
    LTokens[I] := StemToken(LTokens[I]);
  LQueryCount := Length(LTokens);
  if AHint <> '' then
    LHintTokens := TokenizeStems(AHint)
  else
    LHintTokens := nil;
  LHintWeight := HELPCHAT_HINT_WEIGHT;
  if (hsrNormalizeHint in LRanking) and (Length(LHintTokens) > 0) then
  begin
    // Once per word ("Leads" as keyword and label is one word), and a long
    // hint shares the weight of HELPCHAT_HINT_BUDGET words.
    LDistinct := nil;
    for LToken in LHintTokens do
      if not HasWord(LDistinct, LToken) then
        LDistinct := LDistinct + [LToken];
    LHintTokens := LDistinct;
    if Length(LHintTokens) > HELPCHAT_HINT_BUDGET then
      LHintWeight := HELPCHAT_HINT_WEIGHT * HELPCHAT_HINT_BUDGET / Length(LHintTokens);
  end;
  LTokens := LTokens + LHintTokens;
  if Length(LTokens) = 0 then
    Exit;

  SetLength(LScores, Length(LEntries));
  SetLength(LRank, Length(LEntries));
  SetLength(LUsed, Length(LEntries));
  SetLength(LIdf, Length(LTokens));
  for I := 0 to High(LEntries) do
    LScores[I] := ScoreEntry(LEntries[I], LTokens);

  // Ranking: rare tokens weigh more (idf), body hits are capped, so the page
  // about the topic beats the long page that merely mentions the common word.
  for T := 0 to High(LTokens) do
  begin
    LToken := LTokens[T];
    if T >= LQueryCount then
      LWeight := LHintWeight
    else
      LWeight := 1;
    LDf := 0;
    for I := 0 to High(LEntries) do
      if (FindPrefix(LEntries[I].LTitle, LToken) > 0) or (FindPrefix(LEntries[I].LKeywords, LToken) > 0) or
         (FindPrefix(LEntries[I].LText, LToken) > 0) then
        Inc(LDf);
    if LDf = 0 then
      Continue;
    // Both numbers are the assistant's: LEntries is already filtered by
    // area, so a word that is common in the manual and rare in this area
    // weighs as a rare one.
    LIdf[T] := Ln(1 + Length(LEntries) / LDf);
    for I := 0 to High(LEntries) do
    begin
      LTitleHits := CountPrefixOccurrences(LEntries[I].LTitle, LToken);
      LKeywordHits := CountPrefixOccurrences(LEntries[I].LKeywords, LToken);
      LBodyHits := CountPrefixOccurrences(LEntries[I].LText, LToken);
      if LBodyHits > HELPCHAT_BODY_HITS_CAP then
        LBodyHits := HELPCHAT_BODY_HITS_CAP;
      LRank[I] := LRank[I] + LIdf[T] * LWeight *
        (LTitleHits * HELPCHAT_TITLE_WEIGHT + LKeywordHits * HELPCHAT_KEYWORD_WEIGHT + LBodyHits);
    end;
  end;

  // What the title says beyond the single words: the words of the question
  // only, never the hint.
  if (LRanking * [hsrPhrase, hsrExactMatch] <> []) and (LQueryCount > 0) then
    for I := 0 to High(LEntries) do
    begin
      if LScores[I] <= 0 then
        Continue;
      if hsrPhrase in LRanking then
      begin
        // Two consecutive words of the question next to each other in the title.
        for T := 0 to LQueryCount - 2 do
          if (LIdf[T] > 0) and (LIdf[T + 1] > 0) and
             HasAdjacent(LEntries[I].TitleWords, LTokens[T], LTokens[T + 1]) then
            LRank[I] := LRank[I] + HELPCHAT_PHRASE_WEIGHT * (LIdf[T] + LIdf[T + 1]);
        // A title of two words or more written whole in the question: the
        // page called like the question. Its last segment, for a title that
        // is a breadcrumb.
        K := Length(LEntries[I].LeafWords);
        if K >= 2 then
          for S := 0 to LQueryCount - K do
          begin
            LRun := True;
            LRunIdf := 0;
            for J := 0 to K - 1 do
              if WordMatches(LEntries[I].LeafWords[J], LTokens[S + J]) then
                LRunIdf := LRunIdf + LIdf[S + J]
              else
              begin
                LRun := False;
                Break;
              end;
            if LRun then
            begin
              LRank[I] := LRank[I] + HELPCHAT_TITLE_MATCH_WEIGHT * LRunIdf;
              Break;
            end;
          end;
      end;
      if hsrExactMatch in LRanking then
        // A word the stemming shortened ("loading" -> "loadi"), unchanged in
        // the title: the page about it, not the one about a sibling word.
        for T := 0 to LQueryCount - 1 do
          if (LWords[T] <> LTokens[T]) and (LIdf[T] > 0) and
             HasWord(LEntries[I].TitleWords, LWords[T]) then
            LRank[I] := LRank[I] + HELPCHAT_EXACT_WEIGHT * LIdf[T];
    end;

  LMax := AMaxPages;
  if LMax <= 0 then
    LMax := HELPCHAT_DEFAULT_MAX_PAGES;

  // The page of the screen, when asked for: the one whose title is the hint
  // or its last segment, the best ranked if several are.
  LPinIdx := -1;
  if (hsrPinHintPage in LRanking) and (Trim(AHint) <> '') then
  begin
    LHint := Trim(AHint).ToLower;
    LHintLeaf := LHint;
    I := LHintLeaf.LastIndexOf('>');
    if I >= 0 then
      LHintLeaf := Trim(LHintLeaf.Substring(I + 1));
    for I := 0 to High(LEntries) do
      if ((Trim(LEntries[I].LTitle) = LHint) or (LEntries[I].LLeaf = LHintLeaf)) and
         ((LPinIdx < 0) or (LRank[I] > LRank[LPinIdx])) then
        LPinIdx := I;
  end;

  LPages := TList<THelpChatDocPage>.Create;
  LLeaves := TList<string>.Create;
  try
    // Greedy top-N by ranking; a page must score > 0 to be relevant at all.
    for J := 1 to LMax do
    begin
      LBestIdx := -1;
      if (J = 1) and (LPinIdx >= 0) then
        LBestIdx := LPinIdx
      else
      begin
        // With distinct titles a title already taken waits until no other
        // page scores; a title of nothing (a page with no leaf) never waits.
        LDistinctOnly := hsrDistinctTitles in LRanking;
        repeat
          LBestRank := 0;
          for I := 0 to High(LEntries) do
            if (not LUsed[I]) and (LScores[I] > 0) and (LRank[I] > LBestRank) and
               not (LDistinctOnly and (LEntries[I].LLeaf <> '') and
                    LLeaves.Contains(LEntries[I].LLeaf)) then
            begin
              LBestRank := LRank[I];
              LBestIdx := I;
            end;
          if (LBestIdx >= 0) or not LDistinctOnly then
            Break;
          LDistinctOnly := False;
        until False;
      end;
      if LBestIdx < 0 then
        Break;
      LUsed[LBestIdx] := True;
      LLeaves.Add(LEntries[LBestIdx].LLeaf);
      LPage.Title := LEntries[LBestIdx].Title;
      LPage.Url := HelpChatJoinUrl(LBase, LEntries[LBestIdx].Url);
      LPage.Summary := LEntries[LBestIdx].Summary;
      LPage.Excerpt := BuildExcerpt(LEntries[LBestIdx], LTokens, LExcerptChars,
        LExcerptWindow);
      LPage.Score := LScores[LBestIdx];
      LPages.Add(LPage);
    end;
    Result := LPages.ToArray;
  finally
    LLeaves.Free;
    LPages.Free;
  end;
end;

end.
