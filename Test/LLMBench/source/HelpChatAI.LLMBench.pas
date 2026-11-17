{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Comparative benchmark of the providers on the same questions:          }
{       the engine of the library, grounded on the manual of the CRM demo,     }
{       with two actions registered, one model after the other.                }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
unit HelpChatAI.LLMBench;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Engine,
  HelpChatAI.Actions,
  HelpChatAI.Provider;

type
  /// <summary>One provider + model to measure. Local models are listed first,
  /// so that Ollama loads each one once and never swaps back and forth.</summary>
  TBenchTarget = record
    Name: string;       // what the report calls it
    Provider: string;   // registered provider name
    Model: string;      // empty = the default of the provider
    BaseUrl: string;    // empty = the default of the provider
    ResponseTimeoutMs: Integer;
    /// <summary>The assistant the target runs as, in the expertise suite:
    /// 0 = the library as it is (the classic suite), 1 = named, no
    /// Expertise, 2 = named, with the Expertise of the CRM demo. (The first
    /// run of the suite, results/llm-bench-expertise-v1.md, measured three
    /// prompts written by hand; the library now composes the third.)</summary>
    Variant: Integer;
  end;

  /// <summary>One question with what a correct answer must contain.</summary>
  TBenchQuestion = record
    Id: string;
    Text: string;
    ScreenLabel: string;           // the screen the user is on (search hint)
    ExpectedPages: TArray<string>; // any of these cited = correct citation
    Facts: TArray<string>;         // substrings (case-insensitive) a correct answer contains
    ExpectedAction: string;        // '' = no action must be called
    ExpectedArg: string;           // substring the action arguments must contain
    AnyCitation: Boolean;          // citing a page or none are both fine
    Rubric: string;                // expertise suite: what the judge looks for
  end;

  TBenchActionCall = record
    Name: string;
    ArgsJson: string;
    Outcome: THelpChatActionOutcome;
    ResultText: string;
  end;

  TBenchResult = record
    Target: string;
    Question: string;
    ElapsedMs: Int64;
    FirstTokenMs: Int64;
    Answer: string;
    IsError: Boolean;
    CitedPages: TArray<string>;
    CitationOk: Boolean;
    FactsFound: Integer;
    FactsTotal: Integer;
    Actions: TArray<TBenchActionCall>;
    ActionOk: Boolean;
    WrongActions: Integer;
    // Expertise suite: the verdict of the judge.
    Judged: Boolean;
    Useful: Integer;       // 0 wrong or no answer, 1 partial, 2 what an expert would say
    Invented: Boolean;     // claims something of the application the manual does not have
    JudgeNote: string;
    // The tokens of the requests of this question, as the service counted
    // them (HelpChatOnTokenUsage: claude, openai, gemini).
    Requests: Integer;
    InputTokens: Integer;
    CacheWriteTokens: Integer;
    CacheReadTokens: Integer;
    OutputTokens: Integer;
  end;

  TBenchRunner = class
  strict private
    FRepoRoot: string;
    FOllamaBaseUrl: string;
    FNoCache: Boolean;
    FKeepConversation: Boolean;
    FUsageLock: TObject;
    FUsage: TBenchResult;     // the token counts of the question being asked
    FTargets: TList<TBenchTarget>;
    FQuestions: TList<TBenchQuestion>;
    FResults: TList<TBenchResult>;
    FCalls: TList<TBenchActionCall>;
    FFirstTokenTicks: Int64;
    FStartTicks: Int64;
    // The manual of the CRM demo, every page, for the judge.
    FManual: string;
    procedure AddUsage(const AUsage: THelpChatTokenUsage);
    /// <summary>The table of the tokens per target, for the providers that
    /// report them.</summary>
    procedure AppendTokens(const ASb: TStringBuilder);
    /// <summary>What each question read from the cache, out of its whole
    /// input, per target.</summary>
    procedure AppendTokensPerQuestion(const ASb: TStringBuilder);
    function MakeSettings(const ATarget: TBenchTarget): THelpChatSettings;
    function MakeBroker: THelpChatActionBroker;
    procedure RecordCall(const AName, AArgsJson: string);
    procedure OnMessageChanged(Sender: TObject; const AMessageId: string);
    procedure OnActionExecuted(Sender: TObject; const AName: string;
      const AOutcome: THelpChatActionOutcome; const AResult: string);
    procedure OnActionConfirm(Sender: TObject; const AName: string;
      const AArgs: THelpChatActionArgs; var AAllow: Boolean);
    function Ask(const AEngine: THelpChatEngine; const ABroker: THelpChatActionBroker;
      const AQuestion: TBenchQuestion; const ATimeoutMs: Integer): TBenchResult;
    procedure Score(const AQuestion: TBenchQuestion; var AResult: TBenchResult);
    procedure Log(const AText: string);
    function JudgeOne(const AEngine: THelpChatEngine; const AQuestion: TBenchQuestion;
      var AResult: TBenchResult): Boolean;
    function FindQuestion(const AId: string; out AQuestion: TBenchQuestion): Boolean;
    function ReportExpertise: string;
  public
    constructor Create(const ARepoRoot: string);
    destructor Destroy; override;
    procedure AddDefaultTargets;
    procedure AddDefaultQuestions;
    /// <summary>The expertise suite: questions an expert of the field of the
    /// CRM demo answers and its manual does not - concepts it takes for
    /// granted, an expert reading of a procedure, traps where expertise
    /// tempts a model to invent, and questions that need the date and time.</summary>
    procedure AddExpertiseQuestions;
    /// <summary>Every target twice, without and with Expertise (see
    /// TBenchTarget.Variant): "claude/v1", "claude/v2".</summary>
    procedure ExpandVariants;
    /// <summary>Asks AJudgeModel (a Claude model) to grade every answer of
    /// the expertise suite against the rubric of its question.</summary>
    procedure Judge(const AJudgeModel: string);
    /// <summary>Reads the targets and the answers back from a report of the
    /// expertise suite, so that they can be graded again without asking the
    /// models a second time.</summary>
    procedure LoadAnswers(const AReportFile: string);
    /// <summary>Keeps only the targets whose name contains one of AFilters.</summary>
    procedure FilterTargets(const AFilters: TArray<string>);
    /// <summary>--terms: the request of TranslateSearch, through the
    /// providers of the library, for the Italian questions of AQuestionsFile
    /// (embeddings\questions.json), the chat in Italian and the manual in
    /// English: what each target writes, and how long it takes. A check of
    /// the provider code against the real services, printed, no
    /// report.</summary>
    procedure RunSearchTerms(const AQuestionsFile: string);
    procedure Run;
    function Report: string;
    property Results: TList<TBenchResult> read FResults;
    property Targets: TList<TBenchTarget> read FTargets;
    property Questions: TList<TBenchQuestion> read FQuestions;
    /// <summary>The Ollama the local targets are asked on, set before
    /// AddDefaultTargets: http://localhost:11434/v1 by default, the server
    /// that runs the models otherwise (--ollama=).</summary>
    property OllamaBaseUrl: string read FOllamaBaseUrl write FOllamaBaseUrl;
    /// <summary>Claude.PromptCaching off (--nocache): the same run without the
    /// prompt cache, to compare the token counts with.</summary>
    property NoCache: Boolean read FNoCache write FNoCache;
    /// <summary>The conversation suite (--suite=conversation): the questions of
    /// a target asked one after the other in one conversation, the history
    /// never cleared - what a user does, and what the prompt cache reads
    /// back from the second question on.</summary>
    property KeepConversation: Boolean read FKeepConversation write FKeepConversation;
  end;

/// <summary>Walks up from the executable to the folder holding "CRM Demo".</summary>
function FindRepoRoot: string;

/// <summary>
///  Retrieval only, no model: runs the real <c>THelpChatDocIndex.Search</c> of
///  AIndexFile for every question of AQuestionsFile (the questions.json of
///  Test\LLMBench\embeddings) and writes the ranked pages to AOutFile as JSON.
///  Each question is searched twice: with its screen as hint, exactly as
///  BuildSystemPrompt does, and without. It is the lexical baseline the
///  embedding measurement is compared with - measured on the Delphi code, not
///  on a port of it. A question that carries "translations" ({translator:
///  English search terms}, written by embeddings\translate_queries.py) is
///  searched again for each: the question plus the terms, with and without
///  the hint ("translated": {translator: {ranking, rankingNoHint}}).
/// </summary>
procedure RunRetrieval(const AIndexFile, AQuestionsFile, AOutFile: string);

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.SyncObjs,
  System.Diagnostics,
  System.RegularExpressions,
  System.JSON,
  System.DateUtils,
  System.TimeSpan,
  HelpChatAI.DocIndex,
  HelpChatAI.Messages,
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI,
  HelpChatAI.Provider.Gemini;

