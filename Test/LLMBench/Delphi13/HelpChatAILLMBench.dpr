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
  HelpChatAI.LLMBench in '..\source\HelpChatAI.LLMBench.pas';

// Usage: HelpChatAILLMBench [--only=name[,name]] [--out=file.md]
//   --only  runs only the targets whose name contains one of the words
//           (gemma, gpt-oss, qwen, claude, gemini)
//   --out   where the report goes (default: Test\LLMBench\results\llm-bench-<stamp>.md)
//
// HelpChatAILLMBench --retrieval=questions.json [--out=file.json]
//   no model at all: the ranking of the real lexical search for every question,
//   as JSON (default: Test\LLMBench\results\retrieval-lexical.json). The input of
//   Test\LLMBench\embeddings\embed_bench.py

var
  LRunner: TBenchRunner;
  LRoot, LOut, LArg, LRetrieval: string;
  LOnly: TArray<string>;
  I: Integer;
begin
  try
    LRoot := FindRepoRoot;
    LOut := '';
    LOnly := nil;
    for I := 1 to ParamCount do
    begin
      LArg := ParamStr(I);
      if LArg.StartsWith('--only=', True) then
        LOnly := LArg.Substring(7).Split([','])
      else if LArg.StartsWith('--out=', True) then
        LOut := LArg.Substring(6)
      else if LArg.StartsWith('--retrieval=', True) then
        LRetrieval := LArg.Substring(12);
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
    if LOut = '' then
      LOut := TPath.Combine(LRoot, 'Test\LLMBench\results\llm-bench-' +
        FormatDateTime('yyyymmdd-hhnn', Now) + '.md');
    TDirectory.CreateDirectory(TPath.GetDirectoryName(LOut));

    LRunner := TBenchRunner.Create(LRoot);
    try
      LRunner.AddDefaultTargets;
      LRunner.AddDefaultQuestions;
      LRunner.FilterTargets(LOnly);
      Writeln('HelpChatAI LLM benchmark: ', LRunner.Targets.Count, ' targets, ',
        LRunner.Questions.Count, ' questions, report ', LOut);
      LRunner.Run;
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
