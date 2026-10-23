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
///  Design-time registration of the VCL component: the palette entry, the
///  library in the splash screen and in the About box of the IDE, the
///  component editor that runs the chat before the application is built, and
///  the property editors of the bubble icon.
///
///  <c>ImageIndex</c> and <c>ImageName</c> get an editor of their own because
///  the one the IDE provides for the standard controls is not offered to a
///  component that is not one of them: without these two the icon would have
///  to be typed by hand. They list what the image list of the application
///  holds, or the icons compiled into the component when there is none.
///
///  The About box is registered here and not in the FMX unit: one library,
///  one entry.
/// </summary>
unit Vcl.HelpChatAI.Register;

{$I HelpChatAI.inc}

interface

uses
  System.Classes,
  System.Types,
  Vcl.Graphics,
  Vcl.ImgList,
  DesignIntf,
  DesignEditors,
  VCLEditors;

{$R HelpChatAI.Splash.res}

type
  /// <summary>Verbs of the component: run it, check it, read about it.</summary>
  TVclHelpChatComponentEditor = class(TComponentEditor)
  strict private
    function GetChat: TComponent;
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

  /// <summary>Picks the bubble icon by index, drawing the images in the
  /// drop-down list.</summary>
  TVclHelpChatImageIndexProperty = class(TIntegerProperty, ICustomPropertyListDrawing)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    function GetImageListAt(Index: Integer): TCustomImageList; virtual;
    // ICustomPropertyListDrawing
    procedure ListMeasureHeight(const Value: string; ACanvas: TCanvas;
      var AHeight: Integer);
    procedure ListMeasureWidth(const Value: string; ACanvas: TCanvas;
      var AWidth: Integer);
    procedure ListDrawValue(const Value: string; ACanvas: TCanvas;
      const ARect: TRect; ASelected: Boolean);
  end;

  /// <summary>Which provider answers: the ones registered in this IDE, which
  /// are the ones compiled into the library. Typing a name that is not there
  /// is the mistake this editor exists to prevent.</summary>
  TVclHelpChatProviderProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  /// <summary>The configuration file, with a file dialog behind the ellipsis.</summary>
  TVclHelpChatConfigFileNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  /// <summary>Container, offering only the controls that can hold another
  /// one. The stock editor lists every TWinControl of the form, which means
  /// offering an edit box or a button as a place to put the chat.</summary>
  TVclHelpChatContainerProperty = class(TComponentProperty)
  public
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  /// <summary>The same by name, the way the VCL wants an icon chosen since
  /// 10.4: the names of the image list, or of the built-in icons.</summary>
  TVclHelpChatImageNameProperty = class(TStringProperty, ICustomPropertyListDrawing)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    function GetImageListAt(Index: Integer): TCustomImageList; virtual;
    // ICustomPropertyListDrawing
    procedure ListMeasureHeight(const Value: string; ACanvas: TCanvas;
      var AHeight: Integer);
    procedure ListMeasureWidth(const Value: string; ACanvas: TCanvas;
      var AWidth: Integer);
    procedure ListDrawValue(const Value: string; ACanvas: TCanvas;
      const ARect: TRect; ASelected: Boolean);
  end;

procedure Register;

implementation

uses
  System.SysUtils,
  System.UITypes,
  Winapi.Windows,
  Winapi.ShellApi,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Imaging.PngImage,
  Vcl.VirtualImageList,
  ToolsAPI,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider,
  HelpChatAI.Diagnostics,
  Vcl.HelpChatAI,
  Vcl.HelpChatAI.Bubble,
  Vcl.HelpChatAI.DesignPreview;

