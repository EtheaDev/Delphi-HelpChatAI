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
///  The configuration editor of the FireMonkey component (design package):
///  the twin of <c>Vcl.HelpChatAI.ConfigEditor</c>, written with FireMonkey
///  controls, over the same <see cref="HelpChatAI.ConfigController" />. No
///  rule lives here: the form shows what the controller says and forwards
///  what the user does.
/// </summary>
unit FMX.HelpChatAI.ConfigEditor;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.Rtti,
  System.Types,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Objects,
  FMX.Edit,
  FMX.EditBox,
  FMX.SpinBox,
  FMX.ComboEdit,
  FMX.ListBox,
  FMX.Memo,
  FMX.Memo.Types,
  FMX.Grid,
  FMX.Grid.Style,
  FMX.ScrollBox,
  FMX.TabControl,
  FMX.Controls.Presentation,
  HelpChatAI.Settings,
  HelpChatAI.ConfigController,
  FMX.WebBrowser,
  FMX.HelpChatAI;

type
  /// <summary>
  ///  The editor as a FireMonkey form, shown modally inside the IDE by the
  ///  component editor of <c>TFmxHelpChatAI</c>. Six pages: Appearance,
  ///  Settings, Prompt and Documents list the settings of the catalogue that
  ///  belong to them, with the value in use and where it comes from (one
  ///  grid and one edit area, <c>GridLayout</c>, moved to the page shown; the
  ///  Prompt page shows beside it the prompt those settings build), then
  ///  the catalogue of models with what the profile offers of it, and the
  ///  profiles of the file. One file is edited at a time; nothing is written
  ///  until Save.
  ///
  ///  A secret is shown masked in the grid (the controller masks it) and
  ///  edited in clear in a password box: what goes back to the controller is
  ///  the text typed, never the mask, and never into the component.
  ///
  ///  Where it differs from the VCL twin, it is the controls: string grids
  ///  for the two list views, a list box with check boxes for the check
  ///  list, <c>TDialogServiceSync</c> for the questions, and no theme of the
  ///  IDE - it wears the default FireMonkey style. The Test button saves
  ///  first and opens the preview of <c>FMX.HelpChatAI.DesignPreview</c>.
  /// </summary>
  TFmxHelpChatConfigEditor = class(TForm)
    /// <summary>The female assistant, the face of the FireMonkey component:
    /// the PNG of 512 pixels in the form file, stretched.</summary>
    AssistantImage: TImage;
    TopLayout: TLayout;
    FileLabel: TLabel;
    FileCombo: TComboBox;
    ReloadButton: TButton;
    SaveButton: TButton;
    FileNameLabel: TLabel;
    BottomLayout: TLayout;
    StatusLabel: TLabel;
    TestButton: TButton;
    CloseButton: TButton;
    HelpButton: TButton;
    TabControl: TTabControl;
    AppearanceTab: TTabItem;
    /// <summary>The right of the Appearance page: the chat as it would look,
    /// the switch between the light and the dark theme, and the style sheet
    /// of the component.</summary>
    PreviewLayout: TLayout;
    PreviewTopLayout: TLayout;
    PreviewLabel: TLabel;
    ThemeLabel: TLabel;
    ThemeSwitch: TSwitch;
    StyleSheetLabel: TLabel;
    StyleSheetEdit: TEdit;
    StyleSheetBrowseButton: TButton;
    StyleSheetApplyButton: TButton;
    StyleSheetErrorLabel: TLabel;
    /// <summary>Where the browser of the preview is created, in code: the
    /// WebView2 loader must be reachable first.</summary>
    PreviewHost: TLayout;
    PreviewMessageLabel: TLabel;
    AppearanceSplitter: TSplitter;
    /// <summary>The left of the Appearance page: the icon, then the grid.</summary>
    AppearanceLeftLayout: TLayout;
    /// <summary>The icon of the assistant: the images of the component's
    /// <c>Images</c>, else the built-in ones; a click writes
    /// <c>ImageIndex</c> or <c>ImageName</c> into the component.</summary>
    IconLayout: TLayout;
    IconLabel: TLabel;
    IconList: TListBox;
    IconHintLabel: TLabel;
    SettingsTab: TTabItem;
    /// <summary>The grid of the settings and the edit area, moved to the
    /// page shown among the four that list settings.</summary>
    GridLayout: TLayout;
    PromptTab: TTabItem;
    PromptLayout: TLayout;
    PromptLabel: TLabel;
    PromptMemo: TMemo;
    PromptSplitter: TSplitter;
    ModelsTab: TTabItem;
    ProfilesTab: TTabItem;
    DocumentsTab: TTabItem;
    ProfileLayout: TLayout;
    ProfileLabel: TLabel;
    ProfileCombo: TComboEdit;
    ProfileHintLabel: TLabel;
    EditLayout: TLayout;
    SettingLabel: TLabel;
    HintLabel: TLabel;
    ValueMemo: TMemo;
    SecretEdit: TEdit;
    ShowSecretCheck: TCheckBox;
    /// <summary>The value controls, one per kind of setting, only one
    /// visible at a time: a line, the memo for the prompts, the password
    /// box for a key, a check box, a spin box, a combo for a language, an
    /// editable combo for a provider or a model, a list with check boxes for
    /// a set.</summary>
    ValueEdit: TEdit;
    ValueCombo: TComboBox;
    ChoiceCombo: TComboEdit;
    ValueCheck: TCheckBox;
    NumberSpin: TSpinBox;
    ValueChecks: TListBox;
    ToProfileButton: TButton;
    ToRootButton: TButton;
    ToComponentButton: TButton;
    RemoveProfileButton: TButton;
    RemoveRootButton: TButton;
    RemoveComponentButton: TButton;
    SettingsGrid: TStringGrid;
    ProfileModelsLayout: TLayout;
    ProfileModelsLabel: TLabel;
    ProfileModelsList: TListBox;
    ProfileModelsButton: TButton;
    ModelLayout: TLayout;
    ModelNameLabel: TLabel;
    ModelNameEdit: TEdit;
    ModelProviderLabel: TLabel;
    ModelProviderCombo: TComboEdit;
    ModelModelLabel: TLabel;
    ModelModelEdit: TEdit;
    ModelUrlLabel: TLabel;
    ModelUrlEdit: TEdit;
    ModelKeyLabel: TLabel;
    ModelKeyEdit: TEdit;
    ProviderKeyLabel: TLabel;
    ProviderKeyEdit: TEdit;
    ProviderKeySetButton: TButton;
    ModelAddButton: TButton;
    ModelUpdateButton: TButton;
    ModelDeleteButton: TButton;
    ModelsGrid: TStringGrid;
    ProfilesHintLabel: TLabel;
    ProfilesList: TListBox;
    ProfileAddButton: TButton;
    ProfileRenameButton: TButton;
    ProfileDeleteButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FileComboChange(Sender: TObject);
    procedure ReloadButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure ProfileComboChange(Sender: TObject);
    procedure SettingsGridSelChanged(Sender: TObject);
    /// <summary>The "In use" column drawn the way the Object Inspector
    /// draws a value: bold for one of a configuration file, bold and blue
    /// for one of the form file, plain for the library's. Assigned in
    /// <c>FormCreate</c>, with the default drawing of the grid off.</summary>
    procedure SettingsGridDrawColumnCell(Sender: TObject; const Canvas: TCanvas;
      const Column: TColumn; const Bounds: TRectF; const Row: Integer;
      const Value: TValue; const State: TGridDrawStates);
    procedure ShowSecretCheckChange(Sender: TObject);
    procedure ToProfileButtonClick(Sender: TObject);
    procedure ToRootButtonClick(Sender: TObject);
    procedure ToComponentButtonClick(Sender: TObject);
    procedure RemoveProfileButtonClick(Sender: TObject);
    procedure RemoveRootButtonClick(Sender: TObject);
    procedure RemoveComponentButtonClick(Sender: TObject);
    procedure ModelsGridSelChanged(Sender: TObject);
    procedure ModelAddButtonClick(Sender: TObject);
    procedure ModelProviderComboChange(Sender: TObject);
    procedure ProviderKeySetButtonClick(Sender: TObject);
    procedure ModelUpdateButtonClick(Sender: TObject);
    procedure ModelDeleteButtonClick(Sender: TObject);
    procedure ProfileModelsButtonClick(Sender: TObject);
    procedure ProfileAddButtonClick(Sender: TObject);
    procedure ProfileRenameButtonClick(Sender: TObject);
    procedure ProfileDeleteButtonClick(Sender: TObject);
    procedure TestButtonClick(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure IconListChange(Sender: TObject);
    procedure ThemeSwitchSwitch(Sender: TObject);
    procedure StyleSheetBrowseButtonClick(Sender: TObject);
    procedure StyleSheetApplyButtonClick(Sender: TObject);
  strict private
    /// <summary>The browser of the preview; nil until the Appearance page is
    /// first shown, and when WebView2 is not available.</summary>
    FPreviewBrowser: TWebBrowser;
    FPreviewTried: Boolean;
    /// <summary>The executable of the project: its folder is where the
    /// WebView2 loader is looked for first.</summary>
    FExeFile: string;
    /// <summary>The component being edited, for the icon; not owned, may
    /// be nil.</summary>
    FChat: TFmxHelpChatAI;
    /// <summary>The prompt shown, with LF line breaks.</summary>
    FPromptText: string;
    FController: THelpChatConfigController;
    FEntries: TArray<THelpChatConfigEntry>;
    FModels: TArray<THelpChatConfigModel>;
    FOnProfileChanged: TProc<string>;
    FOnComponentChanged: TProc<string>;
    FOnTest: TProc;
    FRefreshing: Boolean;
    /// <summary>The hint of the setting the ticks of <c>ValueChecks</c>
    /// belong to, which the hint of the selected item follows.</summary>
    FCheckEntryHint: string;
    /// <summary>True once the window is shown: the preview waits for it.</summary>
    FShown: Boolean;
    /// <summary>Shows the hint of the item selected in <c>ValueChecks</c>
    /// under the caption of the setting.</summary>
    procedure ValueChecksChange(Sender: TObject);
    /// <summary>Gives a grid its read-only columns and row selection. In
    /// code and not in the FMX file: the grid is the one control the VCL
    /// twin has no equivalent of.</summary>
    procedure AddColumns(const AGrid: TStringGrid; const ACaptions: array of string;
      const AWidths: array of Single);
    /// <summary>Fills the list of files, then everything that depends on
    /// the file being edited.</summary>
    procedure RefreshAll;
    /// <summary>Shows the file being edited again: profiles, settings and
    /// models. After a load, a save or a change of file.</summary>
    procedure RefreshFile;
    /// <summary>Fills the profile combo and the list of the Profiles page.
    /// <c>FRefreshing</c> keeps the change events of the controls from
    /// reading this as a choice of the user.</summary>
    procedure RefreshProfiles;
    /// <summary>Asks the controller for every setting again and fills the
    /// grid, keeping the selected row; then the status line (what the
    /// configuration would raise at activation, if anything) and the
    /// "modified" mark. Called after every change: provenance is the
    /// controller's to compute, not this form's to patch.</summary>
    procedure RefreshEntries;
    /// <summary>Fills the grid of the catalogue and the list of what the
    /// profile offers. A key shows as "set", never as its value.</summary>
    procedure RefreshModels;
    /// <summary>The row of the key of the provider chosen in the Models
    /// page: its caption, and whether this file has one.</summary>
    procedure RefreshProviderKey;
    /// <summary>Writes a key typed in the row of the provider's key and not
    /// confirmed with Set, and empties the box: Add, Save, closing and a
    /// change of file take it as Set does - it used to be dropped without a
    /// word. True when there was one.</summary>
    function CommitProviderKey: Boolean;
    /// <summary>The Models page, when the configuration has no model at all
    /// (<c>NeedsModel</c>): it is the first thing a new one needs.</summary>
    procedure ShowModelsWhenNone;
    /// <summary>Shows the selected setting in the edit area: the value the
    /// file has where the user would write it - the profile first, then the
    /// root - in the memo, or in the password box for a secret, and which
    /// of the buttons make sense.</summary>
    procedure ShowSelected;
    function SelectedEntry(out AEntry: THelpChatConfigEntry): Boolean;
    /// <summary>What the user set for the selected setting, as text the
    /// controller reads: from the control of its kind, trimmed; "true" or
    /// "false" for a check box, the ticked items separated by commas for a
    /// set.</summary>
    function EditedValue: string;
    function ModelFromEdits: THelpChatConfigModel;
    /// <summary>The page of the catalogue the page shown stands for; False
    /// for Models and Profiles, which list no settings.</summary>
    function ShownPage(out APage: THelpChatConfigPage): Boolean;
    /// <summary>The icons the component can show, the one in use selected.</summary>
    procedure RefreshIcons;
    /// <summary>The prompt, with the part the selected setting writes
    /// selected and scrolled into view: a FireMonkey memo has one font, so
    /// the selection - kept visible when the memo has no focus - is what
    /// the VCL twin shows in bold.</summary>
    procedure HighlightPrompt;
    /// <summary>The chat as the settings in force, the icon, the theme of the
    /// switch and the style sheet of the component would show it. Only on
    /// the Appearance page.</summary>
    procedure RefreshPreview;
    /// <summary>A question that waits for its answer. The synchronous
    /// service, because the callers decide on the answer before going
    /// on.</summary>
    function Ask(const AMessage: string; const AButtons: TMsgDlgButtons): TModalResult;
    /// <summary>With changes not saved yet, asks whether to save them. True
    /// when the caller may go on: nothing to save, saved, or the user chose
    /// to drop them; False on Cancel or when the save failed (the reason is
    /// shown). What closing, switching file and testing all ask first.</summary>
    function SaveFirst: Boolean;
  protected
    /// <summary>The first preview, once the window is on the screen: a
    /// browser created and loaded while the form is still hidden shows
    /// nothing until the next load.</summary>
    procedure DoShow; override;
  public
    /// <summary>Opens the editor on the settings of a component and returns
    /// when it is closed. AChat is the component, for the icon (nil offers
    /// none). ASettings are the component's and are not owned:
    /// only "To component" writes into them, and never a secret. AExeFile is
    /// the executable of the project being designed - never the IDE's -
    /// where the application file lives and what names the per-user folder;
    /// AConfigFileName the one of the component, which named is the only
    /// file. AAssistantName is the AssistantName of the component, a
    /// property of the component and not of its settings.
    /// AOnProfileChanged gives the component its new Profile,
    /// AOnComponentChanged receives the path of a value written into the
    /// settings and tells the designer the form file changed (for
    /// AssistantName the caller moves the name to the component), AOnTest
    /// would open a preview and is nil here. The same contract as
    /// <c>TVclHelpChatConfigEditor.Execute</c>, so that the two design
    /// packages call their editor alike.</summary>
    class procedure Execute(const AChat: TFmxHelpChatAI; const ASettings: THelpChatSettings;
      const AProfile, AAssistantName, AExeFile, AConfigFileName: string;
      const AOnProfileChanged, AOnComponentChanged: TProc<string>; const AOnTest: TProc);
  end;

implementation

{$R *.fmx}

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.ShellAPI,
  System.Win.Registry,
  {$ENDIF}
  ToolsAPI,
  FMX.DialogService.Sync,
  FMX.Text,
  FMX.ImgList,
  FMX.Dialogs,
  HelpChatAI.Assistant,
  HelpChatAI.Commands,
  FMX.HelpChatAI.DesignPreview;

var
  // Where the editor was when it was closed: the bounds of the normal
  // window, whether it was maximized, and the page. Kept here while the IDE
  // runs, and in the registry of the IDE (LoadPlacement, StorePlacement), so
  // that a restart or a package loaded again does not forget it.
  GSavedBounds: TRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);
  GSavedWindowState: TWindowState = TWindowState.wsNormal;
  GSavedTabIndex: Integer = -1;

