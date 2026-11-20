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
///  The configuration editor of the VCL component (design package): a view
///  over <see cref="HelpChatAI.ConfigController" />, which holds every rule.
///  The form only shows what the controller says and forwards what the user
///  does; the FireMonkey editor is its twin, written with FireMonkey controls.
///  A DFM, like the confirmation dialog: the IDE scales a form it loads.
/// </summary>
unit Vcl.HelpChatAI.ConfigEditor;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.CheckLst,
  Vcl.Imaging.pngimage,
  Vcl.ImgList,
  Vcl.VirtualImageList,
  Vcl.WinXCtrls,
  Vcl.Edge,
  HelpChatAI.Settings,
  HelpChatAI.ConfigController,
  Vcl.HelpChatAI;

type
  /// <summary>
  ///  The form of the editor: six pages over one controller.
  ///  <list type="bullet">
  ///   <item><c>Appearance</c>, <c>Settings</c>, <c>Prompt</c> and
  ///    <c>Documents</c>: the settings of the catalogue that belong to that
  ///    page (<see cref="THelpChatConfigEntry.Pages" />), each with the value
  ///    in force and who set it, and three places to write the one selected -
  ///    the root of the file being edited, the profile of the assistant in
  ///    that file, or the component (the form file). One list and one edit
  ///    panel (<c>GridPanel</c>) serve the four pages: it moves to the page
  ///    shown. The Prompt page shows beside it the prompt those settings
  ///    build (<see cref="THelpChatConfigController.PromptPreview" />);</item>
  ///   <item><c>Models</c>: the catalogue of models at the root of the file,
  ///    and which of them the profile offers in the panel;</item>
  ///   <item><c>Profiles</c>: the sections under <c>"Profiles"</c> of the
  ///    file - add, rename, delete.</item>
  ///  </list>
  ///  Nothing is decided here. What is shown comes from
  ///  <see cref="THelpChatConfigController" /> (<c>Entries</c>, <c>Models</c>,
  ///  <c>Profiles</c>, <c>Validate</c>) and is asked again after every
  ///  change; what the user does is forwarded to it as it is. A change to a
  ///  file stays in memory until Save; a change to the component, and the
  ///  choice of the profile, are applied at once and are not undone by
  ///  closing without saving.
  ///  Use <see cref="Execute" />: the form is never created by itself, since
  ///  it has no controller until <c>Execute</c> gives it one.
  /// </summary>
  TVclHelpChatConfigEditor = class(TForm)
    TopPanel: TPanel;
    /// <summary>The male assistant, the face of the VCL component: the PNG
    /// of 512 pixels in the form file, stretched (pngimage, from vclimg).</summary>
    AssistantImage: TImage;
    FileLabel: TLabel;
    FileCombo: TComboBox;
    ReloadButton: TButton;
    SaveButton: TButton;
    FileNameLabel: TLabel;
    PageControl: TPageControl;
    AppearanceTab: TTabSheet;
    /// <summary>The right of the Appearance page: the chat as it would look,
    /// with the switch between the light and the dark theme and the style
    /// sheet of the component.</summary>
    PreviewPanel: TPanel;
    PreviewTopPanel: TPanel;
    PreviewLabel: TLabel;
    ThemeSwitch: TToggleSwitch;
    StyleSheetLabel: TLabel;
    StyleSheetEdit: TEdit;
    StyleSheetBrowseButton: TButton;
    StyleSheetApplyButton: TButton;
    StyleSheetErrorLabel: TLabel;
    /// <summary>Where the browser of the preview is created, in code: the
    /// WebView2 loader must be reachable first.</summary>
    PreviewHost: TPanel;
    PreviewMessageLabel: TLabel;
    AppearanceSplitter: TSplitter;
    /// <summary>The left of the Appearance page: the icon, then the list.</summary>
    AppearanceLeftPanel: TPanel;
    /// <summary>The icon of the assistant: the images of the component's
    /// <c>Images</c>, else the built-in ones; a click writes
    /// <c>ImageIndex</c> or <c>ImageName</c> into the component.</summary>
    IconPanel: TPanel;
    IconLabel: TLabel;
    IconList: TListView;
    IconHintLabel: TLabel;
    SettingsTab: TTabSheet;
    /// <summary>The list of the settings and the edit panel, moved to the
    /// page shown among the four that list settings.</summary>
    GridPanel: TPanel;
    PromptTab: TTabSheet;
    PromptPanel: TPanel;
    PromptLabel: TLabel;
    /// <summary>The prompt, with the part the selected setting writes in
    /// bold: a rich edit, because a memo has one font for everything.</summary>
    PromptMemo: TRichEdit;
    PromptSplitter: TSplitter;
    ModelsTab: TTabSheet;
    ProfilesTab: TTabSheet;
    DocumentsTab: TTabSheet;
    ProfilePanel: TPanel;
    ProfileLabel: TLabel;
    ProfileCombo: TComboBox;
    ProfileHintLabel: TLabel;
    SettingsList: TListView;
    EditPanel: TPanel;
    SettingLabel: TLabel;
    HintLabel: TLabel;
    ValueMemo: TMemo;
    SecretEdit: TEdit;
    ShowSecretCheck: TCheckBox;
    /// <summary>The value controls, one per kind of setting
    /// (<see cref="THelpChatConfigValueKind" />), only one visible at a time:
    /// a line for text and free lists, the memo for the prompts, the masked
    /// line for a key, a check box, a number with its arrows, a combo for a
    /// choice and a check list for a set.</summary>
    ValueEdit: TEdit;
    ValueCombo: TComboBox;
    ValueCheck: TCheckBox;
    NumberEdit: TEdit;
    NumberUpDown: TUpDown;
    ValueChecks: TCheckListBox;
    ToProfileButton: TButton;
    ToRootButton: TButton;
    ToComponentButton: TButton;
    RemoveProfileButton: TButton;
    RemoveRootButton: TButton;
    RemoveComponentButton: TButton;
    ModelsList: TListView;
    ModelPanel: TPanel;
    ModelNameLabel: TLabel;
    ModelNameEdit: TEdit;
    ModelProviderLabel: TLabel;
    ModelProviderCombo: TComboBox;
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
    ProfileModelsPanel: TPanel;
    ProfileModelsLabel: TLabel;
    ProfileModelsList: TCheckListBox;
    ProfileModelsButton: TButton;
    ProfilesList: TListBox;
    ProfileAddButton: TButton;
    ProfileRenameButton: TButton;
    ProfileDeleteButton: TButton;
    ProfilesHintLabel: TLabel;
    BottomPanel: TPanel;
    StatusLabel: TLabel;
    TestButton: TButton;
    CloseButton: TButton;
    HelpButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FileComboChange(Sender: TObject);
    procedure ReloadButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure ProfileComboChange(Sender: TObject);
    procedure SettingsListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure SettingsListCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure SettingsListCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ShowSecretCheckClick(Sender: TObject);
    procedure ToProfileButtonClick(Sender: TObject);
    procedure ToRootButtonClick(Sender: TObject);
    procedure ToComponentButtonClick(Sender: TObject);
    procedure RemoveProfileButtonClick(Sender: TObject);
    procedure RemoveRootButtonClick(Sender: TObject);
    procedure RemoveComponentButtonClick(Sender: TObject);
    procedure ModelsListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
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
    procedure PageControlChange(Sender: TObject);
    procedure IconListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ThemeSwitchClick(Sender: TObject);
    procedure StyleSheetBrowseButtonClick(Sender: TObject);
    procedure StyleSheetApplyButtonClick(Sender: TObject);
  strict private
    /// <summary>The browser of the preview; nil until the Appearance page is
    /// first shown, and when WebView2 is not available.</summary>
    FPreviewBrowser: TEdgeBrowser;
    /// <summary>The page to show once the browser is ready: it navigates
    /// only after its WebView exists.</summary>
    FPendingPreview: string;
    /// <summary>True once the browser was tried, whatever came of it.</summary>
    FPreviewTried: Boolean;
    /// <summary>The component being edited, for what is not in its settings
    /// (the icon); not owned.</summary>
    FChat: TVclHelpChatAI;
    /// <summary>The built-in icons as an image list, when the component has
    /// no <c>Images</c>; owned.</summary>
    FBuiltInImages: TVirtualImageList;
    /// <summary>The prompt shown, with LF line breaks: a rich edit counts a
    /// line break as one character, and so does this string.</summary>
    FPromptText: string;
    /// <summary>Every rule of the editor. Owned: created by
    /// <see cref="Execute" /> after the form (so <c>FormCreate</c> runs
    /// without it), freed in <c>FormDestroy</c>.</summary>
    FController: THelpChatConfigController;
    /// <summary>The settings of the component being edited; not owned, and
    /// only kept for reference: the controller is what writes into them.</summary>
    FSettings: THelpChatSettings;
    /// <summary>What <c>SettingsList</c> shows, row for row: the settings of
    /// the page shown, the index of a list item is the index here. Replaced
    /// by every <see cref="RefreshEntries" />.</summary>
    FEntries: TArray<THelpChatConfigEntry>;
    /// <summary>What <c>ModelsList</c> shows, row for row; the keys in it are
    /// the clear ones, as the file has them.</summary>
    FModels: TArray<THelpChatConfigModel>;
    /// <summary>Called with the new profile every time the profile of the
    /// editor changes (the combo, or the rename of the profile in use); nil
    /// is allowed.</summary>
    FOnProfileChanged: TProc<string>;
    /// <summary>Called with the path of a value just written into the
    /// settings of the component; nil is allowed.</summary>
    FOnComponentChanged: TProc<string>;
    /// <summary>The colour of a value the form file sets, in the "In use"
    /// column: the blue of the Object Inspector, lighter on a dark theme of
    /// the IDE, where that blue would not read.</summary>
    FComponentColor: TColor;
    /// <summary>The colour of the other values: the text of the theme.</summary>
    FTextColor: TColor;
    /// <summary>The background of the list: the window of the theme.</summary>
    FWindowColor: TColor;
    /// <summary>What the Test button runs; nil disables the button.</summary>
    FOnTest: TProc;
    /// <summary>True while the form fills its own combos: their
    /// <c>OnChange</c> must not read that as a choice of the user.</summary>
    FRefreshing: Boolean;
    /// <summary>What <c>ValueChecks</c> holds, item for item: the value each
    /// tick writes (the caption shown may say more) and its hint.</summary>
    FCheckValues: TArray<string>;
    FCheckHints: TArray<string>;
    /// <summary>The hint of the setting the ticks belong to, which the hint
    /// of the selected item follows.</summary>
    FCheckEntryHint: string;
    /// <summary>True once the window is shown: the preview waits for it.</summary>
    FShown: Boolean;
    /// <summary>Shows the hint of the item selected in <c>ValueChecks</c>
    /// under the caption of the setting.</summary>
    procedure ValueChecksClick(Sender: TObject);
    /// <summary>The page of the catalogue the page shown stands for; False
    /// for Models and Profiles, which list no settings.</summary>
    function ShownPage(out APage: THelpChatConfigPage): Boolean;
    /// <summary>The icons the component can show, the one in use selected.</summary>
    procedure RefreshIcons;
    /// <summary>The prompt in plain text, then in bold the part the selected
    /// setting writes (<see cref="THelpChatConfigController.PromptFragment" />),
    /// scrolled into view.</summary>
    procedure HighlightPrompt;
    /// <summary>The chat as the settings in force, the icon, the theme of the
    /// switch and the style sheet of the component would show it. Only on
    /// the Appearance page.</summary>
    procedure RefreshPreview;
    procedure PreviewCreated(Sender: TCustomEdgeBrowser; AResult: HResult);
    /// <summary>The colours of the theme on the canvas of a cell, the font
    /// plain: what both custom draw handlers start from.</summary>
    procedure PrepareCell(const AList: TCustomListView);
    /// <summary>The list of files, then everything that depends on the one
    /// being edited. Once, when the editor opens.</summary>
    procedure RefreshAll;
    /// <summary>Everything that depends on the file being edited: its name,
    /// its profiles, the settings, the models. After a change of file, a
    /// reload or a save.</summary>
    procedure RefreshFile;
    /// <summary>The profiles of the file, in the combo and in the list of
    /// the Profiles page. The text of the combo is the profile of the
    /// controller even when the file has no such section yet: writing a
    /// value into the profile is what creates it.</summary>
    procedure RefreshProfiles;
    /// <summary>Asks the controller for the settings again and rebuilds the
    /// list, keeping the selected row; then the status line, which is what
    /// <c>Validate</c> says - the error the component would raise when it
    /// activates - and the "(modified)" mark of the file. Also resets the
    /// edit box to what the file says, so a text typed and not applied is
    /// dropped.</summary>
    procedure RefreshEntries;
    /// <summary>The catalogue of the file and, checked, the models the
    /// profile offers. Only the catalogue of the file being edited is
    /// listed: a model another file defines cannot be ticked from here.</summary>
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
    /// <summary>Puts the selected setting in the edit panel: the memo, or
    /// the masked edit box for a secret, filled with what the file says in
    /// the profile, else at the root - the value itself and not the masked
    /// one of the list, so that what a button writes back is a key and never
    /// a row of asterisks.</summary>
    procedure ShowSelected;
    /// <summary>The entry of the selected row; False when none is.</summary>
    function SelectedEntry(out AEntry: THelpChatConfigEntry): Boolean;
    /// <summary>What the user set for the selected setting, as text the
    /// controller reads: from the control of its kind, trimmed; "true" or
    /// "false" for a check box, the ticked items separated by commas for a
    /// set.</summary>
    function EditedValue: string;
    /// <summary>The model the edit boxes of the Models page describe.</summary>
    function ModelFromEdits: THelpChatConfigModel;
    /// <summary>After any change made through the controller: the origins,
    /// the status line and the "(modified)" mark all depend on it.</summary>
    procedure Changed;
  protected
    /// <summary>The first preview, once the window is on the screen: a
    /// WebView created and navigated while the form is still hidden shows
    /// nothing until the next navigation.</summary>
    procedure DoShow; override;
  public
    /// <summary>
    ///  Opens the editor, modally, on the settings of a component, and
    ///  returns when it is closed. Main thread, inside the IDE.
    ///  <para><c>AChat</c> is the component itself, for what does not live in
    ///  its settings - the icon - and may be nil (the Appearance page then
    ///  offers no icon); <c>AOnComponentChanged</c> is called with the name of
    ///  the property written there (<c>ImageName</c>, <c>ImageIndex</c>).</para>
    ///  <para><c>ASettings</c> are the component's own (not owned): "To
    ///  component" writes into them at once. <c>AProfile</c> is its
    ///  <c>Profile</c>, empty for the default assistant, and
    ///  <c>AAssistantName</c> its <c>AssistantName</c>, which is a property of
    ///  the component and not of its settings.
    ///  <c>AExeFile</c> is the executable of the project - its folder holds
    ///  the application file, its name the per-user folder; empty (no
    ///  project open) leaves the shared file alone to edit.
    ///  <c>AConfigFileName</c> is the component's: named, it is the only
    ///  file offered.</para>
    ///  <para><c>AOnProfileChanged</c> receives the profile each time it
    ///  changes in the editor - while the user types it, too - and is where
    ///  the caller sets <c>Profile</c> on the component;
    ///  <c>AOnComponentChanged</c> receives the path of a value written into
    ///  the settings and tells the designer that the form file changed - for
    ///  <c>AssistantName</c> it is where the caller moves the name from the
    ///  settings to the property of the component; <c>AOnTest</c> opens the design-time preview, and nil
    ///  disables its button. All three run inside the modal loop of the
    ///  editor; any of them may be nil.</para>
    ///  <para>There is no result and no Cancel: the files change only on
    ///  Save (closing with unsaved changes asks), the component changes
    ///  as the user goes.</para>
    /// </summary>
    class procedure Execute(const AChat: TVclHelpChatAI; const ASettings: THelpChatSettings;
      const AProfile, AAssistantName, AExeFile, AConfigFileName: string;
      const AOnProfileChanged, AOnComponentChanged: TProc<string>; const AOnTest: TProc);
  end;

