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
///  Design-time registration of the FMX component, with the component editor
///  that answers "would this configuration work?" without building the
///  application: the same check the VCL editor runs, over the settings read
///  the way the built application would read them.
///
///  There is no live preview here. The VCL panel is a <c>TEdgeBrowser</c>,
///  which the IDE can host; the FMX one is a native <c>TWebBrowser</c> window
///  inside an FMX form, and an FMX form created by a design package inside
///  the VCL IDE is not a place to find out whether that works.
///
///  The splash screen and the About box belong to <c>Vcl.HelpChatAI.Register</c>:
///  one library, one entry, whichever packages are installed.
///
///  The few lines that ask the IDE for the active project are the same as the
///  VCL ones on purpose: sharing them would mean this package requiring the
///  VCL design package, and with it the whole VCL side of the library.
/// </summary>
unit FMX.HelpChatAI.Register;

{$I HelpChatAI.inc}

interface

uses
  System.Classes,
  DesignIntf,
  DesignEditors;

type
  /// <summary>Which provider answers: the ones registered in this IDE. Same
  /// editor as the VCL side, registered again here so that installing the FMX
  /// package alone is enough.</summary>
  TFmxHelpChatProviderProperty = class(TStringProperty)
  public
    /// <summary>A drop-down that still takes typed text: a provider the
    /// application registers at run time is a legitimate value this IDE
    /// cannot list.</summary>
    function GetAttributes: TPropertyAttributes; override;
    /// <summary>The providers registered in the IDE process: the ones the
    /// design package links, see the uses clause.</summary>
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  /// <summary>Which face the assistant wears: the icons compiled into the
  /// component. A drop-down and not a free string, because nothing else would
  /// tell anybody what the four names are. It stays editable: with an image
  /// list of the application the name is that list's, not ours. Unlike the
  /// VCL editor it draws no image next to the name, and there is no editor
  /// for <c>ImageIndex</c>.</summary>
  TFmxHelpChatImageNameProperty = class(TStringProperty)
  public
    /// <summary>Editable text, no <c>paValueList</c>.</summary>
    function GetAttributes: TPropertyAttributes; override;
    /// <summary>The names of <c>HelpChatAssistantIconNames</c>.</summary>
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  /// <summary>Verbs of the component, in this order: the configuration
  /// editor (verb 0, so a double click on the component opens it), the
  /// configuration check, the rebuild of the documentation index, and the
  /// version line that opens the documentation on the web. One verb fewer
  /// than the VCL editor: there is no design-time preview in FireMonkey.
  /// Everything is resolved against the active project of the IDE, never
  /// against bds.exe.</summary>
  TFmxHelpChatComponentEditor = class(TComponentEditor)
  strict private
    /// <summary>The component being edited, nil when it is not a
    /// <c>TFmxHelpChatAI</c>.</summary>
    function GetChat: TComponent;
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    /// <summary>Runs a verb. The configuration editor writes the profile it
    /// is given back into the component and marks the designer modified;
    /// the check first offers to build an index that is missing; neither
    /// starts the component.</summary>
    procedure ExecuteVerb(Index: Integer); override;
  end;

/// <summary>Called by the IDE when the design package is loaded: marks the
/// process as design time (<c>HelpChatDesignTime</c>, so secrets are read
/// in clear and no <c>OnDecryptSecret</c> is expected), puts the component
/// on the palette and registers its editors. The provider editor is
/// registered on <c>THelpChatSettings</c>, as the VCL package does: with
/// both packages installed the two registrations name the same list.</summary>
procedure Register;

implementation

uses
  System.SysUtils,
  System.UITypes,
  System.Variants,
  System.IOUtils,
  Winapi.Windows,
  Winapi.ShellApi,
  Vcl.Dialogs,
  ToolsAPI,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Diagnostics,
  HelpChatAI.IndexBuilder,
  HelpChatAI.Assistant,
  HelpChatAI.Provider,
  // A provider exists only where its unit is linked, and the IDE is no
  // exception: without these four the registry inside bds.exe holds the stub
  // alone, and the check would report every real provider as "nobody
  // registered it". They are the ones compiled into the library; a provider
  // of the application cannot be tested here, and the check says so.
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI,
  HelpChatAI.Provider.Gemini,
  FMX.HelpChatAI,
  FMX.HelpChatAI.ConfigEditor;

const
  HELPCHAT_PALETTE_PAGE = 'Ethea HelpChat';
  HELPCHAT_DOCS_URL = 'https://ethea.it/docs/helpchatai/';

