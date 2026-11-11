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
///  The copy is a real component, so it goes where every active assistant
///  goes: it acquires an engine from <c>THelpChatEngines</c> (released when
///  the preview closes, which frees it - the preview is modal, so there is
///  never a second holder), and it joins the process-wide coordinator of
///  <c>Vcl.HelpChatAI</c>, with F1 and the help viewer off so that nothing of
///  the IDE is answered by it. What it carries of the component is its
///  settings - with the profile section of the files already applied to
///  them -, <c>FollowVclStyle</c> and <c>VoiceEngine</c>; the rest (name,
///  icon, stylesheets, commands, actions) is the default of a new component.
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
/// Empty when no project is open. With a trailing delimiter. It is the
/// active project of the IDE, whichever project the form being designed
/// belongs to, and the output folder as the project options give it: one
/// that still holds a macro the IDE does not expand does not exist, and the
/// project folder is returned instead.</summary>
function HelpChatDesignBaseFolder: string;

/// <summary>The executable of the active project: its folder holds the
/// configuration file of the application, its name the per-user folder.
/// Never bds.exe. It is deduced, not asked: the base folder of the design
/// time (the output folder when it exists, else the project folder) plus
/// the name of the project file with .exe - so it is the active project of
/// the group that counts, not the one the form belongs to. Empty when no
/// project is open: the editor then offers the shared file alone.</summary>
function HelpChatDesignExeFile: string;

/// <summary>Everything the design-time check found: the configuration ones
/// plus what only matters inside the IDE (no project open, no WebView2
/// loader). Loads the loader when it finds it - a side effect the preview
/// relies on. Never raises for a configuration that cannot be read: a named
/// file that is missing comes back as an error finding. <c>AChat</c> is only
/// read: its settings, its profile (inside them) and its
/// <c>ConfigFileName</c>.</summary>
function HelpChatDesignCheck(const AChat: TVclHelpChatAI): THelpChatIssues;

/// <summary>Shows the findings and, unless one of them is an error, the live
/// chat in a modal window. Offers to build the documentation index when it is
/// not there: without it there is nothing to preview an answer from. Returns
/// when the window is closed; by then the copy that ran is stopped and
/// freed, and the engine it held with it. <c>AChat</c> itself is never
/// activated or changed. The conversation of a preview is a real one: it is
/// answered by the configured provider, with the key of the developer.</summary>
procedure HelpChatDesignPreview(const AChat: TVclHelpChatAI);

/// <summary>Rebuilds the documentation index of the application being
/// designed, from the folder and to the file the settings name. Shows what it
/// is about to do - the deductions included - and asks before doing it, then
/// says how it went. True when the index was written; False when there was
/// nothing to build from, when the developer said no, or when it failed.</summary>
function HelpChatDesignRebuildIndex(const AChat: TVclHelpChatAI): Boolean;

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
  HelpChatAI.IndexBuilder,
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
    /// <summary>Builds the window in code (no DFM): the findings in a
    /// read-only memo at the foot, the panel for the chat above it.</summary>
    constructor CreatePreview(const ACaption: string; const AIssues: THelpChatIssues;
      const AWidth, AHeight: Integer); reintroduce;
    /// <summary>Esc closes the window, unless the key belongs to the page.</summary>
    procedure KeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    /// <summary>Where the chat is parented.</summary>
    property ChatPanel: TPanel read FChatPanel;
    /// <summary>The chat to open on show; not owned.</summary>
    property Chat: TVclHelpChatAI read FChat write FChat;
  end;

/// <summary>Expands the macros the IDE knows at its root - $(BDS), the
/// environment variables, $(HELPCHATAIDIR) once the installer defined it. A
/// macro it does not know comes back as it was written.</summary>
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
  // Already in the process, or on the search path. The module is never
  // released: it has to stay for as long as the IDE may open a panel.
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
/// two files it would read next to its executable - or the one file
/// <c>ConfigFileName</c> names, which must exist (EHelpChatConfigError
/// otherwise). The profile travels inside the settings of the component, so
/// each file is applied with its root and then its section of that profile.
/// The per-user file is the one of the project's executable. The caller
/// frees the result.</summary>
function DesignSettings(const AChat: TVclHelpChatAI; const ABaseFolder: string;
  out AConfigFiles: TArray<string>): THelpChatSettings;
begin
  Result := HelpChatSettingsForFolder(AChat.Settings, ABaseFolder,
    AChat.ConfigFileName, AConfigFiles, HelpChatDesignExeFile);
end;

function HelpChatDesignExeFile: string;
var
  LProject: IOTAProject;
  LFolder: string;
