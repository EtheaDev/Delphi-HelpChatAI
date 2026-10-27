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
///  The round button that opens the chat, as a windowed control.
///
///  It used to be a TSpeedButton, and in a real application it disappeared: a
///  TGraphicControl has no window of its own, it is painted on the canvas of
///  its parent, and in the VCL a graphic control is always *below* every
///  windowed control of the same parent. BringToFront only reorders it among
///  the other graphic ones, so a grid, a page control or a panel covering the
///  corner simply hid it. A TCustomControl has a window, so it can be kept on
///  top with SetWindowPos, which is what this control does — and it asks to be
///  put back on top whenever the host form creates a child or is resized.
///
///  It is drawn by hand: an ellipse in the colours of the active VCL style
///  (BubbleColor overrides them) with the assistant icon in the middle. The
///  window is clipped to the ellipse, so the corners show whatever is behind.
///
///  The icon follows the usual Delphi contract: hook an image list to Images
///  and pick it with ImageIndex or ImageName. With no image list of your own,
///  the control uses the icons compiled into the component (a TVirtualImageList
///  over a shared TImageCollection, see HelpChatAssistantIcons), which hold
///  every size the DPI of the window may ask for.
/// </summary>
unit Vcl.HelpChatAI.Bubble;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.ImageCollection,
  Vcl.VirtualImageList,
  Vcl.ActnList,
  HelpChatAI.Assistant,
  System.UITypes;   // after Vcl.ImgList, whose own TImageIndex is deprecated

const
  /// <summary>Side of the bubble at 96 DPI.</summary>
  HELPCHAT_BUBBLE_DEF_SIZE = 44;
  /// <summary>Share of the side taken by the icon.</summary>
  HELPCHAT_BUBBLE_GLYPH_RATIO = 0.62;

  /// <summary>
  ///  Posted to the bubble (never broadcast) to ask it back on top of its
  ///  siblings. In the WM_APP range because nobody else talks to this window.
  /// </summary>
  HELPCHAT_CM_BRINGTOTOP = WM_APP + 117;

  // The names of the icons, their sizes and the one used by default live in
  // HelpChatAI.Assistant, with the resource: FireMonkey needs them too.
  // Re-declared here so the unit that has always published them still does.
  HELPCHAT_ICON_AI_MALE = HelpChatAI.Assistant.HELPCHAT_ICON_AI_MALE;
  HELPCHAT_ICON_AI_FEMALE = HelpChatAI.Assistant.HELPCHAT_ICON_AI_FEMALE;
  HELPCHAT_ICON_MALE = HelpChatAI.Assistant.HELPCHAT_ICON_MALE;
  HELPCHAT_ICON_FEMALE = HelpChatAI.Assistant.HELPCHAT_ICON_FEMALE;
  HELPCHAT_ICON_DEFAULT = HelpChatAI.Assistant.HELPCHAT_ICON_DEFAULT;
  HELPCHAT_ICON_PANEL_SIZE = HelpChatAI.Assistant.HELPCHAT_ICON_PANEL_SIZE;

