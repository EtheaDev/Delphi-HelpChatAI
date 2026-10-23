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
///  The chat as a Delphi help viewer (System.HelpIntfs, framework independent).
///  Registered with the help manager while a component is active, it receives
///  what the VCL routes for F1 and for Application.HelpKeyword / HelpContext /
///  HelpShowTableOfContents, and what any code asks the help system directly,
///  exactly like a CHM or Markdown viewer would. The component (VCL or FMX)
///  implements <see cref="IHelpChatHelpTarget" />.
/// </summary>
unit HelpChatAI.HelpViewer;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.HelpIntfs;

const
  HELPCHAT_HELP_VIEWER_NAME = 'HelpChat';

type
  /// <summary>What the viewer needs from the component owning it.</summary>
  IHelpChatHelpTarget = interface
    ['{7C1E0B2A-5D3F-4E86-9A47-2B6C8D1F0E53}']
    /// <summary>False while the component is inactive or not meant to be the
    /// help viewer: the help system then ignores it.</summary>
    function IsHelpViewerActive: Boolean;
    procedure Open;
    procedure OpenForHelp(const AKeyword: string; const AContext: Integer);
    procedure Close;
  end;

  THelpChatHelpViewer = class(TInterfacedObject, ICustomHelpViewer, IExtendedHelpViewer)
  strict private
    FTarget: IHelpChatHelpTarget;
    FViewerID: Integer;
    FHelpManager: IHelpManager;
    function TargetActive: Boolean;
  public
    constructor Create(const ATarget: IHelpChatHelpTarget);
    /// <summary>Registers with the help manager of the process.</summary>
    procedure Register;
    /// <summary>Releases the registration and forgets the target.</summary>
    procedure Unregister;
    // ICustomHelpViewer
    function GetViewerName: string;
    function UnderstandsKeyword(const HelpString: string): Integer;
    function GetHelpStrings(const HelpString: string): TStringList;
    function CanShowTableOfContents: Boolean;
    procedure ShowTableOfContents;
    procedure ShowHelp(const HelpString: string);
    procedure NotifyID(const ViewerID: Integer);
    procedure SoftShutDown;
    procedure ShutDown;
    // IExtendedHelpViewer
    function UnderstandsTopic(const Topic: string): Boolean;
    procedure DisplayTopic(const Topic: string);
    function UnderstandsContext(const ContextID: THelpContext; const HelpFileName: string): Boolean;
    procedure DisplayHelpByContext(const ContextID: THelpContext; const HelpFileName: string);
    property ViewerID: Integer read FViewerID;
  end;

implementation

{ THelpChatHelpViewer }

constructor THelpChatHelpViewer.Create(const ATarget: IHelpChatHelpTarget);
begin
  inherited Create;
  // A component implements the target: no reference counting behind it, the
  // component calls Unregister before it goes away.
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
