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
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.CheckLst,
  Vcl.Imaging.pngimage,
  HelpChatAI.Settings,
  HelpChatAI.ConfigController;

type
  /// <summary>
  ///  The form of the editor: three pages over one controller.
  ///  <list type="bullet">
  ///   <item><c>Settings</c>: every setting of the catalogue with the value in
  ///    force and who set it, and three places to write the one selected -
  ///    the root of the file being edited, the profile of the assistant in
  ///    that file, or the component (the form file);</item>
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
    SettingsTab: TTabSheet;
    ModelsTab: TTabSheet;
    ProfilesTab: TTabSheet;
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
    ToProfileButton: TButton;
    ToRootButton: TButton;
    ToComponentButton: TButton;
    RemoveProfileButton: TButton;
    RemoveRootButton: TButton;
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
    ModelIconLabel: TLabel;
    ModelIconEdit: TEdit;
    ModelKeyLabel: TLabel;
    ModelKeyEdit: TEdit;
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
    procedure ShowSecretCheckClick(Sender: TObject);
    procedure ToProfileButtonClick(Sender: TObject);
    procedure ToRootButtonClick(Sender: TObject);
    procedure ToComponentButtonClick(Sender: TObject);
    procedure RemoveProfileButtonClick(Sender: TObject);
    procedure RemoveRootButtonClick(Sender: TObject);
    procedure ModelsListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ModelAddButtonClick(Sender: TObject);
    procedure ModelUpdateButtonClick(Sender: TObject);
    procedure ModelDeleteButtonClick(Sender: TObject);
    procedure ProfileModelsButtonClick(Sender: TObject);
    procedure ProfileAddButtonClick(Sender: TObject);
    procedure ProfileRenameButtonClick(Sender: TObject);
    procedure ProfileDeleteButtonClick(Sender: TObject);
    procedure TestButtonClick(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
  strict private
    /// <summary>Every rule of the editor. Owned: created by
    /// <see cref="Execute" /> after the form (so <c>FormCreate</c> runs
    /// without it), freed in <c>FormDestroy</c>.</summary>
    FController: THelpChatConfigController;
    /// <summary>The settings of the component being edited; not owned, and
    /// only kept for reference: the controller is what writes into them.</summary>
    FSettings: THelpChatSettings;
    /// <summary>What <c>SettingsList</c> shows, row for row: the index of a
    /// list item is the index here. Replaced by every
    /// <see cref="RefreshEntries" />.</summary>
    FEntries: TArray<THelpChatConfigEntry>;
    /// <summary>What <c>ModelsList</c> shows, row for row; the keys in it are
    /// the clear ones, as the file has them.</summary>
    FModels: TArray<THelpChatConfigModel>;
    /// <summary>Called with the new profile every time the profile of the
    /// editor changes (the combo, or the rename of the profile in use); nil
    /// is allowed.</summary>
    FOnProfileChanged: TProc<string>;
    /// <summary>Called after a value was written into the settings of the
    /// component; nil is allowed.</summary>
    FOnComponentChanged: TProc;
    /// <summary>What the Test button runs; nil disables the button.</summary>
    FOnTest: TProc;
    /// <summary>True while the form fills its own combos: their
    /// <c>OnChange</c> must not read that as a choice of the user.</summary>
    FRefreshing: Boolean;
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
    /// <summary>Puts the selected setting in the edit panel: the memo, or
    /// the masked edit box for a secret, filled with what the file says in
    /// the profile, else at the root - the value itself and not the masked
    /// one of the list, so that what a button writes back is a key and never
    /// a row of asterisks.</summary>
    procedure ShowSelected;
    /// <summary>The entry of the selected row; False when none is.</summary>
    function SelectedEntry(out AEntry: THelpChatConfigEntry): Boolean;
    /// <summary>What the user typed for the selected setting, trimmed: from
    /// the masked edit box for a secret, from the memo for the rest.</summary>
    function EditedValue: string;
    /// <summary>The model the edit boxes of the Models page describe.</summary>
    function ModelFromEdits: THelpChatConfigModel;
    /// <summary>After any change made through the controller: the origins,
    /// the status line and the "(modified)" mark all depend on it.</summary>
    procedure Changed;
  public
    /// <summary>
    ///  Opens the editor, modally, on the settings of a component, and
    ///  returns when it is closed. Main thread, inside the IDE.
    ///  <para><c>ASettings</c> are the component's own (not owned): "To
    ///  component" writes into them at once. <c>AProfile</c> is its
    ///  <c>Profile</c>, empty for the default assistant.
    ///  <c>AExeFile</c> is the executable of the project - its folder holds
    ///  the application file, its name the per-user folder; empty (no
    ///  project open) leaves the shared file alone to edit.
    ///  <c>AConfigFileName</c> is the component's: named, it is the only
    ///  file offered.</para>
    ///  <para><c>AOnProfileChanged</c> receives the profile each time it
    ///  changes in the editor - while the user types it, too - and is where
    ///  the caller sets <c>Profile</c> on the component;
    ///  <c>AOnComponentChanged</c> tells the designer that the form file
    ///  changed; <c>AOnTest</c> opens the design-time preview, and nil
    ///  disables its button. All three run inside the modal loop of the
    ///  editor; any of them may be nil.</para>
    ///  <para>There is no result and no Cancel: the files change only on
    ///  Save (closing with unsaved changes asks), the component changes
    ///  as the user goes.</para>
    /// </summary>
    class procedure Execute(const ASettings: THelpChatSettings;
      const AProfile, AExeFile, AConfigFileName: string;
      const AOnProfileChanged: TProc<string>; const AOnComponentChanged, AOnTest: TProc);
  end;

implementation

{$R *.dfm}

uses
  System.UITypes,
  System.StrUtils,
  Vcl.Graphics,
  Vcl.Themes,
  Vcl.Dialogs,
  Winapi.Windows,
  Winapi.ShellAPI,
  ToolsAPI,
  BrandingAPI,
  IDETheme.Utils;

const
  // The "key" column of the models list: that a model has a key of its own,
  // never the key.
  SCOPE_TEXT: array[Boolean] of string = ('', 'set');

class procedure TVclHelpChatConfigEditor.Execute(const ASettings: THelpChatSettings;
  const AProfile, AExeFile, AConfigFileName: string;
  const AOnProfileChanged: TProc<string>; const AOnComponentChanged, AOnTest: TProc);
var
  LForm: TVclHelpChatConfigEditor;
begin
  LForm := TVclHelpChatConfigEditor.Create(nil);
  try
    // The controller comes after the form: FormCreate has run without it,
    // and FormDestroy frees it. Should its constructor raise here, the form
    // goes away with no controller, which FormCloseQuery allows for.
    LForm.FSettings := ASettings;
    LForm.FController := THelpChatConfigController.Create(ASettings, AProfile, AExeFile,
      AConfigFileName);
    LForm.FOnProfileChanged := AOnProfileChanged;
    LForm.FOnComponentChanged := AOnComponentChanged;
    LForm.FOnTest := AOnTest;
    LForm.TestButton.Enabled := Assigned(AOnTest);
    LForm.RefreshAll;
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

procedure TVclHelpChatConfigEditor.FormCreate(Sender: TObject);
var
  LStyle: TCustomStyleServices;

  procedure PaintPanel(const APanel: TPanel);
  begin
    APanel.StyleElements := APanel.StyleElements - [seClient];
    APanel.ParentBackground := False;
    APanel.Color := LStyle.GetSystemColor(clBtnFace);
  end;

begin
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
  PageControl.ActivePage := SettingsTab;
  // The profile is taken when it is picked or when the box is left, not at
  // every letter typed into it (the form file says OnChange).
  ProfileCombo.OnChange := nil;
  ProfileCombo.OnSelect := ProfileComboChange;
  ProfileCombo.OnExit := ProfileComboChange;
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

procedure TVclHelpChatConfigEditor.RefreshEntries;
var
  LEntry: THelpChatConfigEntry;
  LItem: TListItem;
  LSelected: Integer;
  LError: string;
begin
  LSelected := -1;
  if Assigned(SettingsList.Selected) then
    LSelected := SettingsList.Selected.Index;
  FEntries := FController.Entries;
  SettingsList.Items.BeginUpdate;
  try
    SettingsList.Items.Clear;
    for LEntry in FEntries do
    begin
      LItem := SettingsList.Items.Add;
      LItem.Caption := LEntry.Caption;
      LItem.SubItems.Add(LEntry.Effective);
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
  if (LSelected >= 0) and (LSelected < SettingsList.Items.Count) then
    SettingsList.Items[LSelected].Selected := True;
  ShowSelected;
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
  LText: string;
begin
  LHasProfile := FController.Profile <> '';
  if not SelectedEntry(LEntry) then
  begin
    SettingLabel.Caption := 'Select a setting';
    HintLabel.Caption := '';
    ValueMemo.Lines.Clear;
    SecretEdit.Text := '';
    EditPanel.Enabled := False;
    Exit;
  end;
  EditPanel.Enabled := True;
  SettingLabel.Caption := LEntry.Caption + '  (' + LEntry.Path + ')';
  HintLabel.Caption := LEntry.Hint;
  LSecret := LEntry.Kind = cvkSecret;
  ValueMemo.Visible := not LSecret;
  SecretEdit.Visible := LSecret;
  ShowSecretCheck.Visible := LSecret;
  // What the file says where the user would write it: the profile first.
  if not (LHasProfile and FController.GetValue(LEntry.Path, ccsProfile, LText)) then
    if not FController.GetValue(LEntry.Path, ccsRoot, LText) then
      LText := '';
  if LSecret then
  begin
    // The clear key of the file, hidden by the edit box and not replaced by
    // a mask: the mask of the list (asterisks and the last four characters)
    // never gets here, so it can never be saved as the key.
    SecretEdit.Text := LText;
    ShowSecretCheck.Checked := False;
    SecretEdit.PasswordChar := '*';
  end
  else
    ValueMemo.Text := LText;
  ToProfileButton.Enabled := LHasProfile;
  RemoveProfileButton.Enabled := LHasProfile and LEntry.InProfile;
  RemoveRootButton.Enabled := LEntry.InRoot;
  // A key belongs to a file, never to the form file.
  ToComponentButton.Enabled := not LSecret;
end;

function TVclHelpChatConfigEditor.EditedValue: string;
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) and (LEntry.Kind = cvkSecret) then
    Result := Trim(SecretEdit.Text)
  else
    Result := Trim(ValueMemo.Text);
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
end;

