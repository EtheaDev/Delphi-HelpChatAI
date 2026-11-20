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

unit HelpChatAI.Tests.SearchTerms;

/// <summary>
///  TranslateSearch: a question asked in the language of the chat is searched
///  in a manual written in another one with the terms the model in use wrote
///  for it, and without the hint of the screen. The settings, the retriever
///  that does it, the bodies of the three providers and the whole path through
///  the runner, with a provider and a retriever of the test.
/// </summary>

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Store,
  HelpChatAI.Runner;

type
  [TestFixture]
  TSearchTermsTests = class
  strict private
    FStore: THelpChatStore;
    FSettings: THelpChatSettings;
    FRunner: THelpChatRunner;
    FRetriever: IHelpChatRetriever;
    FContext: THelpChatContext;
    FMessage: THelpChatMessage;
    procedure StartRunner(const AChat: THelpChatLanguage);
    procedure StopRunner;
    function Ask(const AProvider, AText: string): THelpChatMessage;
    function Searches: string;
  public
    [Test] procedure TranslatesSearch_OnlyWhenTheManualIsInAnotherLanguage;
    [Test] procedure LanguageRule_TheChatDecides;
    [Test] procedure SearchTermsPrompt_SaysTheLanguageOfTheManual_AndFallsBack;
    [Test] procedure Settings_Json_AndAssign;
    [Test] procedure SearchTermsQuestion_CarriesThePreviousQuestion;
    [Test] procedure TranslatedRetriever_SearchesTheTerms_WithoutTheHint;
    [Test] procedure SearchTerms_OneLine_AFailureIsNoTerms;
    [Test] procedure SearchTerms_NotAskedWhenTheLanguagesAgree;
    [Test] procedure JsonSetNumber_CreatesThePath;
    [Test] procedure CompletionBodies_OneQuestion_NoTools_ACap;
    [Test] procedure Runner_TranslatedQuestion_FindsThePageOfTheTerms;
    [Test] procedure Runner_SameLanguage_AsksNothing_KeepsTheHint;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  HelpChatAI.Provider,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI,
  HelpChatAI.Provider.Gemini,
  HelpChatAI.Tests.Helpers;

const
  K = HELPCHAT_DEFAULT_CONVERSATION;
  TERMS_PROVIDER = 'test-terms';
  TERMS_FAILING_PROVIDER = 'test-terms-failing';

var
  // What the providers of the test were asked, from the worker thread.
  GLock: TObject;
  GAskedSystem, GAskedUser: string;
  GAskedCount: Integer;

