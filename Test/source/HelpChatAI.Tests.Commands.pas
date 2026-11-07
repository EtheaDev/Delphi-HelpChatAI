{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Tests of the slash commands: names, the default set, and the answers   }
{       of the engine-side ones.                                               }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
unit HelpChatAI.Tests.Commands;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Engine,
  HelpChatAI.Actions,
  HelpChatAI.Commands;

type
  [TestFixture]
  TCommandsTests = class
  strict private
    FSettings: THelpChatSettings;
    FEngine: THelpChatEngine;
    FBroker: THelpChatActionBroker;
    FInvoker: IHelpChatActionInvoker;
    FRan: string;
    function Run(const ACommand: THelpChatCommand; const AArgs: string = '';
      const AScreen: string = ''): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Names_AreUniqueLowercase_AndRoundTrip;
    [Test] procedure Default_IsEverythingButPromptAndRun;
    [Test] procedure Json_ListsOnlyTheEnabled_InOrder_WithLocal;
    [Test] procedure ParseLine_SplitsNameAndArgs;
    [Test] procedure Who_NamesTheActiveAssistant;
    [Test] procedure Search_And_Pages_LinkThePages;
    [Test] procedure Context_ListsWhatTheHostSent;
    [Test] procedure Actions_ListsTheRegisteredOnes;
    [Test] procedure Check_IsTheDiagnostics;
    [Test] procedure Prompt_IsTheSystemPromptOfTheLastQuestion;
    [Test] procedure Run_InvokesTheAction_WithTheArguments;
    [Test] procedure APageCommand_AnswersWithItsDescription;
    [Test] procedure Descriptions_ExistInBothLanguages;
    [Test] procedure EveryAnswer_StartsWithItsHeading;
    [Test] procedure Help_ListsTheEnabled;
    [Test] procedure Text_IsTheHeadingThenTheLines;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  HelpChatAI.Messages,
  HelpChatAI.Tests.Helpers;