implementation

{$R *.dfm}

uses
  System.UITypes,
  System.StrUtils,
  System.Math,
  Winapi.Messages,
  Winapi.RichEdit,
  System.IOUtils,
  HelpChatAI.Commands,
  Vcl.HelpChatAI.Bubble,
  Vcl.HelpChatAI.DesignPreview,
  Vcl.Themes,
  Vcl.Dialogs,
  Winapi.Windows,
  Winapi.ShellAPI,
  System.Win.Registry,
  ToolsAPI,
  BrandingAPI,
  IDETheme.Utils;

const
  // The "key" column of the models list: that a model has a key of its own,
  // never the key.
  SCOPE_TEXT: array[Boolean] of string = ('', 'set');

var
  // Where the editor was when it was closed: the bounds of the normal
  // window, whether it was maximized, and the page. Kept here while the IDE
  // runs, and in the registry of the IDE (LoadPlacement, StorePlacement), so
  // that a restart or a package loaded again does not forget it.
  GSavedBounds: TRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);
  GSavedWindowState: TWindowState = wsNormal;
  GSavedPageIndex: Integer = -1;

const
  // Under the key of the Delphi that runs: each version keeps its own.
  PLACEMENT_KEY = '\HelpChatAI\ConfigEditorVcl';

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
        GSavedWindowState := wsMaximized;
      if LReg.ValueExists('Page') then
        GSavedPageIndex := LReg.ReadInteger('Page');
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
      LReg.WriteBool('Maximized', GSavedWindowState = wsMaximized);
      LReg.WriteInteger('Page', GSavedPageIndex);
    finally
      LReg.Free;
    end;
  except
    // Remembered for this session only.
  end;