const
  // Under the key of the Delphi that runs: each version keeps its own.
  PLACEMENT_KEY = '\HelpChatAI\ConfigEditorFmx';

var
  GPlacementLoaded: Boolean = False;

function PlacementKey: string;
var
  LServices: IOTAServices;
begin
  Result := '';
  if Supports(BorlandIDEServices, IOTAServices, LServices) then
    Result := LServices.GetBaseRegistryKey + PLACEMENT_KEY;
end;

procedure LoadPlacement;
var
  LReg: TRegistry;
  LKey: string;
begin
  // Once per IDE session, the first time the editor opens: from then on the
  // variables are what counts. Never an error: an editor that does not open
  // because of where it was last time would be worse than one that forgot.
  if GPlacementLoaded then
    Exit;
  GPlacementLoaded := True;
  LKey := PlacementKey;
  if LKey = '' then
    Exit;
  try
    LReg := TRegistry.Create(KEY_READ);
    try
      LReg.RootKey := HKEY_CURRENT_USER;
      if not LReg.OpenKeyReadOnly(LKey) then
        Exit;
      if LReg.ValueExists('Width') and LReg.ValueExists('Height') and
         LReg.ValueExists('Left') and LReg.ValueExists('Top') and
         (LReg.ReadInteger('Width') > 0) and (LReg.ReadInteger('Height') > 0) then
        GSavedBounds := TRect.Create(TPoint.Create(LReg.ReadInteger('Left'),
          LReg.ReadInteger('Top')), LReg.ReadInteger('Width'), LReg.ReadInteger('Height'));
      if LReg.ValueExists('Maximized') and LReg.ReadBool('Maximized') then
        GSavedWindowState := TWindowState.wsMaximized;
      if LReg.ValueExists('Page') then
        GSavedTabIndex := LReg.ReadInteger('Page');
    finally
      LReg.Free;
    end;
  except
    // Left as it was: the editor opens where its form file says.
  end;
