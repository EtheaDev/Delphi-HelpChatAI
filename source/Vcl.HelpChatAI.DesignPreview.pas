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
///  "Test HelpChat..." of the component editor: the real chat, with the
///  settings of the component on the form, running inside the IDE before the
///  application is built once.
///
///  Three things make a design-time run different from a runtime one, and all
///  three are handled here rather than in the component:
///  <list type="bullet">
///   <item>relative paths resolve against the folder of the running
///    executable, which here is the folder of the IDE: they are expanded
///    against the output folder of the active project, and the
///    <c>helpchatai.json</c> of that folder is the one read;</item>
///   <item><c>WebView2Loader.dll</c> sits next to the application, never next
///    to <c>bds.exe</c>: it is loaded by full path before the panel asks for
///    it;</item>
///   <item>a component on a form is in <c>csDesigning</c> and refuses to
///    activate, on purpose. What runs is a separate copy of it, owned by
///    nothing, freed when the preview closes: the component being designed is
///    never started, never streamed, never touched.</item>
///  </list>
///
///  What cannot work says so instead of opening an empty panel: the check of
///  <c>HelpChatAI.Diagnostics</c> runs first and its findings stay visible under
///  the chat for the whole preview.
/// </summary>
unit Vcl.HelpChatAI.DesignPreview;

{$I HelpChatAI.inc}

interface

uses
  Vcl.HelpChatAI,
  HelpChatAI.Settings,
  HelpChatAI.Diagnostics;

/// <summary>Folder the relative paths of the active project resolve against:
/// its output folder when it exists, else the folder of the project file.
/// Empty when no project is open.</summary>
function HelpChatDesignBaseFolder: string;

/// <summary>Everything the design-time check found: the configuration ones
/// plus what only matters inside the IDE (no project open, no WebView2
/// loader). Loads the loader when it finds it.</summary>
function HelpChatDesignCheck(const AChat: TVclHelpChatAI): THelpChatIssues;

/// <summary>Shows the findings and, unless one of them is an error, the live
/// chat in a modal window.</summary>
procedure HelpChatDesignPreview(const AChat: TVclHelpChatAI);

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Variants,
  System.IOUtils,
  System.UITypes,
  Winapi.Windows,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Dialogs,
  ToolsAPI,
  HelpChatAI.Types,
  HelpChatAI.Provider,
  // A provider exists only where its unit is linked, and the IDE is no
  // exception: without these four the registry inside bds.exe holds the stub
  // alone, and the check would report every real provider as "nobody
  // registered it". They are the ones compiled into the library; a provider
  // of the application cannot be tested here, and the check says so.
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI,
  HelpChatAI.Provider.Gemini;

const
  /// <summary>Where the installer puts the loader, under the folder the IDE
  /// knows as $(HELPCHATAIDIR).</summary>
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
  /// the check stay readable underneath.</summary>
  THelpChatPreviewForm = class(TForm)
  strict private
    FChatPanel: TPanel;
    FFooter: TPanel;
    FLog: TMemo;
    FCloseButton: TButton;
    FChat: TVclHelpChatAI;
    procedure CloseClick(Sender: TObject);
  strict protected
    /// <summary>The chat opens here and not before: the panel needs a window
    /// of its own for the WebView, and it gets one when the form is shown.</summary>
    procedure DoShow; override;
  public
    constructor CreatePreview(const ACaption: string; const AIssues: THelpChatIssues;
      const AWidth, AHeight: Integer); reintroduce;
    procedure KeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    /// <summary>Where the chat is parented.</summary>
    property ChatPanel: TPanel read FChatPanel;
    /// <summary>The chat to open on show; not owned.</summary>
    property Chat: TVclHelpChatAI read FChat write FChat;
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
      // An unknown macro is not worth an exception in a check.
      Result := AValue;
    end;
end;

function HelpChatDesignBaseFolder: string;
var
  LProject: IOTAProject;
  LOutput: string;
begin
  Result := '';
  LProject := GetActiveProject;
  if LProject = nil then
    Exit;
  Result := ExtractFilePath(LProject.FileName);
  // The application resolves its relative paths against its own folder, so the
  // output folder is the honest answer; the project folder is the fallback for
  // a project that has not been built yet.
  LOutput := '';
  try
    if Assigned(LProject.ProjectOptions) then
      LOutput := VarToStrDef(LProject.ProjectOptions.Values['OutputDir'], '');
  except
    LOutput := '';
  end;
  if LOutput = '' then
    Exit;
  LOutput := ExpandIdeMacro(LOutput);
  if TPath.IsRelativePath(LOutput) then
    LOutput := TPath.Combine(Result, LOutput);
  if TDirectory.Exists(LOutput) then
    Result := IncludeTrailingPathDelimiter(TPath.GetFullPath(LOutput));
end;

