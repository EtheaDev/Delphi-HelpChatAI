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
  HelpChatAI.Actions;

type
  /// <summary>One provider + model to measure. Local models are listed first,
  /// so that Ollama loads each one once and never swaps back and forth.</summary>
  TBenchTarget = record
    Name: string;       // what the report calls it
    Provider: string;   // registered provider name
    Model: string;      // empty = the default of the provider
    BaseUrl: string;    // empty = the default of the provider
    ResponseTimeoutMs: Integer;
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
  end;

  TBenchRunner = class
  strict private
    FRepoRoot: string;
    FTargets: TList<TBenchTarget>;
    FQuestions: TList<TBenchQuestion>;
    FResults: TList<TBenchResult>;
    FCalls: TList<TBenchActionCall>;
    FFirstTokenTicks: Int64;
    FStartTicks: Int64;
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
  public
    constructor Create(const ARepoRoot: string);
    destructor Destroy; override;
    procedure AddDefaultTargets;
    procedure AddDefaultQuestions;
    /// <summary>Keeps only the targets whose name contains one of AFilters.</summary>
    procedure FilterTargets(const AFilters: TArray<string>);
    procedure Run;
    function Report: string;
    property Results: TList<TBenchResult> read FResults;
    property Targets: TList<TBenchTarget> read FTargets;
    property Questions: TList<TBenchQuestion> read FQuestions;
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
///  on a port of it.
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
  HelpChatAI.DocIndex,
  HelpChatAI.Messages,
  HelpChatAI.Provider,
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
      LResults.Add(LItem);
    end;
    TFile.WriteAllText(AOutFile, LOut.Format(2), TEncoding.UTF8);
    Writeln(Format('%d questions over %d pages -> %s', [LResults.Count, LIndex.Count, AOutFile]));
  finally
    LOut.Free;
    LInput.Free;
  end;
end;

{ TBenchRunner }

constructor TBenchRunner.Create(const ARepoRoot: string);
begin
  inherited Create;
  FRepoRoot := ARepoRoot;
  FTargets := TList<TBenchTarget>.Create;
  FQuestions := TList<TBenchQuestion>.Create;
  FResults := TList<TBenchResult>.Create;
  FCalls := TList<TBenchActionCall>.Create;
end;

destructor TBenchRunner.Destroy;
begin
  FCalls.Free;
  FResults.Free;
  FQuestions.Free;
  FTargets.Free;
  inherited;
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
    T.Name := AName;
    T.Provider := AProvider;
    T.Model := AModel;
    T.BaseUrl := ABaseUrl;
    T.ResponseTimeoutMs := ATimeout;
    FTargets.Add(T);
  end;

begin
  // Local models first, one after the other: Ollama keeps one in VRAM.
  AddTarget('gemma4:12b', 'openai', 'gemma4:12b', OLLAMA_BASEURL, OLLAMA_TIMEOUT_MS);
  AddTarget('gpt-oss:20b', 'openai', 'gpt-oss:20b', OLLAMA_BASEURL, OLLAMA_TIMEOUT_MS);
  AddTarget('qwen3-coder:30b', 'openai', 'qwen3-coder:30b', OLLAMA_BASEURL, OLLAMA_TIMEOUT_MS);
  // The references: the two remote providers as configured on this machine.
  AddTarget('claude', 'claude', '', '', CLOUD_TIMEOUT_MS);
  AddTarget('gemini', 'gemini', '', '', CLOUD_TIMEOUT_MS);
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
    Result.Assistants.Clear;
    Result.Assistant := '';
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
  FCalls.Clear;
  FFirstTokenTicks := 0;
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
  if Length(AQuestion.ExpectedPages) = 0 then
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
  for F in AQuestion.Facts do
    if ContainsText(AResult.Answer, F) then
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

      for Q in FQuestions do
      begin
        R := Ask(LEngine, LBroker, Q, T.ResponseTimeoutMs + 30000);
        R.Target := T.Name;
        Score(Q, R);
        FResults.Add(R);
        Log(Format('  %s: %d ms (first token %d ms)  cite=%s facts=%d/%d actions=%d%s  %s',
          [Q.Id, R.ElapsedMs, R.FirstTokenMs, BoolToStr(R.CitationOk, True),
           R.FactsFound, R.FactsTotal, Length(R.Actions),
           IfThen(R.ActionOk, '', '(wrong)'), IfThen(R.IsError, 'ERROR: ' + R.Answer, '')]));
      end;
    finally
      LEngine.Stop;
      LEngine.Free;
      LInvoker := nil;
    end;
  end;
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
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('# HelpChatAI provider benchmark');
    LSb.AppendLine;
    LSb.AppendFormat('Run on %s. Grounding: `CRM Demo\Help\help-index.json`, %d pages x %d chars; ' +
      'two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); ' +
      'a new conversation per question; language rule English.',
      [FormatDateTime('yyyy-mm-dd hh:nn', Now), HELPCHAT_MODEL_DEF_GROUNDING,
       HELPCHAT_MODEL_DEF_GROUNDING_CHARS]);
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