type
  TVclHelpChatAIBubble = class;

  /// <summary>
  ///  Action link of the bubble: enabled state and image, nothing else. A
  ///  bubble is never grouped and never checked, so GroupIndex and Checked
  ///  are deliberately not linked.
  /// </summary>
  THelpChatBubbleActionLink = class(TControlActionLink)
  strict protected
    FClient: TVclHelpChatAIBubble;
    procedure AssignClient(AClient: TObject); override;
    function IsEnabledLinked: Boolean; override;
    function IsImageIndexLinked: Boolean; override;
    function IsImageNameLinked: Boolean; override;
    procedure SetEnabled(Value: Boolean); override;
    procedure SetImageIndex(Value: Integer); override;
  end;

  /// <summary>
  ///  The round "ask the assistant" button. Windowed, so it stays visible over
  ///  the controls of the host form.
  /// </summary>
  TVclHelpChatAIBubble = class(TCustomControl)
  strict private
    FImages: TCustomImageList;
    FImageChangeLink: TChangeLink;
    FImageIndex: TImageIndex;
    FImageName: TImageName;
    FBuiltIn: TVirtualImageList;
    FBubbleColor: TColor;
    FHot: Boolean;
    FPressed: Boolean;
    FHookedParent: TWinControl;
    FOldParentProc: TWndMethod;
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageName(const Value: TImageName);
    procedure SetBubbleColor(const Value: TColor);
    procedure ImageListChange(Sender: TObject);
    function BuiltInImages: TVirtualImageList;
    function IsImageNameStored: Boolean;
    procedure UpdateGlyphSize;
    procedure UpdateRegion;
    procedure HookParent(const AParent: TWinControl);
    procedure UnhookParent;
    procedure ParentWndProc(var AMessage: TMessage);
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure CMBringToTop(var Message: TMessage); message HELPCHAT_CM_BRINGTOTOP;
  strict protected
    function GetActionLinkClass: TControlActionLinkClass; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CreateWnd; override;
    procedure SetParent(AParent: TWinControl); override;
    procedure Resize; override;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    /// <summary>Colour of the disc: BubbleColor, else the style highlight.</summary>
    function FillColor: TColor;
    /// <summary>Colour of the fallback "?" glyph.</summary>
    function GlyphColor: TColor;
    /// <summary>Images, or the built-in list when the application gave none.</summary>
    function ActiveImages: TCustomImageList;
    /// <summary>Index to draw: ImageName wins over ImageIndex; -1 for none.</summary>
    function ActiveImageIndex: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>Puts the window back on top of its siblings.</summary>
    procedure BringToTop;
  published
    property Action;
    property Align;
    property Anchors;
    /// <summary>Colour of the disc; clNone (default) follows the VCL style.</summary>
    property BubbleColor: TColor read FBubbleColor write SetBubbleColor default clNone;
    property Constraints;
    property Cursor default crHandPoint;
    property Enabled;
    property Font;
    property Hint;
    /// <summary>Image list holding the icon; nil uses the built-in icons.</summary>
    property Images: TCustomImageList read FImages write SetImages;
    /// <summary>Icon by index, used when ImageName finds nothing.</summary>
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    /// <summary>Icon by name: with the built-in icons, one of HELPCHAT_ICON_*.</summary>
    property ImageName: TImageName read FImageName write SetImageName stored IsImageNameStored;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseUp;
  end;

/// <summary>
///  The icons compiled into the component, as a collection shared by every
///  bubble of the process: AIAssistant_Male, AIAssistant_Female,
///  Assistant_Male and Assistant_Female, each in nine sizes.
/// </summary>
function HelpChatAssistantIcons: TImageCollection;

/// <summary>
///  Which image of <c>AList</c> the bubble draws: <c>AImageName</c> first, then
///  <c>AImageIndex</c>, -1 for none. With the built-in collection
///  (<c>ABuiltIn</c>) an empty name means the default assistant. One rule, so
///  the bubble and the chat panel cannot show two different icons.
/// </summary>
function HelpChatIconIndex(const AList: TCustomImageList; const ABuiltIn: Boolean;
  const AImageIndex: TImageIndex; const AImageName: TImageName): Integer;

/// <summary>
///  The icon the bubble would draw, as a <c>data:image/png;base64,</c> URI for
///  the header of the chat panel; empty when there is no icon. <c>AImages</c>
///  nil means the icons compiled into the component, rendered at
///  <c>ASize</c>; an image list of the application is taken at its own size.
///  Call it on the main thread: it draws through GDI.
/// </summary>
function HelpChatIconDataUri(const AImages: TCustomImageList;
  const AImageIndex: TImageIndex; const AImageName: TImageName;
  const ASize: Integer = HELPCHAT_ICON_PANEL_SIZE): string;

implementation

// The resource itself is linked by HelpChatAI.Assistant, in the engine
// package: one copy for both frameworks.

uses
  System.Math,
  System.NetEncoding,
  Vcl.Forms,
  Vcl.Themes;

var
  GAssistantIcons: TImageCollection = nil;

function HelpChatAssistantIcons: TImageCollection;
var
  LName: string;
  LSuffixes: array of string;
  I: Integer;
begin
  if GAssistantIcons = nil then
  begin
    SetLength(LSuffixes, Length(HELPCHAT_ICON_SIZES));
    for I := Low(HELPCHAT_ICON_SIZES) to High(HELPCHAT_ICON_SIZES) do
      LSuffixes[I] := '_' + IntToStr(HELPCHAT_ICON_SIZES[I]);
    GAssistantIcons := TImageCollection.Create(nil);
    // HelpChatAssistantModule, not HInstance: the pictures are linked into the
    // engine package, and this unit is in another one.
    for LName in HelpChatAssistantIconNames do
      GAssistantIcons.Add(LName, HelpChatAssistantModule,
        UpperCase(LName), LSuffixes);
  end;
  Result := GAssistantIcons;
