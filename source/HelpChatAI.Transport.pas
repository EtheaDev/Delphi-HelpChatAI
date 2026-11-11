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
///  The transport is what the HTML panel talks to. The UI component (VCL or
///  FMX) does not know whether the chat is served by an HTTP server embedded in
///  the process (<c>THelpChatLocalServer</c>, desktop) or by a remote server
///  (mobile, or when the API key must stay server-side): it asks the transport
///  for the URL to load in the embedded browser and hands it the screen context.
///
///  This interface is the seam between the user interface and whatever
///  answers. Everything that is of one panel - the screen context, the
///  colours, the name and the icon, the enabled commands, the actions of its
///  form - goes through here and nowhere else; the page itself only speaks
///  the HTTP contract of <c>HelpChatAI.Panel</c>. What still ties a component
///  to <see cref="THelpChatEngine" /> directly is <see cref="GetEngine" /> and
///  the handful of calls the components make on the engine for what the
///  application does from code (models, language, attachments, the question
///  of F1): a backend that is not a <c>THelpChatEngine</c> answers nil there,
///  the way the remote transport does, and those calls answer "not
///  available".
/// </summary>
unit HelpChatAI.Transport;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  HelpChatAI.Types,
  HelpChatAI.Theme,
  HelpChatAI.Html,
  HelpChatAI.Commands,
  HelpChatAI.Actions,
  HelpChatAI.Engine;

type
  /// <summary>A command the page sent to its host ('close'); delivered on the
  /// main thread.</summary>
  THelpChatUiCommandEvent = reference to procedure(const ACommand: string);

  /// <summary>A document the page asked to be saved as PDF, delivered on the
  /// main thread. It arrives without a stylesheet on purpose: what it looks
  /// like is the client's business, exactly like the colours of the panel -
  /// and so is where the file goes, which only the client can ask the
  /// user.</summary>
  THelpChatPdfRequestEvent = reference to procedure(const ADoc: THelpChatPrintableDoc);

  /// <summary>What a component asks of the thing that serves its panel. Two
  /// implementations: <c>THelpChatLocalServer</c> (the engine in this process,
  /// one session) and <c>THelpChatRemoteTransport</c> (a HelpChatAI server). A
  /// component creates its own in <c>CreateTransport</c>, which is virtual:
  /// that is where another one is plugged in. Setters are called on the main
  /// thread; the transport reads on its own threads.</summary>
  IHelpChatTransport = interface
    ['{E2B7C4D9-5A31-4F8E-9C06-7D1B3A2E8F54}']
    /// <summary>Makes the panel reachable (starts the local server, or checks
    /// the remote one). Idempotent.</summary>
    procedure Start;
    /// <summary>Stops serving the panel: the URL of the page stops answering.
    /// Does not stop the engine, which may be shared.</summary>
    procedure Stop;
    /// <summary>True when the panel can be loaded. For a remote transport it
    /// means "ready", not "connected": the session is opened on first
    /// use.</summary>
    function IsActive: Boolean;
    /// <summary>URL the embedded browser navigates to; empty when not active.
    /// Includes whatever secret the page needs to call the API.</summary>
    function GetPanelUrl: string;
    /// <summary>Origin (scheme://host:port) of the panel: the browser is confined
    /// to it, every other navigation opens in the system browser.</summary>
    function GetPanelOrigin: string;
    /// <summary>Screen context attached to the next messages. The UI layer sets
    /// it on the main thread when the panel opens or the screen changes; the
    /// transport reads it on its own threads.</summary>
    procedure SetContext(const AContext: THelpChatContext);
    /// <summary>The context last set.</summary>
    function GetContext: THelpChatContext;
    /// <summary>Colours of the host application, injected into the panel page
    /// when it is served (a running page is updated by the UI layer through
    /// window.hcApplyTheme). Empty theme = page defaults.</summary>
    procedure SetTheme(const ATheme: THelpChatTheme);
    /// <summary>The theme last set.</summary>
    function GetTheme: THelpChatTheme;
    /// <summary>The name the panel writes in its header and the icon it draws
    /// left of it, as a <c>data:image/...</c> URI. They travel for the same
    /// reason the colours do: an image list is a VCL object and a name may
    /// come from a published property, so only the client knows them. Empty
    /// name = the localized default; empty icon = no icon.</summary>
    procedure SetAssistant(const AName, AIconDataUri: string);
    /// <summary>The name last set, unresolved: an empty one is resolved by the
    /// page in the language it is rendered in.</summary>
    function GetAssistantName: string;
    /// <summary>The icon last set, as a data: URI; empty = none.</summary>
    function GetAssistantIcon: string;
    /// <summary>The slash commands the panel accepts (<c>EnabledCommands</c>
    /// of the component). Local: the session refuses the others. Remote: the
    /// server decides for everybody, and this is kept for the record.</summary>
    procedure SetEnabledCommands(const ACommands: THelpChatCommands);
    /// <summary>The set last given.</summary>
    function GetEnabledCommands: THelpChatCommands;
    /// <summary>What this assistant may do: travels with every question and
    /// command of its panel, because the engine may be shared by the
    /// assistants of one profile, each with the actions of its own form.
    /// Remote: actions do not travel yet, and this is kept for the record.</summary>
    procedure SetActions(const AActions: IHelpChatActionInvoker);
    /// <summary>The actions last given; nil = this assistant can only
    /// answer.</summary>
    function GetActions: IHelpChatActionInvoker;
    /// <summary>The engine behind this transport: nil for a remote one, and
    /// for any transport whose backend is not a <c>THelpChatEngine</c>. A
    /// caller must check.</summary>
    function GetEngine: THelpChatEngine;
    /// <summary>Receives the commands the page posts to /api/ui/{command}, on
    /// the main thread. The page has no other bridge to its host: WebView2
    /// messages exist only in the VCL, FMX exposes none, a remote page has no
    /// native side at all. The server is the bridge everywhere.</summary>
    procedure SetOnUiCommand(const AHandler: THelpChatUiCommandEvent);
    /// <summary>Receives what the page wants turned into a PDF, on the main
    /// thread. Nothing is delivered when the engine is remote: the document
    /// would be built on the server and there is no channel back yet.</summary>
    procedure SetOnPdfRequest(const AHandler: THelpChatPdfRequestEvent);
  end;

implementation

end.
