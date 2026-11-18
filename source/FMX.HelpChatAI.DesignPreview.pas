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
///  "Test HelpChat..." of the FireMonkey component editor: the real chat, in a
///  FireMonkey form with the <c>TFmxHelpChatAIPanel</c> of the component,
///  running inside the IDE. The twin of <c>Vcl.HelpChatAI.DesignPreview</c>,
///  with the same three differences from a runtime run handled here: the
///  configuration read from the output folder of the project, the WebView2
///  loader loaded by full path, and a copy of the component owned by nothing
///  instead of the one in <c>csDesigning</c>.
///
///  What is FireMonkey here is what the application will run: the form, the
///  native <c>TWebBrowser</c> of the panel, <c>ThemeMode</c>. The window is
///  the host form of the copy and its container at once, so the bubble, F1,
///  the help viewer and the remembered position are off - the window is the
///  preview. The sizes are logical units, which FireMonkey scales by itself.
///
///  The loader and the base folder are resolved by the caller
///  (<c>FMX.HelpChatAI.Register</c>): this unit only runs what was checked.
/// </summary>
unit FMX.HelpChatAI.DesignPreview;

{$I HelpChatAI.inc}

interface

uses
  FMX.HelpChatAI,
  HelpChatAI.Settings,
  HelpChatAI.Diagnostics;

/// <summary>Makes <c>WebView2Loader.dll</c> reachable by its base name inside
/// the IDE: already loaded, next to the application being designed
/// (<c>ABaseFolder</c>), or where the installer left it
/// (<c>$(HELPCHATAIDIR)\Redist\WebView2</c>). <c>AFrom</c> is the file
/// loaded. The module stays loaded for as long as the IDE runs.</summary>
function FmxHelpChatEnsureWebView2Loader(const ABaseFolder: string;
  out AFrom: string): Boolean;

/// <summary>Shows the live chat of <c>AChat</c> in a modal FireMonkey window,
/// with <c>AIssues</c> readable underneath. <c>ASettings</c> are the settings
/// the built application would see (the caller reads them and frees them):
/// the copy runs on its own copy of them. Returns when the window is closed;
/// by then the copy is stopped and freed, and the engine it held with it.
/// <c>AChat</c> is never activated or changed. <c>ABaseFolder</c> is the
/// folder the application is built in: the files the component names with a
/// relative path are read there.</summary>
procedure FmxHelpChatDesignPreview(const AChat: TFmxHelpChatAI;
  const ASettings: THelpChatSettings; const AIssues: THelpChatIssues;
  const ABaseFolder: string = '');

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  System.UITypes,
  System.IOUtils,
  Winapi.Windows,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Layouts,
  FMX.StdCtrls,
  FMX.Memo,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Controls.Presentation,
  Vcl.Dialogs,
  ToolsAPI,
  HelpChatAI.Types;

const
  HELPCHAT_DESIGN_LIBRARY_MACRO = '$(HELPCHATAIDIR)';
  HELPCHAT_DESIGN_LOADER_DLL = 'WebView2Loader.dll';
  {$IFDEF WIN64}
  HELPCHAT_DESIGN_LOADER_SUBDIR = 'Redist\WebView2\x64';
  {$ELSE}
  HELPCHAT_DESIGN_LOADER_SUBDIR = 'Redist\WebView2\x86';
  {$ENDIF}
  HELPCHAT_DESIGN_MIN_WIDTH = 420;
  HELPCHAT_DESIGN_MIN_HEIGHT = 520;
  HELPCHAT_DESIGN_LOG_HEIGHT = 92;

