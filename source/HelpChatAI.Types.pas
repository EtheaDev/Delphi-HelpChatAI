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
///  Core value types shared by every HelpChat unit: the chat message record,
///  the screen context passed to providers, the streaming token callback, the
///  cancellation token and the retriever contract used for documentation
///  grounding. Pure RTL: no VCL, no FMX, no web.
/// </summary>
unit HelpChatAI.Types;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Character;

const
  /// <summary>Library version (major.minor.release).</summary>
  HELPCHAT_VERSION = '2.0.0';

type
  /// <summary>Author of a chat message.</summary>
  THelpChatRole = (hcrUser, hcrAssistant, hcrSystem);

  /// <summary>
  ///  A single chat message. A plain value record (strings + enums) so it can be
  ///  copied into the store and passed to a worker thread without any ownership
  ///  concern. Assistant messages produced asynchronously start with
  ///  <c>Pending = True</c> and are later completed (or marked <c>IsError</c>).
  /// </summary>
  THelpChatMessage = record
    /// <summary>URL-safe id (hyphenated GUID without braces).</summary>
    Id: string;
    Role: THelpChatRole;
    Content: string;
    Created: TDateTime;
    /// <summary>True while an assistant reply is still being produced.</summary>
    Pending: Boolean;
    /// <summary>True when the assistant reply ended in an error (Content is the message).</summary>
    IsError: Boolean;
    /// <summary>Formats a fresh URL-safe message id.</summary>
    class function NewId: string; static;
    /// <summary>True for a message that is neither pending nor failed.</summary>
    function IsCompleted: Boolean;
  end;

  /// <summary>
  ///  Where the user is when asking. Filled automatically by the VCL/FMX
  ///  component (active form, caption, HelpKeyword/HelpContext, focused control)
  ///  and optionally refined by the host application. Only names and labels
  ///  travel to the provider: never record data.
  /// </summary>
  THelpChatContext = record
    /// <summary>Logical user name (single-user desktop apps may leave it empty).</summary>
    UserName: string;
    /// <summary>Name of the active screen (e.g. the form Name).</summary>
    ScreenName: string;
    /// <summary>Human-readable label of the screen (e.g. the form Caption).</summary>
    ScreenLabel: string;
    /// <summary>Type of the screen (e.g. the form ClassName, or "List"/"Form").</summary>
    ScreenType: string;
    /// <summary>Standard Delphi HelpKeyword of the active form/control, if any.</summary>
    HelpKeyword: string;
    /// <summary>Standard Delphi HelpContext of the active form/control (0 = none).</summary>
    HelpContext: Integer;
    /// <summary>Name of the focused control, if any.</summary>
    FocusedControl: string;
    /// <summary>True when no screen information is available.</summary>
    function IsEmpty: Boolean;
    /// <summary>True when HelpKeyword reads as a title (has letters), not as a code.</summary>
    function HasReadableKeyword: Boolean;
    /// <summary>Best name for the screen in a question: the HelpKeyword when it
    /// is readable (it names the documentation page), else the label, else the name.</summary>
    function DisplayName: string;
    /// <summary>What biases the documentation search: the HelpKeyword alone when
    /// present (the precise anchor), else the screen label. Never the class name.</summary>
    function SearchHint: string;
  end;

  /// <summary>Callback invoked by a streaming provider for each produced token.</summary>
  THelpChatTokenProc = reference to procedure(const AToken: string);

  /// <summary>A link of the panel is leaving it (a documentation page outside
  /// the panel, a web site, a mail address): set <c>AHandled</c> to open it
  /// yourself, leave it False for the system browser. Fired on the main thread.</summary>
  THelpChatOpenLinkEvent = procedure(Sender: TObject; const AUrl: string;
    var AHandled: Boolean) of object;

  /// <summary>
  ///  Cooperative cancellation. The runner hands one token per request to the
  ///  provider, which checks it between steps and aborts the HTTP stream when it
  ///  flips. Thread-safe.
  /// </summary>
  IHelpChatCancelToken = interface
    /// <summary>True once somebody asked to stop: a provider checks it between
    /// the reads of its stream and before every action.</summary>
    ['{7D0B2C64-9E3A-4F1B-8C55-2A6E0D9F31B7}']
    function IsCancelled: Boolean;
    /// <summary>Asks to stop. Never undone: a token is for one
    /// request.</summary>
    procedure Cancel;
  end;

  /// <summary>Default <see cref="IHelpChatCancelToken" /> implementation.</summary>
  THelpChatCancelToken = class(TInterfacedObject, IHelpChatCancelToken)
  strict private
    FCancelled: Integer;
  public
    function IsCancelled: Boolean;
    procedure Cancel;
  end;

  /// <summary>
  ///  Whether the object a queued call is meant for is still there. A call
  ///  handed to <c>TThread.Queue</c> cannot be taken back, and it holds a
  ///  method of an object - a component, usually - that may be freed before
  ///  the message loop gets to it: the closure captures this token with the
  ///  method, the object kills it in its destructor, and the closure asks
  ///  before calling. Reference counted, so it outlives both. Killed and
  ///  asked on the main thread: it needs no lock.
  /// </summary>
  IHelpChatLifeToken = interface
    ['{6B1D8E55-0C2F-4B49-9A57-3F1E2D7C8A41}']
    /// <summary>True until <c>Kill</c>.</summary>
    function IsAlive: Boolean;
    /// <summary>The object is going: every call still queued for it does
    /// nothing.</summary>
    procedure Kill;
  end;

  /// <summary>Default <see cref="IHelpChatLifeToken" /> implementation.</summary>
  THelpChatLifeToken = class(TInterfacedObject, IHelpChatLifeToken)
  strict private
    FDead: Boolean;
  public
    function IsAlive: Boolean;
    procedure Kill;
  end;

  /// <summary>Base class of all HelpChat exceptions.</summary>
  EHelpChatError = class(Exception);
  /// <summary>Raised when a provider is missing a required setting (e.g. the API key).</summary>
  EHelpChatConfigError = class(EHelpChatError);
  /// <summary>Raised by a provider when its request was cancelled.</summary>
  EHelpChatCancelled = class(EHelpChatError);

  /// <summary>A documentation page returned by a retriever: title, absolute URL
  /// (base URL already joined), one-line summary and relevance score.</summary>
  THelpChatDocPage = record
    Title: string;
    Url: string;
    Summary: string;
    /// <summary>The passages of the page around the matching terms (windows
    /// joined by an ellipsis), sized for a model prompt. Empty when the
    /// retriever has no text.</summary>
    Excerpt: string;
    Score: Integer;
  end;

  /// <summary>
  ///  Retrieval contract used for documentation grounding. The default
  ///  implementation is the keyword-scoring <c>THelpChatDocIndex</c>; an
  ///  embedding-based retriever can replace it without touching the providers.
  /// </summary>
  IHelpChatRetriever = interface
    ['{A3F1C8E2-5B7D-4C09-9E61-4D2F8B0A7C13}']
    /// <summary>True when an index is loaded and can answer queries.</summary>
    function IsAvailable: Boolean;
    /// <summary>Base URL of the documentation (with trailing slash), for fallbacks.</summary>
    function GetBaseUrl: string;
    /// <summary>Returns the pages best matching <c>AQuery</c> (optionally biased by
    /// <c>AHint</c>, e.g. the screen type), most relevant first, up to
    /// <c>AMaxPages</c> (&lt;= 0 defaults to 3). Empty when nothing scores.</summary>
    function Search(const AQuery, AHint: string; const AMaxPages: Integer): TArray<THelpChatDocPage>;
  end;

