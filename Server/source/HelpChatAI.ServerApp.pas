{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and        }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  The HelpChat server as a console application: reads its configuration,
///  builds the engine, serves the clients and logs what happens. Everything it
///  does is in <see cref="THelpChatRemoteServer" />, so the same server can be
///  hosted inside an existing application instead — this unit is only the
///  plumbing around it (configuration, console, shutdown).
///
///  Configuration is one file, <c>helpchatai-server.json</c>: the engine reads
///  the settings it knows (provider, language, documentation index, Claude key)
///  and this unit reads the rest (port, application keys, sessions). Command
///  line options win over the file.
/// </summary>
unit HelpChatAI.ServerApp;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  HelpChatAI.Settings,
  HelpChatAI.Engine,
  HelpChatAI.Server.Remote;

const
  HELPCHAT_SERVER_CONFIG_FILENAME = 'helpchatai-server.json';

type
  THelpChatServerApp = class
  strict private
    FSettings: THelpChatSettings;
    FEngine: THelpChatEngine;
    FServer: THelpChatRemoteServer;
    FConfigFile: string;
    FQuiet: Boolean;
    procedure Say(const AText: string); overload;
    procedure Say(const AFormat: string; const AArgs: array of const); overload;
    procedure ServerLog(Sender: TObject; const AText: string);
    function ReadConfig(const AFileName: string): Boolean;
    function ParseCommandLine: Boolean;
    procedure WriteSampleConfig(const AFileName: string);
    procedure ShowUsage;
    procedure Report;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Configures, starts, waits for Ctrl+C, stops. Returns the exit code.</summary>
    function Run: Integer;
  end;

/// <summary>Set by the console handler: the server stops when it is signalled.</summary>
var
  HelpChatShutdown: TEvent;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Provider,
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI,
  HelpChatAI.Provider.Gemini;

/// <summary>A relative folder in the configuration is relative to the exe, not
/// to whatever directory the server happened to be started from.</summary>
function ResolveFolder(const AFolder: string): string;
begin
  Result := Trim(AFolder);
  if Result = '' then
    Exit;
  if not TPath.IsPathRooted(Result) then
    Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), Result);
end;

function ConsoleHandler(ACtrlType: DWORD): BOOL; stdcall;
begin
  // Ctrl+C, the close button, the end of a session: all mean "stop cleanly".
  Result := ACtrlType in [CTRL_C_EVENT, CTRL_BREAK_EVENT, CTRL_CLOSE_EVENT,
    CTRL_LOGOFF_EVENT, CTRL_SHUTDOWN_EVENT];
  if Result and Assigned(HelpChatShutdown) then
    HelpChatShutdown.SetEvent;
end;

{ THelpChatServerApp }

constructor THelpChatServerApp.Create;
begin
  inherited Create;
  FSettings := THelpChatSettings.Create;
  FConfigFile := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), HELPCHAT_SERVER_CONFIG_FILENAME);
end;

destructor THelpChatServerApp.Destroy;
begin
  FServer.Free;
  FEngine.Free;
  FSettings.Free;
  inherited;
end;

procedure THelpChatServerApp.Say(const AText: string);
begin
  if FQuiet then
    Exit;
  Writeln(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '  ' + AText);
  Flush(Output);
end;

procedure THelpChatServerApp.Say(const AFormat: string; const AArgs: array of const);
begin
  Say(Format(AFormat, AArgs));
end;

procedure THelpChatServerApp.ServerLog(Sender: TObject; const AText: string);
begin
  Say(AText);
end;

function THelpChatServerApp.ReadConfig(const AFileName: string): Boolean;
var
  LValue, LSessions: TJSONValue;
  LRoot: TJSONObject;
  LKeys: TJSONArray;
  LKey: TJSONValue;
  LStorage: string;
begin
  Result := TFile.Exists(AFileName);
  if not Result then
    Exit;
  // The engine reads the settings it knows from the same file.
  FSettings.LoadFromFile(AFileName);

  LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(AFileName, TEncoding.UTF8));
  if not (LValue is TJSONObject) then
  begin
    LValue.Free;
    raise EHelpChatConfigError.CreateFmt('%s: expected a JSON object', [AFileName]);
  end;
  LRoot := TJSONObject(LValue);
  try
    FServer.Port := LRoot.GetValue<Integer>('Port', FServer.Port);
    FServer.BindIP := LRoot.GetValue<string>('BindIP', FServer.BindIP);
    if LRoot.TryGetValue<TJSONArray>('Keys', LKeys) then
      for LKey in LKeys do
        if Trim(LKey.Value) <> '' then
          FServer.AppKeys.Add(Trim(LKey.Value));
    if LRoot.TryGetValue<TJSONValue>('Sessions', LSessions) and (LSessions is TJSONObject) then
    begin
      LStorage := TJSONObject(LSessions).GetValue<string>('Storage', '');
      if SameText(LStorage, 'disk') then
        FServer.Storage := hssDisk
      else if SameText(LStorage, 'memory') then
        FServer.Storage := hssMemory;
      FServer.SessionFolder := ResolveFolder(
        TJSONObject(LSessions).GetValue<string>('Folder', FServer.SessionFolder));
      FServer.IdleMinutes := TJSONObject(LSessions).GetValue<Integer>('IdleMinutes', FServer.IdleMinutes);
      FServer.MaxSessions := TJSONObject(LSessions).GetValue<Integer>('Max', FServer.MaxSessions);
    end;
  finally
    LRoot.Free;
  end;