end;

procedure SaveEditorPlacement(const AEditor: TVclHelpChatConfigEditor);
begin
  // The bounds of the normal window only: those of a maximized one, put back
  // on a normal window, give a window as big as the screen and not maximized.
  if AEditor.WindowState = wsNormal then
    GSavedBounds := AEditor.BoundsRect;
  if AEditor.WindowState = wsMaximized then
    GSavedWindowState := wsMaximized
  else
    GSavedWindowState := wsNormal;
  GSavedPageIndex := AEditor.PageControl.ActivePageIndex;
  StorePlacement;
end;

procedure RestoreEditorPlacement(const AEditor: TVclHelpChatConfigEditor);
begin
  LoadPlacement;
  if GSavedBounds.Width > 0 then
  begin
    AEditor.Position := poDesigned;
    AEditor.SetBounds(GSavedBounds.Left, GSavedBounds.Top, GSavedBounds.Width,
      GSavedBounds.Height);
    // Put back inside a monitor that is still there.
    AEditor.MakeFullyVisible(Screen.MonitorFromRect(GSavedBounds));
  end;
  // After the normal bounds, so that Restore goes back to them.
  if GSavedWindowState = wsMaximized then
    AEditor.WindowState := wsMaximized;
end;

class procedure TVclHelpChatConfigEditor.Execute(const AChat: TVclHelpChatAI;
  const ASettings: THelpChatSettings;
  const AProfile, AAssistantName, AExeFile, AConfigFileName: string;
  const AOnProfileChanged, AOnComponentChanged: TProc<string>; const AOnTest: TProc);
var
  LForm: TVclHelpChatConfigEditor;
begin
  LForm := TVclHelpChatConfigEditor.Create(nil);
  try
    // The controller comes after the form: FormCreate has run without it,
    // and FormDestroy frees it. Should its constructor raise here, the form
    // goes away with no controller, which FormCloseQuery allows for.
    LForm.FSettings := ASettings;
    LForm.FChat := AChat;
    LForm.FController := THelpChatConfigController.Create(ASettings, AProfile, AExeFile,
      AConfigFileName);
    LForm.FController.ComponentAssistantName := AAssistantName;
    LForm.FOnProfileChanged := AOnProfileChanged;
    LForm.FOnComponentChanged := AOnComponentChanged;
    LForm.FOnTest := AOnTest;
    LForm.TestButton.Enabled := Assigned(AOnTest);
    LoadPlacement;
    // The page it was left on, Appearance the first time; then the list goes
    // where that page wants it - through the handler of a change of page,
    // which leaves it alone on a page that shows no settings (Models,
    // Profiles): put there, it covered the controls of that page.
    if (GSavedPageIndex >= 0) and (GSavedPageIndex < LForm.PageControl.PageCount) then
      LForm.PageControl.ActivePageIndex := GSavedPageIndex
    else
      LForm.PageControl.ActivePage := LForm.AppearanceTab;
    LForm.PageControlChange(LForm.PageControl);
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

procedure TVclHelpChatConfigEditor.FormCreate(Sender: TObject);
var
  LStyle: TCustomStyleServices;
  LWindow: TColor;
  LProvider: string;

  procedure PaintPanel(const APanel: TPanel);
  begin
    APanel.StyleElements := APanel.StyleElements - [seClient];
    APanel.ParentBackground := False;
    APanel.Color := LStyle.GetSystemColor(clBtnFace);
  end;

