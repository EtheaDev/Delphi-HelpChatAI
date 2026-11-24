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
unit HelpChatAI.Tests.SearchRanking;

{ The ranking options of THelpChatDocIndex (issue #10), each on the case the
  issue describes: first what the plain ranking does, then what the option
  changes. Plus the OnSearchDocs path (THelpChatSearchRetriever) and the
  Search section of the settings. }

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.DocIndex;

type
  [TestFixture]
  TSearchRankingTests = class
  strict private
    FIndex: THelpChatDocIndex;
    FRetriever: IHelpChatRetriever; // keeps FIndex alive
    FCalls: Integer;
    FSeenQuery: string;
    FSeenIndex: THelpChatDocIndex;
    procedure AddFillers;
    function FirstTitle(const AQuery, AHint: string; const ARanking: THelpChatSearchRankings): string;
    function Titles(const AQuery, AHint: string; const AMax: Integer;
      const ARanking: THelpChatSearchRankings): string;
    procedure ReverseAndAdd(Sender: TObject; const AIndex: THelpChatDocIndex;
      const AQuery, AHint: string; const AMaxPages: Integer;
      var APages: TArray<THelpChatDocPage>);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Default_IsEverythingButThePin;
    [Test] procedure Phrase_TitleCalledLikeTheQuestion_Wins;
    [Test] procedure ExactMatch_PrefersTheUnstemmedWord;
    [Test] procedure DistinctTitles_LetsTheSecondTopicIn;
    [Test] procedure DistinctTitles_FallsBackToRepeatedTitles;
    [Test] procedure NormalizeHint_LongHintDoesNotDrownTheQuestion;
    [Test] procedure PinHintPage_PutsTheScreenPageFirst;
    [Test] procedure Retriever_HandlerHasTheLastWord;
    [Test] procedure Retriever_Detached_IsTheIndexAlone;
    [Test] procedure Settings_Search_RoundTrip_AndAssign;
  end;

implementation

uses
  System.SysUtils,
  HelpChatAI.Settings,
  HelpChatAI.Engine;

const
  ALL_OFF: THelpChatSearchRankings = [];

procedure TSearchRankingTests.Setup;
begin
  FIndex := THelpChatDocIndex.Create;
  FRetriever := FIndex;
  FCalls := 0;
  FSeenQuery := '';
  FSeenIndex := nil;
end;

procedure TSearchRankingTests.TearDown;
begin
  FRetriever := nil;
  FIndex := nil;
end;

procedure TSearchRankingTests.AddFillers;
begin
  // Pages about nothing the questions ask, so that a word of two pages is
  // rare enough to matter.
  FIndex.AddPage('Getting Started', 'start.md', '', 'Install the application and log in.');
  FIndex.AddPage('Keyboard Shortcuts', 'keys.md', '', 'Every key the windows understand.');
  FIndex.AddPage('Release History', 'history.md', '', 'What changed in every version.');
end;

function TSearchRankingTests.FirstTitle(const AQuery, AHint: string;
  const ARanking: THelpChatSearchRankings): string;
var
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.Ranking := ARanking;
  LPages := FIndex.Search(AQuery, AHint, 3);
  if Length(LPages) = 0 then
    Exit('');
  Result := LPages[0].Title;
end;

function TSearchRankingTests.Titles(const AQuery, AHint: string; const AMax: Integer;
  const ARanking: THelpChatSearchRankings): string;
var
  LPage: THelpChatDocPage;
begin
  FIndex.Ranking := ARanking;
  Result := '';
  for LPage in FIndex.Search(AQuery, AHint, AMax) do
    Result := Result + LPage.Title + '|';
end;

procedure TSearchRankingTests.Default_IsEverythingButThePin;
var
  LSettings: THelpChatSettings;
begin
  Assert.IsTrue(FIndex.Ranking = HELPCHAT_DEF_SEARCH_RANKING, 'an index starts with the default');
  Assert.IsTrue(HELPCHAT_DEF_SEARCH_RANKING = [hsrPhrase, hsrExactMatch, hsrDistinctTitles,
    hsrNormalizeHint], 'pinning is opt-in');
  LSettings := THelpChatSettings.Create;
  try
    Assert.IsTrue(LSettings.SearchRanking = HELPCHAT_DEF_SEARCH_RANKING,
      'the defaults of the settings and of the index are the same');
  finally
    LSettings.Free;
  end;
end;

procedure TSearchRankingTests.Phrase_TitleCalledLikeTheQuestion_Wins;
const
  QUERY = 'How do I set the billing profile?';
begin
  AddFillers;
  FIndex.AddPage('Billing Profile', 'billing-profile.md', '', 'Settings of the account.');
  FIndex.AddPage('Billing', 'billing.md', '',
    'Billing billing billing billing billing: each profile, the profile of a ' +
    'customer, profile after profile, the last profile.');
  Assert.AreEqual('Billing', FirstTitle(QUERY, '', ALL_OFF),
    'the words apart win without the phrase - the case of the issue');
  Assert.AreEqual('Billing Profile', FirstTitle(QUERY, '', [hsrPhrase]));
end;

procedure TSearchRankingTests.ExactMatch_PrefersTheUnstemmedWord;
const
  QUERY = 'item_loading';
begin
  AddFillers;
  FIndex.AddPage('Item_Loading', 'item-loading.md', '', 'Fires while the item is prepared.');
  FIndex.AddPage('Item_Loaded', 'item-loaded.md', '',
    'Fires after the item finished loading: loading done, no loading left, ' +
    'loading over, loading complete.', 'item loading events');
  Assert.AreEqual('Item_Loaded', FirstTitle(QUERY, '', ALL_OFF),
    'the sibling page wins on the stem - the case of the issue');
  Assert.AreEqual('Item_Loading', FirstTitle(QUERY, '', [hsrExactMatch]));
end;

procedure TSearchRankingTests.DistinctTitles_LetsTheSecondTopicIn;
const
  QUERY = 'How does item_loading differ from item_loaded?';
  BODY = 'The item is loaded: item loaded, item loaded, item loaded, item loaded, item loaded.';
begin
  AddFillers;
  FIndex.AddPage('Section A > Item_Loaded', 'a/item-loaded.md', '', BODY);
  FIndex.AddPage('Section B > Item_Loaded', 'b/item-loaded.md', '', BODY);
  FIndex.AddPage('Section C > Item_Loaded', 'c/item-loaded.md', '', BODY);
  FIndex.AddPage('Item_Loading', 'item-loading.md', '', 'Before.');
  Assert.DoesNotContain(Titles(QUERY, '', 3, ALL_OFF), 'Item_Loading|',
    'one topic in three sections takes every place - the case of the issue');
  Assert.Contains(Titles(QUERY, '', 3, [hsrDistinctTitles]), 'Item_Loading|');
end;

procedure TSearchRankingTests.DistinctTitles_FallsBackToRepeatedTitles;
const
  BODY = 'The item is loaded.';
begin
  FIndex.AddPage('Section A > Item_Loaded', 'a/item-loaded.md', '', BODY);
  FIndex.AddPage('Section B > Item_Loaded', 'b/item-loaded.md', '', BODY);
  FIndex.AddPage('Keyboard Shortcuts', 'keys.md', '', 'Every key.');
  Assert.AreEqual(2, Integer(Length((function: TArray<THelpChatDocPage>
    begin
      FIndex.Ranking := [hsrDistinctTitles];
      Result := FIndex.Search('item loaded', '', 3);
    end)())), 'a repeated title still comes when nothing else scores');
end;

procedure TSearchRankingTests.NormalizeHint_LongHintDoesNotDrownTheQuestion;
const
  QUERY = 'How do I export to Excel?';
  HINT = 'Orders > Customers > Invoices > Payments';
begin
  AddFillers;
  FIndex.AddPage('Export to Excel', 'export.md', '',
    'Export export export export export the grid to Excel excel excel excel excel.');
  FIndex.AddPage('Orders and Customers', 'orders.md', '', 'The two lists.');
  Assert.AreEqual('Orders and Customers', FirstTitle(QUERY, HINT, ALL_OFF),
    'four words of breadcrumb, each weighing double, beat the question - the case of the issue');
  Assert.AreEqual('Export to Excel', FirstTitle(QUERY, HINT, [hsrNormalizeHint]));
  // A hint of one word keeps its whole weight.
  Assert.AreEqual(FirstTitle(QUERY, 'Orders', ALL_OFF), FirstTitle(QUERY, 'Orders', [hsrNormalizeHint]));
end;

procedure TSearchRankingTests.PinHintPage_PutsTheScreenPageFirst;
const
  QUERY = 'Show me an example';
  HINT = 'Sales > Customers';
begin
  AddFillers;
  FIndex.AddPage('Customers', 'customers.md', '', 'The list of the companies.');
  FIndex.AddPage('Examples', 'examples.md', '',
    'An example, another example, one more example, the example, a last example.', 'example');
  Assert.AreEqual('Examples', FirstTitle(QUERY, HINT, ALL_OFF));
  Assert.AreEqual('Customers', FirstTitle(QUERY, HINT, [hsrPinHintPage]),
    'the page whose title is the last segment of the hint comes first');
  Assert.AreEqual('Customers', FirstTitle(QUERY, 'Customers', [hsrPinHintPage]),
    'and the page whose title is the hint');
  Assert.AreEqual('Examples', FirstTitle(QUERY, 'Nothing like it', [hsrPinHintPage]),
    'no such page: the ranking as it is');
end;

procedure TSearchRankingTests.ReverseAndAdd(Sender: TObject; const AIndex: THelpChatDocIndex;
  const AQuery, AHint: string; const AMaxPages: Integer; var APages: TArray<THelpChatDocPage>);
var
  LPage: THelpChatDocPage;
  LReversed: TArray<THelpChatDocPage>;
  I: Integer;
begin
  Inc(FCalls);
  FSeenQuery := AQuery;
  FSeenIndex := AIndex;
  SetLength(LReversed, Length(APages));
  for I := 0 to High(APages) do
    LReversed[High(APages) - I] := APages[I];
  LPage := Default(THelpChatDocPage);
  LPage.Title := 'From the application';
  LPage.Excerpt := 'A page of ours.';
  APages := LReversed + [LPage];
end;

procedure TSearchRankingTests.Retriever_HandlerHasTheLastWord;
var
  LRetriever: IHelpChatRetriever;
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.AddPage('Orders', 'orders.md', '', 'Orders orders orders.');
  FIndex.AddPage('Order Lines', 'lines.md', '', 'The lines of an order.');
  LRetriever := THelpChatSearchRetriever.Create(FIndex, ReverseAndAdd, Self);
  LPages := LRetriever.Search('orders', '', 3);
  Assert.AreEqual(1, FCalls);
  Assert.AreEqual('orders', FSeenQuery);
  Assert.IsTrue(FSeenIndex = FIndex, 'the handler gets the index, to search again');
  Assert.AreEqual(3, Integer(Length(LPages)));
  Assert.AreEqual('Order Lines', LPages[0].Title, 'reordered');
  Assert.AreEqual('From the application', LPages[2].Title, 'and a page added');
end;

procedure TSearchRankingTests.Retriever_Detached_IsTheIndexAlone;
var
  LRetriever: THelpChatSearchRetriever;
  LKeep: IHelpChatRetriever;
  LPages: TArray<THelpChatDocPage>;
begin
  FIndex.AddPage('Orders', 'orders.md', '', 'Orders orders orders.');
  LRetriever := THelpChatSearchRetriever.Create(FIndex, ReverseAndAdd, Self);
  LKeep := LRetriever;
  LRetriever.Detach;
  LPages := LKeep.Search('orders', '', 3);
  Assert.AreEqual(0, FCalls);
  Assert.AreEqual(1, Integer(Length(LPages)));
  Assert.AreEqual('Orders', LPages[0].Title);
end;

procedure TSearchRankingTests.Settings_Search_RoundTrip_AndAssign;
var
  LSource, LTarget: THelpChatSettings;
  LJson: string;
begin
  LSource := THelpChatSettings.Create;
  LTarget := THelpChatSettings.Create;
  try
    LSource.SearchRanking := [hsrPinHintPage, hsrExactMatch];
    LJson := LSource.SaveToJSON;
    Assert.Contains(LJson, '"exactMatch"', 'names, not numbers');
    LTarget.LoadFromJSON(LJson);
    Assert.IsTrue(LTarget.SearchRanking = [hsrPinHintPage, hsrExactMatch]);
    LTarget.LoadFromJSON('{"SearchRanking": "phrase, hsrDistinctTitles, nonsense"}');
    Assert.IsTrue(LTarget.SearchRanking = [hsrPhrase, hsrDistinctTitles],
      'a string with commas, identifiers too, unknown names skipped; the whole set');
    LTarget.LoadFromJSON('{"SearchRanking": []}');
    Assert.IsTrue(LTarget.SearchRanking = [], 'empty: the ranking of 2.2');
    LTarget.LoadFromJSON('{"Language": "it"}');
    Assert.IsTrue(LTarget.SearchRanking = [], 'a file that does not name it leaves it');
    LSource.SetSearchHandler(ReverseAndAdd, Self);
    LTarget.Assign(LSource);
    Assert.IsTrue(LTarget.SearchRanking = [hsrPinHintPage, hsrExactMatch]);
    Assert.IsTrue(Assigned(LTarget.OnSearchDocs), 'a snapshot keeps the handler');
    Assert.IsTrue(LTarget.SearchSender = Self);
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSearchRankingTests);

end.