const
  HELPCHAT_PALETTE_PAGE = 'Ethea HelpChat';
  HELPCHAT_DOCS_URL = 'https://ethea.it/docs/helpchatai/';
  {$IFDEF D11+}
  HELPCHAT_ABOUT_RES_NAME = 'HELPCHATSPLASH48PNG';
  HELPCHAT_SPLASH_RES_NAME = 'HELPCHATSPLASH48PNG';
  {$ELSE}
  HELPCHAT_ABOUT_RES_NAME = 'HELPCHATSPLASH24BMP';
  HELPCHAT_SPLASH_RES_NAME = 'HELPCHATSPLASH24BMP';
  {$ENDIF}

resourcestring
  SHelpChatAboutTitle = 'Ethea HelpChat';
  SHelpChatAboutDescription =
    'Ethea - HelpChat Components (VCL and FMX) - https://ethea.it/docs/helpchatai/' + sLineBreak +
    'An in-app AI help assistant: the user asks how to use the application, ' +
    'the answer comes from its documentation, through Anthropic Claude or a ' +
    'provider of yours.';
  SHelpChatAboutLicense = 'Apache 2.0 (Free/Opensource)';
  SHelpChatVerbTest = '&Test HelpChat...';
  SHelpChatVerbCheck = '&Check configuration...';
  SHelpChatVerbAbout = 'Ver. %s - (c) Ethea S.r.l. - Open Web Help...';
  SHelpChatCheckOk = 'HelpChat is ready to run with this configuration.';
  SHelpChatCheckFailed = 'HelpChat cannot run with this configuration:';
  SHelpChatConfigFileTitle = 'HelpChat configuration file';
  SHelpChatConfigFileFilter = 'HelpChat configuration (*.json)|*.json|All files (*.*)|*.*';

var
  GAboutBoxServices: IOTAAboutBoxServices = nil;
  GAboutBoxIndex: Integer = 0;
  GBuiltInImages: TVirtualImageList = nil;

{ splash screen and About box }

{$IFDEF D11+}
function CreateBitmapFromPngRes(const AResName: string): Vcl.Graphics.TBitmap;
var
  LPngImage: TPngImage;
  LResStream: TResourceStream;
begin
  LPngImage := nil;
  try
    Result := Vcl.Graphics.TBitmap.Create;
    LPngImage := TPngImage.Create;
    LResStream := TResourceStream.Create(HInstance, AResName, RT_RCDATA);
    try
      LPngImage.LoadFromStream(LResStream);
      Result.Assign(LPngImage);
    finally
      LResStream.Free;
    end;
  finally
    LPngImage.Free;
  end;
end;

procedure RegisterAboutBox;
var
  LBitmap: Vcl.Graphics.TBitmap;
begin
  if not Supports(BorlandIDEServices, IOTAAboutBoxServices, GAboutBoxServices) then
    Exit;
  LBitmap := CreateBitmapFromPngRes(HELPCHAT_ABOUT_RES_NAME);
  try
    GAboutBoxIndex := GAboutBoxServices.AddPluginInfo(
      SHelpChatAboutTitle + ' ' + HELPCHAT_VERSION,
      SHelpChatAboutDescription, LBitmap.Handle, False, SHelpChatAboutLicense);
  finally
    LBitmap.Free;
  end;
end;

procedure RegisterWithSplashScreen;
var
  LBitmap: Vcl.Graphics.TBitmap;
begin
  LBitmap := CreateBitmapFromPngRes(HELPCHAT_SPLASH_RES_NAME);
  try
    SplashScreenServices.AddPluginBitmap(
      SHelpChatAboutTitle + ' ' + HELPCHAT_VERSION,
      LBitmap.Handle, False, SHelpChatAboutLicense, '');
  finally
    LBitmap.Free;
  end;
end;
{$ELSE}
procedure RegisterAboutBox;
var
  LProductImage: HBITMAP;
begin
  if not Supports(BorlandIDEServices, IOTAAboutBoxServices, GAboutBoxServices) then
    Exit;
  LProductImage := LoadBitmap(FindResourceHInstance(HInstance), HELPCHAT_ABOUT_RES_NAME);
  GAboutBoxIndex := GAboutBoxServices.AddPluginInfo(
    SHelpChatAboutTitle + ' ' + HELPCHAT_VERSION,
    SHelpChatAboutDescription, LProductImage, False, SHelpChatAboutLicense);