type
  /// <summary>The window of the preview: the chat fills it, the findings of
  /// the check stay readable underneath. Built in code, no FMX file.</summary>
  TFmxHelpChatPreviewForm = class(TForm)
  strict private
    FChatLayout: TLayout;
    FFooter: TLayout;
    FLog: TMemo;
    FCloseButton: TButton;
    FChat: TFmxHelpChatAI;
  strict protected
    /// <summary>The chat opens here and not before: the native browser of
    /// the panel needs the window of the form.</summary>
    procedure DoShow; override;
  public
    constructor CreatePreview(const ACaption: string; const AIssues: THelpChatIssues;
      const AWidth, AHeight: Integer);
    /// <summary>Where the chat is parented.</summary>
    property ChatLayout: TLayout read FChatLayout;
    /// <summary>The chat to open on show; not owned.</summary>
    property Chat: TFmxHelpChatAI read FChat write FChat;
  end;

  /// <summary>The copy that runs in the preview: the configuration has
  /// already been read for it, from the output folder of the project, and
  /// must not be read again from the folder of the IDE.</summary>
  TFmxHelpChatPreviewChat = class(TFmxHelpChatAI)
  protected
    procedure LoadConfiguration; override;
  end;

  /// <summary>The context the copy answers about: the preview is not a
  /// screen of the application, and saying so is better than handing the
  /// model whatever the IDE has focused.</summary>
  TFmxHelpChatPreviewContext = class
  strict private
    FComponentName: string;
  public
    constructor Create(const AComponentName: string);
    procedure GetContext(Sender: TObject; var AContext: THelpChatContext);
  end;

function ExpandIdeMacro(const AValue: string): string;
var
  LServices: IOTAServices;
begin
  Result := AValue;
  if Supports(BorlandIDEServices, IOTAServices, LServices) then
    try
      Result := LServices.ExpandRootMacro(AValue);
    except
      Result := AValue;
    end;
end;

function FmxHelpChatEnsureWebView2Loader(const ABaseFolder: string;
  out AFrom: string): Boolean;

  function TryLoad(const AFileName: string): Boolean;
  begin
    Result := (AFileName <> '') and TFile.Exists(AFileName) and
      (LoadLibrary(PChar(AFileName)) <> 0);
    if Result then
      AFrom := AFileName;
  end;

var
  LLibrary: string;
begin
  AFrom := '';
  if LoadLibrary(PChar(HELPCHAT_DESIGN_LOADER_DLL)) <> 0 then
  begin
    AFrom := HELPCHAT_DESIGN_LOADER_DLL;
    Exit(True);
  end;
  if (ABaseFolder <> '') and
     TryLoad(TPath.Combine(ABaseFolder, HELPCHAT_DESIGN_LOADER_DLL)) then
    Exit(True);
  LLibrary := ExpandIdeMacro(HELPCHAT_DESIGN_LIBRARY_MACRO);
  if (LLibrary <> '') and (LLibrary <> HELPCHAT_DESIGN_LIBRARY_MACRO) then
    if TryLoad(TPath.Combine(TPath.Combine(LLibrary, HELPCHAT_DESIGN_LOADER_SUBDIR),
      HELPCHAT_DESIGN_LOADER_DLL)) then
      Exit(True);
  Result := False;
end;

{ TFmxHelpChatPreviewForm }

constructor TFmxHelpChatPreviewForm.CreatePreview(const ACaption: string;
  const AIssues: THelpChatIssues; const AWidth, AHeight: Integer);
begin
  inherited CreateNew(nil);
  Caption := ACaption;
  BorderStyle := TFmxFormBorderStyle.Sizeable;
  Position := TFormPosition.ScreenCenter;
  // Logical units: FireMonkey scales them to the screen by itself.
  Width := AWidth;
  Height := AHeight;
  Constraints.MinWidth := HELPCHAT_DESIGN_MIN_WIDTH;
  Constraints.MinHeight := HELPCHAT_DESIGN_MIN_HEIGHT;

  FFooter := TLayout.Create(Self);
  FFooter.Parent := Self;
  FFooter.Align := TAlignLayout.Bottom;
  FFooter.Height := HELPCHAT_DESIGN_LOG_HEIGHT;
  FFooter.Padding.Rect := TRectF.Create(6, 6, 6, 6);

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := FFooter;
  FCloseButton.Align := TAlignLayout.Right;
  FCloseButton.Width := 90;
  FCloseButton.Text := 'Close';
  // Esc closes the window: inside the page the key belongs to the native
  // browser, which keeps it.
  FCloseButton.Cancel := True;
  FCloseButton.ModalResult := mrCancel;

  FLog := TMemo.Create(Self);
  FLog.Parent := FFooter;
  FLog.Align := TAlignLayout.Client;
  FLog.Margins.Right := 6;
  FLog.ReadOnly := True;
  FLog.TextSettings.WordWrap := True;
  FLog.Lines.Text := HelpChatIssuesToText(AIssues);

  FChatLayout := TLayout.Create(Self);
  FChatLayout.Parent := Self;
  FChatLayout.Align := TAlignLayout.Client;