end;

function HelpChatIconIndex(const AList: TCustomImageList; const ABuiltIn: Boolean;
  const AImageIndex: TImageIndex; const AImageName: TImageName): Integer;
var
  LName: TImageName;
begin
  Result := -1;
  if AList = nil then
    Exit;
  LName := AImageName;
  if (LName = '') and ABuiltIn then
    LName := HELPCHAT_ICON_DEFAULT;      // built-in list: the default assistant
  if (LName <> '') and AList.IsImageNameAvailable then
    Result := AList.GetIndexByName(LName);
  if (Result < 0) and (AImageIndex >= 0) then
    Result := AImageIndex;
  if (Result < 0) or (Result >= AList.Count) then
    Result := -1;
end;

/// <summary>
///  One image of a list as a PNG with its transparency. The alpha of an image
///  list cannot be read back: GDI writes no alpha channel, so a bitmap drawn
///  from it comes back opaque. Drawing the same image twice, once over white
///  and once over black, gives it back exactly - where the icon is transparent
///  the two differ by 255, where it is solid they are equal - and the drawing
///  over black already *is* the colour multiplied by the alpha, which is what
///  a bitmap declared afDefined holds.
/// </summary>
function HelpChatIconPng(const AImages: TCustomImageList; const AIndex: Integer;
  const AStream: TStream): Boolean;
var
  LW, LH, X, Y, LAlpha: Integer;
  LWhite, LBlack, LIcon: TBitmap;
  LWic: TWICImage;
  LRowW, LRowB, LRowI: PRGBQuad;

  function Flat(const AColor: TColor): TBitmap;
  begin
    Result := TBitmap.Create;
    try
      Result.PixelFormat := pf32bit;
      Result.AlphaFormat := afIgnored;
      Result.SetSize(LW, LH);
      Result.Canvas.Brush.Style := bsSolid;
      Result.Canvas.Brush.Color := AColor;
      Result.Canvas.FillRect(Rect(0, 0, LW, LH));
      AImages.Draw(Result.Canvas, 0, 0, AIndex, True);
    except
      Result.Free;
      raise;
    end;
  end;

begin
  Result := False;
  if (AImages = nil) or (AIndex < 0) or (AIndex >= AImages.Count) then
    Exit;
  LW := AImages.Width;
  LH := AImages.Height;
  if (LW <= 0) or (LH <= 0) then
    Exit;

  LWhite := nil;
  LBlack := nil;
  LIcon := nil;
  LWic := nil;
  try
    LWhite := Flat(clWhite);
    LBlack := Flat(clBlack);

    LIcon := TBitmap.Create;
    LIcon.PixelFormat := pf32bit;
    LIcon.SetSize(LW, LH);
    // Declared before the pixels are written: setting it afterwards would make
    // the VCL premultiply values that already are.
    LIcon.AlphaFormat := afDefined;
    for Y := 0 to LH - 1 do
    begin
      LRowW := LWhite.ScanLine[Y];
      LRowB := LBlack.ScanLine[Y];
      LRowI := LIcon.ScanLine[Y];
      for X := 0 to LW - 1 do
      begin
        LAlpha := 255 - (Integer(LRowW^.rgbGreen) - Integer(LRowB^.rgbGreen));
        if LAlpha < 0 then
          LAlpha := 0
        else if LAlpha > 255 then
          LAlpha := 255;
        LRowI^.rgbBlue := LRowB^.rgbBlue;
        LRowI^.rgbGreen := LRowB^.rgbGreen;
        LRowI^.rgbRed := LRowB^.rgbRed;
        LRowI^.rgbReserved := Byte(LAlpha);
        Inc(LRowW);
        Inc(LRowB);
        Inc(LRowI);
      end;
    end;

    LWic := TWICImage.Create;
    LWic.Assign(LIcon);          // Assign resets the format, so PNG comes after
    LWic.ImageFormat := wifPng;
    LWic.SaveToStream(AStream);
    Result := AStream.Size > 0;
  finally
    LWic.Free;
    LIcon.Free;
    LBlack.Free;
    LWhite.Free;
  end;
end;

function HelpChatIconDataUri(const AImages: TCustomImageList;
  const AImageIndex: TImageIndex; const AImageName: TImageName;
  const ASize: Integer = HELPCHAT_ICON_PANEL_SIZE): string;
