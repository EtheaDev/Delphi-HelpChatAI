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
///  The chat as a Delphi help viewer (System.HelpIntfs, framework independent).
///  Registered with the help manager while a component is active, it receives
///  what the VCL routes for F1 and for Application.HelpKeyword / HelpContext /
///  HelpShowTableOfContents, and what any code asks the help system directly,
///  exactly like a CHM or Markdown viewer would. Whoever stands behind it
///  implements <see cref="IHelpChatHelpTarget" />: since several assistants
///  may be active at once, that is the coordinator of the framework unit, one
///  per process, which forwards a request to the assistant of the form the
///  user is on - one viewer for the help manager, however many assistants.
///  Everything here runs on the main thread, where the help system calls.
/// </summary>
unit HelpChatAI.HelpViewer;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.HelpIntfs;

const
  /// <summary>The name the help manager knows this viewer by, and the prefix
  /// of the one topic it offers when the user has to choose between
  /// viewers.</summary>
  HELPCHAT_HELP_VIEWER_NAME = 'HelpChat';

type
  /// <summary>What the viewer needs from whoever answers behind it: the
  /// coordinator of the process, which picks the assistant. The implementer
  /// is a component, not a reference-counted object: it must call
  /// <see cref="THelpChatHelpViewer.Unregister" /> before it goes away.</summary>
  IHelpChatHelpTarget = interface
    ['{7C1E0B2A-5D3F-4E86-9A47-2B6C8D1F0E53}']
    /// <summary>False while no assistant is active or meant to be the help
    /// viewer: the help system then ignores this viewer and another one (a
    /// CHM) gets the request. Asked again at every request, never
    /// cached.</summary>
    function IsHelpViewerActive: Boolean;
    /// <summary>The table of contents was asked for: open the chat as it
    /// is, with no question.</summary>
    procedure Open;
    /// <summary>A keyword, a topic or a context id was asked for: only one
    /// of the two is set, the other is empty or 0. The target adds the
    /// screen the user is on.</summary>
    procedure OpenForHelp(const AKeyword: string; const AContext: Integer);
    /// <summary>The help system is closing its viewers (the application is
    /// shutting down, or another viewer takes over): close every chat
    /// window.</summary>
    procedure Close;
  end;

  /// <summary>
  ///  The viewer the help manager holds. Reference counted, and the manager
  ///  keeps a reference of its own until <c>Unregister</c>: the owner keeps
  ///  an interface reference too and never frees it. It claims every keyword,
  ///  topic and context id while its target is active - the chat answers
  ///  about anything - and none when it is not.
  /// </summary>
  THelpChatHelpViewer = class(TInterfacedObject, ICustomHelpViewer, IExtendedHelpViewer)
  strict private
    FTarget: IHelpChatHelpTarget;
    FViewerID: Integer;
    FHelpManager: IHelpManager;
    function TargetActive: Boolean;
  public
    /// <summary><c>ATarget</c> is not kept alive by this reference when it
    /// is a component, which is the case: see
    /// <see cref="Unregister" />.</summary>
    constructor Create(const ATarget: IHelpChatHelpTarget);
    /// <summary>Registers with the help manager of the process. Does nothing
    /// when already registered.</summary>
    procedure Register;
    /// <summary>Releases the registration and forgets the target. The viewer
    /// is finished after this: it cannot be registered again with the same
    /// target, a new one is created instead. Safe to call twice, and after
    /// the manager shut down.</summary>
    procedure Unregister;
    // ICustomHelpViewer
    function GetViewerName: string;
    /// <summary>1 for any keyword while the target is active, 0 otherwise:
    /// one topic, whatever is asked. With another viewer answering for the
    /// same keyword the help system lets the user choose.</summary>
    function UnderstandsKeyword(const HelpString: string): Integer;
    /// <summary>The line the user sees in that choice. The caller owns the
    /// list.</summary>
    function GetHelpStrings(const HelpString: string): TStringList;
    function CanShowTableOfContents: Boolean;
    procedure ShowTableOfContents;
    procedure ShowHelp(const HelpString: string);
    procedure NotifyID(const ViewerID: Integer);
    /// <summary>Closes the chat windows; the registration stays.</summary>
    procedure SoftShutDown;
    /// <summary>The manager is going away: closes the chat windows and drops
    /// the reference to it, so that <c>Unregister</c> has nothing left to
    /// release.</summary>
    procedure ShutDown;
    // IExtendedHelpViewer
    function UnderstandsTopic(const Topic: string): Boolean;
    procedure DisplayTopic(const Topic: string);
    /// <summary>True for any context id while the target is active: the
    /// help file name is ignored, the chat has no file.</summary>
    function UnderstandsContext(const ContextID: THelpContext; const HelpFileName: string): Boolean;
    procedure DisplayHelpByContext(const ContextID: THelpContext; const HelpFileName: string);
    /// <summary>The id the help manager gave this viewer at registration,
    /// needed to release it.</summary>
    property ViewerID: Integer read FViewerID;
  end;