resourcestring
  SHelpChatVerbConfig = 'C&onfiguration...';
  SHelpChatVerbCheck = '&Check configuration...';
  SHelpChatVerbIndex = '&Rebuild documentation index...';
  SHelpChatVerbAbout = 'Ver. %s - (c) Ethea S.r.l. - Open Web Help...';
  SHelpChatCheckOk = 'HelpChat is ready to run with this configuration.';
  SHelpChatCheckFailed = 'HelpChat cannot run with this configuration:';

/// <summary>Expands the root macros of the IDE in a path
/// (<c>IOTAServices.ExpandRootMacro</c>); the value as it is when the IDE
/// cannot.</summary>
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

/// <summary>Folder the relative paths of the active project resolve against:
/// its output folder when it exists, else the folder of the project file.</summary>
function DesignBaseFolder: string;
var
  LProject: IOTAProject;
  LOutput: string;
begin
  Result := '';
  LProject := GetActiveProject;
  if LProject = nil then
    Exit;
  Result := ExtractFilePath(LProject.FileName);
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

/// <summary>The executable of the active project: its folder holds the
/// configuration file of the application, its name the per-user folder.
/// Deduced, not read: the output folder plus the name of the project file
/// with .exe, so a project that renames its target, or one for another
/// platform, is not followed. Empty when no project is open.</summary>
function DesignExeFile: string;
var
  LProject: IOTAProject;
  LFolder: string;
begin
  Result := '';
  LProject := GetActiveProject;
  LFolder := DesignBaseFolder;
  if (LProject = nil) or (LFolder = '') then
    Exit;
  Result := IncludeTrailingPathDelimiter(LFolder) +
    ChangeFileExt(ExtractFileName(LProject.FileName), '.exe');
end;

/// <summary>"Would this work?" for the application being designed: the
/// settings of the component merged with the configuration files the built
/// application would read from its output folder, then
/// <c>HelpChatCheckSettings</c>. Never raises: a configuration file that was
/// named and is missing becomes an error line. Nothing is started and no
/// service is called.</summary>
function DesignCheck(const AChat: TFmxHelpChatAI): THelpChatIssues;
var
  LSettings: THelpChatSettings;
  LConfigFiles: TArray<string>;
  LBaseFolder, LFile: string;
begin
  Result := [];
  LBaseFolder := DesignBaseFolder;
  if LBaseFolder = '' then
  begin
    Result := Result + [THelpChatIssue.Create(hikError, 'Project',
      'No project is open: there is no folder to resolve the documentation ' +
      'index and the configuration file against.')];
    Exit;
  end;
  Result := Result + [THelpChatIssue.Create(hikInfo, 'Project folder', LBaseFolder)];
  try
    LSettings := HelpChatSettingsForFolder(AChat.Settings, LBaseFolder,
      AChat.ConfigFileName, LConfigFiles, DesignExeFile);
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

/// <summary>The plan of an index rebuild for the application being designed,
/// with its paths resolved the way the built application resolves them. The
/// VCL design package has the same twenty lines, and for the same reason as
/// the ones above: sharing them would mean requiring that package, and with
/// it the whole VCL runtime of the library.</summary>
function DesignIndexPlan(const AChat: TFmxHelpChatAI; out APlan: THelpChatIndexPlan;
  out AError: string): Boolean;
var
  LSettings: THelpChatSettings;
  LConfigFiles: TArray<string>;
  LBaseFolder: string;
begin
  APlan := Default(THelpChatIndexPlan);
  AError := '';
  LBaseFolder := DesignBaseFolder;
  if LBaseFolder = '' then
  begin
    AError := 'No project is open: there is no folder to resolve the ' +
      'documentation folder and the index against.';
    Exit(False);
  end;
  try
    LSettings := HelpChatSettingsForFolder(AChat.Settings, LBaseFolder,
      AChat.ConfigFileName, LConfigFiles, DesignExeFile);
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

/// <summary>Builds the index APlan describes and says how it went, with the
/// VCL message box: this package runs inside the IDE, which is a VCL
/// application.</summary>
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

/// <summary>The verb: shows the plan - the deductions included, such as the
/// link extension - and builds only on a Yes. A design-time action that
/// guesses in silence is worse than one that asks.</summary>
function DesignRebuildIndex(const AChat: TFmxHelpChatAI): Boolean;
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

/// <summary>An index that is not there means an assistant with nothing to
/// answer from, and the developer usually wants it built rather than
/// explained. Says nothing when it is there, or when there is no folder to
/// build it from - the check reports that one.</summary>
procedure OfferIndexBeforeCheck(const AChat: TFmxHelpChatAI);
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