begin
  ValueChecks.OnClick := ValueChecksClick;
  // The editor lives inside the IDE: it follows its light or dark theme, the
  // way the editors of SVGIconImageList do. Delphi 10.4 does not give its
  // theme font to a form of a package; from 11 on ApplyTheme does.
  {$IF CompilerVersion <= 34.0}
  if UseThemeFont then
    Font.Assign(GetThemeFont);
  {$IFEND}
  if IDEThemeAvailable then
  begin
    LStyle := ThemeProperties.StyleServices;
    StyleElements := StyleElements - [seClient];
    Color := LStyle.GetSystemColor(clWindow);
    PaintPanel(TopPanel);
    PaintPanel(BottomPanel);
    IDEThemeManager.RegisterFormClass(TVclHelpChatConfigEditor);
    ThemeProperties.ApplyTheme(Self);
  end;
  // The colours of the "In use" column, from the window the list is painted
  // on: the blue of the Object Inspector on a light one, a light blue on a
  // dark one.
  FTextColor := clWindowText;
  FWindowColor := clWindow;
  if IDEThemeAvailable then
  begin
    FTextColor := ThemeProperties.StyleServices.GetSystemColor(clWindowText);
    FWindowColor := ThemeProperties.StyleServices.GetSystemColor(clWindow);
  end;
  LWindow := ColorToRGB(FWindowColor);
  SettingsList.Font.Color := FTextColor;
  // The prompt is drawn in the colours set by hand, like the list: the
  // theme would repaint the text of a rich edit in its own.
  PromptMemo.StyleElements := [seBorder];
  PromptMemo.Color := FWindowColor;
  PromptMemo.Font.Color := FTextColor;
  if (GetRValue(LWindow) * 299 + GetGValue(LWindow) * 587 + GetBValue(LWindow) * 114) div 1000 < 128 then
    FComponentColor := RGB($6C, $B4, $FF)
  else
    FComponentColor := clBlue;
  PageControl.ActivePage := SettingsTab;
  GridPanel.Parent := SettingsTab;
  // The profile is taken when it is picked or when the box is left, not at
  // every letter typed into it (the form file says OnChange).
  ProfileCombo.OnChange := nil;
  ProfileCombo.OnSelect := ProfileComboChange;
  ProfileCombo.OnExit := ProfileComboChange;
  ModelProviderCombo.Items.Clear;
  for LProvider in THelpChatConfigController.ModelProviders do
    ModelProviderCombo.Items.Add(LProvider);
end;

procedure TVclHelpChatConfigEditor.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FController);
end;