end;

procedure RegisterWithSplashScreen;
var
  LProductImage: HBITMAP;
begin
  LProductImage := LoadBitmap(FindResourceHInstance(HInstance), HELPCHAT_SPLASH_RES_NAME);
  SplashScreenServices.AddPluginBitmap(SHelpChatAboutTitle + ' ' + HELPCHAT_VERSION,
    LProductImage, False, SHelpChatAboutLicense);
end;
{$ENDIF}

procedure UnregisterAboutBox;
begin
  if (GAboutBoxIndex <> 0) and Assigned(GAboutBoxServices) then
  begin
    GAboutBoxServices.RemovePluginInfo(GAboutBoxIndex);
    GAboutBoxIndex := 0;
  end;
  GAboutBoxServices := nil;
end;

{ shared helpers }

/// <summary>The icons compiled into the component, as an image list the
/// property editors can measure and draw. One per IDE session.</summary>
function BuiltInImages: TCustomImageList;
begin
  if GBuiltInImages = nil then
  begin
    GBuiltInImages := TVirtualImageList.Create(nil);
    GBuiltInImages.ImageCollection := HelpChatAssistantIcons;
    GBuiltInImages.AutoFill := True;
  end;
  Result := GBuiltInImages;
end;

/// <summary>Where the icons of <c>APersistent</c> come from: the image list
/// of the application, or the built-in ones when it gave none - which is
/// exactly what the bubble does when it paints itself.</summary>
function ImagesOf(const APersistent: TPersistent): TCustomImageList;
begin
  Result := nil;
  if APersistent is TVclHelpChatAI then
    Result := TVclHelpChatAI(APersistent).Images
  else if APersistent is TVclHelpChatAIBubble then
    Result := TVclHelpChatAIBubble(APersistent).Images;
  if Result = nil then
    Result := BuiltInImages;
end;

procedure DrawImageValue(const AImages: TCustomImageList; const AIndex: Integer;
  const AValue: string; ACanvas: TCanvas; const ARect: TRect);
var
  LLeft: Integer;
begin
  ACanvas.FillRect(ARect);
  LLeft := ARect.Left + 2;
  if Assigned(AImages) and (AIndex >= 0) and (AIndex < AImages.Count) then
  begin
    AImages.Draw(ACanvas, LLeft, ARect.Top + 2, AIndex);
    Inc(LLeft, AImages.Width);
  end;
  ACanvas.TextOut(LLeft + 3, ARect.Top + 1, AValue);
end;

procedure MeasureImageHeight(const AImages: TCustomImageList; const AValue: string;
  ACanvas: TCanvas; var AHeight: Integer);
begin
  AHeight := ACanvas.TextHeight(AValue) + 2;
  if Assigned(AImages) and (AImages.Height + 4 > AHeight) then
    AHeight := AImages.Height + 4;
end;

procedure MeasureImageWidth(const AImages: TCustomImageList; const AValue: string;
  ACanvas: TCanvas; var AWidth: Integer);
begin
  AWidth := ACanvas.TextWidth(AValue) + 4;
  if Assigned(AImages) then
    Inc(AWidth, AImages.Width);
end;

{ TVclHelpChatComponentEditor }

function TVclHelpChatComponentEditor.GetChat: TComponent;
begin
  Result := Component;
  if not (Result is TVclHelpChatAI) then
    Result := nil;
end;

function TVclHelpChatComponentEditor.GetVerbCount: Integer;
begin
  Result := 3;
end;

function TVclHelpChatComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SHelpChatVerbTest;
    1: Result := SHelpChatVerbCheck;
    2: Result := Format(SHelpChatVerbAbout, [HELPCHAT_VERSION]);
  else
    Result := '';
  end;
end;