/// <summary>Makes the WebView2 loader reachable by base name. Nothing ships it
/// next to bds.exe, so it is loaded by full path first: the panel then asks
/// Windows for "WebView2Loader.dll" and gets the module already in the
/// process.</summary>
function EnsureWebView2Loader(const ABaseFolder: string; out AFrom: string): Boolean;

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
  // Next to the application being designed, where it has to be at runtime.
  if TryLoad(TPath.Combine(ABaseFolder, HELPCHAT_DESIGN_LOADER_DLL)) then
    Exit(True);
  // Where the installer left it.
  LLibrary := ExpandIdeMacro(HELPCHAT_DESIGN_LIBRARY_MACRO);
  if (LLibrary <> '') and (LLibrary <> HELPCHAT_DESIGN_LIBRARY_MACRO) then
    if TryLoad(TPath.Combine(TPath.Combine(LLibrary, HELPCHAT_DESIGN_LOADER_SUBDIR),
      HELPCHAT_DESIGN_LOADER_DLL)) then
      Exit(True);
  Result := False;
end;

/// <summary>The settings of the component as the built application would see
/// them: the shared helpchatai.json and the one of the output folder are the
/// two files it would read next to its executable.</summary>
function DesignSettings(const AChat: TVclHelpChatAI; const ABaseFolder: string;
  out AConfigFiles: TArray<string>): THelpChatSettings;
begin
  Result := HelpChatSettingsForFolder(AChat.Settings, ABaseFolder,
    AChat.ConfigFileName, AConfigFiles);
end;

function HelpChatDesignCheck(const AChat: TVclHelpChatAI): THelpChatIssues;
var
  LSettings: THelpChatSettings;
  LConfigFiles: TArray<string>;
  LBaseFolder, LFile, LLoadedFrom: string;
begin
  Result := [];
  LBaseFolder := HelpChatDesignBaseFolder;
  if LBaseFolder = '' then
  begin
    Result := Result + [THelpChatIssue.Create(hikError, 'Project',
      'No project is open: there is no folder to resolve the documentation ' +
      'index and the configuration file against.')];
    Exit;
  end;
  Result := Result + [THelpChatIssue.Create(hikInfo, 'Project folder', LBaseFolder)];

  if EnsureWebView2Loader(LBaseFolder, LLoadedFrom) then
  begin
    if not SameText(LLoadedFrom, HELPCHAT_DESIGN_LOADER_DLL) then
      Result := Result + [THelpChatIssue.Create(hikInfo, 'WebView2 loader', LLoadedFrom)];
  end
  else
    Result := Result + [THelpChatIssue.Create(hikError, 'WebView2 loader',
      Format('%s was not found. Copy the one of Redist\WebView2 (%s inside the ' +
        'IDE) into the output folder of the project, where the application ' +
        'needs it anyway.', [HELPCHAT_DESIGN_LOADER_DLL,
        {$IFDEF WIN64}'x64'{$ELSE}'x86'{$ENDIF}]))];

  try
    LSettings := DesignSettings(AChat, LBaseFolder, LConfigFiles);
  except
    // A configuration that was asked for and is not there is an error the
    // developer has to see, not an exception out of a check.
    on E: Exception do
    begin
      Result := Result + [THelpChatIssue.Create(hikError, 'Configuration file', E.Message)];
      Exit;
    end;
  end;
  try
    for LFile in LConfigFiles do
      Result := Result + [THelpChatIssue.Create(hikInfo, 'Configuration file', LFile)];
    Result := Result + HelpChatCheckSettings(LSettings);
    // "Nobody registered it" means something else here than at run time.
    if (Trim(LSettings.Provider) <> '') and
       not THelpChatProviderRegistry.IsRegistered(LSettings.Provider) then
      Result := Result + [THelpChatIssue.Create(hikInfo, 'Provider',
        Format('Inside the IDE only the providers compiled into HelpChat run: ' +
      '%s. One registered by your own application exists only once that ' +
      'application runs, so it cannot be tested from here.',
        [string.Join(', ', THelpChatProviderRegistry.ProviderNames)]))];
  finally
    LSettings.Free;
  end;
end;

{ THelpChatPreviewForm }

constructor THelpChatPreviewForm.CreatePreview(const ACaption: string;
  const AIssues: THelpChatIssues; const AWidth, AHeight: Integer);
begin
  inherited CreateNew(nil);
  Caption := ACaption;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  Width := AWidth;
  Height := AHeight;
  Constraints.MinWidth := HELPCHAT_DESIGN_MIN_WIDTH;
  Constraints.MinHeight := HELPCHAT_DESIGN_MIN_HEIGHT;
  KeyPreview := True;
  OnKeyDown := KeyDownHandler;

  FFooter := TPanel.Create(Self);
  FFooter.Parent := Self;
  FFooter.Align := alBottom;
  FFooter.Height := HELPCHAT_DESIGN_LOG_HEIGHT;
  FFooter.BevelOuter := bvNone;
  FFooter.Padding.SetBounds(6, 6, 6, 6);

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := FFooter;
  FCloseButton.Align := alRight;
  FCloseButton.Width := 90;
  FCloseButton.Caption := 'Close';
  FCloseButton.Cancel := True;
  FCloseButton.OnClick := CloseClick;

  FLog := TMemo.Create(Self);
  FLog.Parent := FFooter;
  FLog.Align := alClient;
  FLog.AlignWithMargins := True;
  FLog.Margins.SetBounds(0, 0, 6, 0);
  FLog.ReadOnly := True;
  FLog.ScrollBars := ssVertical;
  FLog.WordWrap := True;
  FLog.Text := HelpChatIssuesToText(AIssues);

  FChatPanel := TPanel.Create(Self);
  FChatPanel.Parent := Self;
  FChatPanel.Align := alClient;
  FChatPanel.BevelOuter := bvNone;
  FChatPanel.Caption := '';