procedure TVclHelpChatConfigEditor.ReloadButtonClick(Sender: TObject);
begin
  FController.Reload;
  RefreshFile;
end;

procedure TVclHelpChatConfigEditor.SaveButtonClick(Sender: TObject);
begin
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
    FOnComponentChanged();
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
      LItem.SubItems.Add(LModel.Icon);
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
  ModelIconEdit.Text := LModel.Icon;
  ModelKeyEdit.Text := LModel.ApiKey;
end;

function TVclHelpChatConfigEditor.ModelFromEdits: THelpChatConfigModel;
begin
  Result := Default(THelpChatConfigModel);
  Result.Name := Trim(ModelNameEdit.Text);
  Result.Provider := Trim(ModelProviderCombo.Text);
  Result.Model := Trim(ModelModelEdit.Text);
  Result.BaseUrl := Trim(ModelUrlEdit.Text);
  Result.Icon := Trim(ModelIconEdit.Text);
  Result.ApiKey := Trim(ModelKeyEdit.Text);
end;

procedure TVclHelpChatConfigEditor.ModelAddButtonClick(Sender: TObject);
begin
  if Trim(ModelNameEdit.Text) = '' then
    Exit;
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

procedure TVclHelpChatConfigEditor.HelpButtonClick(Sender: TObject);
begin
  // The page of the online documentation about this editor, in the browser
  // of the system.
  ShellExecute(0, 'open', PChar(HELPCHAT_CONFIG_EDITOR_HELP_URL), nil, nil, SW_SHOWNORMAL);
end;

end.