implementation

{ THelpChatHelpViewer }

constructor THelpChatHelpViewer.Create(const ATarget: IHelpChatHelpTarget);
begin
  inherited Create;
  // A component implements the target (the coordinator of the process): no
  // reference counting behind it, it calls Unregister before it goes away.
  FTarget := ATarget;
end;

procedure THelpChatHelpViewer.Register;
begin
  if not Assigned(FHelpManager) then
    System.HelpIntfs.RegisterViewer(Self, FHelpManager);
end;

procedure THelpChatHelpViewer.Unregister;
var
  LManager: IHelpManager;
begin
  FTarget := nil;
  if Assigned(FHelpManager) then
  begin
    LManager := FHelpManager;
    FHelpManager := nil;
    LManager.Release(FViewerID); // the manager drops its reference to this viewer
  end;
end;

function THelpChatHelpViewer.TargetActive: Boolean;
begin
  Result := Assigned(FTarget) and FTarget.IsHelpViewerActive;
end;

function THelpChatHelpViewer.GetViewerName: string;
begin
  Result := HELPCHAT_HELP_VIEWER_NAME;
end;

function THelpChatHelpViewer.UnderstandsKeyword(const HelpString: string): Integer;
begin
  // One topic for any keyword: the chat answers about anything the application
  // asks for. With another viewer registered too, the help system lets the user
  // choose (GetHelpStrings).
  if TargetActive then
    Result := 1
  else
    Result := 0;
end;

function THelpChatHelpViewer.GetHelpStrings(const HelpString: string): TStringList;
begin
  Result := TStringList.Create;
  if TargetActive then
    Result.Add(HELPCHAT_HELP_VIEWER_NAME + ': ' + HelpString);
end;

function THelpChatHelpViewer.CanShowTableOfContents: Boolean;
begin
  Result := TargetActive;
end;

procedure THelpChatHelpViewer.ShowTableOfContents;
begin
  if TargetActive then
    FTarget.Open;
end;

procedure THelpChatHelpViewer.ShowHelp(const HelpString: string);
begin
  if TargetActive then
    FTarget.OpenForHelp(HelpString, 0);
end;

procedure THelpChatHelpViewer.NotifyID(const ViewerID: Integer);
begin
  FViewerID := ViewerID;
end;

procedure THelpChatHelpViewer.SoftShutDown;
begin
  if Assigned(FTarget) then
    FTarget.Close;
end;

procedure THelpChatHelpViewer.ShutDown;
begin
  SoftShutDown;
  FHelpManager := nil;
end;

function THelpChatHelpViewer.UnderstandsTopic(const Topic: string): Boolean;
begin
  Result := TargetActive;
end;

procedure THelpChatHelpViewer.DisplayTopic(const Topic: string);
begin
  if TargetActive then
    FTarget.OpenForHelp(Topic, 0);
end;

function THelpChatHelpViewer.UnderstandsContext(const ContextID: THelpContext;
  const HelpFileName: string): Boolean;
begin
  Result := TargetActive;
end;

procedure THelpChatHelpViewer.DisplayHelpByContext(const ContextID: THelpContext;
  const HelpFileName: string);
begin
  if TargetActive then
    FTarget.OpenForHelp('', ContextID);
end;

end.