const
  OLLAMA_BASEURL = 'http://localhost:11434/v1';
  OLLAMA_TIMEOUT_MS = 300000;   // a cold load of a 30B model plus the answer
  CLOUD_TIMEOUT_MS = 120000;
  WARMUP_QUESTION = 'Hello';

function FindRepoRoot: string;
var
  LDir: string;
  I: Integer;
begin
  LDir := TPath.GetDirectoryName(ParamStr(0));
  for I := 1 to 8 do
  begin
    if TFile.Exists(TPath.Combine(LDir, 'CRM Demo\Help\help-index.json')) then
      Exit(LDir);
    LDir := TPath.GetDirectoryName(LDir);
    if LDir = '' then
      Break;
  end;
  raise Exception.Create('Cannot locate the repository root (CRM Demo\Help\help-index.json)');
end;

procedure RunRetrieval(const AIndexFile, AQuestionsFile, AOutFile: string);
const
  // Every page that scores at all: the ranking, not only the prompt's top 3.
  ALL_PAGES = 1000;

  function Ranking(const AIndex: THelpChatDocIndex; const AQuery, AHint: string;
    out AMs: Double): TJSONArray;
  var
    LPages: TArray<THelpChatDocPage>;
    LPage: THelpChatDocPage;
    LWatch: TStopwatch;
  begin
    LWatch := TStopwatch.StartNew;
    LPages := AIndex.Search(AQuery, AHint, ALL_PAGES);
    AMs := LWatch.Elapsed.TotalMilliseconds;
    Result := TJSONArray.Create;
    for LPage in LPages do
      Result.Add(TJSONObject.Create
        .AddPair('page', LPage.Url)
        .AddPair('score', TJSONNumber.Create(LPage.Score)));
  end;

var
  LIndex: THelpChatDocIndex;
  LKeep: IHelpChatRetriever;
  LInput, LOut, LItem: TJSONObject;
  LQuestions: TJSONArray;
  LResults: TJSONArray;
  LValue: TJSONValue;
  LText, LScreen: string;
  LMsHint, LMsNone: Double;
  LTranslations, LTranslated: TJSONObject;
  LPair: TJSONPair;
begin
  LIndex := THelpChatDocIndex.Create;
  LKeep := LIndex; // reference counted: the interface frees it
  if not LIndex.LoadFromFile(AIndexFile) then
    raise Exception.Create(LIndex.LastError);
  LInput := TJSONObject.ParseJSONValue(TFile.ReadAllText(AQuestionsFile, TEncoding.UTF8)) as TJSONObject;
  if LInput = nil then
    raise Exception.CreateFmt('Not a JSON object: %s', [AQuestionsFile]);
  LOut := TJSONObject.Create;
  try
    LQuestions := LInput.GetValue<TJSONArray>('questions');
    LResults := TJSONArray.Create;
    LOut.AddPair('index', AIndexFile);
    LOut.AddPair('pages', TJSONNumber.Create(LIndex.Count));
    LOut.AddPair('results', LResults);
    for LValue in LQuestions do
    begin
      LText := LValue.GetValue<string>('text');
      LScreen := LValue.GetValue<string>('screen', '');
      LItem := TJSONObject.Create;
      LItem.AddPair('id', LValue.GetValue<string>('id'));
      LItem.AddPair('hint', LScreen);
      LItem.AddPair('ranking', Ranking(LIndex, LText, LScreen, LMsHint));
      LItem.AddPair('rankingNoHint', Ranking(LIndex, LText, '', LMsNone));
      LItem.AddPair('ms', TJSONNumber.Create(LMsHint));
      // The proposal: the question plus the English terms a model wrote for it.
      LTranslations := LValue.FindValue('translations') as TJSONObject;
      if LTranslations <> nil then
      begin
        LTranslated := TJSONObject.Create;
        for LPair in LTranslations do
          LTranslated.AddPair(LPair.JsonString.Value, TJSONObject.Create
            .AddPair('ranking', Ranking(LIndex, LText + ' ' + LPair.JsonValue.Value, LScreen, LMsHint))
            .AddPair('rankingNoHint', Ranking(LIndex, LText + ' ' + LPair.JsonValue.Value, '', LMsNone)));
        LItem.AddPair('translated', LTranslated);
      end;
      LResults.Add(LItem);
    end;
    TFile.WriteAllText(AOutFile, LOut.Format(2), TEncoding.UTF8);
    Writeln(Format('%d questions over %d pages -> %s', [LResults.Count, LIndex.Count, AOutFile]));
  finally
    LOut.Free;
    LInput.Free;
  end;
end;

const
  /// <summary>Who the assistant of the CRM demo is in variants 2 and 3.</summary>
  EXPERT_NAME = 'Giulio';
  EXPERT_FIELD = 'B2B sales and customer relationship management: leads and the ' +
    'sales pipeline, accounts, proposals and invoicing, follow-up, sales reporting';

  JUDGE_PROMPT =
    'You grade the answers of the in-app help assistant of a CRM application. You get the ' +
    'whole manual of the application (below), then in each message the question of the ' +
    'user, a rubric written by the developers, and the answer. The manual is the complete truth about the application: what ' +
    'it does not describe does not exist. Grade two things. "useful": 2 when the answer ' +
    'gives what a competent expert of the field would, correct and to the point; 1 when it is ' +
    'partial, vague or only says it does not know where it could have helped; 0 when it is ' +
    'wrong, harmful or off-topic. "invented": true only when the answer claims a screen, field, ' +
    'button, report, setting, automatic feature or behaviour of the application that the manual ' +
    'contradicts or does not contain; something left out is not an invention, and general ' +
    'knowledge of the field presented as such is not one either. Reply with one line of JSON ' +
    'and nothing else: ' +
    '{"useful": 0, "invented": false, "note": "one short sentence"}';

/// <summary>True when AText contains one of the alternatives of AFact,
/// separated by "|", ignoring case.</summary>
function MatchesAny(const AText, AFact: string): Boolean;
var
  S: string;
begin
  for S in AFact.Split(['|']) do
    if (S <> '') and ContainsText(AText, S) then
      Exit(True);
  Result := False;
end;

{ TBenchRunner }

constructor TBenchRunner.Create(const ARepoRoot: string);
begin
  inherited Create;
  FRepoRoot := ARepoRoot;
  FOllamaBaseUrl := OLLAMA_BASEURL;
  FUsageLock := TObject.Create;
  FTargets := TList<TBenchTarget>.Create;
  FQuestions := TList<TBenchQuestion>.Create;
  FResults := TList<TBenchResult>.Create;
  FCalls := TList<TBenchActionCall>.Create;
end;

destructor TBenchRunner.Destroy;
begin
  FUsageLock.Free;
  FCalls.Free;
  FResults.Free;
  FQuestions.Free;
  FTargets.Free;
  inherited;
end;

procedure TBenchRunner.AddUsage(const AUsage: THelpChatTokenUsage);
begin
  // Worker thread: one call per request of the reply.
  TMonitor.Enter(FUsageLock);
  try
    Inc(FUsage.Requests);
    Inc(FUsage.InputTokens, AUsage.InputTokens);
    Inc(FUsage.CacheWriteTokens, AUsage.CacheWriteTokens);
    Inc(FUsage.CacheReadTokens, AUsage.CacheReadTokens);
    Inc(FUsage.OutputTokens, AUsage.OutputTokens);
  finally
    TMonitor.Exit(FUsageLock);
  end;
end;

procedure TBenchRunner.Log(const AText: string);
begin
  Writeln(FormatDateTime('hh:nn:ss', Now), '  ', AText);
end;

procedure TBenchRunner.AddDefaultTargets;

  procedure AddTarget(const AName, AProvider, AModel, ABaseUrl: string; const ATimeout: Integer);
  var
    T: TBenchTarget;
  begin
    // Every field: Variant above all, which decides the prompt and the report.
    T := Default(TBenchTarget);
    T.Name := AName;
    T.Provider := AProvider;
    T.Model := AModel;
    T.BaseUrl := ABaseUrl;
    T.ResponseTimeoutMs := ATimeout;
    FTargets.Add(T);
  end;

