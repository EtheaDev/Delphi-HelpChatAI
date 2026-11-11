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
///  It is drawn by hand, with GDI+: an ellipse in the colours of the active
///  VCL style (BubbleColor overrides them) with the assistant icon in the
///  middle. From Windows 8 on it is a layered child window with per-pixel
///  alpha, so its edge blends with whatever is behind and a click on a
///  transparent corner goes through; where that is not possible (the
///  designer, Windows 7, no manifest) the window is clipped to the ellipse
///  by a region instead.
///
///  There is one bubble per assistant, on the host form of that assistant:
///  nothing here is per process but the shared collection of built-in icons.
///  A bubble listens to the window procedure of its own parent through one
///  hook per parent, shared by the bubbles on it: two assistants that
///  resolve to the same form come and go in any order.
///  The control knows nothing of the chat: it is a button with an icon, and
///  what a click does is the <c>OnClick</c> its owner assigns.
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
    /// <summary>The bubble this link serves; the inherited client is typed
    /// <c>TControl</c>, whose image properties are not reachable.</summary>
    FClient: TVclHelpChatAIBubble;
    procedure AssignClient(AClient: TObject); override;
    /// <summary>Linked while the bubble still has the value of the action:
    /// a property set by hand on the bubble stops following it.</summary>
    function IsEnabledLinked: Boolean; override;
    function IsImageIndexLinked: Boolean; override;
    function IsImageNameLinked: Boolean; override;
    procedure SetEnabled(Value: Boolean); override;
    procedure SetImageIndex(Value: Integer); override;
  end;

  /// <summary>
  ///  The round "ask the assistant" button. Windowed, so it stays visible over
  ///  the controls of the host form. The component creates one at run time
  ///  on the host form of the assistant and mirrors its own <c>Images</c>,
  ///  <c>ImageIndex</c> and <c>ImageName</c> on it; an application may also
  ///  create one itself and give it an <c>OnClick</c> or an <c>Action</c>.
  ///  Main thread only, like every control.
  /// </summary>
  TVclHelpChatAIBubble = class(TCustomControl)
  strict private
    FImages: TCustomImageList;
    // Tells the bubble to repaint when the image list of the application
    // changes its pictures.
    FImageChangeLink: TChangeLink;
    FImageIndex: TImageIndex;
    FImageName: TImageName;
    // The built-in icons at the size of this bubble; created on first use,
    // owned by the bubble, over the collection shared by the process.
    FBuiltIn: TVirtualImageList;
    FBubbleColor: TColor;
    FHot: Boolean;
    FPressed: Boolean;
    // The parent whose messages this bubble listens to, through the hook
    // the bubbles of one parent share (TBubbleParentHook).
    FHookedParent: TWinControl;
    // A layered child window (Windows 8 and later, with the manifest every
    // Delphi application carries) painted with per-pixel alpha: the only way
    // to an edge that is smooth over whatever lies under the bubble. False
    // in the designer, on Windows 7, or when the system refused it: then the
    // window is clipped by a region, as it always was, and only the drawing
    // inside it is antialiased.
    FLayered: Boolean;
    /// <summary>Whether to ask Windows for a layered window at all: not in
    /// the designer, not before Windows 8.</summary>
    function WantsLayered: Boolean;
    /// <summary>Draws the bubble into a premultiplied 32-bit section and
    /// pushes it to the layered window. False when Windows refused, which
    /// the caller takes as "fall back to the region".</summary>
    function RenderLayered: Boolean;
    /// <summary>The drawing itself, shared by the two ways of showing it:
    /// the disc, its rim, then the icon with its alpha or a question mark.
    /// <c>AGraphics</c> is a <c>TGPGraphics</c>, typed <c>TObject</c> so
    /// that the interface of the unit does not use the GDI+ units.</summary>
    procedure DrawBubble(const AGraphics: TObject; const AWidth, AHeight: Integer);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageName(const Value: TImageName);
    procedure SetBubbleColor(const Value: TColor);
    procedure ImageListChange(Sender: TObject);
    function BuiltInImages: TVirtualImageList;
    function IsImageNameStored: Boolean;
    /// <summary>Sizes the built-in list to the share of the side the icon
    /// takes, so that the collection hands out the picture made for it.</summary>
    procedure UpdateGlyphSize;
    /// <summary>The shape of the window: none when layered (the alpha is
    /// the shape), an ellipse otherwise.</summary>
    procedure UpdateRegion;
    /// <summary>Starts listening to the messages of the parent. Its
    /// <c>WindowProc</c> is replaced once, by an object the bubbles of that
    /// parent share, so two assistants on one form can come and go in any
    /// order. Never in the designer.</summary>
    procedure HookParent(const AParent: TWinControl);
    /// <summary>Stops listening; the last bubble to leave puts the
    /// procedure of the parent back, when the parent still points at the
    /// hook.</summary>
    procedure UnhookParent;
  private
    /// <summary>Called by the hook after the parent handled a message: a
    /// request to come back on top for the messages that can bury the
    /// bubble.</summary>
    procedure ParentMessage(const AMsg: Cardinal);
  strict private
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure CMBringToTop(var Message: TMessage); message HELPCHAT_CM_BRINGTOTOP;
  strict protected
    function GetActionLinkClass: TControlActionLinkClass; override;
    /// <summary>An image list that goes away takes the bubble back to the
    /// built-in icons.</summary>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// <summary>Asks for <c>WS_EX_LAYERED</c> where it can work.</summary>
    procedure CreateParams(var Params: TCreateParams); override;
    /// <summary>Finds out whether the window really is layered - the first
    /// push is the test - and falls back to the region when it is not; then
    /// shapes the window and raises it.</summary>
    procedure CreateWnd; override;
    /// <summary>Moves the hook with the bubble: off the old parent, onto
    /// the new one.</summary>
    procedure SetParent(AParent: TWinControl); override;
    procedure Resize; override;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    /// <summary>The region fallback only: a layered window is never asked
    /// to paint.</summary>
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
    /// <summary>A 44-pixel disc (at 96 DPI) with no image list: until
    /// <c>Images</c> is set it shows the default built-in assistant.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Takes its hook off the parent first, when the chain is
    /// still its own.</summary>
    destructor Destroy; override;
    /// <summary>Puts the window back on top of its siblings, without
    /// activating it. Nothing while it has no window or is hidden. The
    /// bubble calls it by itself whenever the parent changes its children
    /// or its size.</summary>
    procedure BringToTop;
    /// <summary>A layered window gets no WM_PAINT: every change of state is
    /// pushed to it here instead.</summary>
    procedure Invalidate; override;
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
///  Assistant_Male and Assistant_Female, each in nine sizes. Created on
///  first use, on the main thread, and freed when the unit finalizes: never
///  free it, and do not add to it - every assistant of the application
///  reads the same one.
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
  System.Generics.Collections,
  System.NetEncoding,
  System.Types,   // Point is inline: without this unit Delphi 10.4 reports H2443
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ,
  Vcl.Forms,
  Vcl.Themes;

