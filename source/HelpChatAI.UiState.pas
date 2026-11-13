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
///  Where the user left things: the file of the UI state of a profile
///  (<c>helpchatai-ui[-Profile].json</c> in the folder of the application
///  data), and the place of the bubble on each form that hosts it.
///
///  The file holds one key per thing remembered - <c>"panel"</c>, the bounds
///  of the own window of the chat, and <c>"bubbles"</c>, the place of the
///  bubble per class of host form - and each is written without touching the
///  others (<c>HelpChatUiStateWrite</c>): with a writer that replaced the whole
///  file, moving the bubble would have forgotten the window, and the other
///  way round.
///
///  A bubble is remembered by the corner of its form it is nearest to and its
///  distance from the two edges of that corner, in pixels at 96 DPI: dragged
///  to the top left it stays at the top left when the form grows, dragged
///  near the bottom right it follows that corner, as it does by default. The
///  frameworks anchor it to the same corner, so the rule holds while the form
///  is resized too.
///
///  RTL only, shared by the VCL and FireMonkey components; main thread, like
///  the controls that call it. Nothing here ever raises for the file: the UI
///  state is a convenience.
/// </summary>
unit HelpChatAI.UiState;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON;

const
  /// <summary>Name of the file of the UI state, before the profile is put in
  /// it (<c>THelpChatSettings.ProfileFileName</c>).</summary>
  HELPCHAT_UI_STATE_FILENAME = 'helpchatai-ui.json';
  /// <summary>Key of the bounds of the own window of the chat.</summary>
  HELPCHAT_UI_STATE_PANEL = 'panel';
  /// <summary>Key of the places of the bubble, one per class of host form.</summary>
  HELPCHAT_UI_STATE_BUBBLES = 'bubbles';

type
  /// <summary>The corner of the host form a bubble keeps its distance from.</summary>
  THelpChatBubbleCorner = (hbcBottomRight, hbcBottomLeft, hbcTopRight, hbcTopLeft);

  /// <summary>
  ///  Where a bubble sits on its form: a corner and the distance from its two
  ///  edges, in pixels at 96 DPI (VCL) - FireMonkey coordinates are already
  ///  independent of the DPI, so there the scale is 1.
  /// </summary>
  THelpChatBubblePlace = record
    Corner: THelpChatBubbleCorner;
    /// <summary>Distance from the left or the right edge of the client area.</summary>
    OffsetX: Integer;
    /// <summary>Distance from the top or the bottom edge of the client area.</summary>
    OffsetY: Integer;
    /// <summary>A corner and two distances.</summary>
    class function Create(const ACorner: THelpChatBubbleCorner;
      const AOffsetX, AOffsetY: Integer): THelpChatBubblePlace; static;
    /// <summary>The place of a bubble of side <c>ASize</c> at
    /// <c>ALeft</c>, <c>ATop</c> of a client area of the given size: the
    /// corner of the quarter its centre is in, the distances divided by
    /// <c>AScale</c> (the DPI of the form over 96). A bubble partly outside
    /// counts as touching the edge.</summary>
    class function FromBounds(const ALeft, ATop, ASize, AClientWidth,
      AClientHeight, AScale: Single): THelpChatBubblePlace; static;
    /// <summary>Left and top of a bubble of side <c>ASize</c> in a client
    /// area of the given size, kept inside it: a form smaller than the one
    /// the place was taken on still shows the whole bubble.</summary>
    procedure ToPosition(const ASize, AClientWidth, AClientHeight, AScale: Single;
      out ALeft, ATop: Single);
    /// <summary>True for the two corners on the left.</summary>
    function IsLeft: Boolean;
    /// <summary>True for the two corners at the top.</summary>
    function IsTop: Boolean;
  end;

/// <summary>The whole UI state of a file: an empty object when the file is
/// missing, unreadable or not a JSON object. Never nil; the caller frees it.</summary>
function HelpChatUiStateLoad(const AFileName: string): TJSONObject;