procedure TVclHelpChatConfigEditor.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // Only the file is at stake here: what went to the component, and the
  // profile, were applied when the user chose them. No closes and drops the
  // changes of the file; a Save that fails keeps the editor open.
  if not Assigned(FController) then
    Exit;
  CommitProviderKey;
  // A profile typed and not confirmed by leaving the box.
  if not SameText(Trim(ProfileCombo.Text), FController.Profile) then
    ProfileComboChange(ProfileCombo);
  if not FController.Modified then
    Exit;
  case MessageDlg('Save the changes to ' + FController.Files[FController.TargetIndex].FileName + '?',
    mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
    mrYes:
      begin
        CanClose := FController.Save;
        // Said, not only refused: an editor that stays open without a word
        // looks like a button that does not work.
        if not CanClose then
          MessageDlg(FController.LastError, mtError, [mbOK], 0);
      end;
    mrCancel: CanClose := False;
  end;
end;

procedure TVclHelpChatConfigEditor.RefreshAll;
var
  LFile: THelpChatConfigFile;
begin
  FRefreshing := True;
  try
    FileCombo.Items.Clear;
    // The caption of a file is "what it is - where it is": the combo shows
    // the first half, the label under it the path.
    for LFile in FController.Files do
      FileCombo.Items.Add(LFile.Caption.Split([' - '])[0]);
    FileCombo.ItemIndex := FController.TargetIndex;
  finally
    FRefreshing := False;
  end;
  RefreshFile;
end;

procedure TVclHelpChatConfigEditor.RefreshFile;
begin
  FileNameLabel.Caption := FController.Files[FController.TargetIndex].FileName;
  if FController.Modified then
    FileNameLabel.Caption := FileNameLabel.Caption + '   (modified)';
  RefreshProfiles;
  RefreshEntries;
  RefreshModels;
end;

procedure TVclHelpChatConfigEditor.RefreshProfiles;
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

function TVclHelpChatConfigEditor.ShownPage(out APage: THelpChatConfigPage): Boolean;
begin
  Result := True;
  if PageControl.ActivePage = AppearanceTab then
    APage := ccpAppearance
  else if PageControl.ActivePage = PromptTab then
    APage := ccpPrompt
  else if PageControl.ActivePage = DocumentsTab then
    APage := ccpDocuments
  else if PageControl.ActivePage = SettingsTab then
    APage := ccpSettings
  else
    Result := False;
end;

procedure TVclHelpChatConfigEditor.PageControlChange(Sender: TObject);
var
  LPage: THelpChatConfigPage;
begin
  // One list for the four pages of settings: it goes where it is needed,
  // and lists the settings of that page. On Appearance it goes under the
  // icon, left of the preview.
  if not ShownPage(LPage) then
    Exit;
  if LPage = ccpAppearance then
    GridPanel.Parent := AppearanceLeftPanel
  else
    GridPanel.Parent := PageControl.ActivePage;
  RefreshEntries;
end;

procedure TVclHelpChatConfigEditor.RefreshEntries;
var
  LEntry: THelpChatConfigEntry;
  LItem: TListItem;
  LSelectedPath: string;
  LError: string;
  LPage: THelpChatConfigPage;
  I: Integer;
begin
  LSelectedPath := '';
  if Assigned(SettingsList.Selected) and (SettingsList.Selected.Index <= High(FEntries)) then
    LSelectedPath := FEntries[SettingsList.Selected.Index].Path;
  if not ShownPage(LPage) then
    LPage := ccpSettings;
  FEntries := THelpChatConfigController.EntriesOfPage(FController.Entries, LPage);
  SettingsList.Items.BeginUpdate;
  try
    SettingsList.Items.Clear;
    for LEntry in FEntries do
    begin
      LItem := SettingsList.Items.Add;
      // The name of the property first, as the Object Inspector lists it,
      // then what it is.
      LItem.Caption := LEntry.Path;
      LItem.SubItems.Add(LEntry.Caption);
      LItem.SubItems.Add(LEntry.InUse);
      LItem.SubItems.Add(LEntry.Origin);
      if LEntry.InRoot then
        LItem.SubItems.Add(LEntry.RootValue)
      else
        LItem.SubItems.Add('');
      if LEntry.InProfile then
        LItem.SubItems.Add(LEntry.ProfileValue)
      else
        LItem.SubItems.Add('');
    end;
  finally
    SettingsList.Items.EndUpdate;
  end;
  // What these settings tell the model, rebuilt with every change; the
  // selection below puts the part of the selected one in bold.
  if LPage = ccpPrompt then
    FPromptText := FController.PromptPreview.Replace(#13#10, #10);
  for I := 0 to High(FEntries) do
    if SameText(FEntries[I].Path, LSelectedPath) then
    begin
      SettingsList.Items[I].Selected := True;
      SettingsList.Items[I].MakeVisible(False);
      Break;
    end;
  ShowSelected;
  if LPage = ccpAppearance then
    RefreshPreview;
  // What the component would raise at activation with these files, else
  // what the controller met while reading them.
  LError := FController.Validate;
  if LError = '' then
    LError := FController.LastError;
  if LError = '' then
    StatusLabel.Caption := 'The configuration loads.'
  else
    StatusLabel.Caption := LError;
  FileNameLabel.Caption := FController.Files[FController.TargetIndex].FileName +
    IfThen(FController.Modified, '   (modified)', '');
end;

function TVclHelpChatConfigEditor.SelectedEntry(out AEntry: THelpChatConfigEntry): Boolean;
begin
  Result := Assigned(SettingsList.Selected) and (SettingsList.Selected.Index <= High(FEntries));
  if Result then
    AEntry := FEntries[SettingsList.Selected.Index];
end;

procedure TVclHelpChatConfigEditor.ShowSelected;
var
  LEntry: THelpChatConfigEntry;
  LSecret, LHasProfile: Boolean;
  LText, LChoice: string;
  LTicked: TArray<string>;
  I: Integer;
begin
  LHasProfile := FController.Profile <> '';
  // One control per kind: all hidden first, the one of the setting shown.
  ValueMemo.Visible := False;
  ValueEdit.Visible := False;
  SecretEdit.Visible := False;
  ShowSecretCheck.Visible := False;
  ValueCheck.Visible := False;
  NumberEdit.Visible := False;
  NumberUpDown.Visible := False;
  ValueCombo.Visible := False;
  ValueChecks.Visible := False;
  if not SelectedEntry(LEntry) then
  begin
    SettingLabel.Caption := 'Select a setting';
    HintLabel.Caption := '';
    EditPanel.Enabled := False;
    if PageControl.ActivePage = PromptTab then
      HighlightPrompt;
    Exit;
  end;
  EditPanel.Enabled := True;
  SettingLabel.Caption := LEntry.Caption + '  (' + LEntry.Path + ')';
  HintLabel.Caption := LEntry.Hint;
  LSecret := LEntry.Kind = cvkSecret;
  // What the file says where the user would write it, the profile first;
  // when it says nothing, the value in use - the one of the component or
  // of another file, so that what is shown is what runs. A key only from
  // the file being edited: copying one into another file must be typed.
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
        // The clear key of the file, hidden by the edit box and not replaced
        // by a mask: the mask of the list (asterisks and the last four
        // characters) never gets here, so it can never be saved as the key.
        SecretEdit.Text := LText;
        ShowSecretCheck.Checked := False;
        SecretEdit.PasswordChar := '*';
        SecretEdit.Visible := True;
        ShowSecretCheck.Visible := True;
      end;
    cvkBoolean:
      begin
        ValueCheck.Checked := SameText(LText, 'true') or (LText = '1');
        ValueCheck.Visible := True;
      end;
    cvkNumber:
      begin
        NumberUpDown.Position := StrToIntDef(LText, 0);
        NumberEdit.Text := IntToStr(StrToIntDef(LText, 0));
        NumberEdit.Visible := True;
        NumberUpDown.Visible := True;
      end;
    cvkLanguage, cvkChoice:
      begin
        // A language is one of the list; a provider or a model may be one
        // the list does not know (registered by the application, named by a
        // file read later), so that combo takes any text.
        if LEntry.Kind = cvkLanguage then
          ValueCombo.Style := csDropDownList
        else
          ValueCombo.Style := csDropDown;
        ValueCombo.Items.Clear;
        for LChoice in LEntry.Choices do
          ValueCombo.Items.Add(LChoice);
        ValueCombo.ItemIndex := ValueCombo.Items.IndexOf(LText);
        if (ValueCombo.ItemIndex < 0) and (LEntry.Kind = cvkChoice) then
          ValueCombo.Text := LText;
        ValueCombo.Visible := True;
      end;
    cvkLanguages, cvkSet:
      begin
        // The items are the choices; a set shows a caption of its own for
        // each (a skill and its actions) and its hint when it is selected.
        LTicked := LText.Split([',', ';']);
        FCheckValues := LEntry.Choices;
        FCheckHints := LEntry.ChoiceHints;
        FCheckEntryHint := LEntry.Hint;
        ValueChecks.Items.Clear;
        for I := 0 to High(LEntry.Choices) do
        begin
          LChoice := LEntry.Choices[I];
          if I < Length(LEntry.ChoiceCaptions) then
            ValueChecks.Items.Add(LEntry.ChoiceCaptions[I])
          else
            ValueChecks.Items.Add(LChoice);
          for LText in LTicked do
            if SameText(Trim(LText), LChoice) then
              ValueChecks.Checked[I] := True;
        end;
        // A caption with the actions does not fit the narrow list of the
        // form file: as wide as the room left of the buttons.
        ValueChecks.Width := ToProfileButton.Left - 2 * ValueChecks.Left;
        ValueChecks.Visible := True;
      end;
  else
    // Text and the free lists (areas, actions): one line.
    ValueEdit.Text := LText;
    ValueEdit.Visible := True;
  end;
  ToProfileButton.Enabled := LHasProfile;
  RemoveProfileButton.Enabled := LHasProfile and LEntry.InProfile;
  if PageControl.ActivePage = PromptTab then
    HighlightPrompt;
  RemoveRootButton.Enabled := LEntry.InRoot;
  // A key belongs to a file, never to the form file.
  ToComponentButton.Enabled := not LSecret;
  RemoveComponentButton.Enabled := LEntry.InComponent and not LSecret;
end;

procedure TVclHelpChatConfigEditor.ValueChecksClick(Sender: TObject);
var
  I: Integer;
begin
  I := ValueChecks.ItemIndex;
  if (I >= 0) and (I < Length(FCheckHints)) and (FCheckHints[I] <> '') then
    HintLabel.Caption := FCheckValues[I] + ': ' + FCheckHints[I]
  else
    HintLabel.Caption := FCheckEntryHint;
  // One line of label: the whole sentence as its tooltip too.
  HintLabel.Hint := HintLabel.Caption;
  HintLabel.ShowHint := True;
end;

function TVclHelpChatConfigEditor.EditedValue: string;
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
    cvkBoolean: Result := LowerCase(BoolToStr(ValueCheck.Checked, True));
    // As typed: the controller refuses what is not a number, an emptied
    // box included, instead of writing 0.
    cvkNumber: Result := Trim(NumberEdit.Text);
    cvkLanguage, cvkChoice: Result := Trim(ValueCombo.Text);
    cvkLanguages, cvkSet:
      // The choice, not the caption shown for it.
      for I := 0 to ValueChecks.Items.Count - 1 do
        if ValueChecks.Checked[I] and (I < Length(FCheckValues)) then
        begin
          if Result <> '' then
            Result := Result + ', ';
          Result := Result + FCheckValues[I];
        end;
  else
    Result := Trim(ValueEdit.Text);
  end;
end;

procedure TVclHelpChatConfigEditor.Changed;
begin
  RefreshEntries;
end;

procedure TVclHelpChatConfigEditor.FileComboChange(Sender: TObject);
begin
  if FRefreshing or (FileCombo.ItemIndex = FController.TargetIndex) then
    Exit;
  // Changing the file reloads the controller, which drops what was not
  // saved: ask first, and put the combo back when the user stays.
  CommitProviderKey;
  if FController.Modified then
    case MessageDlg('Save the changes to ' + FController.Files[FController.TargetIndex].FileName +
      ' first?', mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
      mrYes:
        if not FController.Save then
        begin
          MessageDlg(FController.LastError, mtError, [mbOK], 0);
          FileCombo.ItemIndex := FController.TargetIndex;
          Exit;
        end;
      mrCancel:
        begin
          FileCombo.ItemIndex := FController.TargetIndex;
          Exit;
        end;
    end;
  FController.TargetIndex := FileCombo.ItemIndex;
  RefreshFile;
  ShowModelsWhenNone;
end;

procedure TVclHelpChatConfigEditor.ReloadButtonClick(Sender: TObject);
begin
  // Reload drops what was not saved, a key typed and not set included.
  ProviderKeyEdit.Text := '';
  FController.Reload;
  RefreshFile;
end;

procedure TVclHelpChatConfigEditor.SaveButtonClick(Sender: TObject);
begin
  CommitProviderKey;
  if FController.Save then
    RefreshFile
  else
    MessageDlg(FController.LastError, mtError, [mbOK], 0);
end;

procedure TVclHelpChatConfigEditor.ProfileComboChange(Sender: TObject);
begin
  if FRefreshing or SameText(Trim(ProfileCombo.Text), FController.Profile) then
    Exit;
  // Typed or picked: a name the file does not have yet is a profile to be,
  // created by the first value written into it. The component follows at
  // once - which assistant it is belongs to the form file, not to this one.
  // Called when a name is picked and when the box is left (FormCreate moves
  // the handler off OnChange): on every keystroke the component was given
  // "O", "Or", "Ord"... as its profile, each one marking the form modified.
  FController.Profile := Trim(ProfileCombo.Text);
  if Assigned(FOnProfileChanged) then
    FOnProfileChanged(FController.Profile);
  RefreshEntries;
  RefreshModels;
end;

procedure TVclHelpChatConfigEditor.SettingsListSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected then
    ShowSelected;
end;

procedure TVclHelpChatConfigEditor.PrepareCell(const AList: TCustomListView);
begin
  // With seFont the IDE theme paints the text in the colour of its style and
  // the blue never shows; without seClient the whole list went white on a
  // dark theme. So only seFont goes - here, because the theme put it back
  // when it was taken away in FormCreate. Without it the colours of a cell
  // are the canvas's, and the VCL resets that canvas to the font and colour
  // of the control (black, white) before every cell: both are set here, the
  // background included, or a dark theme draws white cells. The column
  // headers are painted by the style hook with the Font of the control when
  // seFont is off (TStyleHook.DrawControlText): that one gets the colour of
  // the theme's text too, or the titles are black on grey.
  if seFont in AList.StyleElements then
    AList.StyleElements := AList.StyleElements - [seFont];
  if SettingsList.Font.Color <> FTextColor then
    SettingsList.Font.Color := FTextColor;
  AList.Canvas.Brush.Color := FWindowColor;
  AList.Canvas.Font.Style := [];
  AList.Canvas.Font.Color := FTextColor;
end;

procedure TVclHelpChatConfigEditor.SettingsListCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  // The first column, which is the caption of the item: the sub-item handler
  // is not asked for it.
  PrepareCell(Sender);
end;

procedure TVclHelpChatConfigEditor.SettingsListCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  // The "In use" column tells at a glance what "From" says in words, the way
  // the Object Inspector does: bold for a value of a configuration file,
  // bold and blue for one of the form file, plain for the library's.
  PrepareCell(Sender);
  if (SubItem <> 2) or (Item.Index > High(FEntries)) then
    Exit;
  case FEntries[Item.Index].Source of
    csrFile:
      Sender.Canvas.Font.Style := [fsBold];
    csrComponent:
      begin
        Sender.Canvas.Font.Style := [fsBold];
        Sender.Canvas.Font.Color := FComponentColor;
      end;
  end;
end;

procedure TVclHelpChatConfigEditor.ShowSecretCheckClick(Sender: TObject);
begin
  if ShowSecretCheck.Checked then
    SecretEdit.PasswordChar := #0
  else
    SecretEdit.PasswordChar := '*';
end;

procedure TVclHelpChatConfigEditor.ToProfileButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) then
  begin
    FController.SetValue(LEntry.Path, ccsProfile, EditedValue);
    Changed;
  end;
end;

procedure TVclHelpChatConfigEditor.ToRootButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) then
  begin
    FController.SetValue(LEntry.Path, ccsRoot, EditedValue);
    Changed;
  end;
end;

procedure TVclHelpChatConfigEditor.ToComponentButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if not SelectedEntry(LEntry) then
    Exit;
  // Into the settings of the component, now: no Save, no undo. The
  // controller refuses a secret, and raises what the settings raise for a
  // value they cannot read.
  FController.SetComponentValue(LEntry.Path, EditedValue);
  if Assigned(FOnComponentChanged) then
    FOnComponentChanged(LEntry.Path);
  Changed;
end;

procedure TVclHelpChatConfigEditor.RemoveProfileButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) then
  begin
    FController.RemoveValue(LEntry.Path, ccsProfile);
    Changed;
  end;
