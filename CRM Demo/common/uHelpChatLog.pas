{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                          }
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
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  The log of the assistant written to a file by Logify
///  (https://github.com/delphi-blocks/Logify, MIT: Logify.pas and
///  Logify.Adapter.Files.pas are copied next to this unit, with their
///  licence). Shared by the two demos: framework-neutral, like the rest of
///  common.
///
///  The library decides what is logged (<c>Settings.LogLevel</c>, raised in
///  helpchatai.json with "LogLevel": "debug"); Logify only writes it, from a
///  thread of its own, rotating the file. So the file adapter is opened at the
///  lowest level, Trace, and lets through whatever the library hands it.
/// </summary>
unit uHelpChatLog;

interface

uses
  HelpChatAI.Log;

/// <summary>Opens the log file of the application: <c>AName</c>.log in
/// %APPDATA%\HelpChatAI\Logs, five files of 5 MB at most, appended to.
/// Call it once, before the assistant is activated.</summary>
procedure HelpChatLogOpen(const AName: string);

/// <summary>One entry to the file. Called by the <c>OnLogEvent</c> of the
/// demos, on whatever thread wrote the entry: Logify queues it and returns.</summary>
procedure HelpChatLogWrite(const AEntry: THelpChatLogEntry);

/// <summary>The folder of the log files.</summary>
function HelpChatLogFolder: string;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Logify,
  Logify.Adapter.Files;

const
  /// <summary>The name the factory is registered under, and the "class" each
  /// line of the file carries.</summary>
  LOG_SOURCE = 'HelpChatAI';
  LOG_FILES = 5;
  LOG_FILE_SIZE = 5 * 1024 * 1024;

var
  GLogger: ILogger;

function HelpChatLogFolder: string;
begin
  Result := TPath.Combine(TPath.Combine(TPath.GetHomePath, 'HelpChatAI'), 'Logs');
end;

procedure HelpChatLogOpen(const AName: string);
var
  LFolder: string;
begin
  if Assigned(GLogger) then
    Exit;
  LFolder := HelpChatLogFolder;
  TDirectory.CreateDirectory(LFolder);
  // The configuration built here, not through the overload that takes a
  // procedure: that one starts from NewSingle, whose default path creates an
  // empty .\logs next to the executable before ours replaces it.
  TLoggerAdapterRegistry.Instance.RegisterFactory(
    TLogifyAdapterFilesFactory.CreateAdapterFactory(LOG_SOURCE,
      TFileLogConfig.NewRotate(TLogLevel.Trace, True, AName, LFolder, '.log',
        LOG_FILES, LOG_FILE_SIZE)));
  GLogger := TLoggerManager.GetLogger(LOG_SOURCE);
end;

/// <summary>The level of Logify an entry is written at: the severity first
/// (a warning or an error of the library are that, whatever the level they
/// appear at), then how deep the level is.</summary>
function LogifyLevel(const AEntry: THelpChatLogEntry): TLogLevel;
begin
  case AEntry.Severity of
    lsError: Exit(TLogLevel.Error);
    lsWarning: Exit(TLogLevel.Warning);
  end;
  case AEntry.Level of
    llDetail: Result := TLogLevel.Debug;
    llDebug: Result := TLogLevel.Trace;
  else
    Result := TLogLevel.Info;
  end;
end;

procedure HelpChatLogWrite(const AEntry: THelpChatLogEntry);
var
  LText: string;
begin
  if not Assigned(GLogger) then
    Exit;
  // Logify writes the time, the level and the thread: the line adds what
  // only the entry knows - the part of the library, the assistant, and the
  // conversation and the reply it belongs to.
  LText := HelpChatLogCategoryName(AEntry.Category) + ': ';
  if AEntry.Profile <> '' then
    LText := LText + '[' + AEntry.Profile + '] ';
  LText := LText + AEntry.Text;
  if AEntry.RequestId <> '' then
    LText := LText + ' {' + AEntry.ConversationKey + ' ' + AEntry.RequestId + '}'
  else if AEntry.ConversationKey <> '' then
    LText := LText + ' {' + AEntry.ConversationKey + '}';
  if AEntry.Data <> '' then
    LText := LText + sLineBreak + AEntry.Data;
  try
    GLogger.Log(LText, LogifyLevel(AEntry));
  except
    // A log that cannot be written does not stop the application.
  end;
end;

end.