end;

procedure StorePlacement;
var
  LReg: TRegistry;
  LKey: string;
begin
  LKey := PlacementKey;
  if LKey = '' then
    Exit;
  try
    LReg := TRegistry.Create(KEY_WRITE);
    try
      LReg.RootKey := HKEY_CURRENT_USER;
      if not LReg.OpenKey(LKey, True) then
        Exit;
      if GSavedBounds.Width > 0 then
      begin
        LReg.WriteInteger('Left', GSavedBounds.Left);
        LReg.WriteInteger('Top', GSavedBounds.Top);
        LReg.WriteInteger('Width', GSavedBounds.Width);
        LReg.WriteInteger('Height', GSavedBounds.Height);
      end;
      LReg.WriteBool('Maximized', GSavedWindowState = TWindowState.wsMaximized);
      LReg.WriteInteger('Page', GSavedTabIndex);
    finally
      LReg.Free;
    end;
  except
    // Remembered for this session only.
  end;
end;

procedure SaveEditorPlacement(const AEditor: TFmxHelpChatConfigEditor);
begin
  // The bounds of the normal window only, as the VCL twin does.
  if AEditor.WindowState = TWindowState.wsNormal then
    GSavedBounds := AEditor.Bounds;
  if AEditor.WindowState = TWindowState.wsMaximized then
    GSavedWindowState := TWindowState.wsMaximized
  else
    GSavedWindowState := TWindowState.wsNormal;
  GSavedTabIndex := AEditor.TabControl.TabIndex;
  StorePlacement;
end;

/// <summary>True when the middle of the title bar of a window with these
/// bounds - what it is dragged back with - is on a display that is there.</summary>
function OnADisplay(const ABounds: TRect): Boolean;
var
  LGrip: TPointF;
  I: Integer;
begin
  Result := False;
  LGrip := TPointF.Create(ABounds.Left + ABounds.Width / 2, ABounds.Top + 12);
  for I := 0 to Screen.DisplayCount - 1 do
    if Screen.Displays[I].WorkArea.Contains(LGrip) then
      Exit(True);
end;

procedure RestoreEditorPlacement(const AEditor: TFmxHelpChatConfigEditor);
begin
  LoadPlacement;
  if GSavedBounds.Width > 0 then
    if OnADisplay(GSavedBounds) then
    begin
      AEditor.Position := TFormPosition.Designed;
      AEditor.Bounds := GSavedBounds;
    end
    else
    begin
      // The monitor it was on is gone, and the registry remembers across
      // restarts: the size, in the middle of the screen as the form file says.
      AEditor.Width := GSavedBounds.Width;
      AEditor.Height := GSavedBounds.Height;
    end;
  if GSavedWindowState = TWindowState.wsMaximized then
    AEditor.WindowState := TWindowState.wsMaximized;
end;

class procedure TFmxHelpChatConfigEditor.Execute(const AChat: TFmxHelpChatAI;
  const ASettings: THelpChatSettings;
  const AProfile, AAssistantName, AExeFile, AConfigFileName: string;
  const AOnProfileChanged, AOnComponentChanged: TProc<string>; const AOnTest: TProc);
var
  LForm: TFmxHelpChatConfigEditor;
begin
  LForm := TFmxHelpChatConfigEditor.Create(nil);
  try
    // After the constructor: FormCreate has run without a controller, and
    // nothing is shown before RefreshAll below.
    LForm.FController := THelpChatConfigController.Create(ASettings, AProfile, AExeFile,
      AConfigFileName);
    LForm.FController.ComponentAssistantName := AAssistantName;
    LForm.FChat := AChat;
    LForm.FExeFile := AExeFile;
    LForm.FOnProfileChanged := AOnProfileChanged;
    LForm.FOnComponentChanged := AOnComponentChanged;
    LForm.FOnTest := AOnTest;
    LForm.TestButton.Enabled := Assigned(AOnTest);
    // The page it was left on, Appearance the first time; then the grid goes
    // where that page wants it.
    // Through the handler of a change of tab, which leaves the grid alone on
    // a tab that shows no settings (Models, Profiles): put there, it covered
    // the controls of that tab.
    LoadPlacement;
    if (GSavedTabIndex >= 0) and (GSavedTabIndex < LForm.TabControl.TabCount) then
      LForm.TabControl.TabIndex := GSavedTabIndex
    else
      LForm.TabControl.ActiveTab := LForm.AppearanceTab;
    LForm.TabControlChange(LForm.TabControl);
    RestoreEditorPlacement(LForm);
    LForm.RefreshAll;
    LForm.ShowModelsWhenNone;
    LForm.RefreshIcons;
    LForm.ShowModal;
    SaveEditorPlacement(LForm);
  finally
    LForm.Free;
  end;
end;

procedure TFmxHelpChatConfigEditor.AddColumns(const AGrid: TStringGrid;
  const ACaptions: array of string; const AWidths: array of Single);