var
  LList: TCustomImageList;
  LOwned: TVirtualImageList;
  LIndex: Integer;
  LPng: TMemoryStream;
  LBase64: TBase64Encoding;
begin
  Result := '';
  LOwned := nil;
  try
    if Assigned(AImages) then
      LList := AImages
    else
    begin
      LOwned := TVirtualImageList.Create(nil);
      LOwned.ImageCollection := HelpChatAssistantIcons;
      LOwned.AutoFill := True;
      LOwned.BeginUpdate;
      try
        LOwned.Width := ASize;
        LOwned.Height := ASize;
      finally
        LOwned.EndUpdate;
      end;
      LList := LOwned;
    end;

    LIndex := HelpChatIconIndex(LList, AImages = nil, AImageIndex, AImageName);
    if LIndex < 0 then
      Exit;

    // Built-in icon: the resource already is a PNG with its transparency, so
    // there is nothing to draw and nothing to recover - just hand it over.
    if AImages = nil then
      Exit(HelpChatAssistantIconDataUri(LList.GetNameByIndex(LIndex), ASize));

    LPng := TMemoryStream.Create;
    try
      if not HelpChatIconPng(LList, LIndex, LPng) then
        Exit;
      // No line breaks: this string goes into an src attribute.
      LBase64 := TBase64Encoding.Create(0);
      try
        Result := 'data:image/png;base64,' +
          LBase64.EncodeBytesToString(LPng.Memory, Integer(LPng.Size));
      finally
        LBase64.Free;
      end;
    finally
      LPng.Free;
    end;
  finally
    LOwned.Free;
  end;
end;

/// <summary>Mixes a colour towards white (APercent > 0) or black (< 0).</summary>
function ShiftColor(const AColor: TColor; const APercent: Integer): TColor;
var
  LRgb: Longint;
  LR, LG, LB: Integer;

  function Mix(const AValue: Integer): Byte;
  begin
    if APercent >= 0 then
      Result := AValue + MulDiv(255 - AValue, APercent, 100)
    else
      Result := AValue - MulDiv(AValue, -APercent, 100);
  end;

begin
  LRgb := ColorToRGB(AColor);
  LR := GetRValue(LRgb);
  LG := GetGValue(LRgb);
  LB := GetBValue(LRgb);
  Result := TColor(RGB(Mix(LR), Mix(LG), Mix(LB)));
end;

{ THelpChatBubbleActionLink }

procedure THelpChatBubbleActionLink.AssignClient(AClient: TObject);
begin
  inherited AssignClient(AClient);
  FClient := AClient as TVclHelpChatAIBubble;
end;

function THelpChatBubbleActionLink.IsEnabledLinked: Boolean;
begin
  Result := Assigned(FClient) and inherited IsEnabledLinked and
    (FClient.Enabled = TCustomAction(Action).Enabled);
end;

function THelpChatBubbleActionLink.IsImageIndexLinked: Boolean;
begin
  Result := Assigned(FClient) and inherited IsImageIndexLinked and
    (FClient.ImageIndex = TCustomAction(Action).ImageIndex);
end;

function THelpChatBubbleActionLink.IsImageNameLinked: Boolean;
begin
  Result := Assigned(FClient) and inherited IsImageNameLinked and
    (FClient.ImageName = TCustomAction(Action).ImageName);
end;

procedure THelpChatBubbleActionLink.SetEnabled(Value: Boolean);
begin
  if IsEnabledLinked then
    FClient.Enabled := Value;
end;

procedure THelpChatBubbleActionLink.SetImageIndex(Value: Integer);
begin
  if IsImageIndexLinked then
    FClient.ImageIndex := Value;
end;

{ TVclHelpChatAIBubble }

constructor TVclHelpChatAIBubble.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csClickEvents, csDoubleClicks,
    csReplicatable] - [csAcceptsControls];
  DoubleBuffered := True;
  Cursor := crHandPoint;
  FBubbleColor := clNone;
  FImageIndex := -1;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImageListChange;
  Width := HELPCHAT_BUBBLE_DEF_SIZE;
  Height := HELPCHAT_BUBBLE_DEF_SIZE;
end;

destructor TVclHelpChatAIBubble.Destroy;
begin
  UnhookParent;
  Images := nil;                 // unregisters the change link first
  FreeAndNil(FImageChangeLink);
  inherited Destroy;