type
  // Color is protected in TControl: the region fallback paints its corners with it.
  TWinControlAccess = class(TWinControl);

  // The WindowProc of a parent, replaced once for all the bubbles on it.
  // Each bubble used to replace it by itself and keep the one it found:
  // with two on a form, the one destroyed first could not restore anything
  // (the parent no longer pointed at it) and stayed in the chain of the
  // other as a method of a freed object. Here the parent calls one object,
  // which lives until no bubble needs it - or, when somebody else hooked
  // the parent after it and is calling it as "the previous procedure",
  // until the parent goes away.
  TBubbleParentHook = class(TComponent)
  strict private
    FParent: TWinControl;
    FOldProc: TWndMethod;
    FBubbles: TList<TVclHelpChatAIBubble>;
    procedure WndProc(var AMessage: TMessage);
    function IsCurrent: Boolean;
    class function Find(const AParent: TWinControl): TBubbleParentHook; static;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor CreateFor(const AParent: TWinControl);
    destructor Destroy; override;
    class procedure Attach(const AParent: TWinControl; const ABubble: TVclHelpChatAIBubble); static;
    class procedure Detach(const AParent: TWinControl; const ABubble: TVclHelpChatAIBubble); static;
  end;

var
  // The one thing of this unit that is per process: pictures, read-only
  // once filled, so every bubble and every assistant can share them.
  GAssistantIcons: TImageCollection = nil;
  GParentHooks: TList<TBubbleParentHook> = nil;