begin
  // Local models first, one after the other: Ollama keeps one in VRAM.
  AddTarget('gemma4:12b', 'openai', 'gemma4:12b', FOllamaBaseUrl, OLLAMA_TIMEOUT_MS);
  AddTarget('gpt-oss:20b', 'openai', 'gpt-oss:20b', FOllamaBaseUrl, OLLAMA_TIMEOUT_MS);
  AddTarget('qwen3-coder:30b', 'openai', 'qwen3-coder:30b', FOllamaBaseUrl, OLLAMA_TIMEOUT_MS);
  // The references: the two remote providers as configured on this machine.
  AddTarget('claude', 'claude', '', '', CLOUD_TIMEOUT_MS);
  // The current Claude generation, against the library default above.
  AddTarget('claude-haiku-5-5', 'claude', 'claude-haiku-5-5', '', CLOUD_TIMEOUT_MS);
  AddTarget('claude-sonnet-5-5', 'claude', 'claude-sonnet-5-5', '', CLOUD_TIMEOUT_MS);
  AddTarget('claude-opus-5-5', 'claude', 'claude-opus-5-5', '', CLOUD_TIMEOUT_MS);
  AddTarget('gemini', 'gemini', '', '', CLOUD_TIMEOUT_MS);
  // Other Gemini models, against the library default above.
  AddTarget('gemini-4-argon', 'gemini', 'gemini-4-argon', '', CLOUD_TIMEOUT_MS);
  AddTarget('gemini-4-carbon', 'gemini', 'gemini-4-carbon', '', CLOUD_TIMEOUT_MS);
  AddTarget('gemini-pro-latest', 'gemini', 'gemini-pro-latest', '', CLOUD_TIMEOUT_MS);
  AddTarget('gemini-3.5-flash-lite', 'gemini', 'gemini-3.5-flash-lite', '', CLOUD_TIMEOUT_MS);
  // OpenAI itself, through the Responses API: the default model and the
  // larger one.
  AddTarget('gpt-6-luna', 'openai', 'gpt-6-luna', '', CLOUD_TIMEOUT_MS);
  AddTarget('gpt-6.1-sol', 'openai', 'gpt-6.1-sol', '', CLOUD_TIMEOUT_MS);
end;

procedure TBenchRunner.AddDefaultQuestions;

  procedure AddQ(const AId, AText, AScreen: string; const APages, AFacts: TArray<string>;
    const AAction: string = ''; const AArg: string = '');
  var
    Q: TBenchQuestion;
  begin
    Q.Id := AId;
    Q.Text := AText;
    Q.ScreenLabel := AScreen;
    Q.ExpectedPages := APages;
    Q.Facts := AFacts;
    Q.ExpectedAction := AAction;
    Q.ExpectedArg := AArg;
    FQuestions.Add(Q);
  end;

begin
  // Grounded questions: the answer is in one page of the manual.
  AddQ('Q1', 'How do I move a lead from one column of the board to another, and what happens to its dates?',
    'Leads', ['Leads.md'], ['drag', 'status', 'date']);
  AddQ('Q2', 'Where is my data stored, and how do I start over with the sample data?',
    'Dashboard', ['FAQ.md', 'Getting-Started.md'], ['w10crmdemo.sdb', 'Documents', 'delete']);
  AddQ('Q3', 'Can I change a proposal after I saved it?',
    'Sales', ['FAQ.md', 'Draft-Proposal.md', 'Sales.md'], ['No', 'delete']);
  AddQ('Q4', 'Which export gives me a file I can open in Excel?',
    'Accounts', ['FAQ.md', 'Marketing.md', 'Accounts.md'], ['Marketing']);
  AddQ('Q5', 'How do I find a lead when I only know its e-mail address?',
    'Leads', ['Leads.md'], ['Search', 'mail']);
  // Not in the manual: a correct answer cites no page and calls no action.
  AddQ('Q6', 'What is the weather in Milan today?',
    'Dashboard', [], []);
  // Actions: one without confirmation, one with.
  AddQ('Q7', 'Open the Accounts screen for me.',
    'Dashboard', [], [], 'open_screen', 'Accounts');
  AddQ('Q8', 'Create a lead named Mario Rossi for the company Apollo Orange, LLC., ' +
    'e-mail mario.rossi@example.com.',
    'Leads', [], [], 'create_lead', 'Mario Rossi');
end;

procedure TBenchRunner.AddExpertiseQuestions;

  procedure AddE(const AId, AText, AScreen: string; const AFacts: TArray<string>;
    const ARubric: string; const AAnyCitation: Boolean = True);
  var
    Q: TBenchQuestion;
  begin
    Q := Default(TBenchQuestion);
    Q.Id := AId;
    Q.Text := AText;
    Q.ScreenLabel := AScreen;
    Q.Facts := AFacts;
    Q.AnyCitation := AAnyCitation;
    Q.Rubric := ARubric;
    FQuestions.Add(Q);
  end;

var
  LDue, LNewYork: TDateTime;
begin
  // A: concepts the manual takes for granted.
  AddE('A1', 'Should I add VAT to a proposal? The prices of my line items are net.', 'Sales',
    ['VAT|tax'],
    'Explains net and gross and that VAT is computed on the net amount at the rate of the ' +
    'country (general practice). Says the draft has no VAT or tax field: the total is the sum of ' +
    'quantity x price, so VAT can only go in as a line item of its own or inside the prices.');
  AddE('A2', 'How do I calculate the value of my sales pipeline?', 'Dashboard',
    ['probabil|weight'],
    'Explains the (weighted) pipeline value: the open deals times the probability of their ' +
    'stage. In the application the amounts are the Value of the proposals still New on the Sales ' +
    'page, the stages are the columns of the board; there is no pipeline report or probability.');
  AddE('A3', 'How long should a lead stay in Active before I consider it lost?', 'Leads',
    ['depend|cycle'],
    'Says there is no universal rule and it depends on the sales cycle, with typical guidance ' +
    '(a number of unanswered follow-ups, a period). In the application Date Contacted tells how ' +
    'long it has been Active, and the lead is closed by dragging it to Closed (or set Inactive); ' +
    'nothing marks a lead lost automatically and there is no Lost status.');
  // B: an expert reading of a procedure.
  AddE('B1', 'I want to do the month-end review of my sales: where do I look?', 'Sales',
    ['Sales', 'Dashboard'],
    'Reads month-end review as: proposals sent, won and lost in the month and how the pipeline ' +
    'moved. Points to the Sales page (Status, Value, DateCreated, DateCompleted) and the Dashboard ' +
    '(leads per status), and says there is no monthly report or date filter.');
  AddE('B2', 'A customer asks for a 10% discount on the proposal. How do I do it?', 'Sales',
    ['10'],
    'Says there is no discount field: lower the prices of the line items, or add a line for the ' +
    'discount, and the total recomputes. Warns that a saved proposal cannot be edited, so the ' +
    'discount goes in before saving.');
  AddE('B3', 'A lead has not answered my proposal for two weeks. What should I do?', 'Leads',
    ['follow'],
    'Good follow-up practice (call or write, ask about the decision, agree a next step, close ' +
    'or park after repeated silence). In the application: Date Drafted says when the proposal ' +
    'went out, Notes in the lead detail record the follow-ups, Inactive parks the lead; the Call ' +
    'and Email buttons do nothing and there are no reminders or tasks.');
  // C: traps - the expertise must not make the model invent.
  AddE('C1', 'How do I set up an automatic reminder for the leads I have not contacted for 30 days?',
    'Leads', ['not|no '],
    'Says the application has no reminders or automation; the closest thing is checking the ' +
    'Active column and its Date Contacted by hand. Any reminder setup described is an invention.');
  AddE('C2', 'Can you make me a sales forecast by quarter?', 'Sales',
    ['forecast'],
    'Explains briefly what a forecast is and that the application does not produce one; the ' +
    'Sales page has the values and dates of the proposals as raw material. Numbers presented as ' +
    'the data of the user are inventions.');
  AddE('C3', 'How do I calculate the payroll of my sales representative?', 'Users',
    [],
    'Outside the field of the assistant and of the application: declines in a sentence or two. ' +
    'Explaining how to compute payroll is a failure; so is claiming payroll or commissions in ' +
    'the application.', False);
  // D: they need today and now.
  LDue := Date + 30;
  AddE('D1', 'This proposal must be valid for 30 days from today. Until what date is it valid?',
    'Sales', [FormatDateTime('d mmmm', LDue, TFormatSettings.Invariant) + '|' +
      FormatDateTime('mmmm d', LDue, TFormatSettings.Invariant)],
    Format('The correct date is %s (today plus 30 days). The draft has no validity field; the ' +
      'date can only be written in a line item title (20 characters) or agreed outside.',
      [FormatDateTime('dddd d mmmm yyyy', LDue, TFormatSettings.Invariant)]));
  // New York in November is UTC-5.
  LNewYork := TTimeZone.Local.ToUniversalTime(Now) - 5 / 24;
  AddE('D2', 'Is it too late right now to call a customer in New York?', 'Lead Detail',
    [],
    Format('It is about %s in New York (UTC-5 in November; the answer may be up to an hour earlier, it was asked before this grading). A good answer works that out from the ' +
      'current time and judges it against business hours; without the current time the best it ' +
      'can do is say it does not know the time and give the offset (useful 1). The Call button ' +
      'of the lead does nothing.', [FormatDateTime('hh:nn', LNewYork)]));
  AddE('D3', 'Which leads did I create this month?', 'Leads',
    [FormatDateTime('mmmm', Date, TFormatSettings.Invariant)],
    Format('Knows that this month is %s. In the application only the New column shows Date ' +
      'Created (the other columns show the date of their stage) and the lead detail shows it for ' +
      'one lead; the search does not filter by date and there is no report.',
      [FormatDateTime('mmmm yyyy', Date, TFormatSettings.Invariant)]));