end;

procedure TVclHelpChatConfigEditor.RemoveRootButtonClick(Sender: TObject);
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) then
  begin
    FController.RemoveValue(LEntry.Path, ccsRoot);
    Changed;
  end;
end;

procedure TVclHelpChatConfigEditor.RemoveComponentButtonClick(Sender: TObject);
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
  Changed;
end;

procedure TVclHelpChatConfigEditor.RefreshModels;
var
  LModel: THelpChatConfigModel;
  LItem: TListItem;
  LOffered: TArray<string>;
  LName, LChoice: string;
  I: Integer;
begin
  FModels := FController.Models;
  ModelsList.Items.BeginUpdate;
  try
    ModelsList.Items.Clear;
    for LModel in FModels do
    begin
      LItem := ModelsList.Items.Add;
      LItem.Caption := LModel.Name;
      LItem.SubItems.Add(LModel.Provider);
      LItem.SubItems.Add(LModel.Model);
      LItem.SubItems.Add(LModel.BaseUrl);
      LItem.SubItems.Add(SCOPE_TEXT[LModel.ApiKey <> '']);
    end;
  finally
    ModelsList.Items.EndUpdate;
  end;
  // The models of the catalogue, ticked when the profile names them, and
  // after them what the profile offers from elsewhere (the catalogue of
  // another file, a model it defines itself). A profile that names none
  // offers them all, which is why nothing ticked and everything ticked read
  // the same in the panel.
  LOffered := FController.ProfileModelNames;
  ProfileModelsList.Items.Clear;
  for LChoice in FController.ProfileModelChoices do
  begin
    I := ProfileModelsList.Items.Add(LChoice);
    for LName in LOffered do
      if SameText(LName, LChoice) then
        ProfileModelsList.Checked[I] := True;
  end;
  ProfileModelsPanel.Enabled := FController.Profile <> '';
  if FController.Profile <> '' then
    ProfileModelsLabel.Caption := 'Offered by the profile ' + FController.Profile +
      ' (none checked = all)'
  else
    ProfileModelsLabel.Caption := 'Choose a profile to say which models it offers';
  RefreshProviderKey;
end;

procedure TVclHelpChatConfigEditor.ShowModelsWhenNone;
begin
  if FController.NeedsModel then
    PageControl.ActivePage := ModelsTab;
end;

function TVclHelpChatConfigEditor.CommitProviderKey: Boolean;
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

