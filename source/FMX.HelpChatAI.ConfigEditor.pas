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
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Objects,
  FMX.Edit,
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
  HelpChatAI.ConfigController;

type
  /// <summary>
  ///  The editor as a FireMonkey form, shown modally inside the IDE by the
  ///  component editor of <c>TFmxHelpChatAI</c>. Three pages: the settings
  ///  with the value in force and where it comes from, the catalogue of
  ///  models with what the profile offers of it, and the profiles of the
  ///  file. One file is edited at a time; nothing is written until Save.
  ///
  ///  A secret is shown masked in the grid (the controller masks it) and
  ///  edited in clear in a password box: what goes back to the controller is
  ///  the text typed, never the mask, and never into the component.
  ///
  ///  Where it differs from the VCL twin, it is the controls: string grids
  ///  for the two list views, a list box with check boxes for the check
  ///  list, <c>TDialogServiceSync</c> for the questions, and no theme of the
  ///  IDE - it wears the default FireMonkey style. The Test button is always
  ///  off: FireMonkey has no design-time preview.
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
    SettingsTab: TTabItem;
    ModelsTab: TTabItem;
    ProfilesTab: TTabItem;
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
    ToProfileButton: TButton;
    ToRootButton: TButton;
    ToComponentButton: TButton;
    RemoveProfileButton: TButton;
    RemoveRootButton: TButton;
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
    ModelIconLabel: TLabel;
    ModelIconEdit: TEdit;
    ModelKeyLabel: TLabel;
    ModelKeyEdit: TEdit;
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
    procedure ShowSecretCheckChange(Sender: TObject);
    procedure ToProfileButtonClick(Sender: TObject);
    procedure ToRootButtonClick(Sender: TObject);
    procedure ToComponentButtonClick(Sender: TObject);
    procedure RemoveProfileButtonClick(Sender: TObject);
    procedure RemoveRootButtonClick(Sender: TObject);
    procedure ModelsGridSelChanged(Sender: TObject);
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
    FController: THelpChatConfigController;
    FEntries: TArray<THelpChatConfigEntry>;
    FModels: TArray<THelpChatConfigModel>;
    FOnProfileChanged: TProc<string>;
    FOnComponentChanged: TProc;
    FOnTest: TProc;
    FRefreshing: Boolean;
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
    /// <summary>Shows the selected setting in the edit area: the value the
    /// file has where the user would write it - the profile first, then the
    /// root - in the memo, or in the password box for a secret, and which
    /// of the buttons make sense.</summary>
    procedure ShowSelected;
    function SelectedEntry(out AEntry: THelpChatConfigEntry): Boolean;
    /// <summary>What the user typed for the selected setting, trimmed: from
    /// the password box for a secret, from the memo otherwise.</summary>
    function EditedValue: string;
    function ModelFromEdits: THelpChatConfigModel;
    /// <summary>A question that waits for its answer. The synchronous
    /// service, because the callers decide on the answer before going
    /// on.</summary>
    function Ask(const AMessage: string; const AButtons: TMsgDlgButtons): TModalResult;
    /// <summary>With changes not saved yet, asks whether to save them. True
    /// when the caller may go on: nothing to save, saved, or the user chose
    /// to drop them; False on Cancel or when the save failed (the reason is
    /// shown). What closing, switching file and testing all ask first.</summary>
    function SaveFirst: Boolean;
  public
    /// <summary>Opens the editor on the settings of a component and returns
    /// when it is closed. ASettings are the component's and are not owned:
    /// only "To component" writes into them, and never a secret. AExeFile is
    /// the executable of the project being designed - never the IDE's -
    /// where the application file lives and what names the per-user folder;
    /// AConfigFileName the one of the component, which named is the only
    /// file. AOnProfileChanged gives the component its new Profile,
    /// AOnComponentChanged tells the designer the form file changed, AOnTest
    /// would open a preview and is nil here. The same contract as
    /// <c>TVclHelpChatConfigEditor.Execute</c>, so that the two design
    /// packages call their editor alike.</summary>
    class procedure Execute(const ASettings: THelpChatSettings;
      const AProfile, AExeFile, AConfigFileName: string;
      const AOnProfileChanged: TProc<string>; const AOnComponentChanged, AOnTest: TProc);
  end;

implementation

{$R *.fmx}

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.ShellAPI,
  {$ENDIF}
  FMX.DialogService.Sync;

class procedure TFmxHelpChatConfigEditor.Execute(const ASettings: THelpChatSettings;
  const AProfile, AExeFile, AConfigFileName: string;
  const AOnProfileChanged: TProc<string>; const AOnComponentChanged, AOnTest: TProc);
var
  LForm: TFmxHelpChatConfigEditor;
begin
  LForm := TFmxHelpChatConfigEditor.Create(nil);
  try
    // After the constructor: FormCreate has run without a controller, and
    // nothing is shown before RefreshAll below.
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
begin
  TabControl.ActiveTab := SettingsTab;
  AddColumns(SettingsGrid, ['Setting', 'In force', 'From', 'This file, root', 'This file, profile'],
    [180, 220, 200, 125, 125]);
  AddColumns(ModelsGrid, ['Name', 'Provider', 'Model', 'Endpoint', 'Icon', 'Key'],
    [140, 80, 140, 170, 60, 40]);
  ModelProviderCombo.Items.CommaText := 'claude,openai,gemini,docsearch,stub';
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