{ TBubbleParentHook }

constructor TBubbleParentHook.CreateFor(const AParent: TWinControl);
begin
  inherited Create(nil);
  FBubbles := TList<TVclHelpChatAIBubble>.Create;
  FParent := AParent;
  FParent.FreeNotification(Self);
  FOldProc := FParent.WindowProc;
  FParent.WindowProc := WndProc;
  if GParentHooks = nil then
    GParentHooks := TList<TBubbleParentHook>.Create;
  GParentHooks.Add(Self);
end;

destructor TBubbleParentHook.Destroy;
begin
  if Assigned(GParentHooks) then
    GParentHooks.Remove(Self);
  FBubbles.Free;
  inherited;
end;

function TBubbleParentHook.IsCurrent: Boolean;
var
  LProc: TWndMethod;
  LOurs, LCurrent: TMethod;
begin
  LProc := WndProc;
  LOurs := TMethod(LProc);
  LCurrent := TMethod(FParent.WindowProc);
  Result := (LCurrent.Code = LOurs.Code) and (LCurrent.Data = LOurs.Data);
end;

class function TBubbleParentHook.Find(const AParent: TWinControl): TBubbleParentHook;
var
  LHook: TBubbleParentHook;
begin
  Result := nil;
  if Assigned(GParentHooks) then
    for LHook in GParentHooks do
      if LHook.FParent = AParent then
        Exit(LHook);
end;

class procedure TBubbleParentHook.Attach(const AParent: TWinControl;
  const ABubble: TVclHelpChatAIBubble);
var
  LHook: TBubbleParentHook;
begin
  LHook := Find(AParent);
  if LHook = nil then
    LHook := TBubbleParentHook.CreateFor(AParent);
  if not LHook.FBubbles.Contains(ABubble) then
    LHook.FBubbles.Add(ABubble);
end;

class procedure TBubbleParentHook.Detach(const AParent: TWinControl;
  const ABubble: TVclHelpChatAIBubble);
var
  LHook: TBubbleParentHook;
begin
  LHook := Find(AParent);
  if LHook = nil then
    Exit;
  LHook.FBubbles.Remove(ABubble);
  // Restore only while the chain is still ours: someone may have hooked
  // after us, and then the hook stays, passing every message on.
  if (LHook.FBubbles.Count = 0) and LHook.IsCurrent then
  begin
    AParent.WindowProc := LHook.FOldProc;
    LHook.Free;
  end;
end;

procedure TBubbleParentHook.WndProc(var AMessage: TMessage);
var
  I: Integer;
  LMsg: Cardinal;
begin
  LMsg := AMessage.Msg;
  if Assigned(FOldProc) then
    FOldProc(AMessage);
  // By index and backwards: handling the message may have removed a bubble.
  for I := FBubbles.Count - 1 downto 0 do
    if I < FBubbles.Count then
      FBubbles[I].ParentMessage(LMsg);
end;

procedure TBubbleParentHook.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  // The parent is going, its window is already gone: nothing calls the hook
  // again. Last statement of the method on purpose.
  if (Operation = opRemove) and (AComponent = FParent) then
    Free;