var
  I: Integer;
  LColumn: TStringColumn;
begin
  for I := 0 to High(ACaptions) do
  begin
    LColumn := TStringColumn.Create(AGrid);
    LColumn.Header := ACaptions[I];
    LColumn.Width := AWidths[I];
    LColumn.ReadOnly := True;
    AGrid.AddObject(LColumn);
  end;
  AGrid.Options := AGrid.Options - [TGridOption.Editing] +
    [TGridOption.RowSelect, TGridOption.AlwaysShowSelection];
end;

procedure TFmxHelpChatConfigEditor.FormCreate(Sender: TObject);
var
  LProvider: string;
begin
  ValueChecks.OnChange := ValueChecksChange;
  ValueChecks.ShowHint := True;
  HintLabel.ShowHint := True;
  TabControl.ActiveTab := SettingsTab;
  GridLayout.Parent := SettingsTab;
  // A prompt is a paragraph: wrapped, not one line to scroll sideways.
  ValueMemo.TextSettings.WordWrap := True;
  AddColumns(SettingsGrid, ['Property', 'Description', 'In use', 'From', 'This file, root',
    'This file, profile'], [170, 170, 230, 210, 140, 140]);
  SettingsGrid.DefaultDrawing := False;
  SettingsGrid.OnDrawColumnCell := SettingsGridDrawColumnCell;
  AddColumns(ModelsGrid, ['Name', 'Provider', 'Model', 'Endpoint', 'Key'],
    [140, 80, 140, 170, 40]);
  ModelProviderCombo.Items.Clear;
  for LProvider in THelpChatConfigController.ModelProviders do
    ModelProviderCombo.Items.Add(LProvider);
end;

procedure TFmxHelpChatConfigEditor.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FController);
end;

function TFmxHelpChatConfigEditor.Ask(const AMessage: string;
  const AButtons: TMsgDlgButtons): TModalResult;
begin
  Result := TDialogServiceSync.MessageDialog(AMessage, TMsgDlgType.mtConfirmation, AButtons,
    TMsgDlgBtn.mbYes, 0);
end;

function TFmxHelpChatConfigEditor.SaveFirst: Boolean;
begin
  Result := True;
  CommitProviderKey;
  if not FController.Modified then
    Exit;
  case Ask('Save the changes to ' + FController.Files[FController.TargetIndex].FileName + '?',
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel]) of
    mrYes:
      begin
        Result := FController.Save;
        if not Result then
          TDialogServiceSync.ShowMessage(FController.LastError);
      end;
    mrCancel: Result := False;
  end;
end;

procedure TFmxHelpChatConfigEditor.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(FController) then
    CanClose := SaveFirst;
end;

procedure TFmxHelpChatConfigEditor.RefreshAll;
var
  LFile: THelpChatConfigFile;
begin
  FRefreshing := True;
  try
    FileCombo.Items.Clear;
    for LFile in FController.Files do
      FileCombo.Items.Add(LFile.Caption.Split([' - '])[0]);
    FileCombo.ItemIndex := FController.TargetIndex;
  finally
    FRefreshing := False;
  end;
  RefreshFile;
end;

procedure TFmxHelpChatConfigEditor.RefreshFile;
begin
  RefreshProfiles;
  RefreshEntries;
  RefreshModels;
end;

procedure TFmxHelpChatConfigEditor.RefreshProfiles;
var
  LName: string;
begin
  FRefreshing := True;
  try
    ProfileCombo.Items.Clear;
    ProfilesList.Items.Clear;
    for LName in FController.Profiles do
    begin
      ProfileCombo.Items.Add(LName);
      ProfilesList.Items.Add(LName);
    end;
    ProfileCombo.Text := FController.Profile;
  finally
    FRefreshing := False;
  end;
end;

function TFmxHelpChatConfigEditor.ShownPage(out APage: THelpChatConfigPage): Boolean;
begin
  Result := True;
  if TabControl.ActiveTab = AppearanceTab then
    APage := ccpAppearance
  else if TabControl.ActiveTab = PromptTab then
    APage := ccpPrompt
  else if TabControl.ActiveTab = DocumentsTab then
    APage := ccpDocuments
  else if TabControl.ActiveTab = SettingsTab then
    APage := ccpSettings
  else
    Result := False;
end;

procedure TFmxHelpChatConfigEditor.TabControlChange(Sender: TObject);
var
  LPage: THelpChatConfigPage;
begin
  // One grid for the four pages of settings: it goes where it is needed,
  // and lists the settings of that page. Not before the controller exists:
  // the form file selects a tab while it loads.
  if not Assigned(FController) or not ShownPage(LPage) then
    Exit;
  // On Appearance the grid goes under the icon, left of the preview.
  if LPage = ccpAppearance then
    GridLayout.Parent := AppearanceLeftLayout
  else
    GridLayout.Parent := TabControl.ActiveTab;
  RefreshEntries;
end;

procedure TFmxHelpChatConfigEditor.RefreshEntries;
var
  I: Integer;
  LError, LSelectedPath: string;
  LPage: THelpChatConfigPage;
