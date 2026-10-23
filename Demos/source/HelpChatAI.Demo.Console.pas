{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Console harness: drives the engine from the command line, without any  }
{       UI, so the providers can be tried and the streaming watched.           }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
unit HelpChatAI.Demo.Console;

interface

/// <summary>Parses the command line, runs the read-eval-print loop, returns the
/// process exit code.</summary>
function RunConsoleDemo: Integer;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Provider,
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI,
  HelpChatAI.Provider.Gemini,
  HelpChatAI.Engine;

procedure PrintUsage;
begin
  Writeln('HelpChat console demo ', HELPCHAT_VERSION);
  Writeln;
  Writeln('Usage: HelpChatAIConsoleDemo [options]');
  Writeln('  --config=<file>     JSON configuration file (default, merged in order:');
  Writeln('                      ', THelpChatSettings.SharedUserConfigFile, ',');
  Writeln('                      helpchatai.json next to the exe, ', THelpChatSettings.UserConfigFile, ')');
  Writeln('  --write-config      write the current settings as a template to the user config file and exit');
  Writeln('  --provider=<name>   stub | docsearch | claude | openai | gemini  (default: stub)');
  Writeln('  --index=<file>      documentation index JSON    (default: help-index.json next to the exe)');
  Writeln('  --docurl=<url>      base URL of the documentation links');
  Writeln('  --lang=en|it        UI language                 (default: OS locale)');
  Writeln('  --model=<id>        model of the chosen provider (default: its own)');
  Writeln('  --apikey=<key>      API key of the chosen provider (default: its environment variable)');
  Writeln('  --baseurl=<url>     endpoint of the chosen provider (openai: Groq, Ollama, Azure...)');
  Writeln('  --persist           save/restore the conversation in the user data folder');
  Writeln('  --screen=<label>    pretend the user is on this screen (context)');
  Writeln('  --help');
  Writeln;
  Writeln('In the chat:  /clear  /provider <name>  /providers  /screen <label>  /html  /quit');
end;

function ArgValue(const AName: string; out AValue: string): Boolean;
var
  I: Integer;
  LArg: string;
begin
  Result := False;
  AValue := '';
  for I := 1 to ParamCount do
  begin
    LArg := ParamStr(I);
    if SameText(LArg, '--' + AName) then
      Exit(True);
    if LArg.StartsWith('--' + AName + '=', True) then
    begin
      AValue := LArg.Substring(AName.Length + 3);
      Exit(True);
    end;
  end;
end;

/// <summary>Polls the pending assistant message and prints the tokens as they
/// arrive, exactly like the panel does with its 1.2 s poll (here 100 ms).</summary>
procedure StreamReply(const AEngine: THelpChatEngine; const AId: string);
var
  LMessage: THelpChatMessage;
  LPrinted: Integer;
begin
  LPrinted := 0;
  Write('assistant> ');
  repeat
    if not AEngine.TryGetMessage(AId, LMessage) then
      Break;
    if LMessage.Content.Length > LPrinted then
    begin
      Write(LMessage.Content.Substring(LPrinted));
      LPrinted := LMessage.Content.Length;
    end;
    if LMessage.Pending then
      TThread.Sleep(100);
  until not LMessage.Pending;
  Writeln;
  if LMessage.IsError then
    Writeln('[error] ', LMessage.Content);
  Writeln;
end;

function RunConsoleDemo: Integer;
var
  LSettings: THelpChatSettings;
  LModel: THelpChatModelSettings;
  LEngine: THelpChatEngine;
  LValue, LLine, LCmd, LArg: string;
  LContext: THelpChatContext;
  LResult: THelpChatSendResult;
  LName: string;
  P: Integer;