/// <summary>Joins a base URL and a relative path with exactly one slash.</summary>
function HelpChatJoinUrl(const ABase, ARelative: string): string;

/// <summary>A relative path of the manual as a link may carry it: a space,
/// a parenthesis, a bracket, <c>%</c>, <c>#</c>, <c>?</c> and the other
/// characters that end or break the target of a Markdown link become
/// <c>%XX</c>. Letters of any alphabet, digits and <c>/</c> stay as they
/// are, so the path of a page named in plain words is unchanged.</summary>
function HelpChatEncodeUrlPath(const APath: string): string;

/// <summary>The inverse of <see cref="HelpChatEncodeUrlPath" />: every
/// <c>%XX</c> becomes its byte, the bytes are read as UTF-8. A <c>+</c> stays
/// a plus, and a text that is not well formed comes back as it is.</summary>
function HelpChatDecodeUrlPath(const APath: string): string;

implementation

function HelpChatEncodeUrlPath(const APath: string): string;
const
  UNSAFE = ' %()<>[]{}"#?`^|\';
var
  LChar: Char;
begin
  Result := '';
  for LChar in APath do
    if (LChar <= ' ') or (LChar = #127) or (Pos(LChar, UNSAFE) > 0) then
      Result := Result + '%' + IntToHex(Ord(LChar), 2)
    else
      Result := Result + LChar;
end;

function HelpChatDecodeUrlPath(const APath: string): string;
var
  LBytes, LPart: TBytes;
  LCount, I, LByte: Integer;
begin
  if Pos('%', APath) = 0 then
    Exit(APath);
  SetLength(LBytes, APath.Length * 4);
  LCount := 0;
  I := 1;
  while I <= APath.Length do
  begin
    if (APath[I] = '%') and (I + 2 <= APath.Length) and
      TryStrToInt('$' + Copy(APath, I + 1, 2), LByte) then
    begin
      LBytes[LCount] := LByte;
      Inc(LCount);
      Inc(I, 3);
    end
    else
    begin
      LPart := TEncoding.UTF8.GetBytes(APath[I]);
      // Both halves of a surrogate pair together.
      if APath[I].IsHighSurrogate and (I < APath.Length) then
      begin
        LPart := TEncoding.UTF8.GetBytes(Copy(APath, I, 2));
        Inc(I);
      end;
      Move(LPart[0], LBytes[LCount], Length(LPart));
      Inc(LCount, Length(LPart));
      Inc(I);
    end;
  end;
  try
    Result := TEncoding.UTF8.GetString(LBytes, 0, LCount);
  except
    Result := '';
  end;
  // Bytes that are not UTF-8 decode to nothing, or raise: as it was.
  if (Result = '') and (LCount > 0) then
    Result := APath;
end;

function HelpChatJoinUrl(const ABase, ARelative: string): string;
begin
  if ABase = '' then
    Exit(ARelative);
  if ARelative = '' then
    Exit(ABase);
  if ABase.EndsWith('/') then
  begin
    if ARelative.StartsWith('/') then
      Result := ABase + ARelative.Substring(1)
    else
      Result := ABase + ARelative;
  end
  else
  begin
    if ARelative.StartsWith('/') then
      Result := ABase + ARelative
    else
      Result := ABase + '/' + ARelative;
  end;
end;

{ THelpChatMessage }

class function THelpChatMessage.NewId: string;
var
  LGuid: TGUID;
begin
  CreateGUID(LGuid);
  // "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}" -> strip braces: URL-safe.
  Result := Copy(GUIDToString(LGuid), 2, 36);
end;

function THelpChatMessage.IsCompleted: Boolean;
begin
  Result := not Pending and not IsError;
end;

{ THelpChatContext }

function THelpChatContext.IsEmpty: Boolean;
begin
  Result := (ScreenName = '') and (ScreenLabel = '') and (ScreenType = '') and
    (HelpKeyword = '') and (HelpContext = 0);
end;

function THelpChatContext.HasReadableKeyword: Boolean;
var
  C: Char;
begin
  for C in HelpKeyword do
    if C.IsLetter then
      Exit(True);
  Result := False;
end;

function THelpChatContext.DisplayName: string;
begin
  if HasReadableKeyword then
    Result := HelpKeyword
  else if ScreenLabel <> '' then
    Result := ScreenLabel
  else
    Result := ScreenName;
end;

function THelpChatContext.SearchHint: string;
begin
  if HelpKeyword <> '' then
    Result := HelpKeyword
  else
    Result := ScreenLabel;
end;

{ THelpChatCancelToken }

function THelpChatCancelToken.IsCancelled: Boolean;
begin
  Result := AtomicCmpExchange(FCancelled, 0, 0) <> 0;
end;

function THelpChatLifeToken.IsAlive: Boolean;
begin
  Result := not FDead;
end;

procedure THelpChatLifeToken.Kill;
begin
  FDead := True;
end;

procedure THelpChatCancelToken.Cancel;
begin
  AtomicExchange(FCancelled, 1);
end;

end.