begin
  LSelectedPath := '';
  if (SettingsGrid.Selected >= 0) and (SettingsGrid.Selected <= High(FEntries)) then
    LSelectedPath := FEntries[SettingsGrid.Selected].Path;
  if not ShownPage(LPage) then
    LPage := ccpSettings;
  FEntries := THelpChatConfigController.EntriesOfPage(FController.Entries, LPage);
  SettingsGrid.BeginUpdate;
  try
    SettingsGrid.RowCount := Length(FEntries);
    for I := 0 to High(FEntries) do
    begin
      // The name of the property first, as the Object Inspector lists it.
      SettingsGrid.Cells[0, I] := FEntries[I].Path;
      SettingsGrid.Cells[1, I] := FEntries[I].Caption;
      SettingsGrid.Cells[2, I] := FEntries[I].InUse;
      SettingsGrid.Cells[3, I] := FEntries[I].Origin;
      SettingsGrid.Cells[4, I] := FEntries[I].RootValue;
      SettingsGrid.Cells[5, I] := FEntries[I].ProfileValue;
    end;
  finally
    SettingsGrid.EndUpdate;
  end;
  if LPage = ccpPrompt then
  begin
    FPromptText := FController.PromptPreview.Replace(#13#10, #10);
    PromptMemo.Text := FPromptText.Replace(#10, sLineBreak);
  end;
  SettingsGrid.Selected := -1;
  for I := 0 to High(FEntries) do
    if SameText(FEntries[I].Path, LSelectedPath) then
    begin
      SettingsGrid.Selected := I;
      Break;
    end;
  ShowSelected;
  if LPage = ccpAppearance then
    RefreshPreview;
  LError := FController.Validate;
  if LError = '' then
    LError := FController.LastError;
  if LError = '' then
    StatusLabel.Text := 'The configuration loads.'
  else
    StatusLabel.Text := LError;
  FileNameLabel.Text := FController.Files[FController.TargetIndex].FileName;
  if FController.Modified then
    FileNameLabel.Text := FileNameLabel.Text + '   (modified)';
end;

function TFmxHelpChatConfigEditor.SelectedEntry(out AEntry: THelpChatConfigEntry): Boolean;
begin
  Result := (SettingsGrid.Selected >= 0) and (SettingsGrid.Selected <= High(FEntries));
  if Result then
    AEntry := FEntries[SettingsGrid.Selected];
end;

procedure TFmxHelpChatConfigEditor.ShowSelected;
var
  LEntry: THelpChatConfigEntry;
  LSecret, LHasProfile: Boolean;
  LText, LChoice, LTick: string;
  LTicked: TArray<string>;
  LItem: TListBoxItem;
  I: Integer;
begin
  LHasProfile := FController.Profile <> '';
  // One control per kind: all hidden first, the one of the setting shown.
  ValueMemo.Visible := False;
  ValueEdit.Visible := False;
  SecretEdit.Visible := False;
  ShowSecretCheck.Visible := False;
  ValueCheck.Visible := False;
  NumberSpin.Visible := False;
  ValueCombo.Visible := False;
  ChoiceCombo.Visible := False;
  ValueChecks.Visible := False;
  if not SelectedEntry(LEntry) then
  begin
    SettingLabel.Text := 'Select a setting';
    HintLabel.Text := '';
    EditLayout.Enabled := False;
    if TabControl.ActiveTab = PromptTab then
      HighlightPrompt;
    Exit;
  end;
  EditLayout.Enabled := True;
  SettingLabel.Text := LEntry.Caption + '  (' + LEntry.Path + ')';
  HintLabel.Text := LEntry.Hint;
  LSecret := LEntry.Kind = cvkSecret;
  // What the file says where the user would write it, the profile first;
  // when it says nothing, the value in use - the one of the component or of
  // another file. A key only from the file being edited, in clear and never
  // the mask of the grid, so what is written back is always a real value.
  if not (LHasProfile and FController.GetValue(LEntry.Path, ccsProfile, LText)) then
    if not FController.GetValue(LEntry.Path, ccsRoot, LText) then
      LText := LEntry.Value;
  case LEntry.Kind of
    cvkMemo:
      begin
        ValueMemo.Text := LText;
        ValueMemo.Visible := True;
      end;
    cvkSecret:
      begin
        SecretEdit.Text := LText;
        ShowSecretCheck.IsChecked := False;
        SecretEdit.Password := True;
        SecretEdit.Visible := True;
        ShowSecretCheck.Visible := True;
      end;
    cvkBoolean:
      begin
        ValueCheck.IsChecked := SameText(LText, 'true') or (LText = '1');
        ValueCheck.Visible := True;
      end;
    cvkNumber:
      begin
        NumberSpin.Value := StrToIntDef(LText, 0);
        NumberSpin.Visible := True;
      end;
    cvkLanguage:
      begin
        ValueCombo.Items.Clear;
        for LChoice in LEntry.Choices do
          ValueCombo.Items.Add(LChoice);
        ValueCombo.ItemIndex := ValueCombo.Items.IndexOf(LText);
        ValueCombo.Visible := True;
      end;
    cvkChoice:
      begin
        // A provider or a model the list does not know (registered by the
        // application, named by a file read later) is typed.
        ChoiceCombo.Items.Clear;
        for LChoice in LEntry.Choices do
          ChoiceCombo.Items.Add(LChoice);
        ChoiceCombo.Text := LText;
        ChoiceCombo.Visible := True;
      end;
    cvkLanguages, cvkSet:
      begin
        // The item carries its choice in TagString: a set shows a caption of
        // its own for each (a skill and its actions), and its hint when it is
        // selected.
        LTicked := LText.Split([',', ';']);
        FCheckEntryHint := LEntry.Hint;
        ValueChecks.Clear;
        for I := 0 to High(LEntry.Choices) do
        begin
          LChoice := LEntry.Choices[I];
          LItem := TListBoxItem.Create(ValueChecks);
          LItem.TagString := LChoice;
          if I < Length(LEntry.ChoiceCaptions) then
            LItem.Text := LEntry.ChoiceCaptions[I]
          else
            LItem.Text := LChoice;
          if I < Length(LEntry.ChoiceHints) then
            LItem.Hint := LEntry.ChoiceHints[I];
          for LTick in LTicked do
            if SameText(Trim(LTick), LChoice) then
              LItem.IsChecked := True;
          ValueChecks.AddObject(LItem);
        end;
        // A caption with the actions does not fit the narrow list of the
        // form file: as wide as the room left of the buttons.
        ValueChecks.Width := ToProfileButton.Position.X - 2 * ValueChecks.Position.X;
        ValueChecks.Visible := True;
      end;
  else
    // Text and the free lists (areas, actions): one line.
    ValueEdit.Text := LText;
    ValueEdit.Visible := True;
  end;
  ToProfileButton.Enabled := LHasProfile;
  RemoveProfileButton.Enabled := LHasProfile and LEntry.InProfile;
  if TabControl.ActiveTab = PromptTab then
    HighlightPrompt;
  RemoveRootButton.Enabled := LEntry.InRoot;
  // A key belongs to a file, never to the form file.
  ToComponentButton.Enabled := not LSecret;
  RemoveComponentButton.Enabled := LEntry.InComponent and not LSecret;
end;

procedure TFmxHelpChatConfigEditor.ValueChecksChange(Sender: TObject);
var
  LItem: TListBoxItem;
begin
  LItem := ValueChecks.Selected;
  if Assigned(LItem) and (LItem.Hint <> '') then
    HintLabel.Text := LItem.TagString + ': ' + LItem.Hint
  else
    HintLabel.Text := FCheckEntryHint;
  HintLabel.Hint := HintLabel.Text;
end;

function TFmxHelpChatConfigEditor.EditedValue: string;
var
  LEntry: THelpChatConfigEntry;
  I: Integer;
begin
  Result := '';
  if not SelectedEntry(LEntry) then
    Exit;
  case LEntry.Kind of
    cvkMemo: Result := Trim(ValueMemo.Text);
    cvkSecret: Result := Trim(SecretEdit.Text);
    cvkBoolean: Result := LowerCase(BoolToStr(ValueCheck.IsChecked, True));
    cvkNumber: Result := IntToStr(Round(NumberSpin.Value));
    cvkLanguage:
      if ValueCombo.ItemIndex >= 0 then
        Result := ValueCombo.Items[ValueCombo.ItemIndex];
    cvkChoice: Result := Trim(ChoiceCombo.Text);
    cvkLanguages, cvkSet:
      // The choice, not the caption shown for it.
      for I := 0 to ValueChecks.Count - 1 do
        if ValueChecks.ListItems[I].IsChecked then
        begin
          if Result <> '' then
            Result := Result + ', ';
          Result := Result + ValueChecks.ListItems[I].TagString;
        end;
  else
    Result := Trim(ValueEdit.Text);
  end;
end;

procedure TFmxHelpChatConfigEditor.FileComboChange(Sender: TObject);
begin
  if FRefreshing or (FileCombo.ItemIndex = FController.TargetIndex) then
    Exit;
  if not SaveFirst then
  begin
    // Cancel, or a save that failed: the combo goes back to the file that
    // is still being edited, without this handler taking it for a choice.
    FRefreshing := True;
    try
      FileCombo.ItemIndex := FController.TargetIndex;
    finally
      FRefreshing := False;
    end;
    Exit;
  end;
  // Setting the target reloads: changes the user chose not to save are gone.
  FController.TargetIndex := FileCombo.ItemIndex;
  RefreshFile;
  ShowModelsWhenNone;
end;

procedure TFmxHelpChatConfigEditor.ReloadButtonClick(Sender: TObject);
begin
  // Reload drops what was not saved, a key typed and not set included.
  ProviderKeyEdit.Text := '';
  FController.Reload;
  RefreshFile;
end;

procedure TFmxHelpChatConfigEditor.SaveButtonClick(Sender: TObject);
begin
  CommitProviderKey;
  if FController.Save then
    RefreshFile
  else
    TDialogServiceSync.ShowMessage(FController.LastError);
end;

procedure TFmxHelpChatConfigEditor.ProfileComboChange(Sender: TObject);
begin
  if FRefreshing then
    Exit;
  FController.Profile := Trim(ProfileCombo.Text);
  if Assigned(FOnProfileChanged) then
    FOnProfileChanged(FController.Profile);
  RefreshEntries;
  RefreshModels;
end;

procedure TFmxHelpChatConfigEditor.SettingsGridDrawColumnCell(Sender: TObject;
  const Canvas: TCanvas; const Column: TColumn; const Bounds: TRectF; const Row: Integer;
  const Value: TValue; const State: TGridDrawStates);
var
  LRect: TRectF;
begin
  if (Column.Index <> 2) or (Row > High(FEntries)) then
  begin
    Column.DefaultDrawCell(Canvas, Bounds, Row, Value, State);
    Exit;
  end;
  Canvas.Font.Family := SettingsGrid.TextSettings.Font.Family;
  Canvas.Font.Size := SettingsGrid.TextSettings.Font.Size;
  Canvas.Font.Style := [];
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := TAlphaColors.Black;
  case FEntries[Row].Source of
    csrFile:
      Canvas.Font.Style := [TFontStyle.fsBold];
    csrComponent:
      begin
        Canvas.Font.Style := [TFontStyle.fsBold];
        Canvas.Fill.Color := TAlphaColors.Blue;
      end;
  end;
  LRect := Bounds;
  LRect.Left := LRect.Left + 2;
  Canvas.FillText(LRect, Value.AsString, False, 1, [], TTextAlign.Leading, TTextAlign.Center);
end;

procedure TFmxHelpChatConfigEditor.SettingsGridSelChanged(Sender: TObject);
begin
  ShowSelected;
end;

procedure TFmxHelpChatConfigEditor.ShowSecretCheckChange(Sender: TObject);
begin
  SecretEdit.Password := not ShowSecretCheck.IsChecked;
end;

procedure TFmxHelpChatConfigEditor.ToProfileButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) then
  begin
    FController.SetValue(LEntry.Path, ccsProfile, EditedValue);
    RefreshEntries;
  end;
end;

procedure TFmxHelpChatConfigEditor.ToRootButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) then
  begin
    FController.SetValue(LEntry.Path, ccsRoot, EditedValue);
    RefreshEntries;
  end;