/// <summary>Puts <c>AValue</c> under <c>AKey</c> in the file, keeping every
/// other key; nil removes the key. Takes ownership of <c>AValue</c> whatever
/// happens. False when the file could not be written.</summary>
function HelpChatUiStateWrite(const AFileName, AKey: string;
  const AValue: TJSONValue): Boolean;

/// <summary>The place the bubble of the forms of class <c>AFormClass</c> was
/// left at, False when none was remembered or the entry is not readable.</summary>
function HelpChatLoadBubblePlace(const AFileName, AFormClass: string;
  out APlace: THelpChatBubblePlace): Boolean;

/// <summary>Remembers the place of the bubble of the forms of class
/// <c>AFormClass</c>, keeping the other forms and the rest of the file.</summary>
function HelpChatSaveBubblePlace(const AFileName, AFormClass: string;
  const APlace: THelpChatBubblePlace): Boolean;

/// <summary>Forgets the place of the bubble of the forms of class
/// <c>AFormClass</c>: the next bubble goes back to the default corner.</summary>
function HelpChatForgetBubblePlace(const AFileName, AFormClass: string): Boolean;

implementation

uses
  System.Math,
  System.IOUtils;

const
  CORNER_NAMES: array[THelpChatBubbleCorner] of string =
    ('bottomRight', 'bottomLeft', 'topRight', 'topLeft');

{ THelpChatBubblePlace }

class function THelpChatBubblePlace.Create(const ACorner: THelpChatBubbleCorner;
  const AOffsetX, AOffsetY: Integer): THelpChatBubblePlace;
begin
  Result.Corner := ACorner;
  Result.OffsetX := AOffsetX;
  Result.OffsetY := AOffsetY;
end;

class function THelpChatBubblePlace.FromBounds(const ALeft, ATop, ASize,
  AClientWidth, AClientHeight, AScale: Single): THelpChatBubblePlace;
var
  LLeft, LTop: Boolean;
  LScale, LX, LY: Single;
begin
  LScale := AScale;
  if LScale <= 0 then
    LScale := 1;
  LLeft := ALeft + ASize / 2 < AClientWidth / 2;
  LTop := ATop + ASize / 2 < AClientHeight / 2;
  if LLeft then
    LX := ALeft
  else
    LX := AClientWidth - ALeft - ASize;
  if LTop then
    LY := ATop
  else
    LY := AClientHeight - ATop - ASize;
  if LTop then
  begin
    if LLeft then
      Result.Corner := hbcTopLeft
    else
      Result.Corner := hbcTopRight;
  end
  else if LLeft then
    Result.Corner := hbcBottomLeft
  else
    Result.Corner := hbcBottomRight;
  Result.OffsetX := Max(0, Round(LX / LScale));
  Result.OffsetY := Max(0, Round(LY / LScale));
end;

function THelpChatBubblePlace.IsLeft: Boolean;
begin
  Result := Corner in [hbcBottomLeft, hbcTopLeft];
end;

function THelpChatBubblePlace.IsTop: Boolean;
begin
  Result := Corner in [hbcTopRight, hbcTopLeft];
end;

procedure THelpChatBubblePlace.ToPosition(const ASize, AClientWidth,
  AClientHeight, AScale: Single; out ALeft, ATop: Single);
var
  LScale: Single;
begin
  LScale := AScale;
  if LScale <= 0 then
    LScale := 1;
  if IsLeft then
    ALeft := OffsetX * LScale
  else
    ALeft := AClientWidth - ASize - OffsetX * LScale;
  if IsTop then
    ATop := OffsetY * LScale
  else
    ATop := AClientHeight - ASize - OffsetY * LScale;
  ALeft := Max(0, Min(ALeft, AClientWidth - ASize));
  ATop := Max(0, Min(ATop, AClientHeight - ASize));
end;

{ the file }

function HelpChatUiStateLoad(const AFileName: string): TJSONObject;
var
  LValue: TJSONValue;
begin
  LValue := nil;
  try
    if (AFileName <> '') and TFile.Exists(AFileName) then
      LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(AFileName, TEncoding.UTF8));
  except
    LValue := nil;
  end;
  if LValue is TJSONObject then
    Exit(TJSONObject(LValue));
  LValue.Free;
  Result := TJSONObject.Create;