procedure TVclHelpChatComponentEditor.ExecuteVerb(Index: Integer);
var
  LChat: TComponent;
  LIssues: THelpChatIssues;
begin
  LChat := GetChat;
  case Index of
    0:
      if Assigned(LChat) then
        HelpChatDesignPreview(TVclHelpChatAI(LChat));
    1:
      if Assigned(LChat) then
      begin
        LIssues := HelpChatDesignCheck(TVclHelpChatAI(LChat));
        if HelpChatHasErrors(LIssues) then
          MessageDlg(SHelpChatCheckFailed + sLineBreak + sLineBreak +
            HelpChatIssuesToText(LIssues), mtError, [mbOK], 0)
        else
          MessageDlg(SHelpChatCheckOk + sLineBreak + sLineBreak +
            HelpChatIssuesToText(LIssues), mtInformation, [mbOK], 0);
      end;
    2:
      ShellExecute(0, 'open', PChar(HELPCHAT_DOCS_URL), nil, nil, SW_SHOWNORMAL);
  end;
end;

{ TVclHelpChatImageIndexProperty }

function TVclHelpChatImageIndexProperty.GetImageListAt(Index: Integer): TCustomImageList;
begin
  Result := ImagesOf(GetComponent(Index));
end;

function TVclHelpChatImageIndexProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paRevertable];
end;

procedure TVclHelpChatImageIndexProperty.GetValues(Proc: TGetStrProc);
var
  LImages: TCustomImageList;
  I: Integer;
begin
  LImages := GetImageListAt(0);
  if Assigned(LImages) then
    for I := 0 to LImages.Count - 1 do
      Proc(IntToStr(I));
end;

procedure TVclHelpChatImageIndexProperty.ListDrawValue(const Value: string;
  ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  DrawImageValue(GetImageListAt(0), StrToIntDef(Value, -1), Value, ACanvas, ARect);
end;

procedure TVclHelpChatImageIndexProperty.ListMeasureHeight(const Value: string;
  ACanvas: TCanvas; var AHeight: Integer);
begin
  MeasureImageHeight(GetImageListAt(0), Value, ACanvas, AHeight);
end;

procedure TVclHelpChatImageIndexProperty.ListMeasureWidth(const Value: string;
  ACanvas: TCanvas; var AWidth: Integer);
begin
  MeasureImageWidth(GetImageListAt(0), Value, ACanvas, AWidth);
end;

{ TVclHelpChatImageNameProperty }

function TVclHelpChatImageNameProperty.GetImageListAt(Index: Integer): TCustomImageList;
begin
  Result := ImagesOf(GetComponent(Index));
end;

function TVclHelpChatImageNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paRevertable];
end;

procedure TVclHelpChatImageNameProperty.GetValues(Proc: TGetStrProc);
var
  LImages: TCustomImageList;
  LName: TImageName;
  LIndex: System.UITypes.TImageIndex;
  I: Integer;
begin
  LImages := GetImageListAt(0);
  if not (Assigned(LImages) and LImages.IsImageNameAvailable) then
    Exit;
  for I := 0 to LImages.Count - 1 do
  begin
    LName := '';
    LIndex := I;
    LImages.CheckIndexAndName(LIndex, LName);
    if LName <> '' then
      Proc(LName);
  end;
end;