end;

procedure TFmxHelpChatConfigEditor.ToComponentButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if not SelectedEntry(LEntry) then
    Exit;
  FController.SetComponentValue(LEntry.Path, EditedValue);
  if Assigned(FOnComponentChanged) then
    FOnComponentChanged(LEntry.Path);
  RefreshEntries;
end;

procedure TFmxHelpChatConfigEditor.RemoveProfileButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) then
  begin
    FController.RemoveValue(LEntry.Path, ccsProfile);
    RefreshEntries;
  end;
end;

procedure TFmxHelpChatConfigEditor.RemoveRootButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) then
  begin
    FController.RemoveValue(LEntry.Path, ccsRoot);
    RefreshEntries;
  end;
end;

procedure TFmxHelpChatConfigEditor.RemoveComponentButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if not SelectedEntry(LEntry) then
    Exit;
  // The library's value back into the settings of the component, now, like
  // "Write to the component": the form file stops storing it.
  FController.ResetComponentValue(LEntry.Path);
  if Assigned(FOnComponentChanged) then
    FOnComponentChanged(LEntry.Path);
  RefreshEntries;
end;

procedure TFmxHelpChatConfigEditor.RefreshModels;
var
  I: Integer;
  LOffered: TArray<string>;
  LName, LChoice: string;
  LItem: TListBoxItem;
begin
  FModels := FController.Models;
  ModelsGrid.BeginUpdate;
  try
    ModelsGrid.RowCount := Length(FModels);
    for I := 0 to High(FModels) do
    begin
      ModelsGrid.Cells[0, I] := FModels[I].Name;
      ModelsGrid.Cells[1, I] := FModels[I].Provider;
      ModelsGrid.Cells[2, I] := FModels[I].Model;
      ModelsGrid.Cells[3, I] := FModels[I].BaseUrl;
      if FModels[I].ApiKey <> '' then
        ModelsGrid.Cells[4, I] := 'set'
      else
        ModelsGrid.Cells[4, I] := '';
    end;
  finally
    ModelsGrid.EndUpdate;
  end;
  // The catalogue of this file, then what the profile offers from
  // elsewhere: see ProfileModelChoices.
  LOffered := FController.ProfileModelNames;
  ProfileModelsList.Clear;
  for LChoice in FController.ProfileModelChoices do
  begin
    LItem := TListBoxItem.Create(ProfileModelsList);
    LItem.Text := LChoice;
    for LName in LOffered do
      if SameText(LName, LChoice) then
        LItem.IsChecked := True;
    ProfileModelsList.AddObject(LItem);
  end;
  ProfileModelsLayout.Enabled := FController.Profile <> '';
  if FController.Profile <> '' then
    ProfileModelsLabel.Text := 'Offered by the profile ' + FController.Profile +
      ' (none checked = all)'
  else
    ProfileModelsLabel.Text := 'Choose a profile to say which models it offers';
  RefreshProviderKey;
end;

procedure TFmxHelpChatConfigEditor.ShowModelsWhenNone;
begin
  if FController.NeedsModel then
    TabControl.ActiveTab := ModelsTab;
end;

function TFmxHelpChatConfigEditor.CommitProviderKey: Boolean;
var
  LPath: string;
begin
  // For the provider the boxes show now: a key pasted before the right
  // provider was picked goes where the user ended up, not where it started.
  LPath := THelpChatConfigController.ProviderKeyPath(Trim(ModelProviderCombo.Text));
  Result := (LPath <> '') and (Trim(ProviderKeyEdit.Text) <> '');
  if not Result then
    Exit;
  // At the root, where the Settings page writes it: taking it away is
  // done there.
  FController.SetValue(LPath, ccsRoot, Trim(ProviderKeyEdit.Text));
  ProviderKeyEdit.Text := '';
end;

procedure TFmxHelpChatConfigEditor.RefreshProviderKey;
var
  LProvider, LPath, LText: string;
begin
  LProvider := Trim(ModelProviderCombo.Text);
  LPath := THelpChatConfigController.ProviderKeyPath(LProvider);
  // What is being typed stays, and follows the provider: every refresh of
  // the page used to empty the box, so Add lost the key typed before it.
  ProviderKeyEdit.Enabled := LPath <> '';
  ProviderKeySetButton.Enabled := LPath <> '';
  if LPath = '' then
  begin
    ProviderKeyEdit.Text := '';
    ProviderKeyLabel.Text := 'Provider key';
    if LProvider = '' then
      ProviderKeyEdit.TextPrompt := 'Choose a provider'
    else
      ProviderKeyEdit.TextPrompt := 'No key for ' + LProvider;
    Exit;
  end;
  // The key of the section, as the Settings page has it: every model on
  // this provider with no key of its own uses it.
  ProviderKeyLabel.Text := LPath.Split(['.'])[0] + ' API key';
  if FController.GetValue(LPath, ccsRoot, LText) and (LText <> '') then
    // Short enough to be read whole in the box: the last four characters
    // only, never the length (MaskSecret is for the list).
    ProviderKeyEdit.TextPrompt := 'Set in this file (' +
      THelpChatConfigController.MaskSecretShort(LText) + '): type a new one to replace it'
  else
    ProviderKeyEdit.TextPrompt := 'Not in this file: type it, then Set';
end;