procedure TVclHelpChatConfigEditor.RefreshProviderKey;
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
    ProviderKeyLabel.Caption := 'Provider key';
    if LProvider = '' then
      ProviderKeyEdit.TextHint := 'Choose a provider'
    else
      ProviderKeyEdit.TextHint := 'No key for ' + LProvider;
    Exit;
  end;
  // The key of the section, as the Settings page has it: every model on
  // this provider with no key of its own uses it.
  ProviderKeyLabel.Caption := LPath.Split(['.'])[0] + ' API key';
  if FController.GetValue(LPath, ccsRoot, LText) and (LText <> '') then
    // Short enough to be read whole in the box: the last four characters
    // only, never the length (MaskSecret is for the list).
    ProviderKeyEdit.TextHint := 'Set in this file (' +
      THelpChatConfigController.MaskSecretShort(LText) + '): type a new one to replace it'
  else
    ProviderKeyEdit.TextHint := 'Not in this file: type it, then Set';
end;

procedure TVclHelpChatConfigEditor.ModelProviderComboChange(Sender: TObject);
begin
  RefreshProviderKey;
end;

procedure TVclHelpChatConfigEditor.ProviderKeySetButtonClick(Sender: TObject);
begin
  if CommitProviderKey then
    RefreshFile;
end;

procedure TVclHelpChatConfigEditor.ModelsListSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  LModel: THelpChatConfigModel;
begin
  if not Selected or (Item.Index > High(FModels)) then
    Exit;
  LModel := FModels[Item.Index];
  ModelNameEdit.Text := LModel.Name;
  ModelProviderCombo.Text := LModel.Provider;
  ModelModelEdit.Text := LModel.Model;
  ModelUrlEdit.Text := LModel.BaseUrl;
  ModelKeyEdit.Text := LModel.ApiKey;
  RefreshProviderKey;
end;

function TVclHelpChatConfigEditor.ModelFromEdits: THelpChatConfigModel;
begin
  Result := Default(THelpChatConfigModel);
  Result.Name := Trim(ModelNameEdit.Text);
  Result.Provider := Trim(ModelProviderCombo.Text);
  Result.Model := Trim(ModelModelEdit.Text);
  Result.BaseUrl := Trim(ModelUrlEdit.Text);
  Result.ApiKey := Trim(ModelKeyEdit.Text);
end;

procedure TVclHelpChatConfigEditor.ModelAddButtonClick(Sender: TObject);
begin
  if Trim(ModelNameEdit.Text) = '' then
    Exit;
  CommitProviderKey;
  FController.SetModels(FModels + [ModelFromEdits]);
  RefreshModels;
  Changed;
end;

procedure TVclHelpChatConfigEditor.ModelUpdateButtonClick(Sender: TObject);
var
  LModels: TArray<THelpChatConfigModel>;
begin
  if not Assigned(ModelsList.Selected) then
    Exit;
  // The whole catalogue goes back with one row replaced: the controller
  // finds what the file had for that model by the name it was read with,
  // so a rename keeps the encrypted key.
  LModels := Copy(FModels);
  LModels[ModelsList.Selected.Index] := ModelFromEdits;
  LModels[ModelsList.Selected.Index].Original := FModels[ModelsList.Selected.Index].Original;
  CommitProviderKey;
  FController.SetModels(LModels);
  RefreshModels;
  Changed;
end;

procedure TVclHelpChatConfigEditor.ModelDeleteButtonClick(Sender: TObject);
var
  LModels: TArray<THelpChatConfigModel>;
begin
  if not Assigned(ModelsList.Selected) then
    Exit;
  LModels := Copy(FModels);
  Delete(LModels, ModelsList.Selected.Index, 1);
  FController.SetModels(LModels);
  RefreshModels;
  Changed;
end;

procedure TVclHelpChatConfigEditor.ProfileModelsButtonClick(Sender: TObject);
var
  LNames: TArray<string>;
  I: Integer;
begin
  // The ticked names become the "Models" of the profile, as bare names;
  // none ticked removes the key, and the profile offers the whole catalogue.
  LNames := nil;
  for I := 0 to ProfileModelsList.Items.Count - 1 do
    if ProfileModelsList.Checked[I] then
      LNames := LNames + [ProfileModelsList.Items[I]];
  FController.SetProfileModelNames(LNames);
  Changed;
end;

procedure TVclHelpChatConfigEditor.ProfileAddButtonClick(Sender: TObject);
var
  LName: string;
begin
  LName := '';
  if InputQuery('New profile', 'Name of the profile (never shown to the user):', LName) and
     (Trim(LName) <> '') then
  begin
    FController.AddProfile(LName);
    RefreshProfiles;
    Changed;
  end;
end;

procedure TVclHelpChatConfigEditor.ProfileRenameButtonClick(Sender: TObject);
var
  LOld, LName: string;
begin
  if ProfilesList.ItemIndex < 0 then
    Exit;
  LOld := ProfilesList.Items[ProfilesList.ItemIndex];
  LName := LOld;
  if InputQuery('Rename profile', 'New name of the profile:', LName) and
     (Trim(LName) <> '') and (LName <> LOld) then
  begin
    FController.RenameProfile(LOld, LName);
    // The assistant whose profile was renamed follows it.
    if SameText(FController.Profile, Trim(LName)) and Assigned(FOnProfileChanged) then
      FOnProfileChanged(FController.Profile);
    RefreshProfiles;
    Changed;
  end;
end;

procedure TVclHelpChatConfigEditor.ProfileDeleteButtonClick(Sender: TObject);
var
  LName: string;