end;

function HelpChatUiStateWrite(const AFileName, AKey: string;
  const AValue: TJSONValue): Boolean;
var
  LRoot: TJSONObject;
begin
  Result := False;
  LRoot := HelpChatUiStateLoad(AFileName);
  try
    LRoot.RemovePair(AKey).Free;
    if Assigned(AValue) then
      LRoot.AddPair(AKey, AValue);
    try
      ForceDirectories(ExtractFilePath(AFileName));
      TFile.WriteAllText(AFileName, LRoot.ToJSON, TEncoding.UTF8);
      Result := True;
    except
      // UI state is a convenience: never fail for it.
    end;
  finally
    LRoot.Free;
  end;
end;

function HelpChatLoadBubblePlace(const AFileName, AFormClass: string;
  out APlace: THelpChatBubblePlace): Boolean;
var
  LRoot, LBubbles, LEntry: TJSONObject;
  LCorner: THelpChatBubbleCorner;
  LName: string;
begin
  Result := False;
  APlace := THelpChatBubblePlace.Create(hbcBottomRight, 0, 0);
  LRoot := HelpChatUiStateLoad(AFileName);
  try
    if not (LRoot.GetValue(HELPCHAT_UI_STATE_BUBBLES) is TJSONObject) then
      Exit;
    LBubbles := TJSONObject(LRoot.GetValue(HELPCHAT_UI_STATE_BUBBLES));
    if not (LBubbles.GetValue(AFormClass) is TJSONObject) then
      Exit;
    LEntry := TJSONObject(LBubbles.GetValue(AFormClass));
    LName := LEntry.GetValue<string>('corner', '');
    for LCorner := Low(THelpChatBubbleCorner) to High(THelpChatBubbleCorner) do
      if SameText(LName, CORNER_NAMES[LCorner]) then
      begin
        APlace := THelpChatBubblePlace.Create(LCorner,
          Max(0, LEntry.GetValue<Integer>('x', 0)), Max(0, LEntry.GetValue<Integer>('y', 0)));
        Exit(True);
      end;
  finally
    LRoot.Free;
  end;
end;

/// <summary>The "bubbles" object of the file with the entry of one form
/// replaced (or removed, when <c>AEntry</c> is nil), written back.</summary>
function WriteBubbleEntry(const AFileName, AFormClass: string;
  const AEntry: TJSONObject): Boolean;
var
  LRoot, LBubbles: TJSONObject;
begin
  LRoot := HelpChatUiStateLoad(AFileName);
  try
    if LRoot.GetValue(HELPCHAT_UI_STATE_BUBBLES) is TJSONObject then
      LBubbles := TJSONObject(LRoot.GetValue(HELPCHAT_UI_STATE_BUBBLES).Clone)
    else
      LBubbles := TJSONObject.Create;
  finally
    LRoot.Free;
  end;
  LBubbles.RemovePair(AFormClass).Free;
  if Assigned(AEntry) then
    LBubbles.AddPair(AFormClass, AEntry);
  if LBubbles.Count = 0 then
  begin
    LBubbles.Free;
    LBubbles := nil;
  end;
  Result := HelpChatUiStateWrite(AFileName, HELPCHAT_UI_STATE_BUBBLES, LBubbles);
end;

function HelpChatSaveBubblePlace(const AFileName, AFormClass: string;
  const APlace: THelpChatBubblePlace): Boolean;
var
  LEntry: TJSONObject;
begin
  LEntry := TJSONObject.Create;
  LEntry.AddPair('corner', CORNER_NAMES[APlace.Corner]);
  LEntry.AddPair('x', TJSONNumber.Create(APlace.OffsetX));
  LEntry.AddPair('y', TJSONNumber.Create(APlace.OffsetY));
  Result := WriteBubbleEntry(AFileName, AFormClass, LEntry);
end;

function HelpChatForgetBubblePlace(const AFileName, AFormClass: string): Boolean;
begin
  Result := WriteBubbleEntry(AFileName, AFormClass, nil);
end;

end.