end;

function TVclHelpChatAIBubble.GetActionLinkClass: TControlActionLinkClass;
begin
  Result := THelpChatBubbleActionLink;
end;

procedure TVclHelpChatAIBubble.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FImages) then
    Images := nil;
end;

{ --- images ------------------------------------------------------------- }

function TVclHelpChatAIBubble.BuiltInImages: TVirtualImageList;
begin
  if FBuiltIn = nil then
  begin
    FBuiltIn := TVirtualImageList.Create(Self);
    FBuiltIn.ImageCollection := HelpChatAssistantIcons;
    FBuiltIn.AutoFill := True;
    UpdateGlyphSize;
  end;
  Result := FBuiltIn;
end;

function TVclHelpChatAIBubble.ActiveImages: TCustomImageList;
begin
  if Assigned(FImages) then
    Result := FImages
  else
    Result := BuiltInImages;
end;

function TVclHelpChatAIBubble.ActiveImageIndex: Integer;
begin
  Result := HelpChatIconIndex(ActiveImages, FImages = nil, FImageIndex, FImageName);
end;

function TVclHelpChatAIBubble.IsImageNameStored: Boolean;
begin
  Result := FImageName <> '';
end;

procedure TVclHelpChatAIBubble.SetImages(const Value: TCustomImageList);
begin
  if FImages = Value then
    Exit;
  if Assigned(FImages) then
  begin
    FImages.UnRegisterChanges(FImageChangeLink);
    FImages.RemoveFreeNotification(Self);
  end;
  FImages := Value;
  if Assigned(FImages) then
  begin
    FImages.RegisterChanges(FImageChangeLink);
    FImages.FreeNotification(Self);
  end
  else
    UpdateGlyphSize;             // back to the built-in list: size it again
  Invalidate;
end;

procedure TVclHelpChatAIBubble.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex = Value then
    Exit;
  FImageIndex := Value;
  Invalidate;
end;

procedure TVclHelpChatAIBubble.SetImageName(const Value: TImageName);
begin
  if FImageName = Value then
    Exit;
  FImageName := Value;
  Invalidate;
end;

procedure TVclHelpChatAIBubble.ImageListChange(Sender: TObject);
begin
  Invalidate;
end;

procedure TVclHelpChatAIBubble.UpdateGlyphSize;
var
  LSide: Integer;
begin
  if FBuiltIn = nil then
    Exit;
  LSide := Max(8, Round(Min(Width, Height) * HELPCHAT_BUBBLE_GLYPH_RATIO));
  if (FBuiltIn.Width = LSide) and (FBuiltIn.Height = LSide) then
    Exit;
  FBuiltIn.BeginUpdate;
  try
    FBuiltIn.Width := LSide;
    FBuiltIn.Height := LSide;
  finally
    FBuiltIn.EndUpdate;
  end;
end;

{ --- staying on top ------------------------------------------------------ }