begin
  Result := '';
  LProject := GetActiveProject;
  LFolder := HelpChatDesignBaseFolder;
  if (LProject = nil) or (LFolder = '') then
    Exit;
  Result := IncludeTrailingPathDelimiter(LFolder) +
    ChangeFileExt(ExtractFileName(LProject.FileName), '.exe');
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
    Result := Result + HelpChatCheckProfile(AChat.Profile, LConfigFiles);
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
    /// <summary>Does nothing: the settings the copy was given already are
    /// the configuration.</summary>
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
    /// <summary>The <c>OnGetContext</c> of the copy: replaces whatever was
    /// computed from the focused window with the name of the component and
    /// the word "Preview".</summary>
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

/// <summary>The plan of a rebuild for the application being designed, with
/// its paths resolved the way the built application resolves them. False with
/// AError set when there is nothing to plan.</summary>
function DesignIndexPlan(const AChat: TVclHelpChatAI; out APlan: THelpChatIndexPlan;
  out AError: string): Boolean;
var
  LSettings: THelpChatSettings;
  LConfigFiles: TArray<string>;
  LBaseFolder: string;
begin
  APlan := Default(THelpChatIndexPlan);
  AError := '';
  LBaseFolder := HelpChatDesignBaseFolder;
  if LBaseFolder = '' then
  begin
    AError := 'No project is open: there is no folder to resolve the ' +
      'documentation folder and the index against.';
    Exit(False);
  end;
  try
    LSettings := DesignSettings(AChat, LBaseFolder, LConfigFiles);
  except
    on E: Exception do
    begin
      AError := E.Message;
      Exit(False);
    end;
  end;
  try
    APlan := HelpChatPlanIndexBuild(LSettings);
  finally
    LSettings.Free;
  end;
  AError := APlan.Problem;
  Result := APlan.CanBuild;
end;

/// <summary>Builds the index of APlan and says how it went.</summary>
function RunAndReport(var APlan: THelpChatIndexPlan): Boolean;
var
  LText: string;
begin
  Result := HelpChatRunIndexBuild(APlan);
  if not Result then
  begin
    MessageDlg('The documentation index could not be built:' + sLineBreak +
      sLineBreak + APlan.Problem, mtError, [mbOK], 0);
    Exit;
  end;
  LText := Format('%d pages indexed into'#13#10'%s', [APlan.PageCount, APlan.OutputFile]);
  if Trim(APlan.Warnings) <> '' then
    LText := LText + sLineBreak + sLineBreak + APlan.Warnings;
  MessageDlg(LText, mtInformation, [mbOK], 0);
end;

function HelpChatDesignRebuildIndex(const AChat: TVclHelpChatAI): Boolean;
var
  LPlan: THelpChatIndexPlan;
  LError: string;
begin
  Result := False;
  if not DesignIndexPlan(AChat, LPlan, LError) then
  begin
    MessageDlg('The documentation index cannot be built:' + sLineBreak +
      sLineBreak + LError, mtWarning, [mbOK], 0);
    Exit;
  end;
  if MessageDlg('Rebuild the documentation index?' + sLineBreak + sLineBreak +
    LPlan.Describe, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  Result := RunAndReport(LPlan);
end;

/// <summary>Before a preview: an index that is not there means an assistant
/// with nothing to answer from, and the developer usually wants it built
/// rather than explained. Says nothing when the index is there, or when there
/// is no folder to build it from - the check reports that one.</summary>
procedure OfferIndexBeforePreview(const AChat: TVclHelpChatAI);
var
  LPlan: THelpChatIndexPlan;
  LError: string;
begin
  if not DesignIndexPlan(AChat, LPlan, LError) then
    Exit;
  if LPlan.OutputExists then
    Exit;
  if MessageDlg('The documentation index is not there yet, so the assistant ' +
    'has nothing to ground its answers on.' + sLineBreak + sLineBreak +
    'Build it now?' + sLineBreak + sLineBreak + LPlan.Describe,
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  RunAndReport(LPlan);
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
  OfferIndexBeforePreview(AChat);
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
    // Which assistant it is, before the settings: assigning them puts the
    // Profile of the copy on them, and an empty one made the preview of every
    // expert acquire the engine of the default assistant and write its
    // conversation and state files.
    LClone.Profile := AChat.Profile;
    LClone.AssistantName := AChat.AssistantName;
    LClone.Caption := AChat.Caption;
    LClone.EnabledCommands := AChat.EnabledCommands;
    // Assigned, not shared: the copy keeps settings of its own.
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
      // The only holder of its engine, so releasing it frees it: nothing of
      // the preview keeps running inside the IDE. The window goes after the
      // copy, whose panel is parented to it.
      LClone.Active := False;          // stops the server, the workers, the engine
      LClone.Free;
    end;
    LForm.Free;
    LContext.Free;
    LSettings.Free;
  end;
end;

end.
