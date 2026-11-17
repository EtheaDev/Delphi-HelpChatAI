{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       LLM benchmark: the same questions to every configured provider,        }
{       one model after the other, with a Markdown report at the end.          }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
program HelpChatAILLMBench;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  HelpChatAI.LLMBench in '..\source\HelpChatAI.LLMBench.pas';

// Usage: HelpChatAILLMBench [--only=name[,name]] [--out=file.md]
//   --only  runs only the targets whose name contains one of the words
//           (gemma, gpt-oss, qwen, claude, gemini)
//   --out   where the report goes (default: Test\LLMBench\results\llm-bench-<stamp>.md)
//   --ollama=http://host:11434  the Ollama of the local models (default localhost)
//   --nocache  Claude.PromptCaching off, to compare the tokens with a run that has it
//
// HelpChatAILLMBench --terms=embeddings\questions.json [--only=...] [--ollama=URL]
//   the request of TranslateSearch through the providers of the library, for the
//   Italian questions, the chat in Italian and the manual in English: printed
//
// HelpChatAILLMBench --suite=conversation [--only=...] [--nocache] [--out=file.md]
//   the same questions, but those of a target asked in one conversation, the history
//   never cleared: what the prompt cache reads back as the conversation grows.
//   Report: llm-bench-conversation-<stamp>.md, with the tokens of every question
//
// HelpChatAILLMBench --suite=expertise [--only=...] [--judge=model] [--out=file.md]
//   the questions an expert of the field answers and the manual does not, each
//   model with three system prompts (as it is; name, now and expertise; plus the
//   rule against inventing), every answer graded by a Claude judge
//   (default claude-opus-5-5). Report: llm-bench-expertise-<stamp>.md
//   --rejudge=report.md  grades again the answers of such a report, asking no model
//
// HelpChatAILLMBench --retrieval=questions.json [--out=file.json]
//   no model at all: the ranking of the real lexical search for every question,
//   as JSON (default: Test\LLMBench\results\retrieval-lexical.json). The input of
//   Test\LLMBench\embeddings\embed_bench.py

var
  LRunner: TBenchRunner;
  LRoot, LOut, LArg, LRetrieval, LSuite, LJudge, LRejudge, LOllama, LTermsFile: string;
  LNoCache: Boolean;
  LOnly: TArray<string>;
  I: Integer;
begin
  try
    LRoot := FindRepoRoot;
    LOut := '';
    LOnly := nil;
    LNoCache := False;
    LJudge := 'claude-opus-5-5';
    for I := 1 to ParamCount do
    begin
      LArg := ParamStr(I);
      if LArg.StartsWith('--only=', True) then
        LOnly := LArg.Substring(7).Split([','])
      else if LArg.StartsWith('--out=', True) then
        LOut := LArg.Substring(6)
      else if LArg.StartsWith('--retrieval=', True) then
        LRetrieval := LArg.Substring(12)
      else if LArg.StartsWith('--terms=', True) then
        LTermsFile := LArg.Substring(8)
      else if LArg.StartsWith('--suite=', True) then
        LSuite := LArg.Substring(8)
      else if SameText(LArg, '--nocache') then
        LNoCache := True
      else if LArg.StartsWith('--ollama=', True) then
      begin
        // The server, with or without the /v1 of the OpenAI-compatible API.
        LOllama := LArg.Substring(9).TrimRight(['/']);
        if not LOllama.EndsWith('/v1', True) then
          LOllama := LOllama + '/v1';
      end
      else if LArg.StartsWith('--judge=', True) then
        LJudge := LArg.Substring(8)
      else if LArg.StartsWith('--rejudge=', True) then
      begin
        LRejudge := TPath.GetFullPath(LArg.Substring(10));
        LSuite := 'expertise';
      end;
    end;
    if LRetrieval <> '' then
    begin
      if LOut = '' then
        LOut := TPath.Combine(LRoot, 'Test\LLMBench\results\retrieval-lexical.json');
      TDirectory.CreateDirectory(TPath.GetDirectoryName(LOut));
      RunRetrieval(TPath.Combine(LRoot, 'CRM Demo\Help\help-index.json'),
        TPath.GetFullPath(LRetrieval), LOut);
      Exit;
    end;
    if LTermsFile <> '' then
    begin
      LRunner := TBenchRunner.Create(LRoot);
      try
        if LOllama <> '' then
          LRunner.OllamaBaseUrl := LOllama;
        LRunner.AddDefaultTargets;
        LRunner.FilterTargets(LOnly);
        LRunner.RunSearchTerms(TPath.GetFullPath(LTermsFile));
      finally
        LRunner.Free;
      end;
      Exit;
    end;
    if LOut = '' then
      LOut := TPath.Combine(LRoot, 'Test\LLMBench\results\llm-bench-' +
        IfThen(SameText(LSuite, 'expertise'), 'expertise-',
          IfThen(SameText(LSuite, 'conversation'), 'conversation-', '')) +
        FormatDateTime('yyyymmdd-hhnn', Now) + '.md');
    TDirectory.CreateDirectory(TPath.GetDirectoryName(LOut));

    LRunner := TBenchRunner.Create(LRoot);
    try
      if LOllama <> '' then
        LRunner.OllamaBaseUrl := LOllama;
      LRunner.NoCache := LNoCache;
      LRunner.KeepConversation := SameText(LSuite, 'conversation');
      LRunner.AddDefaultTargets;
      if SameText(LSuite, 'expertise') then
        LRunner.AddExpertiseQuestions
      else
        LRunner.AddDefaultQuestions;
      LRunner.FilterTargets(LOnly);
      if LRejudge <> '' then
        LRunner.LoadAnswers(LRejudge)
      else if SameText(LSuite, 'expertise') then
        LRunner.ExpandVariants;
      Writeln('HelpChatAI LLM benchmark: ', LRunner.Targets.Count, ' targets, ',
        LRunner.Questions.Count, ' questions, report ', LOut);
      if LRejudge = '' then
        LRunner.Run;
      if SameText(LSuite, 'expertise') then
        LRunner.Judge(LJudge);
      TFile.WriteAllText(LOut, LRunner.Report, TEncoding.UTF8);
      Writeln('Report written to ', LOut);
    finally
      LRunner.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