procedure TFmxHelpChatConfigEditor.ModelProviderComboChange(Sender: TObject);
begin
  RefreshProviderKey;
end;

procedure TFmxHelpChatConfigEditor.ProviderKeySetButtonClick(Sender: TObject);
begin
  if CommitProviderKey then
  begin
    RefreshEntries;
    RefreshProviderKey;
  end;
end;

procedure TFmxHelpChatConfigEditor.ModelsGridSelChanged(Sender: TObject);
var
  LModel: THelpChatConfigModel;
begin
  if (ModelsGrid.Selected < 0) or (ModelsGrid.Selected > High(FModels)) then
    Exit;
  LModel := FModels[ModelsGrid.Selected];
  ModelNameEdit.Text := LModel.Name;
  ModelProviderCombo.Text := LModel.Provider;
  ModelModelEdit.Text := LModel.Model;
  ModelUrlEdit.Text := LModel.BaseUrl;
  ModelKeyEdit.Text := LModel.ApiKey;
  RefreshProviderKey;
end;

function TFmxHelpChatConfigEditor.ModelFromEdits: THelpChatConfigModel;
begin
  Result := Default(THelpChatConfigModel);
  Result.Name := Trim(ModelNameEdit.Text);
  Result.Provider := Trim(ModelProviderCombo.Text);
  Result.Model := Trim(ModelModelEdit.Text);
  Result.BaseUrl := Trim(ModelUrlEdit.Text);
  Result.ApiKey := Trim(ModelKeyEdit.Text);
end;

procedure TFmxHelpChatConfigEditor.ModelAddButtonClick(Sender: TObject);
begin
  if Trim(ModelNameEdit.Text) = '' then
    Exit;
  CommitProviderKey;
  FController.SetModels(FModels + [ModelFromEdits]);
  RefreshModels;
  RefreshEntries;
end;

procedure TFmxHelpChatConfigEditor.ModelUpdateButtonClick(Sender: TObject);
var
  LModels: TArray<THelpChatConfigModel>;
begin
  if (ModelsGrid.Selected < 0) or (ModelsGrid.Selected > High(FModels)) then
    Exit;
  LModels := Copy(FModels);
  LModels[ModelsGrid.Selected] := ModelFromEdits;
  // Found again by the name it was read with: a rename keeps the encrypted key.
  LModels[ModelsGrid.Selected].Original := FModels[ModelsGrid.Selected].Original;
  CommitProviderKey;
  FController.SetModels(LModels);
  RefreshModels;
  RefreshEntries;
end;

procedure TFmxHelpChatConfigEditor.ModelDeleteButtonClick(Sender: TObject);
var
  LModels: TArray<THelpChatConfigModel>;
begin
  if (ModelsGrid.Selected < 0) or (ModelsGrid.Selected > High(FModels)) then
    Exit;
  LModels := Copy(FModels);
  Delete(LModels, ModelsGrid.Selected, 1);
  FController.SetModels(LModels);
  RefreshModels;
  RefreshEntries;
end;

procedure TFmxHelpChatConfigEditor.ProfileModelsButtonClick(Sender: TObject);
var
  LNames: TArray<string>;
  I: Integer;
begin
  LNames := nil;
  for I := 0 to ProfileModelsList.Count - 1 do
    if ProfileModelsList.ListItems[I].IsChecked then
      LNames := LNames + [ProfileModelsList.ListItems[I].Text];
  FController.SetProfileModelNames(LNames);
  RefreshEntries;
end;

procedure TFmxHelpChatConfigEditor.ProfileAddButtonClick(Sender: TObject);
var
  LValues: array of string;
begin
  SetLength(LValues, 1);
  if TDialogServiceSync.InputQuery('New profile', ['Name of the profile (never shown to the user):'],
    LValues) and (Trim(LValues[0]) <> '') then
  begin
    FController.AddProfile(LValues[0]);
    RefreshProfiles;
    RefreshEntries;
  end;
end;

procedure TFmxHelpChatConfigEditor.ProfileRenameButtonClick(Sender: TObject);
var
  LOld: string;
  LValues: array of string;
begin
  if ProfilesList.ItemIndex < 0 then
    Exit;
  LOld := ProfilesList.Items[ProfilesList.ItemIndex];
  SetLength(LValues, 1);
  LValues[0] := LOld;
  if TDialogServiceSync.InputQuery('Rename profile', ['New name of the profile:'], LValues) and
     (Trim(LValues[0]) <> '') and (LValues[0] <> LOld) then
  begin
    FController.RenameProfile(LOld, LValues[0]);
    // The assistant whose profile was renamed follows it.
    if SameText(FController.Profile, Trim(LValues[0])) and Assigned(FOnProfileChanged) then
      FOnProfileChanged(FController.Profile);
    RefreshProfiles;
    RefreshEntries;
  end;
end;

procedure TFmxHelpChatConfigEditor.ProfileDeleteButtonClick(Sender: TObject);
var
  LName: string;
begin
  if ProfilesList.ItemIndex < 0 then
    Exit;
  LName := ProfilesList.Items[ProfilesList.ItemIndex];
  if Ask(Format('Delete the profile %s and everything it says?', [LName]),
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo]) <> mrYes then
    Exit;
  FController.DeleteProfile(LName);
  RefreshProfiles;
  RefreshEntries;
end;

procedure TFmxHelpChatConfigEditor.TestButtonClick(Sender: TObject);
begin
  if not SaveFirst then
    Exit;
  RefreshFile;
  if Assigned(FOnTest) then
    FOnTest();
end;