end;

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
///  The image AIndex of AImages as a 32-bit bitmap with its alpha
///  (premultiplied, <c>afDefined</c>), or nil when there is no such image;
///  the caller frees it. <c>AEnabled</c> False draws the disabled look of
///  the list. The alpha of an image list cannot be read back: GDI writes no
///  alpha channel, so a bitmap drawn from it comes back opaque. Drawing the
///  same image twice, once over white and once over black, gives it back
///  exactly - where the icon is transparent the two differ by 255, where it
///  is solid they are equal - and the drawing over black already *is* the
///  colour multiplied by the alpha, which is what a bitmap declared
///  afDefined holds. Main thread: it draws through GDI.
/// </summary>
function HelpChatIconBitmap(const AImages: TCustomImageList; const AIndex: Integer;
  const AEnabled: Boolean = True): TBitmap;
var
  LW, LH, X, Y, LAlpha: Integer;
  LWhite, LBlack: TBitmap;
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
      AImages.Draw(Result.Canvas, 0, 0, AIndex, AEnabled);
    except
      Result.Free;
      raise;
    end;
  end;

begin
  Result := nil;
  if (AImages = nil) or (AIndex < 0) or (AIndex >= AImages.Count) then
    Exit;
  LW := AImages.Width;
  LH := AImages.Height;
  if (LW <= 0) or (LH <= 0) then
    Exit;

  LWhite := nil;
  LBlack := nil;
  try
    LWhite := Flat(clWhite);
    LBlack := Flat(clBlack);

    Result := TBitmap.Create;
    Result.PixelFormat := pf32bit;
    Result.SetSize(LW, LH);
    // Declared before the pixels are written: setting it afterwards would make
    // the VCL premultiply values that already are.
    Result.AlphaFormat := afDefined;
    for Y := 0 to LH - 1 do
    begin
      LRowW := LWhite.ScanLine[Y];
      LRowB := LBlack.ScanLine[Y];
      LRowI := Result.ScanLine[Y];
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
  except
    FreeAndNil(Result);
    LBlack.Free;
    LWhite.Free;
    raise;
  end;
  LBlack.Free;
  LWhite.Free;
end;

/// <summary>Writes one image of a list to AStream as a PNG with its
/// transparency (see HelpChatIconBitmap for how the alpha is recovered).
/// False when there is no such image.</summary>
function HelpChatIconPng(const AImages: TCustomImageList; const AIndex: Integer;
  const AStream: TStream): Boolean;
var
  LIcon: TBitmap;
  LWic: TWICImage;
begin
  Result := False;
  LIcon := HelpChatIconBitmap(AImages, AIndex);
  if LIcon = nil then
    Exit;
  LWic := nil;
  try
    LWic := TWICImage.Create;
    LWic.Assign(LIcon);          // Assign resets the format, so PNG comes after
    LWic.ImageFormat := wifPng;
    LWic.SaveToStream(AStream);
    Result := AStream.Size > 0;
  finally
    LWic.Free;
    LIcon.Free;
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
  TBubbleParentHook.Attach(AParent, Self);
end;

procedure TVclHelpChatAIBubble.UnhookParent;
begin
  if FHookedParent = nil then
    Exit;
  TBubbleParentHook.Detach(FHookedParent, Self);
  FHookedParent := nil;
end;

procedure TVclHelpChatAIBubble.ParentMessage(const AMsg: Cardinal);
begin
  // A new child, a resize or a reorder can bury the bubble: ask to come back
  // on top, but later — the host is in the middle of its own work right now.
  case AMsg of
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

function TVclHelpChatAIBubble.WantsLayered: Boolean;
begin
  // Child windows can be layered from Windows 8 on, for an application whose
  // manifest says it knows Windows 8 (Delphi's default_app.manifest does).
  Result := not (csDesigning in ComponentState) and CheckWin32Version(6, 2);
end;

procedure TVclHelpChatAIBubble.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if WantsLayered then
    Params.ExStyle := Params.ExStyle or WS_EX_LAYERED;
end;