end;

procedure THelpChatServerApp.WriteSampleConfig(const AFileName: string);
var
  LRoot, LSessions, LClaude: TJSONObject;
  LKeys: TJSONArray;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('Port', TJSONNumber.Create(HELPCHAT_REMOTE_DEF_PORT));
    LRoot.AddPair('BindIP', '0.0.0.0');
    LKeys := TJSONArray.Create;
    LKeys.Add('change-this-key');
    LRoot.AddPair('Keys', LKeys);
    LSessions := TJSONObject.Create;
    LSessions.AddPair('Storage', 'memory');
    LSessions.AddPair('Folder', 'sessions');
    LSessions.AddPair('IdleMinutes', TJSONNumber.Create(HELPCHAT_REMOTE_DEF_IDLE_MINUTES));
    LSessions.AddPair('Max', TJSONNumber.Create(HELPCHAT_REMOTE_DEF_MAX_SESSIONS));
    LRoot.AddPair('Sessions', LSessions);
    LRoot.AddPair('Provider', 'docsearch');
    LRoot.AddPair('Language', 'auto');
    LRoot.AddPair('DocIndexFile', 'help-index.json');
    LRoot.AddPair('DocBaseUrl', 'https://help.example.com/');
    LClaude := TJSONObject.Create;
    LClaude.AddPair('ApiKey', '');
    LClaude.AddPair('Model', HELPCHAT_CLAUDE_DEF_MODEL);
    LRoot.AddPair('Claude', LClaude);
    TFile.WriteAllText(AFileName, LRoot.Format(2), TEncoding.UTF8);
  finally
    LRoot.Free;
  end;
  Say('sample configuration written to %s', [AFileName]);
end;

procedure THelpChatServerApp.ShowUsage;
begin
  Writeln('HelpChat server ', HELPCHAT_VERSION, ' - Ethea S.r.l. - Apache 2.0');
  Writeln('');
  Writeln('  Serves the HelpChat panel and its API to the applications of your');
  Writeln('  organization: the model key, the documentation index and the');
  Writeln('  conversations stay here, the clients only show the chat.');
  Writeln('');
  Writeln('Usage: HelpChatAIServerApp [options]');
  Writeln('');
  Writeln('  --config <file>      configuration file (default: ', HELPCHAT_SERVER_CONFIG_FILENAME, ' next to the exe)');
  Writeln('  --write-config <f>   write a sample configuration and exit');
  Writeln('  --port <n>           port to listen on');
  Writeln('  --bind <ip>          address to bind (0.0.0.0 = every interface)');
  Writeln('  --key <key>          accept this application key (repeatable)');
  Writeln('  --storage <mode>     memory | disk');
  Writeln('  --folder <dir>       where disk storage keeps the conversations');
  Writeln('  --idle <minutes>     end a session after this much inactivity');
  Writeln('  --provider <name>    stub | docsearch | claude');
  Writeln('  --index <file>       documentation index (help-index.json)');
  Writeln('  --lang <auto|en|it>  language of the assistant');
  Writeln('  --quiet              no log on the console');
  Writeln('  --help               this text');
  Writeln('');
  Writeln('The API key of the model is read from the configuration file (Claude.ApiKey)');
  Writeln('or from the ANTHROPIC_API_KEY environment variable, and never leaves this process.');
end;

function THelpChatServerApp.ParseCommandLine: Boolean;
var
  I: Integer;
  LOption, LValue: string;

  function NextValue: string;
  begin
    Inc(I);
    if I <= ParamCount then
      Result := ParamStr(I)
    else
      Result := '';
  end;