procedure TVclHelpChatImageNameProperty.ListDrawValue(const Value: string;
  ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
var
  LImages: TCustomImageList;
  LIndex: Integer;
begin
  LImages := GetImageListAt(0);
  LIndex := -1;
  if Assigned(LImages) and LImages.IsImageNameAvailable then
    LIndex := LImages.GetIndexByName(Value);
  DrawImageValue(LImages, LIndex, Value, ACanvas, ARect);
end;

procedure TVclHelpChatImageNameProperty.ListMeasureHeight(const Value: string;
  ACanvas: TCanvas; var AHeight: Integer);
begin
  MeasureImageHeight(GetImageListAt(0), Value, ACanvas, AHeight);
end;

procedure TVclHelpChatImageNameProperty.ListMeasureWidth(const Value: string;
  ACanvas: TCanvas; var AWidth: Integer);
begin
  MeasureImageWidth(GetImageListAt(0), Value, ACanvas, AWidth);
end;

{ TVclHelpChatProviderProperty }

function TVclHelpChatProviderProperty.GetAttributes: TPropertyAttributes;
begin
  // Not paValueList alone: a provider the application registers at run time
  // is a legitimate value that this IDE cannot know about.
  Result := [paMultiSelect, paValueList, paRevertable];
end;

procedure TVclHelpChatProviderProperty.GetValues(Proc: TGetStrProc);
var
  LName: string;
begin
  for LName in THelpChatProviderRegistry.ProviderNames do
    Proc(LName);
end;

{ TVclHelpChatConfigFileNameProperty }

function TVclHelpChatConfigFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;

procedure TVclHelpChatConfigFileNameProperty.Edit;
var
  LDialog: TOpenDialog;
begin
  LDialog := TOpenDialog.Create(nil);
  try
    LDialog.Title := SHelpChatConfigFileTitle;
    LDialog.Filter := SHelpChatConfigFileFilter;
    LDialog.Options := LDialog.Options + [ofFileMustExist, ofPathMustExist];
    LDialog.FileName := GetValue;
    if LDialog.Execute then
      SetValue(LDialog.FileName);
  finally
    LDialog.Free;
  end;
end;

{ TVclHelpChatContainerProperty }

procedure TVclHelpChatContainerProperty.GetValues(Proc: TGetStrProc);
var
  LRoot: TComponent;
  LComponent: TComponent;
  I: Integer;
begin
  if (Designer = nil) or (Designer.Root = nil) then
    Exit;
  LRoot := Designer.Root;
  for I := 0 to LRoot.ComponentCount - 1 do
  begin
    LComponent := LRoot.Components[I];
    // csAcceptsControls is the VCL's own answer to "can this be a parent?":
    // a panel, a page, a group box say yes; an edit or a button say no.
    if (LComponent is TWinControl) and (LComponent.Name <> '') and
       (csAcceptsControls in TWinControl(LComponent).ControlStyle) then
      Proc(LComponent.Name);
  end;
  // The form itself is a container, and a legitimate one.
  if (LRoot is TWinControl) and (LRoot.Name <> '') and
     (csAcceptsControls in TWinControl(LRoot).ControlStyle) then
    Proc(LRoot.Name);
end;

procedure Register;
begin
  RegisterWithSplashScreen;

  RegisterComponents(HELPCHAT_PALETTE_PAGE, [TVclHelpChatAI]);
  RegisterComponentEditor(TVclHelpChatAI, TVclHelpChatComponentEditor);

  RegisterPropertyEditor(TypeInfo(System.UITypes.TImageIndex),
    TVclHelpChatAI, 'ImageIndex', TVclHelpChatImageIndexProperty);
  RegisterPropertyEditor(TypeInfo(System.UITypes.TImageName),
    TVclHelpChatAI, 'ImageName', TVclHelpChatImageNameProperty);

  // On THelpChatSettings, not on the component: the same section is reached
  // from the VCL component, the FMX one and anything else that owns settings.
  RegisterPropertyEditor(TypeInfo(string),
    THelpChatSettings, 'Provider', TVclHelpChatProviderProperty);
  RegisterPropertyEditor(TypeInfo(TFileName),
    TVclHelpChatAI, 'ConfigFileName', TVclHelpChatConfigFileNameProperty);
  RegisterPropertyEditor(TypeInfo(TWinControl),
    TVclHelpChatAI, 'Container', TVclHelpChatContainerProperty);
end;

initialization
  RegisterAboutBox;

finalization
  UnregisterAboutBox;
  FreeAndNil(GBuiltInImages);

end.