end;

procedure TBenchRunner.ExpandVariants;
var
  LBase: TArray<TBenchTarget>;
  T: TBenchTarget;
  V: Integer;
begin
  LBase := FTargets.ToArray;
  FTargets.Clear;
  for T in LBase do
    for V := 1 to 2 do
    begin
      FTargets.Add(T);
      FTargets.List[FTargets.Count - 1].Name := T.Name + '/v' + IntToStr(V);
      FTargets.List[FTargets.Count - 1].Variant := V;
    end;
end;

function TBenchRunner.FindQuestion(const AId: string; out AQuestion: TBenchQuestion): Boolean;
var
  Q: TBenchQuestion;
begin
  for Q in FQuestions do
    if Q.Id = AId then
    begin
      AQuestion := Q;
      Exit(True);
    end;
  Result := False;
end;

function TBenchRunner.JudgeOne(const AEngine: THelpChatEngine; const AQuestion: TBenchQuestion;
  var AResult: TBenchResult): Boolean;
var
  LAsk: TBenchQuestion;
  LReply: TBenchResult;
  LJson: string;
  LValue: TJSONValue;
  I, J: Integer;
begin
  Result := False;
  LAsk := Default(TBenchQuestion);
  LAsk.Id := 'judge';
  LAsk.ScreenLabel := '';
  LAsk.Text := 'QUESTION OF THE USER:'#10 + AQuestion.Text + #10#10 +
    'RUBRIC:'#10 + AQuestion.Rubric + #10#10 +
    'ANSWER TO GRADE:'#10 + AResult.Answer;
  LReply := Ask(AEngine, nil, LAsk, CLOUD_TIMEOUT_MS);
  if LReply.IsError then
  begin
    AResult.JudgeNote := 'judge error: ' + LReply.Answer;
    Exit;
  end;
  I := Pos('{', LReply.Answer);
  J := LReply.Answer.LastIndexOf('}') + 1;
  if (I = 0) or (J < I) then
  begin
    AResult.JudgeNote := 'judge said: ' + LReply.Answer;
    Exit;
  end;
  LJson := Copy(LReply.Answer, I, J - I + 1);
  LValue := TJSONObject.ParseJSONValue(LJson);
  try
    if not (LValue is TJSONObject) then
    begin
      AResult.JudgeNote := 'judge said: ' + LReply.Answer;
      Exit;
    end;
    AResult.Useful := TJSONObject(LValue).GetValue<Integer>('useful', 0);
    AResult.Invented := TJSONObject(LValue).GetValue<Boolean>('invented', False);
    AResult.JudgeNote := TJSONObject(LValue).GetValue<string>('note', '');
    AResult.Judged := True;
    Result := True;
  finally
    LValue.Free;
  end;
end;

procedure TBenchRunner.Judge(const AJudgeModel: string);
var
  LTarget: TBenchTarget;
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  Q: TBenchQuestion;
  R: TBenchResult;
  I: Integer;
  LFile: string;
begin
  // Every page of the manual, images left out.
  FManual := '';
  for LFile in TDirectory.GetFiles(TPath.Combine(FRepoRoot, 'CRM Demo\Help'), '*.md') do
    FManual := FManual + '=== ' + TPath.GetFileName(LFile) + #10 +
      TRegEx.Replace(TFile.ReadAllText(LFile, TEncoding.UTF8), '!\[[^\]]*\]\([^)]*\)', '') + #10;
  LTarget := Default(TBenchTarget);
  LTarget.Name := 'judge';
  LTarget.Provider := 'claude';
  LTarget.Model := AJudgeModel;
  LTarget.ResponseTimeoutMs := CLOUD_TIMEOUT_MS;
  LSettings := MakeSettings(LTarget);
  // The judge reads no manual: the facts are in the question.
  LSettings.ActiveModel.GroundingMaxPages := 0;
  // The manual in the system prompt: a user message is cut at MessageMaxLength,
  // and the first run of this judge graded a manual cut in half and nothing else.
  LSettings.SystemPrompt := JUDGE_PROMPT + #10#10'MANUAL OF THE APPLICATION:'#10 + FManual;
  LSettings.MessageMaxLength := 100000;
  LEngine := THelpChatEngine.Create(LSettings, True);
  try
    LEngine.Start;
    Log('=== judge: ' + LSettings.ActiveModel.ResolveModel);
    for I := 0 to FResults.Count - 1 do
    begin
      R := FResults[I];
      if R.IsError or not FindQuestion(R.Question, Q) or (Q.Rubric = '') then
        Continue;
      JudgeOne(LEngine, Q, R);
      FResults[I] := R;
      Log(Format('  %s %s: useful=%d invented=%s  %s',
        [R.Target, R.Question, R.Useful, BoolToStr(R.Invented, True), R.JudgeNote]));
    end;
  finally
    LEngine.Stop;
    LEngine.Free;
  end;
end;

function TBenchRunner.ReportExpertise: string;
var
  LSb: TStringBuilder;
  T: TBenchTarget;
  Q: TBenchQuestion;
  R: TBenchResult;
  V, LN, LUseful, LInvented, LPass, LErr: Integer;
  LSum: Int64;
  LNames: TList<string>;
  LBase, LAnswer: string;

  function Secs(const AMs: Int64): string;
  begin
    Result := Format('%.1f s', [AMs / 1000], TFormatSettings.Invariant);
  end;

  function Passed(const AResult: TBenchResult): Boolean;
  begin
    Result := AResult.Judged and (AResult.Useful = 2) and not AResult.Invented;
  end;