procedure TFmxHelpChatConfigEditor.RefreshEntries;
var
  I, LSelected: Integer;
  LError: string;
begin
  LSelected := SettingsGrid.Selected;
  FEntries := FController.Entries;
  SettingsGrid.BeginUpdate;
  try
    SettingsGrid.RowCount := Length(FEntries);
    for I := 0 to High(FEntries) do
    begin
      SettingsGrid.Cells[0, I] := FEntries[I].Caption;
      SettingsGrid.Cells[1, I] := FEntries[I].Effective;
      SettingsGrid.Cells[2, I] := FEntries[I].Origin;
      SettingsGrid.Cells[3, I] := FEntries[I].RootValue;
      SettingsGrid.Cells[4, I] := FEntries[I].ProfileValue;
    end;
  finally
    SettingsGrid.EndUpdate;
  end;
  if (LSelected >= 0) and (LSelected < SettingsGrid.RowCount) then
    SettingsGrid.Selected := LSelected;
  ShowSelected;
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
  LText: string;
begin
  LHasProfile := FController.Profile <> '';
  if not SelectedEntry(LEntry) then
  begin
    SettingLabel.Text := 'Select a setting';
    HintLabel.Text := '';
    ValueMemo.Lines.Clear;
    SecretEdit.Text := '';
    EditLayout.Enabled := False;
    Exit;
  end;
  EditLayout.Enabled := True;
  SettingLabel.Text := LEntry.Caption + '  (' + LEntry.Path + ')';
  HintLabel.Text := LEntry.Hint;
  LSecret := LEntry.Kind = cvkSecret;
  ValueMemo.Visible := not LSecret;
  SecretEdit.Visible := LSecret;
  ShowSecretCheck.Visible := LSecret;
  // What the file says where the user would write it: the profile first.
  // For a secret this is the clear node as the file has it, not the mask
  // the grid shows - so what is written back is always a real value.
  if not (LHasProfile and FController.GetValue(LEntry.Path, ccsProfile, LText)) then
    if not FController.GetValue(LEntry.Path, ccsRoot, LText) then
      LText := '';
  if LSecret then
  begin
    SecretEdit.Text := LText;
    ShowSecretCheck.IsChecked := False;
    SecretEdit.Password := True;
  end
  else
    ValueMemo.Text := LText;
  ToProfileButton.Enabled := LHasProfile;
  RemoveProfileButton.Enabled := LHasProfile and LEntry.InProfile;
  RemoveRootButton.Enabled := LEntry.InRoot;
  // A key belongs to a file, never to the form file.
  ToComponentButton.Enabled := not LSecret;
end;

function TFmxHelpChatConfigEditor.EditedValue: string;
var
  LEntry: THelpChatConfigEntry;
begin
  if SelectedEntry(LEntry) and (LEntry.Kind = cvkSecret) then
    Result := Trim(SecretEdit.Text)
  else
    Result := Trim(ValueMemo.Text);
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
end;

procedure TFmxHelpChatConfigEditor.ReloadButtonClick(Sender: TObject);
begin
  FController.Reload;
  RefreshFile;
end;

procedure TFmxHelpChatConfigEditor.SaveButtonClick(Sender: TObject);
begin
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
    FOnComponentChanged();
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
      ModelsGrid.Cells[4, I] := FModels[I].Icon;
      if FModels[I].ApiKey <> '' then
        ModelsGrid.Cells[5, I] := 'set'
      else
        ModelsGrid.Cells[5, I] := '';
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
  ModelIconEdit.Text := LModel.Icon;
  ModelKeyEdit.Text := LModel.ApiKey;
end;

function TFmxHelpChatConfigEditor.ModelFromEdits: THelpChatConfigModel;
begin
  Result := Default(THelpChatConfigModel);
  Result.Name := Trim(ModelNameEdit.Text);
  Result.Provider := Trim(ModelProviderCombo.Text);
  Result.Model := Trim(ModelModelEdit.Text);
  Result.BaseUrl := Trim(ModelUrlEdit.Text);
  Result.Icon := Trim(ModelIconEdit.Text);
  Result.ApiKey := Trim(ModelKeyEdit.Text);
end;

procedure TFmxHelpChatConfigEditor.ModelAddButtonClick(Sender: TObject);
begin
  if Trim(ModelNameEdit.Text) = '' then
    Exit;
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

procedure TFmxHelpChatConfigEditor.HelpButtonClick(Sender: TObject);
begin
  // The page of the online documentation about this editor, in the browser
  // of the system. The editor runs inside the IDE, which is Windows.
  {$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(HELPCHAT_CONFIG_EDITOR_HELP_URL), nil, nil, SW_SHOWNORMAL);
  {$ENDIF}
end;

end.