end;

procedure THelpChatPreviewForm.CloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure THelpChatPreviewForm.DoShow;
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

procedure THelpChatPreviewForm.KeyDownHandler(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Esc inside the page belongs to the page (it closes the documentation
  // view); here it is the window that closes.
  if (Key = VK_ESCAPE) and (Shift = []) and not FChatPanel.Focused then
    ModalResult := mrCancel;
end;

{ the preview }

type
  /// <summary>The copy that runs in the preview. It differs from the real
  /// component in one point only: the configuration has already been read for
  /// it, from the output folder of the project, so reading it again - from
  /// the folder of the IDE, and raising when the named file is not there -
  /// would be both wrong and rude.</summary>
  THelpChatPreviewChat = class(TVclHelpChatAI)
  protected
    procedure LoadConfiguration; override;
  end;

  /// <summary>Carries the context the clone answers about: the preview is not
  /// a screen of the application, and saying so is better than handing the
  /// model whatever window of the IDE happens to be focused.</summary>
  THelpChatPreviewContext = class
  strict private
    FComponentName: string;
  public
    constructor Create(const AComponentName: string);
    procedure GetContext(Sender: TObject; var AContext: THelpChatContext);
  end;

procedure THelpChatPreviewChat.LoadConfiguration;
begin
  // Already done by HelpChatDesignCheck, against the right folder.
end;

constructor THelpChatPreviewContext.Create(const AComponentName: string);
begin
  inherited Create;
  FComponentName := AComponentName;
end;

procedure THelpChatPreviewContext.GetContext(Sender: TObject;
  var AContext: THelpChatContext);
begin
  AContext := Default(THelpChatContext);
  AContext.ScreenName := FComponentName;
  AContext.ScreenLabel := 'HelpChat design-time preview';
  AContext.ScreenType := 'Preview';
end;

procedure HelpChatDesignPreview(const AChat: TVclHelpChatAI);
var
  LIssues: THelpChatIssues;
  LSettings: THelpChatSettings;
  LConfigFiles: TArray<string>;
  LForm: THelpChatPreviewForm;
  LClone: TVclHelpChatAI;
  LContext: THelpChatPreviewContext;
  LBaseFolder: string;
begin
  LIssues := HelpChatDesignCheck(AChat);
  if HelpChatHasErrors(LIssues) then
  begin
    MessageDlg('HelpChat cannot run with this configuration:' + sLineBreak +
      sLineBreak + HelpChatIssuesToText(LIssues), mtError, [mbOK], 0);
    Exit;
  end;

  LBaseFolder := HelpChatDesignBaseFolder;
  LSettings := DesignSettings(AChat, LBaseFolder, LConfigFiles);
  LContext := nil;
  LClone := nil;
  LForm := nil;
  try
    LContext := THelpChatPreviewContext.Create(AChat.Name);
    LForm := THelpChatPreviewForm.CreatePreview(
      Format('HelpChat preview - %s', [AChat.Name]), LIssues,
      Max(AChat.PanelWidth, HELPCHAT_DESIGN_MIN_WIDTH),
      Max(AChat.PanelHeight, HELPCHAT_DESIGN_MIN_HEIGHT) + HELPCHAT_DESIGN_LOG_HEIGHT);

    // A copy, not the component on the form: that one is in csDesigning and
    // must stay exactly as the developer left it.
    LClone := THelpChatPreviewChat.Create(nil);
    LClone.Settings := LSettings;
    LClone.ShowBubble := False;        // the window is the preview itself
    LClone.RegisterHelpViewer := False;
    LClone.HandleF1 := False;
    LClone.RememberPanelPosition := False;
    LClone.FollowVclStyle := AChat.FollowVclStyle;
    LClone.VoiceEngine := AChat.VoiceEngine;
    LClone.ActionsEnabled := False;    // the handlers live in the application
    LClone.Container := LForm.ChatPanel;
    LClone.OnGetContext := LContext.GetContext;
    try
      LClone.Active := True;
    except
      on E: Exception do
      begin
        // A port that will not listen, an engine that will not start: say it
        // here, do not leave an empty window in front of the developer.
        MessageDlg(Format('HelpChat could not start: %s', [E.Message]),
          mtError, [mbOK], 0);
        Exit;
      end;
    end;
    LForm.Chat := LClone;
    LForm.ShowModal;
  finally
    if Assigned(LClone) then
    begin
      LClone.Active := False;          // stops the server, the workers, the engine
      LClone.Free;
    end;
    LForm.Free;
    LContext.Free;
    LSettings.Free;
  end;
end;

end.