begin
  Result := 0;
  if ArgValue('help', LValue) or ArgValue('?', LValue) then
  begin
    PrintUsage;
    Exit;
  end;

  LSettings := THelpChatSettings.Create;
  try
    LSettings.PersistConversation := False;

    // Configuration files first, then the command line on top.
    if ArgValue('config', LValue) and (LValue <> '') then
    begin
      if not LSettings.LoadFromFile(LValue) then
      begin
        Writeln('Configuration file not found: ', LValue);
        Exit(2);
      end;
      Writeln('Configuration: ', LValue);
    end
    else
      for LName in LSettings.LoadFromDefaultFiles do
        Writeln('Configuration: ', LName);

    if ArgValue('persist', LValue) then
      LSettings.PersistConversation := True;
    if ArgValue('provider', LValue) and (LValue <> '') then
      LSettings.Provider := LValue;
    if ArgValue('index', LValue) and (LValue <> '') then
      LSettings.DocIndexFile := LValue;
    if ArgValue('docurl', LValue) and (LValue <> '') then
      LSettings.DocBaseUrl := LValue;
    if ArgValue('lang', LValue) then
      if SameText(LValue, 'it') then
        LSettings.Language := hclItalian
      else if SameText(LValue, 'en') then
        LSettings.Language := hclEnglish;
    // --model, --apikey and --baseurl apply to whichever provider --provider chose.
    LModel := LSettings.ActiveModel;
    if Assigned(LModel) then
    begin
      if ArgValue('model', LValue) and (LValue <> '') then
        LModel.Model := LValue;
      if ArgValue('apikey', LValue) and (LValue <> '') then
        LModel.ApiKey := LValue;
      if ArgValue('baseurl', LValue) and (LValue <> '') then
        LModel.BaseUrl := LValue;
    end;

    if ArgValue('write-config', LValue) then
    begin
      LSettings.SaveToFile(THelpChatSettings.UserConfigFile);
      Writeln('Configuration template written to: ', THelpChatSettings.UserConfigFile);
      Writeln('Edit it and paste your key in the section of your provider ' +
        '("Claude", "OpenAI" or "Gemini") under "ApiKey".');
      Exit;
    end;

    LContext := Default(THelpChatContext);
    if ArgValue('screen', LValue) and (LValue <> '') then
    begin
      LContext.ScreenLabel := LValue;
      LContext.ScreenName := LValue;
    end;

    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Writeln('HelpChat console demo ', HELPCHAT_VERSION, ' - provider: ', LSettings.Provider,
        ' - language: ', HelpChatLanguageCode(LSettings.Language));
      if LEngine.DocIndex.IsAvailable then
        Writeln('Documentation index: ', LEngine.DocIndex.Count, ' pages from ', LEngine.DocIndex.LoadedFrom)
      else
        Writeln('Documentation index: not available (', LSettings.ResolveDocIndexFile, ')');
      if Length(LEngine.Messages) > 0 then
        Writeln('Restored ', Length(LEngine.Messages), ' messages from ', LSettings.ResolveConversationFile);
      Writeln('Type a question, or /quit. /help for commands.');
      Writeln;
      Writeln('assistant> ', LEngine.Greeting);
      Writeln;

      while True do
      begin
        Write('you> ');
        Readln(LLine);
        LLine := Trim(LLine);
        if LLine = '' then
          Continue;

        if LLine.StartsWith('/') then
        begin
          P := LLine.IndexOf(' ');
          if P > 0 then
          begin
            LCmd := LLine.Substring(0, P).ToLower;
            LArg := Trim(LLine.Substring(P + 1));
          end
          else
          begin
            LCmd := LLine.ToLower;
            LArg := '';
          end;

          if (LCmd = '/quit') or (LCmd = '/exit') or (LCmd = '/q') then
            Break
          else if LCmd = '/help' then
            Writeln('/clear  /provider <name>  /providers  /screen <label>  /html  /quit')
          else if LCmd = '/clear' then
          begin
            LEngine.Clear;
            Writeln('(conversation cleared)');
          end
          else if LCmd = '/providers' then
          begin
            for LName in THelpChatProviderRegistry.ProviderNames do
              Writeln('  ', LName);
          end
          else if LCmd = '/provider' then
          begin
            if THelpChatProviderRegistry.IsRegistered(LArg) then
            begin
              LSettings.Provider := LArg;
              Writeln('(provider: ', LArg, ')');
            end
            else
              Writeln('(unknown provider: ', LArg, ')');
          end
          else if LCmd = '/screen' then
          begin
            LContext.ScreenLabel := LArg;
            LContext.ScreenName := LArg;
            Writeln('(screen context: "', LArg, '")');
          end
          else if LCmd = '/html' then
            Writeln(LEngine.RenderHistoryHtml)
          else
            Writeln('(unknown command)');
          Writeln;
          Continue;
        end;

        LResult := LEngine.Send(LLine, LContext);
        if LResult.Sent then
          StreamReply(LEngine, LResult.AssistantMessage.Id);
      end;

      LEngine.Stop;
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

end.
