{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       The slash commands of the panel: the enumeration, the names, which    }
{       ones an application enables, and the answers of the engine-side ones. }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{       you may not use this file except in compliance with the License.       }
{       You may obtain a copy of the License at                                }
{                                                                              }
{       http://www.apache.org/licenses/LICENSE-2.0                             }
{                                                                              }
{       Unless required by applicable law or agreed to in writing, software    }
{       distributed under the License is distributed on an "AS IS" BASIS,      }
{       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.}
{       See the License for the specific language governing permissions and    }
{       limitations under the License.                                         }
{                                                                              }
{******************************************************************************}
/// <summary>
///  A line that starts with "/" in the question box is a command, not a
///  question: it never reaches the model. <see cref="THelpChatCommand" /> lists
///  them all; <c>EnabledCommands</c> on the components (a set of this type,
///  <see cref="HELPCHAT_DEF_COMMANDS" /> by default: everything but
///  <c>prompt</c> and <c>run</c>) says which ones the panel accepts, and the
///  session of the server refuses the others. Some run in the page alone
///  (<see cref="HELPCHAT_COMMANDS_PAGE" />: a button pressed from the keyboard,
///  a switch of assistant); the others are answered here by
///  <see cref="HelpChatRunCommand" /> with an HTML fragment the page shows as a
///  system bubble - never stored, never part of the next prompt.
///  Adding a command: a member here, its name in <see cref="HelpChatCommandName" />,
///  its description in <c>HelpChatAI.Messages</c> (both languages), and either
///  a case in <see cref="HelpChatRunCommand" /> or a branch in <c>panel.js</c>
///  with the member in <see cref="HELPCHAT_COMMANDS_PAGE" />. Nothing else:
///  the components, the server and the page read the set.
/// </summary>
unit HelpChatAI.Commands;

interface

uses
  System.SysUtils,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Engine;

type
  /// <summary>Every command the panel knows. The name typed after the slash
  /// is <see cref="HelpChatCommandName" />.</summary>
  THelpChatCommand = (
    /// <summary>The enabled commands, with a line each.</summary>
    hccHelp,
    /// <summary>The assistant in use: name, model, provider, endpoint.</summary>
    hccWho,
    /// <summary>Switches to the named assistant (what the badge menu does).</summary>
    hccUse,
    /// <summary>Asks the last question again, to another assistant if named.</summary>
    hccRetry,
    /// <summary>The pages the retriever would ground an answer on.</summary>
    hccSearch,
    /// <summary>Opens a page of the documentation in the panel.</summary>
    hccDoc,
    /// <summary>The pages of the documentation index.</summary>
    hccPages,
    /// <summary>The screen context the host sent (what F1 knows).</summary>
    hccContext,
    /// <summary>The actions the application registered.</summary>
    hccActions,
    /// <summary>The configuration check of the engine, as the IDE shows it.</summary>
    hccCheck,
    /// <summary>Timing of the last answer.</summary>
    hccStats,
    /// <summary>Clears the conversation.</summary>
    hccClear,
    /// <summary>Saves the conversation as PDF.</summary>
    hccPdf,
    /// <summary>Copies the last answer.</summary>
    hccCopy,
    /// <summary>Attaches a file.</summary>
    hccAttach,
    /// <summary>The system prompt the last question went with, excerpts included.</summary>
    hccPrompt,
    /// <summary>Runs a registered action without the model, with the usual confirmation.</summary>
    hccRun);
  THelpChatCommands = set of THelpChatCommand;

  /// <summary>What the server needs to answer a command of the engine.</summary>
  THelpChatCommandRequest = record
    Command: THelpChatCommand;
    /// <summary>What followed the name on the line, trimmed.</summary>
    Args: string;
    ConversationKey: string;
    Context: THelpChatContext;
    Language: THelpChatLanguage;
    /// <summary>The commands enabled for the user: what <c>help</c> lists.</summary>
    Enabled: THelpChatCommands;
  end;

const
  /// <summary>What an application gets without saying anything: everything
  /// but <c>prompt</c> (it shows the context of the request) and <c>run</c>
  /// (it runs an action by hand).</summary>
  HELPCHAT_DEF_COMMANDS = [hccHelp..hccAttach];
  /// <summary>The commands the page answers by itself, without the server:
  /// the page knows the list of the assistants, the questions it sent, its
  /// own buttons and the timing of the answers.</summary>
  HELPCHAT_COMMANDS_PAGE =
    [hccHelp, hccUse, hccRetry, hccDoc, hccStats, hccClear, hccPdf, hccCopy, hccAttach];
  /// <summary>How many pages <c>/search</c> lists.</summary>
  HELPCHAT_CMD_SEARCH_PAGES = 5;

/// <summary>The word typed after the slash: "who", "use", "search"...</summary>
function HelpChatCommandName(const ACommand: THelpChatCommand): string;

/// <summary>The command named AName (case-insensitive, with or without the
/// slash); False for a word that is not one.</summary>
function HelpChatCommandByName(const AName: string; out ACommand: THelpChatCommand): Boolean;

/// <summary>One line, localized, for <c>/help</c> and the tooltips.</summary>
function HelpChatCommandDescription(const ACommand: THelpChatCommand;
  const ALanguage: THelpChatLanguage): string;

/// <summary>The first line of the answer, localized ("Available actions"),
/// without the " (/actions):" that follows it; a <c>%s</c> in it stands for
/// the arguments (the words of <c>/search</c>).</summary>
function HelpChatCommandTitle(const ACommand: THelpChatCommand;
  const ALanguage: THelpChatLanguage): string;

/// <summary>"Available actions (/actions):" - the heading every answer to a
/// command starts with, so that it is clear what it answers.</summary>
function HelpChatCommandHeading(const ACommand: THelpChatCommand; const AArgs: string;
  const ALanguage: THelpChatLanguage): string;

/// <summary>Every command as the page reads it: a JSON array of
/// <c>{name, title, description, local, enabled}</c>, in the order of the
/// enumeration. The page lets the user type the enabled ones; the host may
/// run any.</summary>
function HelpChatCommandsToJson(const AEnabled: THelpChatCommands;
  const ALanguage: THelpChatLanguage): string;

/// <summary>The commands as a comma-separated list of names, and back:
/// for a configuration file or a log line.</summary>
function HelpChatCommandsToText(const ACommands: THelpChatCommands): string;
function HelpChatCommandsFromText(const AText: string): THelpChatCommands;

/// <summary>Splits "/name the rest" into the command and its arguments.
/// False when the line is not a command at all (no leading slash) or names
/// one that does not exist.</summary>
function HelpChatParseCommandLine(const ALine: string; out ACommand: THelpChatCommand;
  out AArgs: string): Boolean;

/// <summary>Answers a command of the engine with the HTML of a system
/// bubble. A command of <see cref="HELPCHAT_COMMANDS_PAGE" /> answers with
/// its description: the page should not have asked. Never raises: an
/// error becomes a sentence.</summary>
function HelpChatRunCommand(const AEngine: THelpChatEngine;
  const ARequest: THelpChatCommandRequest): string;

/// <summary>The same answer as plain text, for an application that asks
/// from code (<c>ExplainCommand</c> of the components): the heading, then
/// one line per item. <c>run</c> is not run here - the action would wait for
/// the main thread that is asking - and answers with its usage.</summary>
function HelpChatCommandText(const AEngine: THelpChatEngine;
  const ARequest: THelpChatCommandRequest): string;

/// <summary>HTML of an answer reduced to text: paragraphs and list items on
/// lines of their own, items with "- ", entities decoded.</summary>
function HelpChatCommandHtmlToText(const AHtml: string): string;

implementation

uses
  System.StrUtils,
  System.JSON,
  System.NetEncoding,
  System.Generics.Collections,
  System.RegularExpressions,
  HelpChatAI.Settings,
  HelpChatAI.DocIndex,
  HelpChatAI.Html,
  HelpChatAI.Actions,
  HelpChatAI.Provider,
  HelpChatAI.Diagnostics;

const
  // The order of THelpChatCommand.
  CommandNames: array[THelpChatCommand] of string = (
    'help', 'who', 'use', 'retry', 'search', 'doc', 'pages', 'context', 'actions',
    'check', 'stats', 'clear', 'pdf', 'copy', 'attach', 'prompt', 'run');
  CommandDescriptions: array[THelpChatCommand] of THelpChatMsgId = (
    hcmCmdHelp, hcmCmdWho, hcmCmdUse, hcmCmdRetry, hcmCmdSearch, hcmCmdDoc, hcmCmdPages,
    hcmCmdContext, hcmCmdActions, hcmCmdCheck, hcmCmdStats, hcmCmdClear, hcmCmdPdf,
    hcmCmdCopy, hcmCmdAttach, hcmCmdPrompt, hcmCmdRun);
  // A command that only does something (clear, pdf...) has no answer to head:
  // its description stands in.
  CommandTitles: array[THelpChatCommand] of THelpChatMsgId = (
    hcmCmdTitleHelp, hcmCmdTitleWho, hcmCmdTitleUse, hcmCmdRetry, hcmCmdTitleSearch,
    hcmCmdDoc, hcmCmdTitlePages, hcmCmdTitleContext, hcmCmdTitleActions, hcmCmdTitleCheck,
    hcmCmdTitleStats, hcmCmdClear, hcmCmdPdf, hcmCmdCopy, hcmCmdAttach,
    hcmCmdTitlePrompt, hcmCmdTitleRun);

function HelpChatCommandName(const ACommand: THelpChatCommand): string;
begin
  Result := CommandNames[ACommand];
end;

function HelpChatCommandByName(const AName: string; out ACommand: THelpChatCommand): Boolean;
var
  LName: string;
  C: THelpChatCommand;
begin
  LName := Trim(AName).TrimLeft(['/']).ToLower;
  for C := Low(THelpChatCommand) to High(THelpChatCommand) do
    if CommandNames[C] = LName then
    begin
      ACommand := C;
      Exit(True);
    end;
  Result := False;
end;

function HelpChatCommandDescription(const ACommand: THelpChatCommand;
  const ALanguage: THelpChatLanguage): string;
begin
  Result := HelpChatMsg(CommandDescriptions[ACommand], ALanguage);
end;

function HelpChatCommandTitle(const ACommand: THelpChatCommand;
  const ALanguage: THelpChatLanguage): string;
begin
  Result := HelpChatMsg(CommandTitles[ACommand], ALanguage);
end;

function HelpChatCommandHeading(const ACommand: THelpChatCommand; const AArgs: string;
  const ALanguage: THelpChatLanguage): string;
begin
  Result := HelpChatCommandTitle(ACommand, ALanguage);
  if Result.Contains('%s') then
    Result := Result.Replace('%s', AArgs);
  Result := Result + ' (/' + CommandNames[ACommand] + '):';
end;

function HelpChatCommandsToJson(const AEnabled: THelpChatCommands;
  const ALanguage: THelpChatLanguage): string;
var
  LArray: TJSONArray;
  LItem: TJSONObject;
  C: THelpChatCommand;
begin
  LArray := TJSONArray.Create;
  try
    for C := Low(THelpChatCommand) to High(THelpChatCommand) do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('name', CommandNames[C]);
      LItem.AddPair('title', HelpChatCommandTitle(C, ALanguage));
      LItem.AddPair('description', HelpChatCommandDescription(C, ALanguage));
      LItem.AddPair('local', TJSONBool.Create(C in HELPCHAT_COMMANDS_PAGE));
      LItem.AddPair('enabled', TJSONBool.Create(C in AEnabled));
      LArray.Add(LItem);
    end;
    Result := LArray.ToJSON;
  finally
    LArray.Free;
  end;
end;

function HelpChatCommandsToText(const ACommands: THelpChatCommands): string;
var
  C: THelpChatCommand;
begin
  Result := '';
  for C := Low(THelpChatCommand) to High(THelpChatCommand) do
    if C in ACommands then
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + CommandNames[C];
    end;
end;

function HelpChatCommandsFromText(const AText: string): THelpChatCommands;
var
  LPart: string;
  C: THelpChatCommand;
begin
  Result := [];
  for LPart in AText.Split([',', ';', ' '], TStringSplitOptions.ExcludeEmpty) do
    if HelpChatCommandByName(LPart, C) then
      Include(Result, C);
end;

function HelpChatParseCommandLine(const ALine: string; out ACommand: THelpChatCommand;
  out AArgs: string): Boolean;
var
  LLine, LName: string;
  LSpace: Integer;
begin
  Result := False;
  AArgs := '';
  LLine := Trim(ALine);
  if (LLine = '') or (LLine[1] <> '/') then
    Exit;
  LSpace := LLine.IndexOfAny([' ', #9]);
  if LSpace < 0 then
    LName := LLine
  else
  begin
    LName := LLine.Substring(0, LSpace);
    AArgs := Trim(LLine.Substring(LSpace + 1));
  end;
  Result := HelpChatCommandByName(LName, ACommand);
end;

{ The answers }

function Esc(const AText: string): string;
begin
  Result := TNetEncoding.HTML.Encode(AText);
end;

function Line(const AText: string): string;
begin
  Result := '<p>' + Esc(AText) + '</p>';
end;

function Heading(const ARequest: THelpChatCommandRequest; const AArgs: string = ''): string;
begin
  Result := '<p class="hc-chat-cmd-title"><b>' +
    Esc(HelpChatCommandHeading(ARequest.Command, AArgs, ARequest.Language)) + '</b></p>';
end;

function AnswerHelp(const ARequest: THelpChatCommandRequest): string;
var
  C: THelpChatCommand;
begin
  Result := '<ul>';
  for C := Low(THelpChatCommand) to High(THelpChatCommand) do
    if C in ARequest.Enabled then
      Result := Result + '<li><code>/' + Esc(CommandNames[C]) + '</code> - ' +
        Esc(HelpChatCommandDescription(C, ARequest.Language)) + '</li>';
  Result := Result + '</ul>';
end;

function PageLink(const ATitle, AUrl: string): string;
begin
  // A relative .md link opens in the documentation view of the panel, the
  // way a link in an answer does; the page lets nothing else navigate it.
  Result := '<a href="' + Esc(AUrl) + '">' + Esc(ATitle) + '</a>';
end;

function LastQuestion(const AEngine: THelpChatEngine; const AKey: string): string;
var
  LMessages: TArray<THelpChatMessage>;
  I: Integer;
begin
  Result := '';
  LMessages := AEngine.Messages(AKey);
  for I := High(LMessages) downto 0 do
    if LMessages[I].Role = hcrUser then
      Exit(LMessages[I].Content);
end;

function AnswerWho(const AEngine: THelpChatEngine; const ALang: THelpChatLanguage): string;
var
  LInfo: THelpChatAssistantInfo;
begin
  LInfo := AEngine.ActiveAssistant;
  Result := '<p><b>' + Esc(LInfo.Name) + '</b>';
  if LInfo.Model <> '' then
    Result := Result + ' &middot; ' + Esc(LInfo.Model);
  Result := Result + '</p>';
  Result := Result + Line(Format('%s: %s', [HelpChatMsg(hcmCmdProvider, ALang), LInfo.Provider]));
  if LInfo.BaseUrl <> '' then
    Result := Result + Line(Format('%s: %s', [HelpChatMsg(hcmCmdEndpoint, ALang), LInfo.BaseUrl]));
end;

function AnswerSearch(const AEngine: THelpChatEngine; const ARequest: THelpChatCommandRequest): string;
var
  LQuery: string;
  LPages: TArray<THelpChatDocPage>;
  LPage: THelpChatDocPage;
begin
  if not Assigned(AEngine.DocIndex) or (AEngine.DocIndex.Count = 0) then
    Exit(Line(HelpChatMsg(hcmCmdNoIndex, ARequest.Language)));
  LQuery := ARequest.Args;
  if LQuery = '' then
    LQuery := LastQuestion(AEngine, ARequest.ConversationKey);
  if LQuery = '' then
    Exit(Line(HelpChatMsg(hcmCmdNoQuestion, ARequest.Language)));
  LPages := AEngine.DocIndex.Search(LQuery, ARequest.Context.SearchHint, HELPCHAT_CMD_SEARCH_PAGES);
  if Length(LPages) = 0 then
    Exit(Line(Format(HelpChatMsg(hcmCmdNoResults, ARequest.Language), [LQuery])));
  Result := '<ol>';
  for LPage in LPages do
  begin
    Result := Result + '<li>' + PageLink(LPage.Title, LPage.Url);
    if LPage.Summary <> '' then
      Result := Result + ' - ' + Esc(LPage.Summary);
    Result := Result + '</li>';
  end;
  Result := Result + '</ol>';
end;

function AnswerPages(const AEngine: THelpChatEngine; const ALang: THelpChatLanguage): string;
var
  LPages: TArray<THelpChatDocPage>;
  LPage: THelpChatDocPage;
begin
  if not Assigned(AEngine.DocIndex) or (AEngine.DocIndex.Count = 0) then
    Exit(Line(HelpChatMsg(hcmCmdNoIndex, ALang)));
  LPages := AEngine.DocIndex.Pages;
  Result := '<ul>';
  for LPage in LPages do
    Result := Result + '<li>' + PageLink(LPage.Title, LPage.Url) + '</li>';
  Result := Result + '</ul>';
end;

function AnswerContext(const ARequest: THelpChatCommandRequest): string;
var
  LCtx: THelpChatContext;
begin
  LCtx := ARequest.Context;
  if LCtx.IsEmpty then
    Exit(Line(HelpChatMsg(hcmCmdNoContext, ARequest.Language)));
  Result := '<ul>';
  if LCtx.ScreenLabel <> '' then
    Result := Result + '<li>' + Esc('ScreenLabel: ' + LCtx.ScreenLabel) + '</li>';
  if LCtx.ScreenName <> '' then
    Result := Result + '<li>' + Esc('ScreenName: ' + LCtx.ScreenName) + '</li>';
  if LCtx.ScreenType <> '' then
    Result := Result + '<li>' + Esc('ScreenType: ' + LCtx.ScreenType) + '</li>';
  if LCtx.HelpKeyword <> '' then
    Result := Result + '<li>' + Esc('HelpKeyword: ' + LCtx.HelpKeyword) + '</li>';
  if LCtx.HelpContext <> 0 then
    Result := Result + '<li>' + Esc('HelpContext: ' + IntToStr(LCtx.HelpContext)) + '</li>';
  if LCtx.FocusedControl <> '' then
    Result := Result + '<li>' + Esc('FocusedControl: ' + LCtx.FocusedControl) + '</li>';
  if LCtx.UserName <> '' then
    Result := Result + '<li>' + Esc('UserName: ' + LCtx.UserName) + '</li>';
  Result := Result + '</ul>';
end;

function AnswerActions(const AEngine: THelpChatEngine; const ALang: THelpChatLanguage): string;
var
  LValue: TJSONValue;
  LTool, LSchema, LProps, LParam: TJSONObject;
  LRequired: TJSONArray;
  LPair: TJSONPair;
  LItem: TJSONValue;
  LLine: string;
begin
  if not Assigned(AEngine.Actions) or not AEngine.Actions.HasActions then
    Exit(Line(HelpChatMsg(hcmCmdNoActions, ALang)));
  LValue := TJSONObject.ParseJSONValue(AEngine.Actions.ToolsJson);
  try
    if not (LValue is TJSONArray) then
      Exit(Line(HelpChatMsg(hcmCmdNoActions, ALang)));
    Result := '<ul>';
    for LItem in TJSONArray(LValue) do
    begin
      if not (LItem is TJSONObject) then
        Continue;
      LTool := TJSONObject(LItem);
      LLine := '<li><b>' + Esc(LTool.GetValue<string>('name', '')) + '</b>';
      if LTool.GetValue<string>('description', '') <> '' then
        LLine := LLine + ' - ' + Esc(LTool.GetValue<string>('description', ''));
      LSchema := LTool.GetValue<TJSONObject>('input_schema', nil);
      if LSchema <> nil then
      begin
        LProps := LSchema.GetValue<TJSONObject>('properties', nil);
        LRequired := LSchema.GetValue<TJSONArray>('required', nil);
        if (LProps <> nil) and (LProps.Count > 0) then
        begin
          LLine := LLine + '<ul>';
          for LPair in LProps do
          begin
            LParam := LPair.JsonValue as TJSONObject;
            LLine := LLine + '<li><code>' + Esc(LPair.JsonString.Value) + '</code>';
            if (LRequired <> nil) and (LRequired.ToString.Contains('"' + LPair.JsonString.Value + '"')) then
              LLine := LLine + ' *';
            if LParam.GetValue<string>('description', '') <> '' then
              LLine := LLine + ' - ' + Esc(LParam.GetValue<string>('description', ''));
            LLine := LLine + '</li>';
          end;
          LLine := LLine + '</ul>';
        end;
      end;
      Result := Result + LLine + '</li>';
    end;
    Result := Result + '</ul>';
  finally
    LValue.Free;
  end;
end;

function AnswerCheck(const AEngine: THelpChatEngine): string;
begin
  // The same report the IDE shows, with the same words: it is not localized
  // (see HelpChatAI.Diagnostics), and that is fine for a report a user pastes
  // into a message to the developer.
  Result := HelpChatTextToHtml(HelpChatIssuesToText(HelpChatCheckSettings(AEngine.Settings)));
end;

function AnswerPrompt(const AEngine: THelpChatEngine; const ARequest: THelpChatCommandRequest): string;
var
  LHistory: TArray<THelpChatMessage>;
  LPrompt: string;
begin
  LHistory := AEngine.Messages(ARequest.ConversationKey);
  if LastQuestion(AEngine, ARequest.ConversationKey) = '' then
    Exit(Line(HelpChatMsg(hcmCmdNoQuestion, ARequest.Language)));
  // Rebuilt the way the provider builds it, for the last question and the
  // screen of now: the excerpts the retriever picks are the same.
  LPrompt := THelpChatProviderBase.BuildSystemPrompt(LHistory, ARequest.Context,
    AEngine.Settings, AEngine.Retriever);
  if Assigned(AEngine.Actions) and AEngine.Actions.HasActions then
    LPrompt := LPrompt + sLineBreak + sLineBreak + HELPCHAT_MODEL_ACTIONS_RULE;
  Result := '<pre class="hc-chat-prompt">' + Esc(LPrompt) + '</pre>';
end;

/// <summary>"name k=v k2="v with spaces"" -> the action and its arguments as
/// the JSON the broker takes.</summary>
function ParseRunArgs(const AArgs: string; out AName, AJson: string): Boolean;
var
  I: Integer;
  LTokens: TList<string>;
  LToken: string;
  LInQuote: Boolean;
  LRoot: TJSONObject;
  LEq: Integer;
begin
  Result := False;
  AName := '';
  AJson := '{}';
  LTokens := TList<string>.Create;
  try
    LToken := '';
    LInQuote := False;
    for I := 1 to Length(AArgs) do
    begin
      if AArgs[I] = '"' then
        LInQuote := not LInQuote
      else if (AArgs[I] = ' ') and not LInQuote then
      begin
        if LToken <> '' then
          LTokens.Add(LToken);
        LToken := '';
      end
      else
        LToken := LToken + AArgs[I];
    end;
    if LToken <> '' then
      LTokens.Add(LToken);
    if LTokens.Count = 0 then
      Exit;
    AName := LTokens[0];
    LRoot := TJSONObject.Create;
    try
      for I := 1 to LTokens.Count - 1 do
      begin
        LEq := LTokens[I].IndexOf('=');
        if LEq <= 0 then
          Exit;
        LRoot.AddPair(LTokens[I].Substring(0, LEq), LTokens[I].Substring(LEq + 1));
      end;
      AJson := LRoot.ToJSON;
    finally
      LRoot.Free;
    end;
    Result := True;
  finally
    LTokens.Free;
  end;
end;

function AnswerRun(const AEngine: THelpChatEngine; const ARequest: THelpChatCommandRequest): string;
var
  LName, LJson, LResult: string;
  LOutcome: THelpChatActionOutcome;
begin
  if not Assigned(AEngine.Actions) or not AEngine.Actions.HasActions then
    Exit(Line(HelpChatMsg(hcmCmdNoActions, ARequest.Language)));
  if not ParseRunArgs(ARequest.Args, LName, LJson) then
    Exit(Line(HelpChatMsg(hcmCmdRunUsage, ARequest.Language)));
  // The same path the model takes, confirmation included: the host runs it
  // on its main thread while this request waits.
  LOutcome := AEngine.Actions.Invoke(LName, LJson, nil, LResult);
  Result := HelpChatTextToHtml(HelpChatActionOutcomeText(LOutcome, LName, LResult));
end;

function SearchQuery(const AEngine: THelpChatEngine; const ARequest: THelpChatCommandRequest): string;
begin
  Result := ARequest.Args;
  if (Result = '') and Assigned(AEngine) then
    Result := LastQuestion(AEngine, ARequest.ConversationKey);
end;

function HelpChatRunCommand(const AEngine: THelpChatEngine;
  const ARequest: THelpChatCommandRequest): string;
begin
  try
    if not Assigned(AEngine) then
      Exit(Line(HelpChatMsg(hcmCmdNoEngine, ARequest.Language)));
    // What it answers first, then the answer: "Available actions (/actions):".
    if ARequest.Command = hccSearch then
      Result := Heading(ARequest, SearchQuery(AEngine, ARequest))
    else if ARequest.Command = hccRun then
      Result := Heading(ARequest, '')
    else
      Result := Heading(ARequest);
    case ARequest.Command of
      hccHelp: Result := Result + AnswerHelp(ARequest);
      hccWho: Result := Result + AnswerWho(AEngine, ARequest.Language);
      hccSearch: Result := Result + AnswerSearch(AEngine, ARequest);
      hccPages: Result := Result + AnswerPages(AEngine, ARequest.Language);
      hccContext: Result := Result + AnswerContext(ARequest);
      hccActions: Result := Result + AnswerActions(AEngine, ARequest.Language);
      hccCheck: Result := Result + AnswerCheck(AEngine);
      hccPrompt: Result := Result + AnswerPrompt(AEngine, ARequest);
      hccRun: Result := Result + AnswerRun(AEngine, ARequest);
    else
      // A command of the page: what it does, since there is nothing to show.
      Result := Line('/' + HelpChatCommandName(ARequest.Command) + ' - ' +
        HelpChatCommandDescription(ARequest.Command, ARequest.Language));
    end;
  except
    on E: Exception do
      Result := Line(E.Message);
  end;
end;

function HelpChatCommandHtmlToText(const AHtml: string): string;
var
  LText: string;
  LLines: TArray<string>;
  LLine: string;
begin
  LText := AHtml;
  LText := TRegEx.Replace(LText, '<li[^>]*>', #10'- ', [roIgnoreCase]);
  LText := TRegEx.Replace(LText, '</(p|li|ul|ol|pre)>|<br\s*/?>', #10, [roIgnoreCase]);
  LText := TRegEx.Replace(LText, '<(ul|ol)[^>]*>', #10, [roIgnoreCase]);
  LText := TRegEx.Replace(LText, '<[^>]+>', '');
  LText := TNetEncoding.HTML.Decode(LText).Replace('&middot;', '·');
  Result := '';
  LLines := LText.Replace(#13, '').Split([#10]);
  for LLine in LLines do
    if Trim(LLine) <> '' then
      Result := Result + TrimRight(LLine) + sLineBreak;
  Result := TrimRight(Result);
end;

function HelpChatCommandText(const AEngine: THelpChatEngine;
  const ARequest: THelpChatCommandRequest): string;
begin
  if ARequest.Command = hccRun then
    Exit(HelpChatCommandHeading(hccRun, '', ARequest.Language) + sLineBreak +
      HelpChatMsg(hcmCmdRunUsage, ARequest.Language));
  Result := HelpChatCommandHtmlToText(HelpChatRunCommand(AEngine, ARequest));
end;

end.