procedure TVclHelpChatAIBubble.BringToTop;
begin
  if HandleAllocated and Visible then
    SetWindowPos(Handle, HWND_TOP, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure TVclHelpChatAIBubble.CMBringToTop(var Message: TMessage);
begin
  BringToTop;
end;

procedure TVclHelpChatAIBubble.HookParent(const AParent: TWinControl);
begin
  if FHookedParent = AParent then
    Exit;
  UnhookParent;
  if (AParent = nil) or (csDesigning in ComponentState) then
    Exit;
  FHookedParent := AParent;
  FOldParentProc := AParent.WindowProc;
  AParent.WindowProc := ParentWndProc;
end;

procedure TVclHelpChatAIBubble.UnhookParent;
var
  LProc: TWndMethod;
  LOurs, LCurrent: TMethod;
begin
  if FHookedParent = nil then
    Exit;
  // Only unhook when the chain is still ours: someone may have hooked after us.
  LProc := ParentWndProc;
  LOurs := TMethod(LProc);
  LCurrent := TMethod(FHookedParent.WindowProc);
  if (LCurrent.Code = LOurs.Code) and (LCurrent.Data = LOurs.Data) then
    FHookedParent.WindowProc := FOldParentProc;
  FHookedParent := nil;
  FOldParentProc := nil;
end;

procedure TVclHelpChatAIBubble.ParentWndProc(var AMessage: TMessage);
begin
  if Assigned(FOldParentProc) then
    FOldParentProc(AMessage);
  // A new child, a resize or a reorder can bury the bubble: ask to come back
  // on top, but later — the host is in the middle of its own work right now.
  case AMessage.Msg of
    CM_CONTROLLISTCHANGE, CM_CONTROLCHANGE, WM_PARENTNOTIFY, WM_SIZE,
    WM_WINDOWPOSCHANGED:
      if HandleAllocated and Visible then
        PostMessage(Handle, HELPCHAT_CM_BRINGTOTOP, 0, 0);
  end;
end;

procedure TVclHelpChatAIBubble.SetParent(AParent: TWinControl);
begin
  if AParent <> Parent then
    UnhookParent;
  inherited SetParent(AParent);
  if not (csDestroying in ComponentState) then
    HookParent(Parent);
end;

{ --- window and painting ------------------------------------------------- }

procedure TVclHelpChatAIBubble.CreateWnd;
begin
  inherited CreateWnd;
  UpdateRegion;
  BringToTop;
end;

procedure TVclHelpChatAIBubble.UpdateRegion;
var
  LRegion: HRGN;
begin
  if not HandleAllocated then
    Exit;
  LRegion := CreateEllipticRgn(0, 0, Width + 1, Height + 1);
  if SetWindowRgn(Handle, LRegion, True) = 0 then
    DeleteObject(LRegion);       // refused: the region is still ours to free
end;

procedure TVclHelpChatAIBubble.Resize;
begin
  inherited Resize;
  UpdateRegion;
  UpdateGlyphSize;
  Invalidate;
end;

procedure TVclHelpChatAIBubble.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited ChangeScale(M, D, isDpiChange);
  UpdateGlyphSize;               // the new side asks the collection for another size
end;

function TVclHelpChatAIBubble.FillColor: TColor;
begin
  if FBubbleColor <> clNone then
    Exit(FBubbleColor);
  if StyleServices.Enabled then
    Result := StyleServices.GetSystemColor(clHighlight)
  else
    Result := clHighlight;
end;

function TVclHelpChatAIBubble.GlyphColor: TColor;
begin
  if StyleServices.Enabled then
    Result := StyleServices.GetSystemColor(clHighlightText)
  else
    Result := clHighlightText;
end;

procedure TVclHelpChatAIBubble.Paint;
var
  LRect: TRect;
  LFill: TColor;
  LImages: TCustomImageList;
  LIndex: Integer;
  LText: string;
begin
  LRect := ClientRect;
  LFill := FillColor;
  if not Enabled then
    LFill := ShiftColor(LFill, 35)
  else if FPressed then
    LFill := ShiftColor(LFill, -18)
  else if FHot then
    LFill := ShiftColor(LFill, 12);

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := LFill;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := ShiftColor(LFill, -25);
  Canvas.Ellipse(LRect);

  LImages := ActiveImages;
  LIndex := ActiveImageIndex;
  if Assigned(LImages) and (LIndex >= 0) then
    LImages.Draw(Canvas, (Width - LImages.Width) div 2,
      (Height - LImages.Height) div 2, LIndex, Enabled)
  else
  begin
    // No icon available: the question mark the bubble has always shown.
    LText := '?';
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Assign(Font);
    Canvas.Font.Color := GlyphColor;
    Canvas.Font.Style := Canvas.Font.Style + [fsBold];
    Canvas.Font.Height := -Round(Height * 0.5);
    Canvas.TextRect(LRect, LText, [tfCenter, tfVerticalCenter, tfSingleLine]);
  end;
end;

{ --- interaction --------------------------------------------------------- }

procedure TVclHelpChatAIBubble.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FPressed := True;
    Invalidate;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TVclHelpChatAIBubble.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if FPressed then
  begin
    FPressed := False;
    Invalidate;
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TVclHelpChatAIBubble.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FHot := True;
  Invalidate;
end;

procedure TVclHelpChatAIBubble.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHot := False;
  FPressed := False;
  Invalidate;
end;

procedure TVclHelpChatAIBubble.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TVclHelpChatAIBubble.CMVisibleChanged(var Message: TMessage);
begin
  inherited;
  if Visible then
    BringToTop;
end;

procedure TVclHelpChatAIBubble.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TVclHelpChatAIBubble.SetBubbleColor(const Value: TColor);
begin
  if FBubbleColor = Value then
    Exit;
  FBubbleColor := Value;
  Invalidate;
end;

initialization

finalization
  FreeAndNil(GAssistantIcons);

end.