procedure TVclHelpChatAIBubble.CreateWnd;
begin
  inherited CreateWnd;
  FLayered := (GetWindowLong(Handle, GWL_EXSTYLE) and WS_EX_LAYERED) <> 0;
  if FLayered and not RenderLayered then
  begin
    // Refused (an application without the Windows 8 manifest entry, a remote
    // session that does not compose): back to the region.
    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and not WS_EX_LAYERED);
    FLayered := False;
  end;
  UpdateRegion;
  BringToTop;
end;

procedure TVclHelpChatAIBubble.Invalidate;
begin
  if FLayered and HandleAllocated then
    RenderLayered
  else
    inherited Invalidate;
end;

procedure TVclHelpChatAIBubble.UpdateRegion;
var
  LRegion: HRGN;
begin
  if not HandleAllocated then
    Exit;
  if FLayered then
  begin
    // The alpha of the pixels is the shape, for the eye and for the mouse:
    // a click on a transparent corner goes to the control underneath.
    SetWindowRgn(Handle, 0, False);
    Exit;
  end;
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

function GPColor(const AColor: TColor; const AAlpha: Byte = 255): TGPColor;
var
  LRgb: Longint;
begin
  LRgb := ColorToRGB(AColor);
  Result := MakeColor(AAlpha, GetRValue(LRgb), GetGValue(LRgb), GetBValue(LRgb));
end;

procedure TVclHelpChatAIBubble.DrawBubble(const AGraphics: TObject;
  const AWidth, AHeight: Integer);
var
  LGraphics: TGPGraphics;
  LFill: TColor;
  LBrush: TGPSolidBrush;
  LPen: TGPPen;
  LImages: TCustomImageList;
  LIndex: Integer;
  LIcon: TBitmap;
  LGlyph: TGPBitmap;
  LFont: TGPFont;
  LFormat: TGPStringFormat;
  LFamily: TGPFontFamily;
begin
  LGraphics := AGraphics as TGPGraphics;
  LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
  LGraphics.SetPixelOffsetMode(PixelOffsetModeHighQuality);
  LGraphics.SetInterpolationMode(InterpolationModeHighQualityBicubic);

  LFill := FillColor;
  if not Enabled then
    LFill := ShiftColor(LFill, 35)
  else if FPressed then
    LFill := ShiftColor(LFill, -18)
  else if FHot then
    LFill := ShiftColor(LFill, 12);

  // The disc, half a pixel in so that its one-pixel rim is not cut.
  LBrush := TGPSolidBrush.Create(GPColor(LFill));
  LPen := TGPPen.Create(GPColor(ShiftColor(LFill, -25)), 1);
  try
    LGraphics.FillEllipse(LBrush, 0.5, 0.5, AWidth - 1.0, AHeight - 1.0);
    LGraphics.DrawEllipse(LPen, 0.5, 0.5, AWidth - 1.0, AHeight - 1.0);
  finally
    LPen.Free;
    LBrush.Free;
  end;

  LImages := ActiveImages;
  LIndex := ActiveImageIndex;
  LIcon := nil;
  if Assigned(LImages) and (LIndex >= 0) then
    LIcon := HelpChatIconBitmap(LImages, LIndex, Enabled);
  if LIcon <> nil then
  try
    // The VCL bitmap is bottom-up: the first scan line is the last in memory,
    // and a negative stride reads it top-down.
    LGlyph := TGPBitmap.Create(LIcon.Width, LIcon.Height, -LIcon.Width * 4,
      PixelFormat32bppPARGB, PByte(LIcon.ScanLine[0]));
    try
      LGraphics.DrawImage(LGlyph, (AWidth - LIcon.Width) div 2,
        (AHeight - LIcon.Height) div 2, LIcon.Width, LIcon.Height);
    finally
      LGlyph.Free;
    end;
  finally
    LIcon.Free;
  end
  else
  begin
    // No icon available: the question mark the bubble has always shown.
    LGraphics.SetTextRenderingHint(TextRenderingHintAntiAlias);
    LFamily := TGPFontFamily.Create(Font.Name);
    LFont := TGPFont.Create(LFamily, AHeight * 0.5, FontStyleBold, UnitPixel);
    LFormat := TGPStringFormat.Create;
    LBrush := TGPSolidBrush.Create(GPColor(GlyphColor));
    try
      LFormat.SetAlignment(StringAlignmentCenter);
      LFormat.SetLineAlignment(StringAlignmentCenter);
      LGraphics.DrawString('?', 1, LFont, MakeRect(0.0, 0.0, AWidth, AHeight), LFormat, LBrush);
    finally
      LBrush.Free;
      LFormat.Free;
      LFont.Free;
      LFamily.Free;
    end;
  end;