procedure TFmxHelpChatConfigEditor.HighlightPrompt;
var
  LEntry: THelpChatConfigEntry;
  LFragment: string;
  LStart, LLine, LCol, LLength: Integer;
  LFrom, LTo: TCaretPosition;

  procedure LineCol(const AIndex: Integer; out ALine, ACol: Integer);
  var
    LText: string;
  begin
    LText := FPromptText.Substring(0, AIndex);
    ALine := LText.CountChar(#10);
    ACol := LText.Length - (LText.LastIndexOf(#10) + 1);
  end;

begin
  PromptMemo.HideSelectionOnExit := False;
  LFragment := '';
  if SelectedEntry(LEntry) then
    LFragment := FController.PromptFragment(LEntry.Path).Replace(#13#10, #10);
  LStart := -1;
  if LFragment <> '' then
    LStart := FPromptText.IndexOf(LFragment);
  if LStart < 0 then
  begin
    PromptMemo.SelLength := 0;
    Exit;
  end;
  // Lines and columns of the LF text, turned into the positions of the
  // memo, whose own counting of a line break is its business.
  LineCol(LStart, LLine, LCol);
  LFrom := TCaretPosition.Create(LLine, LCol);
  LineCol(LStart + LFragment.Length, LLine, LCol);
  LTo := TCaretPosition.Create(LLine, LCol);
  LLength := PromptMemo.PosToTextPos(LTo) - PromptMemo.PosToTextPos(LFrom);
  // The caret first, which scrolls the part into view, then the selection.
  PromptMemo.CaretPosition := LFrom;
  PromptMemo.SelStart := PromptMemo.PosToTextPos(LFrom);
  PromptMemo.SelLength := LLength;
end;

procedure TFmxHelpChatConfigEditor.RefreshIcons;
var
  LItem: TListBoxItem;
  LName: string;
  LBytes: TBytes;
  LStream: TBytesStream;
  LSelected, I: Integer;
  LImage: TImage;
  LGlyph: TGlyph;

  // An item of its own making: the picture over its name. The bitmap of the
  // item would be drawn by the style of the list, at the size of a row.
  function NewItem(const ACaption: string): TListBoxItem;
  var
    LLabel: TLabel;
  begin
    Result := TListBoxItem.Create(IconList);
    Result.Parent := IconList;
    Result.TagString := ACaption;
    LLabel := TLabel.Create(Result);
    LLabel.Parent := Result;
    LLabel.Align := TAlignLayout.Bottom;
    LLabel.Height := 18;
    LLabel.TextSettings.HorzAlign := TTextAlign.Center;
    LLabel.Text := ACaption;
    LLabel.HitTest := False;
  end;

  procedure AddPicture(const AItem: TListBoxItem; const AControl: TControl);
  begin
    AControl.Parent := AItem;
    AControl.Align := TAlignLayout.Client;
    AControl.Margins.Rect := TRectF.Create(4, 4, 4, 0);
    AControl.HitTest := False;
  end;

begin
  FRefreshing := True;
  IconList.BeginUpdate;
  try
    IconList.Clear;
    IconLayout.Enabled := Assigned(FChat);
    StyleSheetEdit.Enabled := Assigned(FChat);
    StyleSheetBrowseButton.Enabled := Assigned(FChat);
    StyleSheetApplyButton.Enabled := Assigned(FChat);
    if not Assigned(FChat) then
      Exit;
    StyleSheetEdit.Text := FChat.PanelStyleSheet;
    LSelected := -1;
    if Assigned(FChat.Images) then
    begin
      // The application's image list wins, as at run time.
      IconList.Images := FChat.Images;
      IconHintLabel.Text := Format('From the Images of the component (%s): a click sets ' +
        'ImageIndex.', [FChat.Images.Name]);
      for I := 0 to FChat.Images.Count - 1 do
      begin
        LItem := NewItem(IntToStr(I));
        LGlyph := TGlyph.Create(LItem);
        LGlyph.Images := FChat.Images;
        LGlyph.ImageIndex := I;
        AddPicture(LItem, LGlyph);
        if I = FChat.ImageIndex then
          LSelected := I;
      end;
    end
    else
    begin
      IconList.Images := nil;
      IconHintLabel.Text := 'The built-in icons (the component has no Images): a click sets ' +
        'ImageName.';
      for LName in HelpChatAssistantIconNames do
      begin
        LItem := NewItem(LName);
        LImage := TImage.Create(LItem);
        LImage.WrapMode := TImageWrapMode.Fit;
        AddPicture(LItem, LImage);
        LBytes := HelpChatAssistantIconPng(LName, 128);
        if Length(LBytes) > 0 then
        begin
          LStream := TBytesStream.Create(LBytes);
          try
            LImage.Bitmap.LoadFromStream(LStream);
          finally
            LStream.Free;
          end;
        end;
        if SameText(LName, FChat.ImageName) or ((FChat.ImageName = '') and
           (LItem.Index = FChat.ImageIndex)) then
          LSelected := LItem.Index;
      end;
      if (LSelected < 0) and (FChat.ImageName = '') then
        for I := 0 to IconList.Count - 1 do
          if SameText(IconList.ListItems[I].TagString, HELPCHAT_ICON_DEFAULT) then
            LSelected := I;
    end;
    IconList.ItemIndex := LSelected;
  finally
    IconList.EndUpdate;
    FRefreshing := False;
  end;
end;

procedure TFmxHelpChatConfigEditor.IconListChange(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := IconList.ItemIndex;
  if FRefreshing or not Assigned(FChat) or (LIndex < 0) then
    Exit;
  if Assigned(FChat.Images) then
  begin
    if FChat.ImageIndex = LIndex then
      Exit;
    FChat.ImageIndex := LIndex;
    if Assigned(FOnComponentChanged) then
      FOnComponentChanged('ImageIndex');
  end
  else
  begin
    if SameText(FChat.ImageName, IconList.ListItems[LIndex].TagString) then
      Exit;
    FChat.ImageName := IconList.ListItems[LIndex].TagString;
    if Assigned(FOnComponentChanged) then
      FOnComponentChanged('ImageName');
  end;
  RefreshPreview;
end;

procedure TFmxHelpChatConfigEditor.DoShow;
begin
  inherited;
  if FShown then
    Exit;
  FShown := True;
  // Queued: the native browser needs a window that is already visible.
  TThread.ForceQueue(nil,
    procedure
    begin
      RefreshPreview;
    end);
end;

procedure TFmxHelpChatConfigEditor.RefreshPreview;
var
  LFrom, LError, LIcon, LStyleSheet, LHtml: string;
  LCommands: THelpChatCommands;
begin
  if not FShown or (TabControl.ActiveTab <> AppearanceTab) then
    Exit;
  if not FPreviewTried then
  begin
    // Once: the loader by full path, then a browser of our own - the panel
    // of the component lets nothing but its server navigate it.
    FPreviewTried := True;
    if FmxHelpChatEnsureWebView2Loader(ExtractFilePath(FExeFile), LFrom) then
    begin
      FPreviewBrowser := TWebBrowser.Create(Self);
      FPreviewBrowser.WindowsEngine := TWindowsEngine.EdgeOnly;
      FPreviewBrowser.Parent := PreviewHost;
      FPreviewBrowser.Align := TAlignLayout.Client;
      PreviewMessageLabel.Visible := False;
    end
    else
      PreviewMessageLabel.Text := 'The preview needs WebView2Loader.dll: put it in the ' +
        'output folder of the project, or install the library with its Redist folder.';
  end;
  if FPreviewBrowser = nil then
    Exit;
  LIcon := '';
  LStyleSheet := '';
  LCommands := HELPCHAT_DEF_COMMANDS;
  if Assigned(FChat) then
  begin
    LIcon := FChat.AssistantIconDataUri;
    LStyleSheet := FChat.PanelStyleSheet;
    LCommands := FChat.EnabledCommands;
  end;
  LHtml := FController.AppearancePreview(ThemeSwitch.IsChecked, LIcon, LStyleSheet,
    LCommands, LError);
  StyleSheetErrorLabel.Text := LError;
  FPreviewBrowser.LoadFromStrings(LHtml, '');
end;

procedure TFmxHelpChatConfigEditor.ThemeSwitchSwitch(Sender: TObject);
begin
  RefreshPreview;
end;

procedure TFmxHelpChatConfigEditor.StyleSheetBrowseButtonClick(Sender: TObject);
var
  LDialog: TOpenDialog;
begin
  LDialog := TOpenDialog.Create(Self);
  try
    LDialog.Filter := 'Style sheets (*.css)|*.css|All files (*.*)|*.*';
    LDialog.FileName := StyleSheetEdit.Text;
    if LDialog.Execute then
    begin
      StyleSheetEdit.Text := LDialog.FileName;
      StyleSheetApplyButtonClick(Sender);
    end;
  finally
    LDialog.Free;
  end;
end;

procedure TFmxHelpChatConfigEditor.StyleSheetApplyButtonClick(Sender: TObject);
begin
  if not Assigned(FChat) or (FChat.PanelStyleSheet = Trim(StyleSheetEdit.Text)) then
    Exit;
  FChat.PanelStyleSheet := Trim(StyleSheetEdit.Text);
  if Assigned(FOnComponentChanged) then
    FOnComponentChanged('PanelStyleSheet');
  RefreshPreview;
end;

procedure TFmxHelpChatConfigEditor.HelpButtonClick(Sender: TObject);
begin
  // The page of the online documentation about this editor, in the browser
  // of the system. The editor runs inside the IDE, which is Windows.
  {$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(HELPCHAT_CONFIG_EDITOR_HELP_URL), nil, nil, SW_SHOWNORMAL);
  {$ENDIF}
end;

end.
