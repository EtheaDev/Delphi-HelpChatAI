{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Test helpers: fixture paths, polling waits, fake providers.            }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
unit HelpChatAI.Tests.Helpers;

interface

uses
  System.SysUtils,
  System.Classes,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider;

const
  TEST_PROVIDER_ECHO = 'test-echo';
  TEST_PROVIDER_SLOW = 'test-slow';
  TEST_PROVIDER_FAIL = 'test-fail';
  TEST_PROVIDER_STUBBORN = 'test-stubborn';
  TEST_SLOW_STEPS = 40;
  TEST_SLOW_STEP_MS = 20;
  TEST_STUBBORN_MS = 1500;

type
  /// <summary>Replies "echo:&lt;last user message&gt;|n=&lt;history length&gt;",
  /// streaming the reply character by character.</summary>
  TEchoProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function SupportsStreaming: Boolean; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  /// <summary>Emits one "x" token every TEST_SLOW_STEP_MS for TEST_SLOW_STEPS
  /// steps, honouring cancellation between steps.</summary>
  TSlowProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function SupportsStreaming: Boolean; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  /// <summary>Always raises.</summary>
  TFailingProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  /// <summary>Ignores cancellation and sleeps TEST_STUBBORN_MS: models a
  /// provider stuck in a network call during shutdown.</summary>
  TStubbornProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

/// <summary>Polls ACondition every 10 ms until True or ATimeoutMs elapsed.</summary>
function WaitFor(const ACondition: TFunc<Boolean>; const ATimeoutMs: Integer = 5000): Boolean;

/// <summary>Full path of a file in the Test\data folder, located by walking up
/// from the executable folder.</summary>
function TestDataFile(const AFileName: string): string;

/// <summary>A unique temp file name (not created).</summary>
function TempFileName(const AExt: string = '.json'): string;

implementation

uses
  System.IOUtils,
  System.Diagnostics;

function WaitFor(const ACondition: TFunc<Boolean>; const ATimeoutMs: Integer): Boolean;
var
  LWatch: TStopwatch;
begin
  LWatch := TStopwatch.StartNew;
  repeat
    if ACondition() then
      Exit(True);
    TThread.Sleep(10);
  until LWatch.ElapsedMilliseconds >= ATimeoutMs;
  Result := ACondition();
end;

function TestDataFile(const AFileName: string): string;
var
  LDir: string;
  I: Integer;
begin
  LDir := TPath.GetDirectoryName(ParamStr(0));
  for I := 1 to 6 do
  begin
    Result := TPath.Combine(TPath.Combine(LDir, 'data'), AFileName);
    if TFile.Exists(Result) then
      Exit;
    LDir := TPath.GetDirectoryName(LDir);
    if LDir = '' then
      Break;
  end;
  raise Exception.CreateFmt('Test data file not found: %s', [AFileName]);
end;

function TempFileName(const AExt: string): string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'helpchat-test-' + THelpChatMessage.NewId + AExt);
end;

{ TEchoProvider }

function TEchoProvider.GetName: string;
begin
  Result := TEST_PROVIDER_ECHO;
end;

function TEchoProvider.SupportsStreaming: Boolean;
begin
  Result := True;
end;

function TEchoProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
var
  C: Char;
begin
  Result := Format('echo:%s|n=%d', [LastUserMessage(AHistory), Length(AHistory)]);
  if Assigned(AOnToken) then
    for C in Result do
      AOnToken(C);
end;

{ TSlowProvider }

function TSlowProvider.GetName: string;
begin
  Result := TEST_PROVIDER_SLOW;
end;

function TSlowProvider.SupportsStreaming: Boolean;
begin
  Result := True;
end;

function TSlowProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to TEST_SLOW_STEPS do
  begin
    CheckCancelled(ACancel);
    TThread.Sleep(TEST_SLOW_STEP_MS);
    Result := Result + 'x';
    if Assigned(AOnToken) then
      AOnToken('x');
  end;
end;

{ TFailingProvider }

function TFailingProvider.GetName: string;
begin
  Result := TEST_PROVIDER_FAIL;
end;

function TFailingProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
begin
  raise Exception.Create('boom');
end;

{ TStubbornProvider }

function TStubbornProvider.GetName: string;
begin
  Result := TEST_PROVIDER_STUBBORN;
end;

function TStubbornProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
begin
  TThread.Sleep(TEST_STUBBORN_MS);
  Result := 'late';
end;

initialization
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_ECHO, TEchoProvider);
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_SLOW, TSlowProvider);
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_FAIL, TFailingProvider);
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_STUBBORN, TStubbornProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_ECHO);
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_SLOW);
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_FAIL);
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_STUBBORN);

end.