begin
  LSb := TStringBuilder.Create;
  LNames := TList<string>.Create;
  try
    LSb.AppendLine('# HelpChatAI expertise benchmark');
    LSb.AppendLine;
    LSb.AppendFormat('Run on %s. Grounding: `CRM Demo\Help\help-index.json`, %d pages; no actions; ' +
      'a new conversation per question; language English. The assistant is called Giulio and the ' +
      'prompt opens with its name and now (date, time, time zone); **v1** without `Expertise`, ' +
      '**v2** with `Expertise` = "%s", which the library composes with the rule that the expertise ' +
      'explains concepts while the procedures of the application come only from the manual. Every answer ' +
      'graded by a judge model against the rubric of its question and the whole manual: ' +
      '*useful* 0-2, *invented* when it claims something of the application the manual does not have. ' +
      '*Pass* = useful 2 and nothing invented.',
      [FormatDateTime('yyyy-mm-dd hh:nn', Now), HELPCHAT_MODEL_DEF_GROUNDING, EXPERT_FIELD]);
    LSb.AppendLine.AppendLine;

    LSb.AppendLine('## Summary');
    LSb.AppendLine;
    LSb.AppendLine('| Target | Questions | Errors | Avg time | Avg useful | Invented | Pass |');
    LSb.AppendLine('|---|---:|---:|---:|---:|---:|---:|');
    for T in FTargets do
    begin
      LN := 0; LUseful := 0; LInvented := 0; LPass := 0; LErr := 0; LSum := 0;
      for R in FResults do
        if (R.Target = T.Name) and (R.Question <> 'warm-up') and (R.Question <> '-') then
        begin
          Inc(LN);
          LSum := LSum + R.ElapsedMs;
          if R.IsError then
            Inc(LErr);
          LUseful := LUseful + R.Useful;
          if R.Invented then
            Inc(LInvented);
          if Passed(R) then
            Inc(LPass);
        end;
      if LN = 0 then
        LSb.AppendFormat('| %s | 0 | skipped | - | - | - | - |', [T.Name])
      else
        LSb.AppendFormat('| %s | %d | %d | %s | %s | %d | **%d/%d** |', [T.Name, LN, LErr,
          Secs(LSum div LN), Format('%.2f', [LUseful / LN], TFormatSettings.Invariant),
          LInvented, LPass, LN]);
      LSb.AppendLine;
    end;
    LSb.AppendLine;

    // Per question and variant, how many models passed.
    for T in FTargets do
    begin
      LBase := T.Name.Substring(0, T.Name.LastIndexOf('/'));
      if not LNames.Contains(LBase) then
        LNames.Add(LBase);
    end;
    LSb.AppendLine('## Passed, per question');
    LSb.AppendLine;
    LSb.AppendFormat('Models that passed, out of %d.', [LNames.Count]);
    LSb.AppendLine.AppendLine;
    LSb.AppendLine('| Question | v1 | v2 |');
    LSb.AppendLine('|---|---:|---:|');
    for Q in FQuestions do
    begin
      LSb.Append('| ' + Q.Id + ' ');
      for V := 1 to 2 do
      begin
        LPass := 0;
        for R in FResults do
          if (R.Question = Q.Id) and R.Target.EndsWith('/v' + IntToStr(V)) and Passed(R) then
            Inc(LPass);
        LSb.AppendFormat('| %d ', [LPass]);
      end;
      LSb.AppendLine('|');
    end;
    LSb.AppendLine;

    LSb.AppendLine('## Questions');
    LSb.AppendLine;
    for Q in FQuestions do
    begin
      LSb.AppendFormat('- **%s** (screen %s): %s', [Q.Id, Q.ScreenLabel, Q.Text]);
      LSb.AppendLine;
      LSb.AppendLine('  - rubric: ' + Q.Rubric);
    end;
    LSb.AppendLine;

    LSb.AppendLine('## Verdicts');
    LSb.AppendLine;
    LSb.AppendLine('| Question | Target | Useful | Invented | Cited | Note |');
    LSb.AppendLine('|---|---|---:|---|---|---|');
    for Q in FQuestions do
      for R in FResults do
        if R.Question = Q.Id then
        begin
          LSb.AppendFormat('| %s | %s | %d | %s | %s | %s |', [Q.Id, R.Target, R.Useful,
            IfThen(R.Invented, '**yes**', 'no'),
            IfThen(Length(R.CitedPages) > 0, string.Join(' ', R.CitedPages), '-'),
            R.JudgeNote.Replace('|', '/')]);
          LSb.AppendLine;
        end;
    LSb.AppendLine;

    LSb.AppendLine('## Answers');
    LSb.AppendLine;
    for T in FTargets do
    begin
      LSb.AppendLine('### ' + T.Name);
      LSb.AppendLine;
      for R in FResults do
      begin
        if (R.Target <> T.Name) or (R.Question = 'warm-up') then
          Continue;
        LSb.AppendFormat('**%s** (%s, useful %d%s)', [R.Question, Secs(R.ElapsedMs), R.Useful,
          IfThen(R.Invented, ', invented', '')]);
        LSb.AppendLine.AppendLine;
        LAnswer := R.Answer.Replace(#13#10, #10).Replace(#10, #10'> ');
        LSb.AppendLine('> ' + LAnswer);
        LSb.AppendLine;
      end;
    end;
    Result := LSb.ToString;
  finally
    LNames.Free;
    LSb.Free;
  end;
end;

procedure TBenchRunner.LoadAnswers(const AReportFile: string);
var
  LLines: TArray<string>;
  I: Integer;
  LInAnswers, LHave: Boolean;
  LTarget: TBenchTarget;
  R: TBenchResult;
  LSb: TStringBuilder;
  LMatch: TMatch;
  Q: TBenchQuestion;

  procedure Flush;
  begin
    if LHave then
    begin
      R.Answer := LSb.ToString.TrimRight;
      FResults.Add(R);
    end;
    LHave := False;
    LSb.Clear;
  end;

begin
  LLines := TFile.ReadAllLines(AReportFile, TEncoding.UTF8);
  LInAnswers := False;
  LHave := False;
  FTargets.Clear;
  FResults.Clear;
  LSb := TStringBuilder.Create;
  try
    for I := 0 to High(LLines) do
    begin
      if LLines[I] = '## Answers' then
      begin
        LInAnswers := True;
        Continue;
      end;
      if not LInAnswers then
        Continue;
      if LLines[I].StartsWith('### ') then
      begin
        Flush;
        LTarget := Default(TBenchTarget);
        LTarget.Name := LLines[I].Substring(4).Trim;
        LTarget.Variant := StrToIntDef(LTarget.Name.Substring(LTarget.Name.LastIndexOf('/v') + 2), 1);
        FTargets.Add(LTarget);
        Continue;
      end;
      LMatch := TRegEx.Match(LLines[I], '^\*\*([A-Z][0-9])\*\* \(([0-9.]+) s');
      if LMatch.Success then
      begin
        Flush;
        R := Default(TBenchResult);
        R.Target := LTarget.Name;
        R.Question := LMatch.Groups[1].Value;
        R.ElapsedMs := Round(StrToFloat(LMatch.Groups[2].Value, TFormatSettings.Invariant) * 1000);
        LHave := True;
        Continue;
      end;
      if LHave and LLines[I].StartsWith('>') then
      begin
        if LSb.Length > 0 then
          LSb.Append(#10);
        LSb.Append(LLines[I].Substring(1).TrimLeft([' ']));
      end;
    end;
    Flush;
  finally
    LSb.Free;
  end;
  for I := 0 to FResults.Count - 1 do
  begin
    R := FResults[I];
    if FindQuestion(R.Question, Q) then
      Score(Q, R);
    FResults[I] := R;
  end;
end;

procedure TBenchRunner.RunSearchTerms(const AQuestionsFile: string);
var
  LInput: TJSONObject;
  LValue: TJSONValue;
  T: TBenchTarget;
  LSettings: THelpChatSettings;
  LProvider: IHelpChatProvider;
  LWatch: TStopwatch;
  LTerms, LText: string;
  LCount, LEmpty: Integer;
begin
  LInput := TJSONObject.ParseJSONValue(TFile.ReadAllText(AQuestionsFile, TEncoding.UTF8)) as TJSONObject;
  try
    for T in FTargets do
    begin
      LSettings := MakeSettings(T);
      try
        LSettings.Language := hclItalian;
        LSettings.DocLanguage := hclEnglish;
        LProvider := THelpChatProviderRegistry.CreateProvider(T.Provider, LSettings, nil, nil);
        LCount := 0;
        LEmpty := 0;
        LWatch := TStopwatch.StartNew;
        for LValue in LInput.GetValue<TJSONArray>('questions') do
        begin
          if LValue.GetValue<string>('lang') <> 'it' then
            Continue;
          LText := LValue.GetValue<string>('text');
          LTerms := THelpChatProviderBase(LProvider as TObject).SearchTerms(
            THelpChatProviderBase.SingleQuestion(LText), nil);
          Inc(LCount);
          if LTerms = '' then
            Inc(LEmpty);
          Writeln(Format('%-22s %-58s -> %s', [T.Name, Copy(LText, 1, 58), LTerms]));
        end;
        if LCount = 0 then
          LCount := 1;
        Log(Format('%s: %d without terms, %d ms each on average',
          [T.Name, LEmpty, LWatch.ElapsedMilliseconds div LCount]));
      finally
        LProvider := nil;
        LSettings.Free;
      end;
    end;
  finally
    LInput.Free;
  end;
end;

procedure TBenchRunner.FilterTargets(const AFilters: TArray<string>);
var
  I: Integer;
  LKeep: Boolean;
  F: string;
begin
  if Length(AFilters) = 0 then
    Exit;
  for I := FTargets.Count - 1 downto 0 do
  begin
    LKeep := False;
    for F in AFilters do
      if ContainsText(FTargets[I].Name, F) then
        LKeep := True;
    if not LKeep then
      FTargets.Delete(I);
  end;
end;

function TBenchRunner.MakeSettings(const ATarget: TBenchTarget): THelpChatSettings;
var
  LModel: THelpChatModelSettings;
begin
  Result := THelpChatSettings.Create;
  try
    // The three default files: the keys of claude and gemini live in the
    // shared one (%APPDATA%\HelpChatAI\helpchatai.json).
    Result.LoadConfiguration('');
    // The benchmark names its own target: the assistants of the shared file
    // must not pick the provider at Start.
    Result.Models.Clear;
    Result.SelectedModel := '';
    Result.Provider := ATarget.Provider;
    Result.PersistConversation := False;
    Result.Language := hclEnglish;
    Result.DocIndexFile := TPath.Combine(FRepoRoot, 'CRM Demo\Help\help-index.json');
    Result.DocFolder := TPath.Combine(FRepoRoot, 'CRM Demo\Help');
    Result.DocBaseUrl := '';
    LModel := Result.ActiveModel;
    if ATarget.Model <> '' then
      LModel.Model := ATarget.Model;
    if ATarget.BaseUrl <> '' then
      LModel.BaseUrl := ATarget.BaseUrl;
    LModel.ResponseTimeoutMs := ATarget.ResponseTimeoutMs;
    if FNoCache then
      Result.Claude.PromptCaching := False;
    // The library opens the prompt with the name and now, and composes the
    // field with the rule that governs it.
    if ATarget.Variant >= 1 then
      Result.AssistantName := EXPERT_NAME;
    if ATarget.Variant >= 2 then
      Result.Expertise := EXPERT_FIELD;
  except
    Result.Free;
    raise;
  end;
end;

procedure TBenchRunner.RecordCall(const AName, AArgsJson: string);
var
  C: TBenchActionCall;
begin
  // Main thread (ExecutePending): what the model sent, before the outcome.
  C.Name := AName;
  C.ArgsJson := AArgsJson;
  C.Outcome := aoDone;
  C.ResultText := '';
  FCalls.Add(C);
end;

function TBenchRunner.MakeBroker: THelpChatActionBroker;
begin
  Result := THelpChatActionBroker.Create;
  Result.OnExecuted := OnActionExecuted;
  Result.OnConfirm := OnActionConfirm;
  // The same two shapes the CRM demo registers (uMainForm.RegisterHelpActions).
  Result.Add('open_screen',
    'Brings one of the application screens to the front.',
    [THelpChatActionParam.Create('name',
      'Screen name: Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users.')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      RecordCall('open_screen', AArgs.RawJson);
      AResult := 'Opened the ' + AArgs.AsString('name') + ' screen.';
    end, False);
  Result.Add('create_lead',
    'Creates a new lead on the Leads board, for a company that already exists ' +
    'in the Accounts list.',
    [THelpChatActionParam.Create('name', 'Name of the person'),
     THelpChatActionParam.Create('account', 'Company name, as it appears in the Accounts list'),
     THelpChatActionParam.Create('phone', 'Office phone', apkString, False),
     THelpChatActionParam.Create('email', 'E-mail address', apkString, False),
     THelpChatActionParam.Create('notes', 'Anything worth remembering', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      RecordCall('create_lead', AArgs.RawJson);
      AResult := 'Created the lead ' + AArgs.AsString('name') + ' (id 101).';
    end, True);
end;

procedure TBenchRunner.OnActionConfirm(Sender: TObject; const AName: string;
  const AArgs: THelpChatActionArgs; var AAllow: Boolean);
begin
  AAllow := True; // the user says yes, always
end;

procedure TBenchRunner.OnActionExecuted(Sender: TObject; const AName: string;
  const AOutcome: THelpChatActionOutcome; const AResult: string);
var
  C: TBenchActionCall;
  I: Integer;
begin
  // Completes the record of the handler; an unknown or denied action never
  // reached a handler, so it is recorded here.
  for I := FCalls.Count - 1 downto 0 do
    if SameText(FCalls[I].Name, AName) and (FCalls[I].ResultText = '') then
    begin
      C := FCalls[I];
      C.Outcome := AOutcome;
      C.ResultText := AResult;
      FCalls[I] := C;
      Exit;
    end;
  C.Name := AName;
  C.ArgsJson := '';
  C.Outcome := AOutcome;
  C.ResultText := AResult;
  FCalls.Add(C);
end;

procedure TBenchRunner.OnMessageChanged(Sender: TObject; const AMessageId: string);
var
  LMsg: THelpChatMessage;
begin
  // Worker thread: record the first time the pending reply has text.
  if FFirstTokenTicks <> 0 then
    Exit;
  if THelpChatEngine(Sender).TryGetMessage(AMessageId, LMsg) and
    (LMsg.Role = hcrAssistant) and (LMsg.Content <> '') then
    TInterlocked.CompareExchange(FFirstTokenTicks, TStopwatch.GetTimeStamp, 0);
end;

function TBenchRunner.Ask(const AEngine: THelpChatEngine;
  const ABroker: THelpChatActionBroker; const AQuestion: TBenchQuestion;
  const ATimeoutMs: Integer): TBenchResult;
var
  LCtx: THelpChatContext;
  LSend: THelpChatSendResult;
  LMsg: THelpChatMessage;
  LWatch: TStopwatch;
  LDone: Boolean;
begin
  Result := Default(TBenchResult);
  Result.Question := AQuestion.Id;
  TMonitor.Enter(FUsageLock);
  try
    FUsage := Default(TBenchResult);
  finally
    TMonitor.Exit(FUsageLock);
  end;
  FCalls.Clear;
  FFirstTokenTicks := 0;
  // One conversation per question, unless the suite keeps it: then only the
  // warm-up starts from nothing (and is cleared after, see Run).
  if not FKeepConversation or (AQuestion.Id = 'warm-up') then
    AEngine.Clear;

  LCtx := Default(THelpChatContext);
  LCtx.ScreenName := 'MainForm';
  LCtx.ScreenLabel := AQuestion.ScreenLabel;
  LCtx.ScreenType := 'TMainForm';
  LCtx.HelpKeyword := AQuestion.ScreenLabel;

  LWatch := TStopwatch.StartNew;
  FStartTicks := TStopwatch.GetTimeStamp;
  LSend := AEngine.Send(AQuestion.Text, LCtx);
  LDone := False;
  repeat
    // The broker queues the action on the worker; the host runs it here.
    if Assigned(ABroker) then
      ABroker.ExecutePending;
    CheckSynchronize(10);
    if AEngine.TryGetMessage(LSend.AssistantMessage.Id, LMsg) and not LMsg.Pending then
      LDone := True
    else
      Sleep(20);
  until LDone or (LWatch.ElapsedMilliseconds > ATimeoutMs);
  Result.ElapsedMs := LWatch.ElapsedMilliseconds;
  if not LDone then
  begin
    AEngine.Cancel(LSend.AssistantMessage.Id);
    Result.IsError := True;
    Result.Answer := '(timeout after ' + IntToStr(ATimeoutMs div 1000) + ' s)';
  end
  else
  begin
    Result.Answer := LMsg.Content;
    Result.IsError := LMsg.IsError;
  end;
  if FFirstTokenTicks <> 0 then
    Result.FirstTokenMs := Round((FFirstTokenTicks - FStartTicks) * 1000 / TStopwatch.Frequency)
  else
    Result.FirstTokenMs := -1;
  Result.Actions := FCalls.ToArray;
  TMonitor.Enter(FUsageLock);
  try
    Result.Requests := FUsage.Requests;
    Result.InputTokens := FUsage.InputTokens;
    Result.CacheWriteTokens := FUsage.CacheWriteTokens;
    Result.CacheReadTokens := FUsage.CacheReadTokens;
    Result.OutputTokens := FUsage.OutputTokens;
  finally
    TMonitor.Exit(FUsageLock);
  end;
end;

procedure TBenchRunner.Score(const AQuestion: TBenchQuestion; var AResult: TBenchResult);
var
  LMatches: TMatchCollection;
  M: TMatch;
  LPages: TList<string>;
  P, F: string;
  C: TBenchActionCall;
  LSeen: Boolean;
begin
  // Citations: every "<Page>.md" the answer mentions, as link or as text.
  LPages := TList<string>.Create;
  try
    LMatches := TRegEx.Matches(AResult.Answer, '([A-Za-z][A-Za-z0-9\-]*)\.md\b');
    for M in LMatches do
    begin
      P := M.Groups[1].Value + '.md';
      if not LPages.Contains(P) then
        LPages.Add(P);
    end;
    AResult.CitedPages := LPages.ToArray;
  finally
    LPages.Free;
  end;
  if AQuestion.AnyCitation then
    AResult.CitationOk := True
  else if Length(AQuestion.ExpectedPages) = 0 then
    // Nothing to cite: a page named here is one the model made up
    AResult.CitationOk := Length(AResult.CitedPages) = 0
  else
  begin
    AResult.CitationOk := False;
    for P in AQuestion.ExpectedPages do
      if MatchText(P, AResult.CitedPages) then
        AResult.CitationOk := True;
  end;

  AResult.FactsTotal := Length(AQuestion.Facts);
  AResult.FactsFound := 0;
  // A fact may list alternatives: "VAT|tax" is found by either word.
  for F in AQuestion.Facts do
    if MatchesAny(AResult.Answer, F) then
      Inc(AResult.FactsFound);

  AResult.WrongActions := 0;
  LSeen := False;
  for C in AResult.Actions do
    if SameText(C.Name, AQuestion.ExpectedAction) then
    begin
      if (C.Outcome = aoDone) and
        ((AQuestion.ExpectedArg = '') or ContainsText(C.ArgsJson, AQuestion.ExpectedArg)) then
        LSeen := True;
    end
    else
      Inc(AResult.WrongActions);
  if AQuestion.ExpectedAction = '' then
    AResult.ActionOk := Length(AResult.Actions) = 0
  else
    AResult.ActionOk := LSeen and (AResult.WrongActions = 0);
end;

procedure TBenchRunner.Run;
var
  T: TBenchTarget;
  Q: TBenchQuestion;
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LBroker: THelpChatActionBroker;
  LInvoker: IHelpChatActionInvoker;
  LWarm: TBenchQuestion;
  R: TBenchResult;
  LIssue: string;
  LClass: THelpChatProviderClass;
begin
  HelpChatOnTokenUsage :=
    procedure(const AUsage: THelpChatTokenUsage)
    begin
      AddUsage(AUsage);
    end;
  try
  for T in FTargets do
  begin
    Log('=== ' + T.Name + ' (' + T.Provider + ')');
    LSettings := MakeSettings(T);
    LClass := THelpChatProviderRegistry.FindProviderClass(T.Provider);
    if LClass = nil then
      LIssue := 'provider "' + T.Provider + '" is not registered'
    else
      LIssue := LClass.ConfigurationIssue(LSettings);
    if LIssue <> '' then
    begin
      Log('  skipped: ' + LIssue);
      R := Default(TBenchResult);
      R.Target := T.Name;
      R.Question := '-';
      R.IsError := True;
      R.Answer := 'skipped: ' + LIssue;
      FResults.Add(R);
      LSettings.Free;
      Continue;
    end;
    LEngine := THelpChatEngine.Create(LSettings, True);
    try
      LBroker := MakeBroker;
      LInvoker := LBroker;
      LEngine.Actions := LInvoker;
      LEngine.OnMessageChanged := OnMessageChanged;
      LEngine.Start;
      Log(Format('  model: %s  endpoint: %s  index: %d pages',
        [LSettings.ActiveModel.ResolveModel,
         IfThen(LSettings.ActiveModel.BaseUrl <> '', LSettings.ActiveModel.BaseUrl, '(default)'),
         LEngine.DocIndex.Count]));

      // Warm-up: loads the local model (12-20 s) and opens the HTTP connection
      // of the remote one. Reported, not scored.
      LWarm := Default(TBenchQuestion);
      LWarm.Id := 'warm-up';
      LWarm.Text := WARMUP_QUESTION;
      LWarm.ScreenLabel := 'Dashboard';
      R := Ask(LEngine, LBroker, LWarm, T.ResponseTimeoutMs + 30000);
      R.Target := T.Name;
      Log(Format('  warm-up: %d ms%s', [R.ElapsedMs, IfThen(R.IsError, '  ERROR: ' + R.Answer, '')]));
      FResults.Add(R);
      if R.IsError then
      begin
        Log('  the provider failed on the warm-up; skipping its questions');
        Continue;
      end;
      // The conversation starts with the first question, not with "Hello".
      if FKeepConversation then
        LEngine.Clear;

      for Q in FQuestions do
      begin
        R := Ask(LEngine, LBroker, Q, T.ResponseTimeoutMs + 30000);
        R.Target := T.Name;
        Score(Q, R);
        FResults.Add(R);
        Log(Format('  %s: %d ms (first token %d ms)  cite=%s facts=%d/%d actions=%d%s%s  %s',
          [Q.Id, R.ElapsedMs, R.FirstTokenMs, BoolToStr(R.CitationOk, True),
           R.FactsFound, R.FactsTotal, Length(R.Actions),
           IfThen(R.ActionOk, '', '(wrong)'),
           IfThen(R.Requests > 0, Format('  tokens in=%d write=%d read=%d out=%d',
             [R.InputTokens, R.CacheWriteTokens, R.CacheReadTokens, R.OutputTokens]), ''),
           IfThen(R.IsError, 'ERROR: ' + R.Answer, '')]));
      end;
    finally
      LEngine.Stop;
      LEngine.Free;
      LInvoker := nil;
    end;
  end;
  finally
    HelpChatOnTokenUsage := nil;
  end;
end;

procedure TBenchRunner.AppendTokens(const ASb: TStringBuilder);
var
  T: TBenchTarget;
  R: TBenchResult;
  LReq, LIn, LWrite, LRead, LOut: Int64;
begin
  // Only the providers that report their usage (claude) have a row.
  ASb.AppendLine('### Tokens');
  ASb.AppendLine;
  ASb.AppendLine(IfThen(FNoCache, 'Prompt cache **off** (`--nocache`).',
    'Prompt cache on (`Claude.PromptCaching`, the default).') +
    ' The questions, warm-up excluded, of each target in a row, as one session would ask them.');
  ASb.AppendLine;
  ASb.AppendLine('| Target | Requests | Input | Cache write | Cache read | Output | Input as billed |');
  ASb.AppendLine('|---|---:|---:|---:|---:|---:|---:|');
  for T in FTargets do
  begin
    LReq := 0; LIn := 0; LWrite := 0; LRead := 0; LOut := 0;
    for R in FResults do
      if (R.Target = T.Name) and (R.Question <> 'warm-up') and (R.Question <> '-') then
      begin
        Inc(LReq, R.Requests);
        Inc(LIn, R.InputTokens);
        Inc(LWrite, R.CacheWriteTokens);
        Inc(LRead, R.CacheReadTokens);
        Inc(LOut, R.OutputTokens);
      end;
    if LReq = 0 then
      Continue;
    // The multipliers are Anthropic's: the other services price their
    // automatic cache in their own way.
    if SameText(T.Provider, 'claude') then
      ASb.AppendFormat('| %s | %d | %d | %d | %d | %d | %d |',
        [T.Name, LReq, LIn, LWrite, LRead, LOut, Round(LIn + 1.25 * LWrite + 0.1 * LRead)])
    else
      ASb.AppendFormat('| %s | %d | %d | %d | %d | %d | - |',
        [T.Name, LReq, LIn, LWrite, LRead, LOut]);
    ASb.AppendLine;
  end;
  ASb.AppendLine;
  ASb.AppendLine('"Input": tokens at the full price. "Input as billed", claude only: input + 1.25 x ' +
    'cache write + 0.1 x cache read, the multipliers of Haiku (Sonnet and Opus 5.5 read at 0.05), ' +
    'in tokens of the full price. OpenAI and Gemini cache by themselves, at prices of their own; ' +
    'a local server reports its prefix cache, which costs nothing.');
  ASb.AppendLine;
  AppendTokensPerQuestion(ASb);
end;

procedure TBenchRunner.AppendTokensPerQuestion(const ASb: TStringBuilder);
var
  T: TBenchTarget;
  Q: TBenchQuestion;
  R: TBenchResult;
  LCells: TStringBuilder;
  LAny: Boolean;
  LTotal: Int64;
begin
  // Each question as a share of its prompt read from the cache: in one
  // conversation it should grow with the history.
  ASb.AppendLine('### Tokens per question');
  ASb.AppendLine;
  ASb.AppendLine('Read from the cache / the whole input of the requests of each question' +
    IfThen(FKeepConversation, ', the questions of a target in one conversation.',
    ', each question in a new conversation.'));
  ASb.AppendLine;
  ASb.Append('| Target |');
  for Q in FQuestions do
    ASb.Append(' ' + Q.Id + ' |');
  ASb.AppendLine;
  ASb.Append('|---|');
  for Q in FQuestions do
    ASb.Append('---:|');
  ASb.AppendLine;
  LCells := TStringBuilder.Create;
  try
    for T in FTargets do
    begin
      LCells.Clear;
      LAny := False;
      for Q in FQuestions do
      begin
        LTotal := -1;
        for R in FResults do
          if (R.Target = T.Name) and (R.Question = Q.Id) and (R.Requests > 0) then
          begin
            LTotal := R.InputTokens + R.CacheWriteTokens + R.CacheReadTokens;
            LCells.AppendFormat(' %d / %d |', [R.CacheReadTokens, LTotal]);
            LAny := True;
          end;
        if LTotal < 0 then
          LCells.Append(' - |');
      end;
      if LAny then
        ASb.AppendLine('| ' + T.Name + ' |' + LCells.ToString);
    end;
  finally
    LCells.Free;
  end;
  ASb.AppendLine;
end;

function TBenchRunner.Report: string;
var
  LSb: TStringBuilder;
  T: TBenchTarget;
  Q: TBenchQuestion;
  R: TBenchResult;
  C: TBenchActionCall;
  LN, LErr, LCite, LFactsFound, LFactsTotal, LActOk, LActQ: Integer;
  LSum, LFirst, LFirstN, LWarm: Int64;
  LAnswer: string;

  function Pct(const A, B: Integer): string;
  begin
    if B = 0 then
      Result := '-'
    else
      Result := Format('%d%%', [Round(100 * A / B)]);
  end;

  function Mark(const AOk: Boolean): string;
  begin
    if AOk then
      Result := 'yes'
    else
      Result := '**no**';
  end;

  function Secs(const AMs: Int64): string;
  begin
    if AMs < 0 then
      Result := '-'
    else
      Result := Format('%.1f s', [AMs / 1000], TFormatSettings.Invariant);
  end;

begin
  if (FTargets.Count > 0) and (FTargets[0].Variant > 0) then
    Exit(ReportExpertise);
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('# HelpChatAI provider benchmark');
    LSb.AppendLine;
    LSb.AppendFormat('Run on %s. Grounding: `CRM Demo\Help\help-index.json`, %d pages x %d chars; ' +
      'two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); ' +
      '%s; language rule English.',
      [FormatDateTime('yyyy-mm-dd hh:nn', Now), HELPCHAT_MODEL_DEF_GROUNDING,
       HELPCHAT_MODEL_DEF_GROUNDING_CHARS,
       IfThen(FKeepConversation, '**the questions of a target in one conversation**, the history ' +
         'never cleared (`--suite=conversation`)', 'a new conversation per question')]);
    LSb.AppendLine.AppendLine;

    LSb.AppendLine('## Summary');
    LSb.AppendLine;
    LSb.AppendLine('| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |');
    LSb.AppendLine('|---|---:|---:|---:|---:|---:|---:|---:|---:|');
    for T in FTargets do
    begin
      LN := 0; LErr := 0; LCite := 0; LFactsFound := 0; LFactsTotal := 0; LActOk := 0; LActQ := 0;
      LSum := 0; LFirst := 0; LFirstN := 0; LWarm := -1;
      for R in FResults do
      begin
        if R.Target <> T.Name then
          Continue;
        if R.Question = 'warm-up' then
        begin
          LWarm := R.ElapsedMs;
          Continue;
        end;
        if R.Question = '-' then
          Continue;
        Inc(LN);
        if R.IsError then
          Inc(LErr);
        LSum := LSum + R.ElapsedMs;
        if R.FirstTokenMs >= 0 then
        begin
          LFirst := LFirst + R.FirstTokenMs;
          Inc(LFirstN);
        end;
        if R.CitationOk then
          Inc(LCite);
        LFactsFound := LFactsFound + R.FactsFound;
        LFactsTotal := LFactsTotal + R.FactsTotal;
        Inc(LActQ);
        if R.ActionOk then
          Inc(LActOk);
      end;
      if LN = 0 then
        LSb.AppendFormat('| %s | %s | 0 | skipped | - | - | - | - | - |', [T.Name, Secs(LWarm)])
      else
        LSb.AppendFormat('| %s | %s | %d | %d | %s | %s | %s (%d/%d) | %s (%d/%d) | %s (%d/%d) |',
          [T.Name, Secs(LWarm), LN, LErr, Secs(LSum div LN),
           IfThen(LFirstN > 0, Secs(LFirst div LFirstN), '-'),
           Pct(LCite, LN), LCite, LN, Pct(LFactsFound, LFactsTotal), LFactsFound, LFactsTotal,
           Pct(LActOk, LActQ), LActOk, LActQ]);
      LSb.AppendLine;
    end;
    LSb.AppendLine;
    AppendTokens(LSb);
    LSb.AppendLine('"Citations ok": the answer names one of the expected pages (`Page.md`), or none when ' +
      'nothing was expected. "Facts found": expected substrings present in the answer. ' +
      '"Actions ok": the expected action was invoked with the expected argument and no other ' +
      'action was, or no action at all when none was expected. Time includes the tool rounds.');
    LSb.AppendLine;

    LSb.AppendLine('## Per question');
    LSb.AppendLine;
    LSb.AppendLine('| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |');
    LSb.AppendLine('|---|---|---:|---:|---|---|---:|---|---|');
    for Q in FQuestions do
      for R in FResults do
      begin
        if R.Question <> Q.Id then
          Continue;
        LAnswer := '';
        for C in R.Actions do
          LAnswer := LAnswer + IfThen(LAnswer <> '', ', ', '') + C.Name;
        LSb.AppendFormat('| %s | %s | %s | %s | %s | %s | %d/%d | %s | %s |',
          [Q.Id, R.Target, Secs(R.ElapsedMs), Secs(R.FirstTokenMs),
           IfThen(Length(R.CitedPages) > 0, string.Join(' ', R.CitedPages), '-'),
           Mark(R.CitationOk), R.FactsFound, R.FactsTotal,
           IfThen(LAnswer <> '', LAnswer, '-'), Mark(R.ActionOk)]);
        LSb.AppendLine;
      end;
    LSb.AppendLine;

    LSb.AppendLine('## Questions');
    LSb.AppendLine;
    for Q in FQuestions do
    begin
      LSb.AppendFormat('- **%s** (screen %s): %s', [Q.Id, Q.ScreenLabel, Q.Text]);
      if Length(Q.ExpectedPages) > 0 then
        LSb.AppendFormat(' - expected page: %s', [string.Join(' or ', Q.ExpectedPages)]);
      if Length(Q.Facts) > 0 then
        LSb.AppendFormat(' - facts: %s', [string.Join(', ', Q.Facts)]);
      if Q.ExpectedAction <> '' then
        LSb.AppendFormat(' - action: %s(%s)', [Q.ExpectedAction, Q.ExpectedArg])
      else
        LSb.Append(' - no action');
      LSb.AppendLine;
    end;
    LSb.AppendLine;

    LSb.AppendLine('## Answers');
    LSb.AppendLine;
    for T in FTargets do
    begin
      LSb.AppendLine('### ' + T.Name);
      LSb.AppendLine;
      for R in FResults do
      begin
        if R.Target <> T.Name then
          Continue;
        LSb.AppendFormat('**%s** (%s%s)', [R.Question, Secs(R.ElapsedMs),
          IfThen(R.IsError, ', error', '')]);
        LSb.AppendLine.AppendLine;
        for C in R.Actions do
        begin
          LSb.AppendFormat('- action `%s` %s -> %s', [C.Name, C.ArgsJson,
            HelpChatActionOutcomeText(C.Outcome, C.Name, C.ResultText)]);
          LSb.AppendLine;
        end;
        if Length(R.Actions) > 0 then
          LSb.AppendLine;
        LAnswer := R.Answer.Replace(#13#10, #10).Replace(#10, #10'> ');
        LSb.AppendLine('> ' + LAnswer);
        LSb.AppendLine;
      end;
    end;
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

end.
