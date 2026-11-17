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
///  The log of the library: what an entry is, the levels, and the one routine
///  every entry goes through. Who writes an entry is
///  <c>THelpChatSettings.Log</c> (the settings carry the level and the
///  handler, and every request works on a copy of them); who reads it is the
///  <c>OnLogEvent</c> of a component and, for code with no component (the
///  console server, a test), <see cref="HelpChatOnLog" />. Pure RTL.
/// </summary>
unit HelpChatAI.Log;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes;

type
  /// <summary>How much is logged. The levels are cumulative: llDetail logs
  /// everything llInfo does and more, llDebug everything. llNone logs
  /// nothing, errors included.</summary>
  THelpChatLogLevel = (llNone, llInfo, llDetail, llDebug);

  /// <summary>How serious an entry is, whatever level it appears at: an error
  /// of the service is an llInfo entry with lsError.</summary>
  THelpChatLogSeverity = (lsInfo, lsWarning, lsError);

  /// <summary>What part of the library an entry is about.</summary>
  THelpChatLogCategory = (lcEngine, lcConfig, lcRequest, lcSearch, lcProvider,
    lcAction, lcCommand, lcAttachment, lcConversation, lcUi, lcTransport,
    lcVoice, lcSkill);

  /// <summary>One entry of the log.</summary>
  THelpChatLogEntry = record
    /// <summary>When it was written, local time.</summary>
    Time: TDateTime;
    /// <summary>The lowest level it appears at.</summary>
    Level: THelpChatLogLevel;
    Severity: THelpChatLogSeverity;
    Category: THelpChatLogCategory;
    /// <summary>The profile of the assistant; empty for the default one.</summary>
    Profile: string;
    /// <summary>The conversation it belongs to, when it belongs to one.</summary>
    ConversationKey: string;
    /// <summary>The id of the reply it belongs to: the entries of one answer
    /// share it.</summary>
    RequestId: string;
    ThreadId: TThreadID;
    /// <summary>One readable line, in English.</summary>
    Text: string;
    /// <summary>Optional JSON with the fields of the entry (the tokens of a
    /// reply, the settings in force), for a tool that reads the log.</summary>
    Data: string;
    /// <summary>"2026-11-17 14:03:12.345 INFO  request  text" - the line a
    /// handler that writes to a file usually wants.</summary>
    function ToString: string;
  end;

  /// <summary>The <c>OnLogEvent</c> of the components. It runs on the
  /// thread that wrote the entry - often a worker answering a question -
  /// one call at a time: a handler that writes to a file needs nothing more,
  /// a handler that touches the user interface uses <c>TThread.Queue</c>.
  /// What it raises is swallowed: a log never stops the assistant.</summary>
  THelpChatLogEvent = procedure(Sender: TObject; const AEntry: THelpChatLogEntry) of object;

  /// <summary>The type of <see cref="HelpChatOnLog" />.</summary>
  THelpChatLogProc = reference to procedure(const AEntry: THelpChatLogEntry);

const
  HELPCHAT_DEF_LOG_LEVEL = llInfo;
  /// <summary>The longest text a log entry carries of something the model or
  /// a service wrote (a body of an error, an answer at llDebug is whole).</summary>
  HELPCHAT_LOG_ERROR_BODY_CHARS = 2000;

var
  /// <summary>Every entry of every assistant of the process, at the level of
  /// the settings that wrote it, after the handler of its component; nil by
  /// default. For code that drives an engine with no component. Same thread
  /// and serialization rules as <see cref="THelpChatLogEvent" />.</summary>
  HelpChatOnLog: THelpChatLogProc;

/// <summary>'none', 'info', 'detail', 'debug': the level as a configuration
/// file writes it.</summary>
function HelpChatLogLevelToConfig(const ALevel: THelpChatLogLevel): string;
/// <summary>The level a configuration names (case ignored, the 'll' prefix
/// allowed); ADefault for anything else.</summary>
function HelpChatConfigToLogLevel(const AValue: string;
  const ADefault: THelpChatLogLevel): THelpChatLogLevel;
