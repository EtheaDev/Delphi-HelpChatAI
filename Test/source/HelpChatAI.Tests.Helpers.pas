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
  TEST_PROVIDER_UNCONFIGURED = 'test-unconfigured';
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

  /// <summary>An echo that always says it is not configured, as a real
  /// provider with no key does.</summary>
  TUnconfiguredProvider = class(TEchoProvider)
  public
    function GetName: string; override;
    class function ConfigurationIssue(const ASettings: THelpChatSettings): string; override;
  end;

/// <summary>Polls ACondition every 10 ms until True or ATimeoutMs elapsed.</summary>
function WaitFor(const ACondition: TFunc<Boolean>; const ATimeoutMs: Integer = 5000): Boolean;

/// <summary>Full path of a file in the Test\data folder, located by walking up
/// from the executable folder.</summary>
function TestDataFile(const AFileName: string): string;

/// <summary>A unique temp file name (not created).</summary>
function TempFileName(const AExt: string = '.json'): string;

/// <summary>Gives every published property of AObject that can be written a
/// value other than the one it has - strings, numbers, Booleans, enumerations,
/// sets - and goes into the published objects it holds (not into
/// collections, nor into the objects of another component). Events and the
/// names in ASkip are left alone. What a test of <c>Assign</c> fills the
/// source with, so that a property added later is checked too.</summary>
procedure FillPublishedProperties(const AObject: TObject; const ASkip: array of string);

/// <summary>The path of the first published property whose value differs
/// between A and B, going into the published objects they hold the way
/// <c>FillPublishedProperties</c> does; empty when none does.</summary>
function FirstPublishedDifference(const A, B: TObject; const ASkip: array of string): string;

implementation

uses
  System.IOUtils,
  System.Diagnostics,
  System.TypInfo,
  System.Variants,
  System.StrUtils;

function IsSkipped(const APath: string; const ASkip: array of string): Boolean;
var
  LName: string;
begin
  for LName in ASkip do
    if SameText(LName, APath) then
      Exit(True);
  Result := False;
end;

function NestedObject(const AObject: TObject; const AProp: PPropInfo): TObject;
begin
  Result := GetObjectProp(AObject, AProp);
  // A collection is compared by its own test; a component is a reference
  // (an image list, a container), not a part of the object.
  if (Result is TCollection) or (Result is TComponent) or not (Result is TPersistent) then
    Result := nil;
end;

procedure FillPublishedAt(const AObject: TObject; const APrefix: string;
  const ASkip: array of string; var ASeed: Integer);
var
  LList: PPropList;
  LCount, I: Integer;
  LProp: PPropInfo;
  LPath: string;
  LData: PTypeData;
  LNested: TObject;
begin
  LCount := GetPropList(AObject, LList);
  try
    for I := 0 to LCount - 1 do
    begin
      LProp := LList[I];
      LPath := APrefix + string(LProp.Name);
      if IsSkipped(LPath, ASkip) then
        Continue;
      Inc(ASeed);
      try
        case LProp.PropType^.Kind of
          tkClass:
            begin
              LNested := NestedObject(AObject, LProp);
              if Assigned(LNested) then
                FillPublishedAt(LNested, LPath + '.', ASkip, ASeed);
            end;
          tkUString, tkLString, tkWString, tkString:
            if Assigned(LProp.SetProc) then
              SetStrProp(AObject, LProp, 'v' + IntToStr(ASeed));
          tkInteger, tkInt64:
            if Assigned(LProp.SetProc) then
              SetOrdProp(AObject, LProp, GetOrdProp(AObject, LProp) + 3);
          tkFloat:
            if Assigned(LProp.SetProc) then
              SetFloatProp(AObject, LProp, GetFloatProp(AObject, LProp) + 1.5);
          tkEnumeration:
            if Assigned(LProp.SetProc) then
            begin
              LData := GetTypeData(LProp.PropType^);
              if GetOrdProp(AObject, LProp) = LData.MaxValue then
                SetOrdProp(AObject, LProp, LData.MinValue)
              else
                SetOrdProp(AObject, LProp, LData.MaxValue);
            end;
          tkSet:
            if Assigned(LProp.SetProc) then
              // The first member flipped: a set of any size has one.
              SetOrdProp(AObject, LProp, GetOrdProp(AObject, LProp) xor 1);
        end;
      except
        // A setter that refuses the value (a range, a format) keeps its own:
        // the comparison then finds both equal, which proves nothing but
        // breaks nothing either.
      end;
    end;
  finally
    FreeMem(LList);
  end;