procedure TCommandsTests.Setup;
begin
  FSettings := THelpChatSettings.Create;
  FSettings.Language := hclEnglish;
  FSettings.PersistConversation := False;
  FSettings.Provider := TEST_PROVIDER_ECHO;
  FSettings.DocIndexFile := TestDataFile('help-index.json');
  FEngine := THelpChatEngine.Create(FSettings);
  FBroker := THelpChatActionBroker.Create;
  FInvoker := FBroker;
  FRan := '';
  FBroker.Add('open_screen', 'Brings a screen to the front.',
    [THelpChatActionParam.Create('name', 'Screen name')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      FRan := 'open_screen(' + AArgs.AsString('name') + ')';
      AResult := 'Opened ' + AArgs.AsString('name');
    end, False);
  FEngine.Actions := FInvoker;
  FEngine.Start;
end;

procedure TCommandsTests.TearDown;
begin
  FEngine.Free;
  FInvoker := nil;
  FSettings.Free;
end;

function TCommandsTests.Run(const ACommand: THelpChatCommand; const AArgs: string;
  const AScreen: string): string;
var
  LRequest: THelpChatCommandRequest;
begin
  LRequest := Default(THelpChatCommandRequest);
  LRequest.Command := ACommand;
  LRequest.Args := AArgs;
  LRequest.ConversationKey := FEngine.ConversationKey;
  LRequest.Language := hclEnglish;
  LRequest.Context.ScreenLabel := AScreen;
  if AScreen <> '' then
    LRequest.Context.ScreenType := 'TOrdersForm';
  Result := HelpChatRunCommand(FEngine, LRequest);
end;

procedure TCommandsTests.Names_AreUniqueLowercase_AndRoundTrip;
var
  C, D: THelpChatCommand;
  LName: string;
begin
  for C := Low(THelpChatCommand) to High(THelpChatCommand) do
  begin
    LName := HelpChatCommandName(C);
    Assert.AreEqual(LName.ToLower, LName, 'lowercase: ' + LName);
    Assert.IsFalse(LName.Contains(' '), LName);
    Assert.IsTrue(HelpChatCommandByName(LName, D), LName);
    Assert.AreEqual(Ord(C), Ord(D), LName);
    Assert.IsTrue(HelpChatCommandByName('/' + LName.ToUpper, D), 'with the slash, any case');
    Assert.AreEqual(Ord(C), Ord(D));
  end;
  Assert.IsFalse(HelpChatCommandByName('nothing', D));
  Assert.IsFalse(HelpChatCommandByName('', D));
  Assert.AreEqual('who,use,run', HelpChatCommandsToText([hccWho, hccUse, hccRun]));
  Assert.IsTrue(HelpChatCommandsFromText('who, RUN;nothing use') = [hccWho, hccUse, hccRun]);
end;

procedure TCommandsTests.Default_IsEverythingButPromptAndRun;
var
  C: THelpChatCommand;
begin
  for C := Low(THelpChatCommand) to High(THelpChatCommand) do
    if C in [hccPrompt, hccRun] then
      Assert.IsFalse(C in HELPCHAT_DEF_COMMANDS, HelpChatCommandName(C))
    else
      Assert.IsTrue(C in HELPCHAT_DEF_COMMANDS, HelpChatCommandName(C));
  Assert.IsTrue(HELPCHAT_COMMANDS_PAGE <= HELPCHAT_DEF_COMMANDS, 'the page ones are on by default');
  Assert.IsFalse(hccWho in HELPCHAT_COMMANDS_PAGE, 'who is the engine''s');
end;

procedure TCommandsTests.Json_ListsOnlyTheEnabled_InOrder_WithLocal;
var
  LJson: string;
begin
  // Every command is listed - the host may run any - and "enabled" says
  // which ones the user may type.
  LJson := HelpChatCommandsToJson([hccRun, hccWho, hccClear], hclEnglish);
  Assert.IsTrue(LJson.StartsWith('[{"name":"help","title":"Available commands","description":"' +
    HelpChatMsg(hcmCmdHelp, hclEnglish) + '","local":true,"enabled":false},' +
    '{"name":"who","title":"Assistant in use","description":"' + HelpChatMsg(hcmCmdWho, hclEnglish) +
    '","local":false,"enabled":true}'), LJson);
  Assert.IsTrue(LJson.Contains('{"name":"clear","title":"' + HelpChatMsg(hcmCmdClear, hclEnglish) +
    '","description":"' + HelpChatMsg(hcmCmdClear, hclEnglish) + '","local":true,"enabled":true}'), LJson);
  Assert.IsTrue(LJson.EndsWith('"local":false,"enabled":true}]'), 'run, last and enabled: ' + LJson);
  Assert.IsFalse(HelpChatCommandsToJson([], hclEnglish).Contains('"enabled":true'));
end;

procedure TCommandsTests.EveryAnswer_StartsWithItsHeading;
begin
  Assert.IsTrue(Run(hccActions).StartsWith(
    '<p class="hc-chat-cmd-title"><b>Available actions (/actions):</b></p>'), Run(hccActions));
  Assert.IsTrue(Run(hccWho).StartsWith(
    '<p class="hc-chat-cmd-title"><b>Assistant in use (/who):</b></p>'));
  Assert.IsTrue(Run(hccSearch, 'export').StartsWith(
    '<p class="hc-chat-cmd-title"><b>Documentation pages for &quot;export&quot; (/search):</b></p>'),
    Run(hccSearch, 'export'));
  Assert.IsTrue(Run(hccPages).StartsWith(
    '<p class="hc-chat-cmd-title"><b>Documentation pages (/pages):</b></p>'));
  Assert.IsTrue(Run(hccContext).StartsWith(
    '<p class="hc-chat-cmd-title"><b>Screen context (/context):</b></p>'));
  Assert.IsTrue(Run(hccCheck).StartsWith(
    '<p class="hc-chat-cmd-title"><b>Configuration check (/check):</b></p>'));
  Assert.AreEqual('Azioni disponibili (/actions):', HelpChatCommandHeading(hccActions, '', hclItalian));
end;

procedure TCommandsTests.Help_ListsTheEnabled;
var
  LRequest: THelpChatCommandRequest;
  LHtml: string;
begin
  LRequest := Default(THelpChatCommandRequest);
  LRequest.Command := hccHelp;
  LRequest.Language := hclEnglish;
  LRequest.Enabled := [hccWho, hccSearch];
  LHtml := HelpChatRunCommand(FEngine, LRequest);
  Assert.IsTrue(LHtml.Contains('<b>Available commands (/help):</b>'), LHtml);
  Assert.IsTrue(LHtml.Contains('<code>/who</code>'), LHtml);
  Assert.IsTrue(LHtml.Contains('<code>/search</code>'), LHtml);
  Assert.IsFalse(LHtml.Contains('<code>/run</code>'), LHtml);
end;

procedure TCommandsTests.Text_IsTheHeadingThenTheLines;
var
  LRequest: THelpChatCommandRequest;
  LText: string;
  LLines: TArray<string>;
begin
  LRequest := Default(THelpChatCommandRequest);
  LRequest.Command := hccActions;
  LRequest.Language := hclEnglish;
  LText := HelpChatCommandText(FEngine, LRequest);
  LLines := LText.Split([sLineBreak]);
  Assert.AreEqual('Available actions (/actions):', LLines[0]);
  Assert.AreEqual('- open_screen - Brings a screen to the front.', LLines[1]);
  Assert.AreEqual('- name * - Screen name', LLines[2]);
  // run is never run from here: the action would wait for this very thread.
  LRequest.Command := hccRun;
  LRequest.Args := 'open_screen name=Leads';
  LText := HelpChatCommandText(FEngine, LRequest);
  Assert.IsTrue(LText.StartsWith('Action run (/run):'), LText);
  Assert.AreEqual('', FRan);
  Assert.AreEqual('A &amp; b'.Replace('&amp;', '&'), HelpChatCommandHtmlToText('<p>A &amp; b</p>'));
end;

procedure TCommandsTests.ParseLine_SplitsNameAndArgs;
var
  C: THelpChatCommand;
  LArgs: string;
begin
  Assert.IsTrue(HelpChatParseCommandLine('/search  export the grid ', C, LArgs));
  Assert.AreEqual(Ord(hccSearch), Ord(C));
  Assert.AreEqual('export the grid', LArgs);
  Assert.IsTrue(HelpChatParseCommandLine('/WHO', C, LArgs));
  Assert.AreEqual(Ord(hccWho), Ord(C));
  Assert.AreEqual('', LArgs);
  Assert.IsFalse(HelpChatParseCommandLine('who', C, LArgs), 'no slash: a question');
  Assert.IsFalse(HelpChatParseCommandLine('/nothing here', C, LArgs));
  Assert.IsFalse(HelpChatParseCommandLine('', C, LArgs));
end;

procedure TCommandsTests.Who_NamesTheActiveAssistant;
var
  LHtml: string;
begin
  LHtml := Run(hccWho);
  Assert.IsTrue(LHtml.Contains('<b>' + TEST_PROVIDER_ECHO + '</b>'), LHtml);
  Assert.IsTrue(LHtml.Contains('Provider: ' + TEST_PROVIDER_ECHO), LHtml);
  with FSettings.Assistants.Add do
  begin
    Name := 'Local <one>';
    Provider := 'openai';
    Model := 'gemma4:12b';
    BaseUrl := 'http://localhost:11434/v1';
  end;
  FEngine.SelectAssistant('Local <one>');
  LHtml := Run(hccWho);
  Assert.IsTrue(LHtml.Contains('<b>Local &lt;one&gt;</b> &middot; gemma4:12b'), 'escaped: ' + LHtml);
  Assert.IsTrue(LHtml.Contains('Endpoint: http://localhost:11434/v1'), LHtml);
end;

procedure TCommandsTests.Search_And_Pages_LinkThePages;
var
  LHtml: string;
begin
  LHtml := Run(hccSearch, 'how do I export the grid?');
  Assert.IsTrue(LHtml.Contains('Documentation pages for &quot;how do I export the grid?&quot; (/search):'), LHtml);
  Assert.IsTrue(LHtml.Contains('<a href="grid/export.html">Exporting the grid</a>'), LHtml);

  // No words: the last question of the conversation.
  Assert.IsTrue(Run(hccSearch).Contains('No question yet.'));
  FEngine.Send('export the grid');
  Assert.IsTrue(Run(hccSearch).Contains('Exporting the grid'));

  LHtml := Run(hccPages);
  Assert.IsTrue(LHtml.Contains('Documentation pages (/pages):'), LHtml);
  Assert.IsTrue(LHtml.Contains('<li><a href="grid/export.html">Exporting the grid</a></li>'), LHtml);
end;

procedure TCommandsTests.Context_ListsWhatTheHostSent;
var
  LHtml: string;
begin
  Assert.IsTrue(Run(hccContext).Contains('No screen context was sent.'));
  LHtml := Run(hccContext, '', 'Orders <Q3>');
  Assert.IsTrue(LHtml.Contains('<li>ScreenLabel: Orders &lt;Q3&gt;</li>'), LHtml);
  Assert.IsTrue(LHtml.Contains('<li>ScreenType: TOrdersForm</li>'), LHtml);
end;

procedure TCommandsTests.Actions_ListsTheRegisteredOnes;
var
  LHtml: string;
begin
  LHtml := Run(hccActions);
  Assert.IsTrue(LHtml.Contains('<b>open_screen</b> - Brings a screen to the front.'), LHtml);
  Assert.IsTrue(LHtml.Contains('<code>name</code> * - Screen name'), 'required marked: ' + LHtml);
  FEngine.Actions := nil;
  Assert.IsTrue(Run(hccActions).Contains('This application registered no actions.'));
end;

procedure TCommandsTests.Check_IsTheDiagnostics;
var
  LHtml: string;
begin
  LHtml := Run(hccCheck);
  Assert.IsTrue(LHtml.Contains(TEST_PROVIDER_ECHO), LHtml);
  Assert.IsTrue(LHtml.Contains('help-index.json'), LHtml);
end;

procedure TCommandsTests.Prompt_IsTheSystemPromptOfTheLastQuestion;
var
  LHtml: string;
begin
  Assert.IsTrue(Run(hccPrompt).Contains('No question yet.'));
  FEngine.Send('how do I export the grid?');
  LHtml := Run(hccPrompt, '', 'Orders');
  Assert.IsTrue(LHtml.StartsWith('<p class="hc-chat-cmd-title"><b>System prompt of the last question (/prompt):</b></p><pre class="hc-chat-prompt">'), LHtml);
  Assert.IsTrue(LHtml.Contains('You are the in-app help assistant'), LHtml);
  Assert.IsTrue(LHtml.Contains('The user is currently on the &quot;Orders&quot; screen'), LHtml);
  Assert.IsTrue(LHtml.Contains('## Exporting the grid'), 'the excerpts: ' + LHtml);
  Assert.IsTrue(LHtml.Contains('tools listed for you'), 'the actions rule, there are actions');
end;

procedure TCommandsTests.Run_InvokesTheAction_WithTheArguments;
var
  LHtml: string;
  LThread: TThread;
  LStart: TDateTime;
begin
  Assert.IsTrue(Run(hccRun).Contains('Usage: /run'), 'no arguments');
  Assert.IsTrue(Run(hccRun, 'open_screen name').Contains('Usage: /run'), 'not name=value');
  // Invoke waits for the host: the command runs on another thread, the
  // test thread plays the main thread and pumps the broker.
  LHtml := '';
  LThread := TThread.CreateAnonymousThread(procedure
    begin
      LHtml := Run(hccRun, 'open_screen name="Leads board"');
    end);
  LThread.FreeOnTerminate := False;
  LThread.Start;
  LStart := Now;
  repeat
    FBroker.ExecutePending;
    CheckSynchronize(10);
    Sleep(10);
  until LThread.Finished or (MilliSecondsBetween(Now, LStart) > 5000);
  LThread.WaitFor;
  LThread.Free;
  Assert.AreEqual('open_screen(Leads board)', FRan, 'quotes keep the spaces');
  Assert.IsTrue(LHtml.Contains('Opened Leads board'), LHtml);
end;

procedure TCommandsTests.APageCommand_AnswersWithItsDescription;
begin
  Assert.IsTrue(Run(hccClear).Contains('/clear - ' + HelpChatMsg(hcmCmdClear, hclEnglish)));
end;

procedure TCommandsTests.Descriptions_ExistInBothLanguages;
var
  C: THelpChatCommand;
begin
  for C := Low(THelpChatCommand) to High(THelpChatCommand) do
  begin
    Assert.AreNotEqual('', HelpChatCommandDescription(C, hclEnglish), HelpChatCommandName(C));
    Assert.AreNotEqual('', HelpChatCommandDescription(C, hclItalian), HelpChatCommandName(C));
    Assert.AreNotEqual(HelpChatCommandDescription(C, hclEnglish),
      HelpChatCommandDescription(C, hclItalian), HelpChatCommandName(C) + ': translated');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCommandsTests);

end.