{ TFmxHelpChatComponentEditor }

function TFmxHelpChatComponentEditor.GetChat: TComponent;
begin
  Result := Component;
  if not (Result is TFmxHelpChatAI) then
    Result := nil;
end;

function TFmxHelpChatComponentEditor.GetVerbCount: Integer;
begin
  Result := 4;
end;

function TFmxHelpChatComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SHelpChatVerbConfig;
    1: Result := SHelpChatVerbCheck;
    2: Result := SHelpChatVerbIndex;
    3: Result := Format(SHelpChatVerbAbout, [HELPCHAT_VERSION]);
  else
    Result := '';
  end;
end;

procedure TFmxHelpChatComponentEditor.ExecuteVerb(Index: Integer);
var
  LChat: TComponent;
  LIssues: THelpChatIssues;
begin
  LChat := GetChat;
  case Index of
    0:
      if Assigned(LChat) then
        TFmxHelpChatConfigEditor.Execute(TFmxHelpChatAI(LChat).Settings,
          TFmxHelpChatAI(LChat).Profile, TFmxHelpChatAI(LChat).AssistantName,
          DesignExeFile, TFmxHelpChatAI(LChat).ConfigFileName,
          procedure(AProfile: string)
          begin
            TFmxHelpChatAI(LChat).Profile := AProfile;
            Designer.Modified;
          end,
          procedure(APath: string)
          begin
            // "To component" writes into Settings, and the name of the
            // assistant is not a published property there: it lives on the
            // component, which is what the form file stores. Moved even when
            // empty, which is how the name is taken away again.
            if SameText(APath, 'AssistantName') then
            begin
              TFmxHelpChatAI(LChat).AssistantName := TFmxHelpChatAI(LChat).Settings.AssistantName;
              TFmxHelpChatAI(LChat).Settings.AssistantName := '';
            end;
            Designer.Modified;
          end,
          // No design-time preview in FireMonkey: the Test button stays off.
          nil);
    1:
      if Assigned(LChat) then
      begin
        // An index that is missing is worth offering to build before
        // reporting it as a finding.
        OfferIndexBeforeCheck(TFmxHelpChatAI(LChat));
        LIssues := DesignCheck(TFmxHelpChatAI(LChat));
        if HelpChatHasErrors(LIssues) then
          MessageDlg(SHelpChatCheckFailed + sLineBreak + sLineBreak +
            HelpChatIssuesToText(LIssues), mtError, [mbOK], 0)
        else
          MessageDlg(SHelpChatCheckOk + sLineBreak + sLineBreak +
            HelpChatIssuesToText(LIssues), mtInformation, [mbOK], 0);
      end;
    2:
      if Assigned(LChat) then
        DesignRebuildIndex(TFmxHelpChatAI(LChat));
    3:
      ShellExecute(0, 'open', PChar(HELPCHAT_DOCS_URL), nil, nil, SW_SHOWNORMAL);
  end;
end;

{ TFmxHelpChatProviderProperty }

function TFmxHelpChatProviderProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paRevertable];
end;

procedure TFmxHelpChatProviderProperty.GetValues(Proc: TGetStrProc);
var
  LName: string;
begin
  for LName in THelpChatProviderRegistry.ProviderNames do
    Proc(LName);
end;

function TFmxHelpChatImageNameProperty.GetAttributes: TPropertyAttributes;
begin
  // paValueList is what makes the Object Inspector call GetValues at all: it
  // shows the list and still lets a name be typed, which an image list of
  // the application needs.
  Result := [paMultiSelect, paValueList, paRevertable];
end;

procedure TFmxHelpChatImageNameProperty.GetValues(Proc: TGetStrProc);
var
  LName: string;
begin
  for LName in HelpChatAssistantIconNames do
    Proc(LName);
end;

procedure Register;
begin
  // Inside the IDE every secret is read in clear: no OnDecryptSecret of the
  // application runs here.
  HelpChatDesignTime := True;
  RegisterComponents(HELPCHAT_PALETTE_PAGE, [TFmxHelpChatAI]);
  RegisterComponentEditor(TFmxHelpChatAI, TFmxHelpChatComponentEditor);
  RegisterPropertyEditor(TypeInfo(string),
    THelpChatSettings, 'Provider', TFmxHelpChatProviderProperty);
  RegisterPropertyEditor(TypeInfo(string),
    TFmxHelpChatAI, 'ImageName', TFmxHelpChatImageNameProperty);
end;

end.
