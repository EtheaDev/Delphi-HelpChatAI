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
///  The transport is what the HTML panel talks to. The UI component (VCL or
///  FMX) does not know whether the chat is served by an HTTP server embedded in
///  the process (<c>THelpChatLocalServer</c>, desktop) or by a remote server
///  (mobile, or when the API key must stay server-side): it asks the transport
///  for the URL to load in the embedded browser and hands it the screen context.
/// </summary>
unit HelpChatAI.Transport;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  HelpChatAI.Types,
  HelpChatAI.Theme,
  HelpChatAI.Engine;

type
  /// <summary>A command the page sent to its host ('close'); delivered on the
  /// main thread.</summary>
  THelpChatUiCommandEvent = reference to procedure(const ACommand: string);

  IHelpChatTransport = interface
    ['{E2B7C4D9-5A31-4F8E-9C06-7D1B3A2E8F54}']
    /// <summary>Makes the panel reachable (starts the local server, or checks
    /// the remote one). Idempotent.</summary>
    procedure Start;
    procedure Stop;
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
    function GetContext: THelpChatContext;
    /// <summary>Colours of the host application, injected into the panel page
    /// when it is served (a running page is updated by the UI layer through
    /// window.hcApplyTheme). Empty theme = page defaults.</summary>
    procedure SetTheme(const ATheme: THelpChatTheme);
    function GetTheme: THelpChatTheme;
    /// <summary>The name the panel writes in its header and the icon it draws
    /// left of it, as a <c>data:image/...</c> URI. They travel for the same
    /// reason the colours do: an image list is a VCL object and a name may
    /// come from a published property, so only the client knows them. Empty
    /// name = the localized default; empty icon = no icon.</summary>
    procedure SetAssistant(const AName, AIconDataUri: string);
    function GetAssistantName: string;
    function GetAssistantIcon: string;
    /// <summary>The engine behind this transport (nil for a pure remote one).</summary>
    function GetEngine: THelpChatEngine;
    /// <summary>Receives the commands the page posts to /api/ui/{command}, on
    /// the main thread. The page has no other bridge to its host: WebView2
    /// messages exist only in the VCL, FMX exposes none, a remote page has no
    /// native side at all. The server is the bridge everywhere.</summary>
    procedure SetOnUiCommand(const AHandler: THelpChatUiCommandEvent);
  end;

implementation

end.