end;

procedure TFmxHelpChatPreviewForm.DoShow;
begin
  inherited DoShow;
  if Assigned(FChat) then
    try
      FChat.Open;
    except
      on E: Exception do
      begin
        FLog.Lines.Insert(0, Format('Error - HelpChat could not open: %s', [E.Message]));
        FChat := nil;
      end;
    end;
end;

{ TFmxHelpChatPreviewChat }

procedure TFmxHelpChatPreviewChat.LoadConfiguration;
begin
  // Already done by the caller, against the folder of the project.
end;

{ TFmxHelpChatPreviewContext }

constructor TFmxHelpChatPreviewContext.Create(const AComponentName: string);
begin
  inherited Create;
  FComponentName := AComponentName;
end;

procedure TFmxHelpChatPreviewContext.GetContext(Sender: TObject;
  var AContext: THelpChatContext);
begin
  AContext := Default(THelpChatContext);
  AContext.ScreenName := FComponentName;
  AContext.ScreenLabel := 'HelpChat design-time preview';
  AContext.ScreenType := 'Preview';
end;

{ the preview }

procedure FmxHelpChatDesignPreview(const AChat: TFmxHelpChatAI;
  const ASettings: THelpChatSettings; const AIssues: THelpChatIssues;
  const ABaseFolder: string);
var
  LForm: TFmxHelpChatPreviewForm;
  LClone: TFmxHelpChatPreviewChat;
  LContext: TFmxHelpChatPreviewContext;
begin
  LContext := nil;
  LClone := nil;
  LForm := nil;
  try
    LContext := TFmxHelpChatPreviewContext.Create(AChat.Name);
    LForm := TFmxHelpChatPreviewForm.CreatePreview(
      Format('HelpChat preview - %s', [AChat.Name]), AIssues,
      Max(AChat.PanelWidth, HELPCHAT_DESIGN_MIN_WIDTH),
      Max(AChat.PanelHeight, HELPCHAT_DESIGN_MIN_HEIGHT) + HELPCHAT_DESIGN_LOG_HEIGHT);

    // A copy, not the component on the form: that one is in csDesigning and
    // must stay exactly as the developer left it. Everything the developer
    // set on it - the icon and its image list, the style sheets... - then
    // what the preview changes: a property copied by hand here was a
    // property forgotten the day it was added (the icon was).
    LClone := TFmxHelpChatPreviewChat.Create(nil);
    LClone.Assign(AChat);
    // The files the component names are read next to the executable, which
    // here is bds.exe: the copy gets them as the application would find
    // them, in the folder of the project.
    LClone.PanelStyleSheet := HelpChatFileInFolder(LClone.PanelStyleSheet, ABaseFolder);
    LClone.PdfStyleSheet := HelpChatFileInFolder(LClone.PdfStyleSheet, ABaseFolder);
    LClone.PdfHeaderFile := HelpChatFileInFolder(LClone.PdfHeaderFile, ABaseFolder);
    LClone.PdfFooterFile := HelpChatFileInFolder(LClone.PdfFooterFile, ABaseFolder);
    LClone.Settings := ASettings;      // assigned: the copy keeps its own
    LClone.ShowBubble := False;        // the window is the preview itself
    LClone.RegisterHelpViewer := False;
    LClone.HandleF1 := False;
    LClone.RememberPanelPosition := False;
    LClone.ActionsEnabled := False;    // the handlers live in the application
    // Owned by nothing, so the copy has no form of its own: the preview is
    // both its host and its container.
    LClone.HostForm := LForm;
    LClone.Container := LForm.ChatLayout;
    LClone.OnGetContext := LContext.GetContext;
    try
      LClone.Active := True;
    except
      on E: Exception do
      begin
        MessageDlg(Format('HelpChat could not start: %s', [E.Message]),
          TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
        Exit;
      end;
    end;
    LForm.Chat := LClone;
    LForm.ShowModal;
  finally
    if Assigned(LClone) then
    begin
      // The only holder of its engine, so releasing it frees it. The window
      // goes after the copy, whose panel is parented to it.
      LClone.Active := False;
      LClone.Free;
    end;
    LForm.Free;
    LContext.Free;
  end;
end;

end.
