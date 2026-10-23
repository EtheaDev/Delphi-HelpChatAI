{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       DUnitX test suite of the engine (no UI, no network).                   }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
program HelpChatAITests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  HelpChatAI.Tests.Helpers in '..\source\HelpChatAI.Tests.Helpers.pas',
  HelpChatAI.Tests.Types in '..\source\HelpChatAI.Tests.Types.pas',
  HelpChatAI.Tests.Messages in '..\source\HelpChatAI.Tests.Messages.pas',
  HelpChatAI.Tests.Settings in '..\source\HelpChatAI.Tests.Settings.pas',
  HelpChatAI.Tests.Provider in '..\source\HelpChatAI.Tests.Provider.pas',
  HelpChatAI.Tests.Diagnostics in '..\source\HelpChatAI.Tests.Diagnostics.pas',
  HelpChatAI.Tests.Store in '..\source\HelpChatAI.Tests.Store.pas',
  HelpChatAI.Tests.DocIndex in '..\source\HelpChatAI.Tests.DocIndex.pas',
  HelpChatAI.Tests.DocPages in '..\source\HelpChatAI.Tests.DocPages.pas',
  HelpChatAI.Tests.Html in '..\source\HelpChatAI.Tests.Html.pas',
  HelpChatAI.Tests.Runner in '..\source\HelpChatAI.Tests.Runner.pas',
  HelpChatAI.Tests.Claude in '..\source\HelpChatAI.Tests.Claude.pas',
  HelpChatAI.Tests.OpenAI in '..\source\HelpChatAI.Tests.OpenAI.pas',
  HelpChatAI.Tests.Gemini in '..\source\HelpChatAI.Tests.Gemini.pas',
  HelpChatAI.Tests.Engine in '..\source\HelpChatAI.Tests.Engine.pas',
  HelpChatAI.Tests.IndexBuilder in '..\source\HelpChatAI.Tests.IndexBuilder.pas',
  HelpChatAI.Tests.Panel in '..\source\HelpChatAI.Tests.Panel.pas',
  HelpChatAI.Tests.Server in '..\source\HelpChatAI.Tests.Server.pas',
  HelpChatAI.Tests.Remote in '..\source\HelpChatAI.Tests.Remote.pas',
  HelpChatAI.Tests.Actions in '..\source\HelpChatAI.Tests.Actions.pas',
  HelpChatAI.Tests.Theme in '..\source\HelpChatAI.Tests.Theme.pas';

{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    // Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    // Create the test runner
    runner := TDUnitX.CreateRunner;
    // Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    // When true, Assertions must be made during tests
    runner.FailsOnNoAsserts := False;

    // Tell the runner how we will log things
    // Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    // Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    // Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    // We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