end;

procedure FillPublishedProperties(const AObject: TObject; const ASkip: array of string);
var
  LSeed: Integer;
begin
  LSeed := 0;
  FillPublishedAt(AObject, '', ASkip, LSeed);
end;

function DifferenceAt(const A, B: TObject; const APrefix: string;
  const ASkip: array of string): string; forward;

function CollectionDifference(const A, B: TCollection; const APath: string;
  const ASkip: array of string): string;
var
  I: Integer;
begin
  if A.Count <> B.Count then
    Exit(Format('%s (%d <> %d items)', [APath, A.Count, B.Count]));
  for I := 0 to A.Count - 1 do
  begin
    Result := DifferenceAt(A.Items[I], B.Items[I], Format('%s[%d].', [APath, I]), ASkip);
    if Result <> '' then
      Exit;
  end;
  Result := '';
end;

function DifferenceAt(const A, B: TObject; const APrefix: string;
  const ASkip: array of string): string;
var
  LList: PPropList;
  LCount, I: Integer;
  LProp: PPropInfo;
  LPath: string;
  LNestedA, LNestedB: TObject;
begin
  Result := '';
  LCount := GetPropList(A, LList);
  try
    for I := 0 to LCount - 1 do
    begin
      LProp := LList[I];
      LPath := APrefix + string(LProp.Name);
      if IsSkipped(LPath, ASkip) or (LProp.PropType^.Kind = tkMethod) then
        Continue;
      if LProp.PropType^.Kind = tkClass then
      begin
        LNestedA := NestedObject(A, LProp);
        LNestedB := NestedObject(B, LProp);
        if Assigned(LNestedA) and Assigned(LNestedB) then
          Result := DifferenceAt(LNestedA, LNestedB, LPath + '.', ASkip)
        else if (GetObjectProp(A, LProp) is TCollection) and
                (GetObjectProp(B, LProp) is TCollection) then
          Result := CollectionDifference(TCollection(GetObjectProp(A, LProp)),
            TCollection(GetObjectProp(B, LProp)), LPath, ASkip)
        else if GetObjectProp(A, LProp) <> GetObjectProp(B, LProp) then
          Result := LPath;
      end
      else if GetPropValue(A, LProp, True) <> GetPropValue(B, LProp, True) then
        Result := Format('%s ("%s" <> "%s")', [LPath, VarToStr(GetPropValue(A, LProp, True)),
          VarToStr(GetPropValue(B, LProp, True))]);
      if Result <> '' then
        Exit;
    end;
  finally
    FreeMem(LList);
  end;
end;

function FirstPublishedDifference(const A, B: TObject; const ASkip: array of string): string;
begin
  Result := DifferenceAt(A, B, '', ASkip);
end;

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

{ TUnconfiguredProvider }

function TUnconfiguredProvider.GetName: string;
begin
  Result := TEST_PROVIDER_UNCONFIGURED;
end;

class function TUnconfiguredProvider.ConfigurationIssue(
  const ASettings: THelpChatSettings): string;
begin
  Result := 'No API key.';
end;

initialization
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_UNCONFIGURED, TUnconfiguredProvider);
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_ECHO, TEchoProvider);
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_SLOW, TSlowProvider);
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_FAIL, TFailingProvider);
  THelpChatProviderRegistry.RegisterProvider(TEST_PROVIDER_STUBBORN, TStubbornProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_UNCONFIGURED);
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_ECHO);
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_SLOW);
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_FAIL);
  THelpChatProviderRegistry.UnregisterProvider(TEST_PROVIDER_STUBBORN);

end.
