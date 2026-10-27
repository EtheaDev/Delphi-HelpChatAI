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
///  The faces of the assistant: four icons, nine sizes each, compiled into
///  <c>HelpChatAI.Assistant.res</c> from the PNGs of <c>Images\</c>.
///
///  They live here, in the engine, and not in one of the framework packages,
///  because both of them need the same pictures: the VCL bubble draws them
///  through a <c>TVirtualImageList</c>, the FireMonkey one loads them into a
///  <c>TBitmap</c>, and the header of the chat page wants them as a
///  <c>data:</c> URI. A resource belongs to the module that links it, so the
///  module handle is published too: that is how
///  <c>Vcl.HelpChatAI.Bubble</c> reaches them from another package.
///
///  Adding an icon: the PNGs in <c>Images\</c>, an entry in
///  <c>resources/HelpChatAI.Assistant.rc</c>, <c>Tools\BuildResources.cmd</c>,
///  and the name in <c>HelpChatAssistantIconNames</c>.
/// </summary>
unit HelpChatAI.Assistant;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes;

const
  /// <summary>Names of the icons compiled into the component. They are also
  /// the resource names, upper-cased and with the size appended.</summary>
  HELPCHAT_ICON_AI_MALE = 'AIAssistant_Male';
  HELPCHAT_ICON_AI_FEMALE = 'AIAssistant_Female';
  HELPCHAT_ICON_MALE = 'Assistant_Male';
  HELPCHAT_ICON_FEMALE = 'Assistant_Female';
  /// <summary>The one used when the application picks none.</summary>
  HELPCHAT_ICON_DEFAULT = HELPCHAT_ICON_AI_MALE;

  /// <summary>Every icon ships in these sizes.</summary>
  HELPCHAT_ICON_SIZES: array[0..8] of Integer =
    (16, 18, 24, 32, 48, 64, 96, 128, 192);

  /// <summary>Side of the icon handed to the chat panel: the page draws it at
  /// 40 CSS pixels, so this is the 2x a high-DPI WebView asks for.</summary>
  HELPCHAT_ICON_PANEL_SIZE = 80;

/// <summary>The four names above, in the order the palette shows them.</summary>
function HelpChatAssistantIconNames: TArray<string>;

/// <summary>True when <c>AName</c> is one of them (case-insensitive).</summary>
function HelpChatIsAssistantIcon(const AName: string): Boolean;

/// <summary>Module the icons are compiled into. A resource is found through
/// the handle of the module that linked it, which is this one and not the
/// caller's: a VCL or FMX package is another BPL.</summary>
function HelpChatAssistantModule: THandle;

/// <summary>The PNG of one icon, at the smallest shipped size that is not
/// below <c>ASize</c> (the largest one when <c>ASize</c> is bigger than all of
/// them). Empty when the name is not one of ours or the resource is missing.</summary>
function HelpChatAssistantIconPng(const AName: string;
  const ASize: Integer = HELPCHAT_ICON_PANEL_SIZE): TBytes;

/// <summary>PNG bytes as the <c>data:image/png;base64,</c> URI the chat page
/// loads; empty for empty bytes. No line breaks: it goes in an attribute.</summary>
function HelpChatPngDataUri(const ABytes: TBytes): string;

/// <summary>One icon straight as a <c>data:</c> URI for the chat page, with no
/// drawing in between - the resource already is a PNG.</summary>
function HelpChatAssistantIconDataUri(const AName: string;
  const ASize: Integer = HELPCHAT_ICON_PANEL_SIZE): string;

implementation

{$R HelpChatAI.Assistant.res}

uses
  Winapi.Windows,   // FindResource and RT_RCDATA
  System.NetEncoding;

function HelpChatAssistantIconNames: TArray<string>;
begin
  Result := [HELPCHAT_ICON_AI_MALE, HELPCHAT_ICON_AI_FEMALE,
    HELPCHAT_ICON_MALE, HELPCHAT_ICON_FEMALE];
end;

function HelpChatIsAssistantIcon(const AName: string): Boolean;
var
  LName: string;
begin
  for LName in HelpChatAssistantIconNames do
    if SameText(LName, AName) then
      Exit(True);
  Result := False;
end;

function HelpChatAssistantModule: THandle;
begin
  Result := HInstance;
end;

/// <summary>The shipped size to ask for: the first one that is not smaller
/// than what the caller wants, so an icon is never scaled up.</summary>
function BestSize(const ASize: Integer): Integer;
var
  I: Integer;
begin
  Result := HELPCHAT_ICON_SIZES[High(HELPCHAT_ICON_SIZES)];
  for I := Low(HELPCHAT_ICON_SIZES) to High(HELPCHAT_ICON_SIZES) do
    if HELPCHAT_ICON_SIZES[I] >= ASize then
      Exit(HELPCHAT_ICON_SIZES[I]);
end;

function HelpChatAssistantIconPng(const AName: string;
  const ASize: Integer = HELPCHAT_ICON_PANEL_SIZE): TBytes;
var
  LResource: string;
  LStream: TResourceStream;
begin
  Result := nil;
  if not HelpChatIsAssistantIcon(AName) then
    Exit;
  LResource := UpperCase(AName) + '_' + IntToStr(BestSize(ASize));
  if FindResource(HInstance, PChar(LResource), RT_RCDATA) = 0 then
    Exit;
  LStream := TResourceStream.Create(HInstance, LResource, RT_RCDATA);
  try
    SetLength(Result, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(Result[0], LStream.Size);
  finally
    LStream.Free;
  end;
end;

function HelpChatPngDataUri(const ABytes: TBytes): string;
var
  LBase64: TBase64Encoding;
begin
  Result := '';
  if Length(ABytes) = 0 then
    Exit;
  // Zero characters per line: a data: URI has no newlines in it.
  LBase64 := TBase64Encoding.Create(0);
  try
    Result := 'data:image/png;base64,' +
      LBase64.EncodeBytesToString(@ABytes[0], Length(ABytes));
  finally
    LBase64.Free;
  end;
end;

function HelpChatAssistantIconDataUri(const AName: string;
  const ASize: Integer = HELPCHAT_ICON_PANEL_SIZE): string;
begin
  Result := HelpChatPngDataUri(HelpChatAssistantIconPng(AName, ASize));
end;

end.
