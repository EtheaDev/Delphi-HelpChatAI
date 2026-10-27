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
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  /// <summary>Which face the assistant wears: the icons compiled into the
  /// component. A drop-down and not a free string, because nothing else would
  /// tell anybody what the four names are. It stays editable: with an image
  /// list of the application the name is that list's, not ours.</summary>
  TFmxHelpChatImageNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  /// <summary>Verbs of the component: check it, read about it.</summary>
  TFmxHelpChatComponentEditor = class(TComponentEditor)
  strict private
    function GetChat: TComponent;
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

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
  FMX.HelpChatAI;

const
  HELPCHAT_PALETTE_PAGE = 'Ethea HelpChat';
  HELPCHAT_DOCS_URL = 'https://ethea.it/docs/helpchatai/';

resourcestring
  SHelpChatVerbCheck = '&Check configuration...';
  SHelpChatVerbAbout = 'Ver. %s - (c) Ethea S.r.l. - Open Web Help...';
  SHelpChatCheckOk = 'HelpChat is ready to run with this configuration.';
  SHelpChatCheckFailed = 'HelpChat cannot run with this configuration:';

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
      AChat.ConfigFileName, LConfigFiles);
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

{ TFmxHelpChatComponentEditor }

function TFmxHelpChatComponentEditor.GetChat: TComponent;
begin
  Result := Component;
  if not (Result is TFmxHelpChatAI) then
    Result := nil;
end;

function TFmxHelpChatComponentEditor.GetVerbCount: Integer;
begin
  Result := 2;
end;

function TFmxHelpChatComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := SHelpChatVerbCheck;
    1: Result := Format(SHelpChatVerbAbout, [HELPCHAT_VERSION]);
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
      begin
        LIssues := DesignCheck(TFmxHelpChatAI(LChat));
        if HelpChatHasErrors(LIssues) then
          MessageDlg(SHelpChatCheckFailed + sLineBreak + sLineBreak +
            HelpChatIssuesToText(LIssues), mtError, [mbOK], 0)
        else
          MessageDlg(SHelpChatCheckOk + sLineBreak + sLineBreak +
            HelpChatIssuesToText(LIssues), mtInformation, [mbOK], 0);
      end;
    1:
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
  // No paValueList: the list is a suggestion, not the only thing allowed.
  Result := [paMultiSelect, paRevertable];
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
  RegisterComponents(HELPCHAT_PALETTE_PAGE, [TFmxHelpChatAI]);
  RegisterComponentEditor(TFmxHelpChatAI, TFmxHelpChatComponentEditor);
  RegisterPropertyEditor(TypeInfo(string),
    THelpChatSettings, 'Provider', TFmxHelpChatProviderProperty);
  RegisterPropertyEditor(TypeInfo(string),
    TFmxHelpChatAI, 'ImageName', TFmxHelpChatImageNameProperty);
end;

end.