end;

function TVclHelpChatAIBubble.RenderLayered: Boolean;
var
  LInfo: TBitmapInfo;
  LDC: HDC;
  LBitmap, LOld: HBITMAP;
  LBits: Pointer;
  LImage: TGPBitmap;
  LGraphics: TGPGraphics;
  LSize: TSize;
  LSource: TPoint;
  LBlend: TBlendFunction;
begin
  Result := False;
  if not HandleAllocated or (Width <= 0) or (Height <= 0) then
    Exit(True);              // nothing to show yet is not a refusal
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
  LInfo.bmiHeader.biWidth := Width;
  LInfo.bmiHeader.biHeight := -Height;      // top-down: the stride is positive
  LInfo.bmiHeader.biPlanes := 1;
  LInfo.bmiHeader.biBitCount := 32;
  LInfo.bmiHeader.biCompression := BI_RGB;
  LDC := CreateCompatibleDC(0);
  if LDC = 0 then
    Exit;
  try
    LBitmap := CreateDIBSection(LDC, LInfo, DIB_RGB_COLORS, LBits, 0, 0);
    if LBitmap = 0 then
      Exit;
    LOld := SelectObject(LDC, LBitmap);
    try
      // GDI+ draws straight into the memory of the section, premultiplied,
      // which is what UpdateLayeredWindow wants.
      LImage := TGPBitmap.Create(Width, Height, Width * 4, PixelFormat32bppPARGB, LBits);
      try
        LGraphics := TGPGraphics.Create(LImage);
        try
          LGraphics.Clear(MakeColor(0, 0, 0, 0));
          DrawBubble(LGraphics, Width, Height);
        finally
          LGraphics.Free;
        end;
      finally
        LImage.Free;
      end;
      LSize.cx := Width;
      LSize.cy := Height;
      LSource := Point(0, 0);
      LBlend.BlendOp := AC_SRC_OVER;
      LBlend.BlendFlags := 0;
      LBlend.SourceConstantAlpha := 255;
      LBlend.AlphaFormat := AC_SRC_ALPHA;
      Result := UpdateLayeredWindow(Handle, 0, nil, @LSize, LDC, @LSource, 0,
        @LBlend, ULW_ALPHA);
    finally
      SelectObject(LDC, LOld);
      DeleteObject(LBitmap);
    end;
  finally
    DeleteDC(LDC);
  end;
end;

procedure TVclHelpChatAIBubble.Paint;
var
  LGraphics: TGPGraphics;
begin
  if FLayered then
    Exit;                      // pushed by RenderLayered, not painted
  // Clipped by the region: the corners take the colour of the parent, so
  // that the antialiased rim blends towards what is most likely behind.
  Canvas.Brush.Style := bsSolid;
  if Parent <> nil then
    Canvas.Brush.Color := TWinControlAccess(Parent).Color
  else
    Canvas.Brush.Color := clBtnFace;
  Canvas.FillRect(ClientRect);
  LGraphics := TGPGraphics.Create(Canvas.Handle);
  try
    DrawBubble(LGraphics, Width, Height);
  finally
    LGraphics.Free;
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
  // A hook still here belongs to a parent that outlives the unit: it is
  // left to it, only the list goes.
  FreeAndNil(GParentHooks);

end.