begin
  Result := True;
  I := 1;
  while I <= ParamCount do
  begin
    LOption := ParamStr(I).ToLower;
    if (LOption = '--help') or (LOption = '-h') or (LOption = '-?') then
    begin
      ShowUsage;
      Exit(False);
    end
    else if LOption = '--config' then
      FConfigFile := NextValue
    else if LOption = '--write-config' then
    begin
      LValue := NextValue;
      if LValue = '' then
        LValue := FConfigFile;
      WriteSampleConfig(LValue);
      Exit(False);
    end
    else if LOption = '--quiet' then
      FQuiet := True;
    Inc(I);
  end;
end;

procedure THelpChatServerApp.Report;
var
  LKeyHint: string;
  LModel: THelpChatModelSettings;
begin
  Say('HelpChat server %s', [HELPCHAT_VERSION]);
  Say('  provider    : %s', [FSettings.Provider]);
  LModel := FSettings.ModelFor(FSettings.Provider);
  if Assigned(LModel) then
  begin
    if LModel.ResolveApiKey = '' then
      LKeyHint := Format('MISSING (%s.ApiKey or %s)',
        [LModel.SectionName, LModel.ApiKeyEnvVar])
    else
      LKeyHint := 'configured';
    Say('  model       : %s, key %s', [LModel.ResolveModel, LKeyHint]);
    Say('  endpoint    : %s', [LModel.NormalizedBaseUrl]);
  end;
  if FEngine.DocIndex.IsAvailable then
    Say('  index       : %d pages from %s', [FEngine.DocIndex.Count, FSettings.ResolveDocIndexFile])
  else
    Say('  index       : NOT FOUND at %s', [FSettings.ResolveDocIndexFile]);
  Say('  sessions    : %s, idle limit %d minutes, at most %d',
    [IfThen(FServer.Storage = hssDisk, 'on disk in ' + FServer.SessionFolder, 'in memory'),
     FServer.IdleMinutes, FServer.MaxSessions]);
  Say('  listening   : http://%s:%d  (health: /health)', [FServer.BindIP, FServer.BoundPort]);
  Say('Press Ctrl+C to stop.');
end;

function THelpChatServerApp.Run: Integer;
var
  I: Integer;
  LOption, LValue: string;

  function NextValue: string;
  begin
    Inc(I);
    if I <= ParamCount then
      Result := ParamStr(I)
    else
      Result := '';
  end;

begin
  Result := 0;
  if not ParseCommandLine then
    Exit;

  FEngine := THelpChatEngine.Create(FSettings);
  FServer := THelpChatRemoteServer.Create(FEngine, False);
  FServer.OnLog := ServerLog;
  try
    if not ReadConfig(FConfigFile) then
      Say('no configuration file at %s (use --write-config to create one)', [FConfigFile]);

    // Command line wins over the file.
    I := 1;
    while I <= ParamCount do
    begin
      LOption := ParamStr(I).ToLower;
      if LOption = '--port' then
        FServer.Port := StrToIntDef(NextValue, FServer.Port)
      else if LOption = '--bind' then
        FServer.BindIP := NextValue
      else if LOption = '--key' then
      begin
        LValue := NextValue;
        if LValue <> '' then
          FServer.AppKeys.Add(LValue);
      end
      else if LOption = '--storage' then
      begin
        LValue := NextValue;
        if SameText(LValue, 'disk') then
          FServer.Storage := hssDisk
        else
          FServer.Storage := hssMemory;
      end
      else if LOption = '--folder' then
        FServer.SessionFolder := ResolveFolder(NextValue)
      else if LOption = '--idle' then
        FServer.IdleMinutes := StrToIntDef(NextValue, FServer.IdleMinutes)
      else if LOption = '--provider' then
        FSettings.Provider := NextValue
      else if LOption = '--index' then
        FSettings.DocIndexFile := NextValue
      else if LOption = '--lang' then
      begin
        LValue := NextValue;
        if SameText(LValue, 'it') then
          FSettings.Language := hclItalian
        else if SameText(LValue, 'en') then
          FSettings.Language := hclEnglish
        else if SameText(LValue, 'auto') then
          FSettings.Language := hclAuto;
      end;
      Inc(I);
    end;

    // The conversations belong to the sessions here: the engine must not also
    // write the single-conversation file of a desktop application.
    FSettings.PersistConversation := False;
    HelpChatDefaultLanguage := FSettings.Language;

    FServer.Start;
    Report;
    HelpChatShutdown.WaitFor(INFINITE);
    Say('stopping...');
    FServer.Stop;
    Say('stopped.');
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'HelpChat server: ' + E.Message);
      Flush(ErrOutput);
      Result := 1;
    end;
  end;
end;

initialization
  HelpChatShutdown := TEvent.Create(nil, True, False, '');
  SetConsoleCtrlHandler(@ConsoleHandler, True);

finalization
  SetConsoleCtrlHandler(@ConsoleHandler, False);
  HelpChatShutdown.Free;

end.