begin
  if ProfilesList.ItemIndex < 0 then
    Exit;
  LName := ProfilesList.Items[ProfilesList.ItemIndex];
  if MessageDlg(Format('Delete the profile %s and everything it says?', [LName]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  FController.DeleteProfile(LName);
  RefreshProfiles;
  Changed;
end;

procedure TVclHelpChatConfigEditor.TestButtonClick(Sender: TObject);
begin
  // The preview builds its settings from the files on disk and from the
  // component, not from this editor: what is not saved would not be in it.
  CommitProviderKey;
  if FController.Modified then
    case MessageDlg('The preview reads the files: save the changes first?',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
      mrYes:
        if not FController.Save then
        begin
          MessageDlg(FController.LastError, mtError, [mbOK], 0);
          Exit;
        end;
      mrCancel: Exit;
    end;
  RefreshFile;
  if Assigned(FOnTest) then
    FOnTest();
end;

procedure TVclHelpChatConfigEditor.HighlightPrompt;
var
  LEntry: THelpChatConfigEntry;
  LFragment: string;
  LStart: Integer;
begin
  PromptMemo.Lines.BeginUpdate;
  try
    // Plain first, in the colours of the theme: a rich edit keeps the
    // attributes of the text it had.
    PromptMemo.Text := FPromptText.Replace(#10, sLineBreak);
    PromptMemo.SelectAll;
    PromptMemo.SelAttributes.Style := [];
    PromptMemo.SelAttributes.Color := FTextColor;
    LStart := -1;
    LFragment := '';
    if SelectedEntry(LEntry) then
      LFragment := FController.PromptFragment(LEntry.Path).Replace(#13#10, #10);
    if LFragment <> '' then
      LStart := FPromptText.IndexOf(LFragment);
    if LStart >= 0 then
    begin
      PromptMemo.SelStart := LStart;
      PromptMemo.SelLength := LFragment.Length;
      PromptMemo.SelAttributes.Style := [fsBold];
    end;
    PromptMemo.SelStart := Max(LStart, 0);
    PromptMemo.SelLength := 0;
  finally
    PromptMemo.Lines.EndUpdate;
  end;
  PromptMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TVclHelpChatConfigEditor.RefreshIcons;
var
  LImages: TCustomImageList;
  LItem: TListItem;
  LName: string;
  LSelected, I: Integer;
begin
  FRefreshing := True;
  IconList.Items.BeginUpdate;
  try
    IconList.Items.Clear;
    IconPanel.Enabled := Assigned(FChat);
    StyleSheetEdit.Enabled := Assigned(FChat);
    StyleSheetBrowseButton.Enabled := Assigned(FChat);
    StyleSheetApplyButton.Enabled := Assigned(FChat);
    if not Assigned(FChat) then
    begin
      IconHintLabel.Caption := '';
      Exit;
    end;
    StyleSheetEdit.Text := FChat.PanelStyleSheet;
    // The application's image list wins, as at run time; with none, the
    // built-in icons, at the size of the list on this monitor.
    if Assigned(FChat.Images) then
    begin
      LImages := FChat.Images;
      IconHintLabel.Caption := Format('From the Images of the component (%s): a click sets ' +
        'ImageIndex, and ImageName follows.', [FChat.Images.Name]);
    end
    else
    begin
      if FBuiltInImages = nil then
      begin
        FBuiltInImages := TVirtualImageList.Create(Self);
        FBuiltInImages.ImageCollection := HelpChatAssistantIcons;
        FBuiltInImages.Width := ScaleValue(48);
        FBuiltInImages.Height := ScaleValue(48);
        FBuiltInImages.AutoFill := True;
      end;
      LImages := FBuiltInImages;
      IconHintLabel.Caption := 'The built-in icons (the component has no Images): a click ' +
        'sets ImageName, and ImageIndex follows.';
    end;
    IconList.LargeImages := LImages;
    LSelected := -1;
    for I := 0 to LImages.Count - 1 do
    begin
      LName := LImages.GetNameByIndex(I);
      LItem := IconList.Items.Add;
      LItem.Caption := LName;
      LItem.ImageIndex := I;
      if Assigned(FChat.Images) then
      begin
        if I = FChat.ImageIndex then
          LSelected := I;
      end
      else if SameText(LName, FChat.ImageName) or ((FChat.ImageName = '') and (I = FChat.ImageIndex)) then
        LSelected := I;
    end;
    if LSelected >= 0 then
      IconList.Items[LSelected].Selected := True;
  finally
    IconList.Items.EndUpdate;
    FRefreshing := False;
  end;
end;

procedure TVclHelpChatConfigEditor.IconListSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if not Selected or not Assigned(FChat) or FRefreshing then
    Exit;
  // Into the component, now, like "Write to the component": the setter keeps
  // the other half in step.
  if Assigned(FChat.Images) then
  begin
    if FChat.ImageIndex = Item.Index then
      Exit;
    FChat.ImageIndex := Item.Index;
    if Assigned(FOnComponentChanged) then
      FOnComponentChanged('ImageIndex');
  end
  else
  begin
    if SameText(FChat.ImageName, Item.Caption) then
      Exit;
    FChat.ImageName := Item.Caption;
    if Assigned(FOnComponentChanged) then
      FOnComponentChanged('ImageName');
  end;
  RefreshPreview;
end;

procedure TVclHelpChatConfigEditor.DoShow;
begin
  inherited;
  if FShown then
    Exit;
  FShown := True;
  // Queued: DoShow runs before the window is made visible, and the WebView
  // must be created in a window that is.
  TThread.ForceQueue(nil,
    procedure
    begin
      RefreshPreview;
    end);
end;

procedure TVclHelpChatConfigEditor.RefreshPreview;
var
  LFrom, LError, LIcon, LStyleSheet: string;
  LCommands: THelpChatCommands;
begin
  if not FShown or (PageControl.ActivePage <> AppearanceTab) then
    Exit;
  if not FPreviewTried then
  begin
    // Once: the loader by full path (nothing ships it next to bds.exe),
    // then a browser of our own - not the panel of the component, which
    // lets nothing but its server navigate it.
    FPreviewTried := True;
    if HelpChatDesignEnsureWebView2Loader(HelpChatDesignBaseFolder, LFrom) then
    begin
      FPreviewBrowser := TEdgeBrowser.Create(Self);
      FPreviewBrowser.Parent := PreviewHost;
      FPreviewBrowser.Align := alClient;
      FPreviewBrowser.UserDataFolder := TPath.Combine(HelpChatAppDataFolder, 'WebView2');
      FPreviewBrowser.OnCreateWebViewCompleted := PreviewCreated;
      PreviewMessageLabel.Visible := False;
    end
    else
      PreviewMessageLabel.Caption := 'The preview needs WebView2Loader.dll: put it in the ' +
        'output folder of the project, or install the library with its Redist folder.';
  end;
  if FPreviewBrowser = nil then
    Exit;
  LIcon := '';
  LStyleSheet := '';
  LCommands := HELPCHAT_DEF_COMMANDS;
  if Assigned(FChat) then
  begin
    LIcon := HelpChatIconDataUri(FChat.Images, FChat.ImageIndex, FChat.ImageName);
    LStyleSheet := FChat.PanelStyleSheet;
    LCommands := FChat.EnabledCommands;
  end;
  FPendingPreview := FController.AppearancePreview(ThemeSwitch.State = tssOn, LIcon,
    LStyleSheet, LCommands, LError);
  StyleSheetErrorLabel.Caption := LError;
  if FPreviewBrowser.WebViewCreated then
    FPreviewBrowser.NavigateToString(FPendingPreview)
  else
    FPreviewBrowser.CreateWebView;
end;

procedure TVclHelpChatConfigEditor.PreviewCreated(Sender: TCustomEdgeBrowser; AResult: HResult);
begin
  if Succeeded(AResult) then
    Sender.NavigateToString(FPendingPreview)
  else
  begin
    PreviewMessageLabel.Caption := Format('WebView2 could not start (0x%.8x).', [AResult]);
    PreviewMessageLabel.Visible := True;
  end;
end;

procedure TVclHelpChatConfigEditor.ThemeSwitchClick(Sender: TObject);
begin
  RefreshPreview;
end;

procedure TVclHelpChatConfigEditor.StyleSheetBrowseButtonClick(Sender: TObject);
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

procedure TVclHelpChatConfigEditor.StyleSheetApplyButtonClick(Sender: TObject);
begin
  if not Assigned(FChat) or (FChat.PanelStyleSheet = Trim(StyleSheetEdit.Text)) then
    Exit;
  // Into the component, now: the form file keeps it, and empty removes it.
  FChat.PanelStyleSheet := Trim(StyleSheetEdit.Text);
  if Assigned(FOnComponentChanged) then
    FOnComponentChanged('PanelStyleSheet');
  RefreshPreview;
end;

procedure TVclHelpChatConfigEditor.HelpButtonClick(Sender: TObject);
begin
  // The page of the online documentation about this editor, in the browser
  // of the system.
  ShellExecute(0, 'open', PChar(HELPCHAT_CONFIG_EDITOR_HELP_URL), nil, nil, SW_SHOWNORMAL);
end;

end.
