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
  HELPCHAT_VERSION = '1.0.0';

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
    ['{7D0B2C64-9E3A-4F1B-8C55-2A6E0D9F31B7}']
    function IsCancelled: Boolean;
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

implementation

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

procedure THelpChatCancelToken.Cancel;
begin
  AtomicExchange(FCancelled, 1);
end;

end.