function HelpChatLogSeverityName(const ASeverity: THelpChatLogSeverity): string;
function HelpChatLogCategoryName(const ACategory: THelpChatLogCategory): string;

/// <summary>Hands AEntry to AHandler (with ASender) and then to
/// <see cref="HelpChatOnLog" />, one entry at a time for the whole process,
/// swallowing what they raise. What <c>THelpChatSettings.Log</c> calls.</summary>
procedure HelpChatDispatchLog(const AEntry: THelpChatLogEntry;
  const AHandler: THelpChatLogEvent; const ASender: TObject);

/// <summary>AText on one line and cut at AMaxChars (0 = whole): what an
/// entry quotes of a text it did not write.</summary>
function HelpChatLogQuote(const AText: string; const AMaxChars: Integer = 0): string;

implementation

uses
  System.SyncObjs;

const
  LEVEL_NAMES: array[THelpChatLogLevel] of string = ('none', 'info', 'detail', 'debug');
  SEVERITY_NAMES: array[THelpChatLogSeverity] of string = ('INFO', 'WARN', 'ERROR');
  CATEGORY_NAMES: array[THelpChatLogCategory] of string = ('engine', 'config',
    'request', 'search', 'provider', 'action', 'command', 'attachment',
    'conversation', 'ui', 'transport', 'voice', 'skill');

var
  GLogLock: TCriticalSection;

function HelpChatLogLevelToConfig(const ALevel: THelpChatLogLevel): string;
begin
  Result := LEVEL_NAMES[ALevel];
end;

function HelpChatConfigToLogLevel(const AValue: string;
  const ADefault: THelpChatLogLevel): THelpChatLogLevel;
var
  LValue: string;
  L: THelpChatLogLevel;
begin
  LValue := LowerCase(Trim(AValue));
  if LValue.StartsWith('ll') then
    LValue := LValue.Substring(2);
  for L := Low(THelpChatLogLevel) to High(THelpChatLogLevel) do
    if LValue = LEVEL_NAMES[L] then
      Exit(L);
  Result := ADefault;
end;

function HelpChatLogSeverityName(const ASeverity: THelpChatLogSeverity): string;
begin
  Result := SEVERITY_NAMES[ASeverity];
end;

function HelpChatLogCategoryName(const ACategory: THelpChatLogCategory): string;
begin
  Result := CATEGORY_NAMES[ACategory];
end;

function HelpChatLogQuote(const AText: string; const AMaxChars: Integer): string;
var
  I: Integer;
begin
  Result := AText.Replace(#13#10, ' ');
  for I := 1 to Length(Result) do
    if (Result[I] = #13) or (Result[I] = #10) or (Result[I] = #9) then
      Result[I] := ' ';
  Result := Trim(Result);
  if (AMaxChars > 0) and (Length(Result) > AMaxChars) then
    Result := Copy(Result, 1, AMaxChars) + '...';
end;

procedure HelpChatDispatchLog(const AEntry: THelpChatLogEntry;
  const AHandler: THelpChatLogEvent; const ASender: TObject);
var
  LHook: THelpChatLogProc;
begin
  LHook := HelpChatOnLog;
  if not Assigned(AHandler) and not Assigned(LHook) then
    Exit;
  GLogLock.Enter;
  try
    if Assigned(AHandler) then
      try
        AHandler(ASender, AEntry);
      except
        // A log never stops the assistant.
      end;
    if Assigned(LHook) then
      try
        LHook(AEntry);
      except
      end;
  finally
    GLogLock.Leave;
  end;
end;

{ THelpChatLogEntry }

function THelpChatLogEntry.ToString: string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Time) + ' ' +
    SEVERITY_NAMES[Severity].PadRight(6) + CATEGORY_NAMES[Category].PadRight(13);
  if Profile <> '' then
    Result := Result + '[' + Profile + '] ';
  Result := Result + Text;
end;

initialization
  GLogLock := TCriticalSection.Create;

finalization
  FreeAndNil(GLogLock);

end.