type
  /// <summary>Writes two lines of terms, and answers with the context of the
  /// question it was built: the excerpts are what the test looks at.</summary>
  TTermsProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function CompleteText(const ASystem, AUser: string;
      const ACancel: IHelpChatCancelToken): string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  /// <summary>The same, but the request for the terms fails.</summary>
  TFailingTermsProvider = class(TTermsProvider)
  public
    function GetName: string; override;
    function CompleteText(const ASystem, AUser: string;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  /// <summary>Remembers every search and finds "Accounts" for a query that
  /// names an account, "Dashboard" for any other.</summary>
  TRecordingRetriever = class(TInterfacedObject, IHelpChatRetriever)
  public
    Searches: TStringList;
    constructor Create;
    destructor Destroy; override;
    function IsAvailable: Boolean;
    function GetBaseUrl: string;
    function Search(const AQuery, AHint: string; const AMaxPages: Integer): TArray<THelpChatDocPage>;
    function Snapshot: string;
  end;

{ TTermsProvider }

function TTermsProvider.GetName: string;
begin
  Result := TERMS_PROVIDER;
end;

function TTermsProvider.CompleteText(const ASystem, AUser: string;
  const ACancel: IHelpChatCancelToken): string;
begin
  TMonitor.Enter(GLock);
  try
    GAskedSystem := ASystem;
    GAskedUser := AUser;
    Inc(GAskedCount);
  finally
    TMonitor.Exit(GLock);
  end;
  Result := 'company account'#10'customer';
end;

function TTermsProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
begin
  Result := BuildQuestionContext(AHistory, AContext, Settings, Retriever);
end;

{ TFailingTermsProvider }

function TFailingTermsProvider.GetName: string;
begin
  Result := TERMS_FAILING_PROVIDER;
end;

function TFailingTermsProvider.CompleteText(const ASystem, AUser: string;
  const ACancel: IHelpChatCancelToken): string;
begin
  inherited;
  raise EHelpChatError.Create('the service is down');
end;

{ TRecordingRetriever }

constructor TRecordingRetriever.Create;
begin
  inherited Create;
  Searches := TStringList.Create;
end;

destructor TRecordingRetriever.Destroy;
begin
  Searches.Free;
  inherited;
end;

function TRecordingRetriever.IsAvailable: Boolean;
begin
  Result := True;
end;

function TRecordingRetriever.GetBaseUrl: string;
begin
  Result := '';
end;

function TRecordingRetriever.Search(const AQuery, AHint: string;
  const AMaxPages: Integer): TArray<THelpChatDocPage>;
begin
  TMonitor.Enter(Self);
  try
    Searches.Add(AQuery + '|' + AHint);
  finally
    TMonitor.Exit(Self);
  end;
  SetLength(Result, 1);
  if Pos('account', LowerCase(AQuery)) > 0 then
  begin
    Result[0].Title := 'Accounts';
    Result[0].Url := 'Accounts.md';
  end
  else
  begin
    Result[0].Title := 'Dashboard';
    Result[0].Url := 'Dashboard.md';
  end;
  Result[0].Summary := 'Summary of ' + Result[0].Title;
end;

function TRecordingRetriever.Snapshot: string;
begin
  TMonitor.Enter(Self);
  try
    Result := Searches.Text;
  finally
    TMonitor.Exit(Self);
  end;
end;

function History(const ATexts: array of string): TArray<THelpChatMessage>;
var
  I: Integer;
begin
  SetLength(Result, Length(ATexts));
  for I := 0 to High(ATexts) do
  begin
    Result[I].Content := ATexts[I];
    if Odd(I) then
      Result[I].Role := hcrAssistant
    else
      Result[I].Role := hcrUser;
  end;
end;

{ TSearchTermsTests }

procedure TSearchTermsTests.TranslatesSearch_OnlyWhenTheManualIsInAnotherLanguage;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    Assert.IsTrue(LSettings.TranslateSearch, 'on by default');
    // The manual's language not stated: nothing to translate into.
    Assert.IsFalse(LSettings.TranslatesSearch(hclItalian));
    LSettings.DocLanguage := hclEnglish;
    Assert.IsTrue(LSettings.TranslatesSearch(hclItalian));
    Assert.IsFalse(LSettings.TranslatesSearch(hclEnglish), 'same language');
    LSettings.TranslateSearch := False;
    Assert.IsFalse(LSettings.TranslatesSearch(hclItalian), 'turned off');
  finally
    LSettings.Free;
  end;
end;

procedure TSearchTermsTests.LanguageRule_TheChatDecides;
var
  LSettings: THelpChatSettings;
  LRule: string;
begin
  LSettings := THelpChatSettings.Create;
  try
    LRule := LSettings.ResolveLanguageRule(hclItalian);
    Assert.AreEqual('The language of this chat is Italian. Reply in Italian, even when the ' +
      'user writes in another language.', LRule);
  finally
    LSettings.Free;
  end;
end;

procedure TSearchTermsTests.SearchTermsPrompt_SaysTheLanguageOfTheManual_AndFallsBack;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.DocLanguage := hclEnglish;
    Assert.Contains(LSettings.ResolveSearchTermsPrompt, 'The manual is written in English');
    LSettings.SearchTermsPrompt := 'Terms in %0:s.';
    Assert.AreEqual('Terms in English.', LSettings.ResolveSearchTermsPrompt);
    // A text that does not fit its values: the library's.
    LSettings.SearchTermsPrompt := 'Terms in %0:s and %1:s.';
    Assert.Contains(LSettings.ResolveSearchTermsPrompt, 'The manual is written in English');
    LSettings.SearchTermsPrompt := '';
    Assert.Contains(LSettings.ResolveSearchTermsPrompt, 'The manual is written in English');
  finally
    LSettings.Free;
  end;
end;

procedure TSearchTermsTests.Settings_Json_AndAssign;
var
  LSettings, LCopy: THelpChatSettings;
  LJson: string;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LJson := LSettings.SaveToJSON;
    Assert.Contains(LJson, '"TranslateSearch"');
    Assert.DoesNotContain(LJson, 'SearchTermsPrompt', 'the default is not written');
    LSettings.TranslateSearch := False;
    LSettings.SearchTermsPrompt := 'Mine %0:s.';
    LCopy.LoadFromJSON(LSettings.SaveToJSON);
    Assert.IsFalse(LCopy.TranslateSearch);
    Assert.AreEqual('Mine %0:s.', LCopy.SearchTermsPrompt);
    LCopy.Free;
    LCopy := THelpChatSettings.Create;
    LCopy.Assign(LSettings);
    Assert.IsFalse(LCopy.TranslateSearch);
    Assert.AreEqual('Mine %0:s.', LCopy.SearchTermsPrompt);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TSearchTermsTests.SearchTermsQuestion_CarriesThePreviousQuestion;
begin
  Assert.AreEqual('inserisci una società',
    THelpChatProviderBase.SearchTermsQuestion(History(['inserisci una società'])));
  Assert.AreEqual('Previous question: inserisci una società'#10'Question: e come la cancello?',
    THelpChatProviderBase.SearchTermsQuestion(History(['inserisci una società', 'Ecco come.',
      'e come la cancello?'])));
  Assert.AreEqual('', THelpChatProviderBase.SearchTermsQuestion(nil));
  Assert.AreEqual(HELPCHAT_SEARCH_TERMS_MAX_CHARS, Length(
    THelpChatProviderBase.SearchTermsQuestion(History([StringOfChar('x', 2000)]))));
end;

procedure TSearchTermsTests.TranslatedRetriever_SearchesTheTerms_WithoutTheHint;
var
  LInner: TRecordingRetriever;
  LKeep: IHelpChatRetriever;
  LTranslated: THelpChatTranslatedRetriever;
  LRetriever: IHelpChatRetriever;
begin
  LInner := TRecordingRetriever.Create;
  LKeep := LInner;
  LTranslated := THelpChatTranslatedRetriever.Create(LInner);
  LRetriever := LTranslated;
  // No terms: as it was.
  LRetriever.Search('inserisci una società', 'Dashboard', 3);
  LTranslated.SetTerms('inserisci una società', 'company account');
  Assert.AreEqual('Accounts', LRetriever.Search('inserisci una società', 'Dashboard', 3)[0].Title);
  // Another query: untouched.
  LRetriever.Search('something else', 'Dashboard', 3);
  Assert.AreEqual(
    'inserisci una società|Dashboard'#13#10 +
    'inserisci una società company account|'#13#10 +
    'something else|Dashboard'#13#10, LInner.Snapshot);
end;

procedure TSearchTermsTests.SearchTerms_OneLine_AFailureIsNoTerms;
var
  LSettings: THelpChatSettings;
  LProvider: IHelpChatProvider;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclItalian;
    LSettings.DocLanguage := hclEnglish;
    LProvider := TTermsProvider.Create(LSettings, nil);
    Assert.AreEqual('company account customer', THelpChatProviderBase(LProvider as TObject)
      .SearchTerms(History(['inserisci una società']), nil));
    Assert.Contains(GAskedSystem, 'The manual is written in English');
    Assert.AreEqual('inserisci una società', GAskedUser);
    LProvider := TFailingTermsProvider.Create(LSettings, nil);
    Assert.AreEqual('', THelpChatProviderBase(LProvider as TObject)
      .SearchTerms(History(['inserisci una società']), nil));
  finally
    LProvider := nil;
    LSettings.Free;
  end;
end;

procedure TSearchTermsTests.SearchTerms_NotAskedWhenTheLanguagesAgree;
var
  LSettings: THelpChatSettings;
  LProvider: IHelpChatProvider;
  LBefore: Integer;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclEnglish;
    LSettings.DocLanguage := hclEnglish;
    LBefore := GAskedCount;
    LProvider := TTermsProvider.Create(LSettings, nil);
    Assert.AreEqual('', THelpChatProviderBase(LProvider as TObject)
      .SearchTerms(History(['add a company']), nil));
    Assert.AreEqual(LBefore, GAskedCount, 'the model is not asked');
  finally
    LProvider := nil;
    LSettings.Free;
  end;
end;

procedure TSearchTermsTests.JsonSetNumber_CreatesThePath;
begin
  Assert.AreEqual('{"a":1,"b":7}', HelpChatJsonSetNumber('{"a":1,"b":2}', 'b', 7));
  Assert.AreEqual('{"a":1,"g":{"m":5}}', HelpChatJsonSetNumber('{"a":1}', 'g.m', 5));
  Assert.AreEqual('not json', HelpChatJsonSetNumber('not json', 'b', 7));
end;

procedure TSearchTermsTests.CompletionBodies_OneQuestion_NoTools_ACap;

  function Parse(const AJson: string): TJSONObject;
  begin
    Result := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
    Assert.IsNotNull(Result, AJson);
  end;

var
  LSettings: THelpChatSettings;
  LBody: TJSONObject;
begin
  LSettings := THelpChatSettings.Create;
  try
    LBody := Parse(THelpChatClaudeProvider.BuildCompletionBody('sys', 'q', LSettings.Claude));
    try
      Assert.AreEqual(HELPCHAT_SEARCH_TERMS_THINKING_TOKENS, LBody.GetValue<Integer>('max_tokens'));
      Assert.AreEqual(1, LBody.GetValue<TJSONArray>('messages').Count);
      Assert.IsNull(LBody.FindValue('tools'));
      Assert.Contains(LBody.ToJSON, '"sys"');
    finally
      LBody.Free;
    end;

    // OpenAI itself: the Responses API.
    LBody := Parse(THelpChatOpenAIProvider.BuildCompletionBody('sys', 'q', LSettings.OpenAI, 'none'));
    try
      Assert.AreEqual(HELPCHAT_SEARCH_TERMS_THINKING_TOKENS, LBody.GetValue<Integer>('max_output_tokens'));
      Assert.AreEqual('sys', LBody.GetValue<string>('instructions'));
      Assert.AreEqual('none', LBody.GetValue<string>('reasoning.effort'));
      Assert.IsNull(LBody.FindValue('tools'));
    finally
      LBody.Free;
    end;

    // A local server: Chat Completions, no reasoning and a short cap, or
    // room to think when the effort is refused.
    LSettings.OpenAI.BaseUrl := 'http://localhost:11434/v1';
    LBody := Parse(THelpChatOpenAIProvider.BuildCompletionBody('sys', 'q', LSettings.OpenAI, 'none'));
    try
      Assert.AreEqual('none', LBody.GetValue<string>('reasoning_effort'));
      Assert.AreEqual(HELPCHAT_SEARCH_TERMS_MAX_TOKENS, LBody.GetValue<Integer>('max_completion_tokens'));
      Assert.AreEqual(2, LBody.GetValue<TJSONArray>('messages').Count, 'system and question');
      Assert.IsNull(LBody.FindValue('tools'));
    finally
      LBody.Free;
    end;
    LBody := Parse(THelpChatOpenAIProvider.BuildCompletionBody('sys', 'q', LSettings.OpenAI, ''));
    try
      Assert.IsNull(LBody.FindValue('reasoning_effort'));
      Assert.AreEqual(HELPCHAT_SEARCH_TERMS_THINKING_TOKENS, LBody.GetValue<Integer>('max_completion_tokens'));
    finally
      LBody.Free;
    end;

    LBody := Parse(THelpChatGeminiProvider.BuildCompletionBody('sys', 'q', LSettings.Gemini));
    try
      Assert.AreEqual(HELPCHAT_SEARCH_TERMS_THINKING_TOKENS,
        LBody.GetValue<Integer>('generationConfig.maxOutputTokens'));
      Assert.AreEqual(1, LBody.GetValue<TJSONArray>('contents').Count);
      Assert.IsNotNull(LBody.FindValue('systemInstruction'));
      Assert.IsNull(LBody.FindValue('tools'));
    finally
      LBody.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TSearchTermsTests.StartRunner(const AChat: THelpChatLanguage);
begin
  FStore := THelpChatStore.Create;
  FSettings := THelpChatSettings.Create;
  FSettings.Language := AChat;
  FSettings.DocLanguage := hclEnglish;
  FRetriever := TRecordingRetriever.Create;
  FRunner := THelpChatRunner.Create(FStore, FRetriever, 1);
  FContext := Default(THelpChatContext);
  FContext.ScreenLabel := 'Dashboard';
end;

procedure TSearchTermsTests.StopRunner;
begin
  FreeAndNil(FRunner);
  FreeAndNil(FStore);
  FreeAndNil(FSettings);
  FRetriever := nil;
end;

function TSearchTermsTests.Ask(const AProvider, AText: string): THelpChatMessage;
var
  LId: string;
begin
  FStore.AddUserMessage(K, AText);
  LId := FStore.AddPendingAssistant(K);
  FRunner.Submit(K, LId, AProvider, FContext, 0, FSettings);
  Assert.IsTrue(WaitFor(
    function: Boolean
    begin
      Result := FStore.TryGetMessage(K, LId, FMessage) and not FMessage.Pending;
    end));
  Result := FMessage;
end;

function TSearchTermsTests.Searches: string;
begin
  Result := (FRetriever as TRecordingRetriever).Snapshot;
end;

procedure TSearchTermsTests.Runner_TranslatedQuestion_FindsThePageOfTheTerms;
var
  LMessage: THelpChatMessage;
  LQuestion: string;
begin
  StartRunner(hclItalian);
  try
    LMessage := Ask(TERMS_PROVIDER, 'inserisci una società');
    Assert.IsFalse(LMessage.IsError, LMessage.Content);
    Assert.Contains(LMessage.Content, '## Accounts', 'the excerpt the terms found');
    Assert.Contains(Searches, 'inserisci una società company account customer|');
    Assert.DoesNotContain(Searches, 'inserisci una società|Dashboard',
      'the hint of the screen is dropped');
    Assert.AreEqual('company account customer', FRunner.SearchTerms(K, LQuestion));
    Assert.AreEqual('inserisci una società', LQuestion);

    // A follow-up: the translator sees the question before it.
    Ask(TERMS_PROVIDER, 'e come la cancello?');
    Assert.StartsWith('Previous question: inserisci una società', GAskedUser);

    // The translation fails: the question alone, with the hint, and a reply.
    LMessage := Ask(TERMS_FAILING_PROVIDER, 'aggiungi un utente');
    Assert.IsFalse(LMessage.IsError, LMessage.Content);
    Assert.Contains(Searches, 'aggiungi un utente|Dashboard');
    Assert.AreEqual('', FRunner.SearchTerms(K, LQuestion));
  finally
    StopRunner;
  end;
end;

procedure TSearchTermsTests.Runner_SameLanguage_AsksNothing_KeepsTheHint;
var
  LBefore: Integer;
begin
  StartRunner(hclEnglish);
  try
    LBefore := GAskedCount;
    Ask(TERMS_PROVIDER, 'add a company');
    Assert.AreEqual(LBefore, GAskedCount, 'no request for terms');
    Assert.Contains(Searches, 'add a company|Dashboard');
  finally
    StopRunner;
  end;
end;

initialization
  GLock := TObject.Create;
  THelpChatProviderRegistry.RegisterProvider(TERMS_PROVIDER, TTermsProvider);
  THelpChatProviderRegistry.RegisterProvider(TERMS_FAILING_PROVIDER, TFailingTermsProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(TERMS_PROVIDER);
  THelpChatProviderRegistry.UnregisterProvider(TERMS_FAILING_PROVIDER);
  GLock.Free;

end.
