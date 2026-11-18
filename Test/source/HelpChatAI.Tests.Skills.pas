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
///  The skills: the registry and the set an assistant attaches (RTL), the
///  confirmation an action may describe itself, and the VCL skills on real
///  forms built here - plain controls, data-aware ones over a
///  <c>TFDMemTable</c>, buttons, pages.
/// </summary>
unit HelpChatAI.Tests.Skills;

interface

uses
  System.Classes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.DBCtrls, Vcl.DBGrids, Vcl.ActnList, Vcl.DBActns, Data.DB,
  FireDAC.Comp.Client,
  DUnitX.TestFramework;

type
  [TestFixture]
  TSkillRegistryTests = class
  public
    [Test] procedure TheVclSkills_AreRegistered;
    [Test] procedure SkillSet_AddsTheActions_AndTakesThemAway;
    [Test] procedure SkillSet_TheApplicationsActionWins;
    [Test] procedure SkillSet_AnActionAddedLater_SurvivesDetach;
    [Test] procedure SkillSet_NamingASkill_AllowsItsActions;
    [Test] procedure SkillSet_UnknownName_IsSkipped;
    [Test] procedure Settings_Skills_StringOrArray_RoundTrip;
    [Test] procedure Diagnostics_UnknownSkill_IsAWarning;
    [Test] procedure Action_OnDisplay_ReplacesSummaryAndValues;
    [Test] procedure Helpers_ParseWhatTheModelWrites;
    [Test] procedure SkillActionNames_AreFoundByName;
  end;

  [TestFixture]
  TVclSkillTests = class
  strict private
    FForm: TForm;
    FCalcClicked: Integer;
    FPages: TPageControl;
    FTabGeneral, FTabNotes, FTabPrivate: TTabSheet;
    FFirst, FPassword: TEdit;
    FCity: TComboBox;
    FNews: TCheckBox;
    FSize: TRadioGroup;
    FColour: TGroupBox;
    FRed, FBlue: TRadioButton;
    FBirth: TDateTimePicker;
    FPrivate: TMemo;
    // data-aware
    FTable, FRegions: TFDMemTable;
    FSource, FRegionSource: TDataSource;
    procedure CalcClick(Sender: TObject);
    procedure BuildPlainForm;
    procedure BuildDataForm;
  public
    [TearDown] procedure TearDown;
    [Test] procedure Fields_CaptionsTypesAndOrder;
    [Test] procedure Fields_DisabledAndHidden_AreLeftOut;
    [Test] procedure Describe_SaysTypesFlagsValuesAndPages;
    [Test] procedure Fill_PlainControls_AndCancelPutsThemBack;
    [Test] procedure Fill_ReportsWhatItCouldNotDo;
    [Test] procedure DataAware_Describe_ReadsTheField;
    [Test] procedure DataAware_APasswordEdit_IsNeverRead;
    [Test] procedure Lookup_BeingEdited_IsNeitherPostedNorCancelled;
    [Test] procedure DataAware_FillInsert_NeverPosts_AndCancelDropsIt;
    [Test] procedure DataAware_Lookup_ByDescription_WritesTheCode;
    [Test] procedure DataAware_NoAutoEdit_CurrentModeRefuses;
    [Test] procedure Records_CountAndFind_RefusingWhileEditing;
    [Test] procedure Records_FindRecord_NeitherSearchesNorReportsAPassword;
    [Test] procedure Commands_LeaveOutTheSaves_AndPress;
    [Test] procedure Commands_WhileEditing_LeaveOutWhatMovesTheRecord;
    [Test] procedure Pages_ShowANestedPage;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.Generics.Collections, System.DateUtils,
  FireDAC.Comp.DataSet, FireDAC.Stan.Intf,
  HelpChatAI.Actions, HelpChatAI.Skills, HelpChatAI.Settings, HelpChatAI.Diagnostics,
  HelpChatAI.Messages,
  Vcl.HelpChatAI.Skills;

{ TSkillRegistryTests }

procedure TSkillRegistryTests.TheVclSkills_AreRegistered;
begin
  Assert.IsTrue(HelpChatIsSkillRegistered('forms'));
  Assert.IsTrue(HelpChatIsSkillRegistered('Commands'), 'case apart');
  Assert.IsTrue(HelpChatIsSkillRegistered('records'));
  Assert.IsTrue(HelpChatIsSkillRegistered('pages'));
  Assert.IsFalse(HelpChatIsSkillRegistered('telepathy'));
  Assert.AreNotEqual('', HelpChatSkillDescription('forms'));
end;

procedure TSkillRegistryTests.SkillSet_AddsTheActions_AndTakesThemAway;
var
  LBroker: THelpChatActionBroker;
  LRef: IHelpChatActionInvoker;
  LSet: THelpChatSkillSet;
begin
  LBroker := THelpChatActionBroker.Create;
  LRef := LBroker;
  LSet := THelpChatSkillSet.Create;
  try
    LBroker.Add('open_screen', 'Opens a screen.',
      procedure(const AArgs: THelpChatActionArgs; var AResult: string) begin end, False);
    LSet.Attach(nil, LBroker, ['forms', 'pages']);
    Assert.AreEqual(2, Length(LSet.Names));
    Assert.IsNotNull(LBroker.Find('describe_form'));
    Assert.IsNotNull(LBroker.Find('fill_form'));
    Assert.IsNotNull(LBroker.Find('cancel_edit'));
    Assert.IsNotNull(LBroker.Find('show_page'));
    Assert.IsNull(LBroker.Find('press_command'), 'commands was not named');
    Assert.IsTrue(LBroker.Find('fill_form').Confirm, 'filling asks');
    Assert.IsFalse(LBroker.Find('describe_form').Confirm, 'describing changes nothing');
    LSet.Detach;
    Assert.IsNull(LBroker.Find('describe_form'));
    Assert.IsNotNull(LBroker.Find('open_screen'), 'what the application registered stays');
  finally
    LSet.Free;
  end;
end;

procedure TSkillRegistryTests.SkillSet_TheApplicationsActionWins;
var
  LBroker: THelpChatActionBroker;
  LRef: IHelpChatActionInvoker;
  LSet: THelpChatSkillSet;
begin
  LBroker := THelpChatActionBroker.Create;
  LRef := LBroker;
  LSet := THelpChatSkillSet.Create;
  try
    LBroker.Add('describe_form', 'Mine.',
      procedure(const AArgs: THelpChatActionArgs; var AResult: string) begin end, False);
    LSet.Attach(nil, LBroker, ['forms']);
    Assert.AreEqual('Mine.', LBroker.Find('describe_form').Description);
    LSet.Detach;
    Assert.IsNotNull(LBroker.Find('describe_form'), 'the skill never takes away what it did not add');
  finally
    LSet.Free;
  end;
end;

procedure TSkillRegistryTests.SkillSet_AnActionAddedLater_SurvivesDetach;
var
  LBroker: THelpChatActionBroker;
  LRef: IHelpChatActionInvoker;
  LSet: THelpChatSkillSet;
begin
  // A component active from the form file attaches its skills in Loaded,
  // before FormCreate registers the actions of the application: one of them
  // under the name of a skill's replaces it, and must not go with the skill.
  LBroker := THelpChatActionBroker.Create;
  LRef := LBroker;
  LSet := THelpChatSkillSet.Create;
  try
    LSet.Attach(nil, LBroker, ['pages']);
    Assert.IsNotNull(LBroker.Find('show_page'));
    LBroker.Add('show_page', 'Mine.',
      procedure(const AArgs: THelpChatActionArgs; var AResult: string) begin end, False);
    LSet.Detach;
    Assert.IsNotNull(LBroker.Find('show_page'), 'the action of the application stays');
    Assert.AreEqual('Mine.', LBroker.Find('show_page').Description);
    Assert.IsNull(LBroker.Find('list_pages'), 'what the skill added goes');
  finally
    LSet.Free;
  end;
end;

procedure TSkillRegistryTests.SkillSet_NamingASkill_AllowsItsActions;
var
  LBroker: THelpChatActionBroker;
  LRef: IHelpChatActionInvoker;
  LSet: THelpChatSkillSet;
begin
  LBroker := THelpChatActionBroker.Create;
  LRef := LBroker;
  LSet := THelpChatSkillSet.Create;
  try
    LBroker.Add('open_screen', 'Opens a screen.',
      procedure(const AArgs: THelpChatActionArgs; var AResult: string) begin end, False);
    LBroker.Allowed := ['open_screen'];
    LSet.Attach(nil, LBroker, ['pages']);
    Assert.IsNotNull(LBroker.Resolve('show_page'));
    Assert.IsNotNull(LBroker.Resolve('open_screen'));
  finally
    LSet.Free;
  end;
end;

procedure TSkillRegistryTests.SkillSet_UnknownName_IsSkipped;
var
  LBroker: THelpChatActionBroker;
  LRef: IHelpChatActionInvoker;
  LSet: THelpChatSkillSet;
begin
  LBroker := THelpChatActionBroker.Create;
  LRef := LBroker;
  LSet := THelpChatSkillSet.Create;
  try
    LSet.Attach(nil, LBroker, ['telepathy', 'records']);
    Assert.AreEqual(1, Length(LSet.Names));
    Assert.AreEqual(1, Length(LSet.Unknown));
    Assert.AreEqual('telepathy', LSet.Unknown[0]);
    Assert.IsNotNull(LBroker.Find('count_records'));
  finally
    LSet.Free;
  end;
end;

procedure TSkillRegistryTests.Settings_Skills_StringOrArray_RoundTrip;
var
  LSettings, LCopy: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LSettings.LoadFromJSON('{"Skills": "forms"}');
    Assert.AreEqual('forms', LSettings.Skills);
    LSettings.Profile := 'Sales';
    LSettings.LoadFromJSON('{"Skills": "forms", ' +
      '"Profiles": {"Sales": {"Skills": ["forms", "commands"]}}}');
    Assert.AreEqual('forms, commands', LSettings.Skills);
    Assert.AreEqual(2, Length(LSettings.ResolveSkills));
    LCopy.Assign(LSettings);
    Assert.AreEqual('forms, commands', LCopy.Skills);
    LCopy.Skills := '';
    LCopy.LoadFromJSON(LSettings.SaveToJSON);
    Assert.AreEqual('forms, commands', LCopy.Skills);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TSkillRegistryTests.Diagnostics_UnknownSkill_IsAWarning;
var
  LSettings: THelpChatSettings;
  LIssue: THelpChatIssue;
  LFound: Boolean;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Skills := 'forms, telepathy';
    LFound := False;
    for LIssue in HelpChatCheckSettings(LSettings) do
      if LIssue.Topic = 'Skills' then
      begin
        Assert.AreEqual(hikWarning, LIssue.Kind);
        Assert.Contains(LIssue.Text, '"telepathy"');
        Assert.DoesNotContain(LIssue.Text, '"forms"');
        LFound := True;
      end;
    Assert.IsTrue(LFound);
  finally
    LSettings.Free;
  end;
end;

procedure TSkillRegistryTests.Action_OnDisplay_ReplacesSummaryAndValues;
var
  LBroker: THelpChatActionBroker;
  LRef: IHelpChatActionInvoker;
  LAction: THelpChatAction;
  LArgs: THelpChatActionArgs;
  LPairs: TArray<TPair<string, string>>;
begin
  LBroker := THelpChatActionBroker.Create;
  LRef := LBroker;
  LAction := LBroker.Add('fill', 'Fills a form, said to the model at length.',
    [THelpChatActionParam.Create('values', 'JSON object')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string) begin end);
  LArgs := THelpChatActionArgs.Create('{"values": {"edName": "Mario"}}');
  try
    Assert.AreEqual('Fills a form, said to the model at length.', LAction.DisplaySummary(LArgs));
    LAction.OnDisplay :=
      procedure(const AArgs: THelpChatActionArgs; var ASummary: string;
        var AValues: TArray<TPair<string, string>>)
      begin
        ASummary := 'Fill the customer?';
        AValues := [TPair<string, string>.Create('Name', 'Mario'#13#10'Rossi')];
      end;
    Assert.AreEqual('Fill the customer?', LAction.DisplaySummary(LArgs));
    LPairs := LArgs.ToDisplayPairs(LAction);
    Assert.AreEqual(1, Length(LPairs));
    Assert.AreEqual('Name', LPairs[0].Key);
    Assert.AreEqual(0, Pos(#13, LPairs[0].Value), 'made safe like any value');
  finally
    LArgs.Free;
  end;
end;

procedure TSkillRegistryTests.Helpers_ParseWhatTheModelWrites;
var
  LBool: Boolean;
  LNumber: Double;
  LDate: TDateTime;
  LValues: TJSONObject;
begin
  Assert.IsTrue(HelpChatParseBoolean('Sì', LBool) and LBool);
  Assert.IsTrue(HelpChatParseBoolean('nein', LBool) and not LBool);
  Assert.IsFalse(HelpChatParseBoolean('maybe', LBool));
  Assert.IsTrue(HelpChatParseNumber('12.5', LNumber));
  Assert.AreEqual(12.5, LNumber, 0.0001);
  Assert.IsTrue(HelpChatParseDateTime('2026-10-19', hfkDate, LDate));
  Assert.AreEqual('2026-10-19', HelpChatFormatDateTime(LDate, hfkDate));
  Assert.IsTrue(HelpChatParseDateTime('2026-10-19 14:30', hfkDateTime, LDate));
  Assert.AreEqual('2026-10-19 14:30', HelpChatFormatDateTime(LDate, hfkDateTime));
  Assert.AreEqual(1, HelpChatMatchChoice(['Milano', 'Roma', 'Monza'], 'roma'));
  Assert.AreEqual(2, HelpChatMatchChoice(['Milano', 'Roma', 'Monza'], 'Mon'));
  Assert.AreEqual(-1, HelpChatMatchChoice(['Milano', 'Roma', 'Monza'], 'M'), 'two of them');
  Assert.AreEqual('Name', HelpChatCleanCaption('&Name *:'));
  Assert.AreEqual('Tom & Jerry', HelpChatCleanCaption('Tom && Jerry'));
  Assert.IsTrue(HelpChatCaptionMarksRequired('Code *:'));
  Assert.IsFalse(HelpChatCaptionMarksRequired('Code:'));
  Assert.AreEqual(hfmInsert, HelpChatParseFillMode('new'));
  Assert.AreEqual(hfmCurrent, HelpChatParseFillMode(''));
  // Models send the object, or a string holding it.
  LValues := HelpChatSkillValues('{"values": {"a": 1}}');
  try
    Assert.AreEqual('1', HelpChatJsonValueText(LValues.GetValue('a')));
  finally
    LValues.Free;
  end;
  LValues := HelpChatSkillValues('{"values": "{\"a\": true}"}');
  try
    Assert.AreEqual('true', HelpChatJsonValueText(LValues.GetValue('a')));
  finally
    LValues.Free;
  end;
  Assert.IsNull(HelpChatSkillValues('{"values": 3}'));
end;

procedure TSkillRegistryTests.SkillActionNames_AreFoundByName;
var
  LNames: TArray<string>;
begin
  LNames := HelpChatSkillActionNames('forms');
  Assert.AreEqual(4, Length(LNames));
  Assert.AreEqual('describe_form', LNames[0]);
  Assert.AreEqual('show_page', HelpChatSkillActionNames('pages')[0]);
  Assert.AreEqual(0, Length(HelpChatSkillActionNames('telepathy')));
  Assert.AreNotEqual(HelpChatSkillDescription('forms', hclEnglish),
    HelpChatSkillDescription('forms', hclItalian), 'it speaks the language of the chat');
end;

{ TVclSkillTests }

procedure TVclSkillTests.TearDown;
begin
  FreeAndNil(FForm);
  FreeAndNil(FTable);
  FreeAndNil(FRegions);
  FreeAndNil(FSource);
  FreeAndNil(FRegionSource);
  HelpChatVclSkills.HideFieldValues := False;
end;

procedure TVclSkillTests.CalcClick(Sender: TObject);
begin
  Inc(FCalcClicked);
end;

function DumpFields(const AFields: TObjectList<THelpChatVclField>): string;
var
  LField: THelpChatVclField;
begin
  Result := '';
  for LField in AFields do
    Result := Result + Format('%s/%s/%s/%s; ', [LField.Id, LField.Caption,
      BoolToStr(LField.Required, True), BoolToStr(TWinControl(LField.Control).Showing, True)]);
end;

function NewLabel(const AParent: TWinControl; const ACaption: string; const ALeft, ATop: Integer;
  const AFocus: TWinControl = nil): TLabel;
begin
  Result := TLabel.Create(AParent.Owner);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.SetBounds(ALeft, ATop, 80, 15);
  Result.FocusControl := AFocus;
end;

procedure TVclSkillTests.BuildPlainForm;
var
  LButton: TButton;
  LDisabled, LHidden: TEdit;
  LInner: TPageControl;
  LPublic: TTabSheet;
begin
  FForm := TForm.CreateNew(nil);
  FForm.Caption := 'Customer';
  FForm.Position := poDesigned;
  FForm.SetBounds(-3000, 100, 700, 600);
  FPages := TPageControl.Create(FForm);
  FPages.Parent := FForm;
  FPages.SetBounds(0, 0, 680, 500);
  FTabGeneral := TTabSheet.Create(FForm);
  FTabGeneral.PageControl := FPages;
  FTabGeneral.Caption := '&General';
  FTabNotes := TTabSheet.Create(FForm);
  FTabNotes.PageControl := FPages;
  FTabNotes.Caption := 'Notes';

  FFirst := TEdit.Create(FForm);
  FFirst.Name := 'edFirst';
  FFirst.Parent := FTabGeneral;
  FFirst.SetBounds(100, 10, 150, 21);
  FFirst.MaxLength := 20;
  FFirst.Text := ''; // naming an edit gives it its name as text
  FFirst.Hint := 'The first name, as on the identity card';
  NewLabel(FTabGeneral, 'First &name *:', 10, 12, FFirst);

  FPassword := TEdit.Create(FForm);
  FPassword.Name := 'edPassword';
  FPassword.Parent := FTabGeneral;
  FPassword.SetBounds(100, 40, 150, 21);
  FPassword.PasswordChar := '*';
  FPassword.Text := 'secret';
  NewLabel(FTabGeneral, 'Password', 10, 42); // no FocusControl: the nearest on the left

  FCity := TComboBox.Create(FForm);
  FCity.Name := 'cbCity';
  FCity.Parent := FTabGeneral;
  FCity.SetBounds(100, 70, 150, 21);
  FCity.Style := csDropDownList;
  FCity.Items.Add('Milano');
  FCity.Items.Add('Roma');
  NewLabel(FTabGeneral, 'City', 10, 72, FCity);

  FNews := TCheckBox.Create(FForm);
  FNews.Name := 'chkNews';
  FNews.Parent := FTabGeneral;
  FNews.SetBounds(100, 100, 150, 17);
  FNews.Caption := '&Newsletter';

  FSize := TRadioGroup.Create(FForm);
  FSize.Name := 'rgSize';
  FSize.Parent := FTabGeneral;
  FSize.SetBounds(100, 125, 150, 60);
  FSize.Caption := 'Size';
  FSize.Items.Add('Small');
  FSize.Items.Add('Large');

  FColour := TGroupBox.Create(FForm);
  FColour.Name := 'gbColour';
  FColour.Parent := FTabGeneral;
  FColour.SetBounds(300, 125, 150, 70);
  FColour.Caption := 'Colour';
  FRed := TRadioButton.Create(FForm);
  FRed.Name := 'rbRed';
  FRed.Parent := FColour;
  FRed.SetBounds(10, 20, 100, 17);
  FRed.Caption := 'Red';
  FBlue := TRadioButton.Create(FForm);
  FBlue.Name := 'rbBlue';
  FBlue.Parent := FColour;
  FBlue.SetBounds(10, 40, 100, 17);
  FBlue.Caption := 'Blue';

  FBirth := TDateTimePicker.Create(FForm);
  FBirth.Name := 'dtBirth';
  FBirth.Parent := FTabGeneral;
  FBirth.SetBounds(100, 230, 150, 21);
  FBirth.ShowCheckbox := True;
  FBirth.Checked := False;
  NewLabel(FTabGeneral, 'Birth date', 100, 212); // above it

  LDisabled := TEdit.Create(FForm);
  LDisabled.Name := 'edDisabled';
  LDisabled.Parent := FTabGeneral;
  LDisabled.SetBounds(100, 260, 150, 21);
  LDisabled.Enabled := False;
  LDisabled.Text := '';
  LHidden := TEdit.Create(FForm);
  LHidden.Name := 'edHidden';
  LHidden.Parent := FTabGeneral;
  LHidden.SetBounds(100, 290, 150, 21);
  LHidden.Visible := False;

  LButton := TButton.Create(FForm);
  LButton.Name := 'btnCalc';
  LButton.Parent := FForm;
  LButton.SetBounds(10, 520, 80, 25);
  LButton.Caption := '&Calculate';
  LButton.Hint := 'Computes the discount';
  LButton.OnClick := CalcClick;
  LButton := TButton.Create(FForm);
  LButton.Name := 'btnStore';
  LButton.Parent := FForm;
  LButton.SetBounds(100, 520, 80, 25);
  LButton.Caption := '&Save';
  LButton := TButton.Create(FForm);
  LButton.Name := 'btnClose';
  LButton.Parent := FForm;
  LButton.SetBounds(190, 520, 80, 25);
  LButton.Caption := 'Close';
  LButton.ModalResult := mrOk;

  // Notes > Private: a page inside a page.
  LInner := TPageControl.Create(FForm);
  LInner.Parent := FTabNotes;
  LInner.SetBounds(0, 0, 600, 400);
  LPublic := TTabSheet.Create(FForm);
  LPublic.PageControl := LInner;
  LPublic.Caption := 'Public';
  FTabPrivate := TTabSheet.Create(FForm);
  FTabPrivate.PageControl := LInner;
  FTabPrivate.Caption := 'Private';
  FPrivate := TMemo.Create(FForm);
  FPrivate.Name := 'memPrivate';
  FPrivate.Parent := FTabPrivate;
  FPrivate.SetBounds(10, 10, 300, 100);
  LInner.ActivePage := LPublic;
  FPages.ActivePage := FTabGeneral;
  FForm.Show;
end;

procedure TVclSkillTests.BuildDataForm;
var
  LEdit: TDBEdit;
  LLookup: TDBLookupComboBox;
  LCheck: TDBCheckBox;
  LGrid: TDBGrid;
begin
  FRegions := TFDMemTable.Create(nil);
  FRegions.Name := 'Regions';
  FRegions.FieldDefs.Add('Id', ftInteger);
  FRegions.FieldDefs.Add('Description', ftString, 30);
  FRegions.CreateDataSet;
  FRegions.AppendRecord([1, 'Lombardia']);
  FRegions.AppendRecord([2, 'Piemonte']);
  FRegions.AppendRecord([3, 'Liguria']);
  FRegionSource := TDataSource.Create(nil);
  FRegionSource.DataSet := FRegions;

  FTable := TFDMemTable.Create(nil);
  FTable.Name := 'Customers';
  FTable.FieldDefs.Add('Code', ftString, 10);
  FTable.FieldDefs.Add('CompanyName', ftString, 40);
  FTable.FieldDefs.Add('Region', ftInteger);
  FTable.FieldDefs.Add('Active', ftBoolean);
  FTable.CreateDataSet;
  FTable.FieldByName('Code').Required := True;
  FTable.FieldByName('CompanyName').DisplayLabel := 'Company';
  FTable.AppendRecord(['C1', 'Acme', 1, True]);
  FTable.AppendRecord(['C2', 'Rossi Srl', 2, False]);
  FTable.First;
  FSource := TDataSource.Create(nil);
  FSource.DataSet := FTable;

  FForm := TForm.CreateNew(nil);
  FForm.Caption := 'Customers';
  FForm.Position := poDesigned;
  FForm.SetBounds(-3000, 100, 700, 600);
  LEdit := TDBEdit.Create(FForm);
  LEdit.Name := 'edCode';
  LEdit.Parent := FForm;
  LEdit.SetBounds(100, 10, 100, 21);
  LEdit.DataSource := FSource;
  LEdit.DataField := 'Code';
  NewLabel(FForm, 'Code', 10, 12, LEdit);
  LEdit := TDBEdit.Create(FForm);
  LEdit.Name := 'edCompany';
  LEdit.Parent := FForm;
  LEdit.SetBounds(100, 40, 200, 21);
  LEdit.DataSource := FSource;
  LEdit.DataField := 'CompanyName'; // no label at all: the display label
  LLookup := TDBLookupComboBox.Create(FForm);
  LLookup.Name := 'cbRegion';
  LLookup.Parent := FForm;
  LLookup.SetBounds(100, 70, 200, 21);
  LLookup.DataSource := FSource;
  LLookup.DataField := 'Region';
  LLookup.ListSource := FRegionSource;
  LLookup.KeyField := 'Id';
  LLookup.ListField := 'Description';
  NewLabel(FForm, 'Region', 10, 72, LLookup);
  LCheck := TDBCheckBox.Create(FForm);
  LCheck.Name := 'chkActive';
  LCheck.Parent := FForm;
  LCheck.SetBounds(100, 100, 100, 17);
  LCheck.Caption := 'Active';
  LCheck.DataSource := FSource;
  LCheck.DataField := 'Active';
  LGrid := TDBGrid.Create(FForm);
  LGrid.Name := 'grdCustomers';
  LGrid.Parent := FForm;
  LGrid.SetBounds(10, 150, 600, 200);
  LGrid.DataSource := FSource;
  FForm.Show;
end;

procedure TVclSkillTests.Fields_CaptionsTypesAndOrder;
var
  LFields: TObjectList<THelpChatVclField>;
begin
  BuildPlainForm;
  LFields := HelpChatVclCollectFields(FForm);
  try
    Assert.AreEqual(7, LFields.Count, DumpFields(LFields));
    Assert.AreEqual('edFirst', LFields[0].Id, 'tab order');
    Assert.AreEqual('First name', LFields[0].Caption, 'the label that points to it');
    Assert.IsTrue(LFields[0].Required, 'the asterisk');
    Assert.AreEqual(20, LFields[0].MaxLength);
    Assert.AreEqual('The first name, as on the identity card', LFields[0].Hint);
    Assert.AreEqual('Password', LFields[1].Caption, 'the nearest label');
    Assert.IsTrue(LFields[1].Secret);
    Assert.AreEqual('cbCity', LFields[2].Id);
    Assert.AreEqual(hfkChoice, LFields[2].Kind);
    Assert.IsTrue(LFields[2].ChoicesOnly);
    Assert.AreEqual('Newsletter', LFields[3].Caption, 'its own caption');
    Assert.AreEqual(hfkBoolean, LFields[3].Kind);
    Assert.AreEqual('Size', LFields[4].Caption);
    Assert.AreEqual('gbColour', LFields[5].Id, 'the radio buttons of a group box are one field');
    Assert.AreEqual('Colour', LFields[5].Caption);
    Assert.AreEqual(2, Length(LFields[5].Choices));
    Assert.AreEqual('Birth date', LFields[6].Caption, 'the label above');
    Assert.AreEqual(hfkDate, LFields[6].Kind);
    Assert.AreEqual('', LFields[6].Value, 'an unchecked date is empty');
  finally
    LFields.Free;
  end;
end;

procedure TVclSkillTests.Fields_DisabledAndHidden_AreLeftOut;
var
  LFields: TObjectList<THelpChatVclField>;
  LField: THelpChatVclField;
begin
  BuildPlainForm;
  LFields := HelpChatVclCollectFields(FForm);
  try
    for LField in LFields do
    begin
      Assert.AreNotEqual('edDisabled', LField.Id);
      Assert.AreNotEqual('edHidden', LField.Id);
      Assert.AreNotEqual('memPrivate', LField.Id, 'a page not shown');
    end;
  finally
    LFields.Free;
  end;
end;

procedure TVclSkillTests.Describe_SaysTypesFlagsValuesAndPages;
var
  LText: string;
begin
  BuildPlainForm;
  FFirst.Text := 'Mario';
  LText := HelpChatVclDescribeForm(FForm, False);
  Assert.Contains(LText, 'Form: Customer');
  Assert.Contains(LText, '- edFirst | First name | text, max 20 characters | required | "Mario"');
  Assert.Contains(LText, 'The first name, as on the identity card');
  Assert.Contains(LText, 'one of: "Milano", "Roma"');
  Assert.Contains(LText, 'edPassword | Password | text | optional, secret: its value is never shown | filled');
  Assert.DoesNotContain(LText, 'secret"', 'a password is never read');
  Assert.Contains(LText, '"General" (shown)');
  Assert.Contains(LText, '"Notes > Private"');
  LText := HelpChatVclDescribeForm(FForm, True);
  Assert.DoesNotContain(LText, '"Mario"', 'HideFieldValues');
end;

procedure TVclSkillTests.Fill_PlainControls_AndCancelPutsThemBack;
var
  LValues: TJSONObject;
  LSnapshot: TDictionary<string, string>;
  LResult: string;
begin
  BuildPlainForm;
  FFirst.Text := 'Old';
  LSnapshot := TDictionary<string, string>.Create;
  LValues := TJSONObject.ParseJSONValue('{"edFirst": "Mario", "City": "roma", ' +
    '"chkNews": true, "rgSize": "Large", "gbColour": "Blue", "dtBirth": "1990-05-17"}') as TJSONObject;
  try
    LResult := HelpChatVclFillForm(FForm, LValues, hfmCurrent, False, LSnapshot);
    Assert.Contains(LResult, '6 field(s) set, 0 not set');
    Assert.AreEqual('Mario', FFirst.Text);
    Assert.AreEqual(1, FCity.ItemIndex);
    Assert.IsTrue(FNews.Checked);
    Assert.AreEqual(1, FSize.ItemIndex);
    Assert.IsTrue(FBlue.Checked);
    Assert.IsTrue(FBirth.Checked);
    Assert.AreEqual(EncodeDate(1990, 5, 17), DateOf(FBirth.Date));
    LResult := HelpChatVclCancelEdit(FForm, LSnapshot);
    Assert.Contains(LResult, 'previous value back');
    Assert.AreEqual('Old', FFirst.Text);
    Assert.AreEqual(-1, FCity.ItemIndex);
    Assert.IsFalse(FNews.Checked);
    Assert.IsFalse(FBlue.Checked);
    Assert.IsFalse(FBirth.Checked);
  finally
    LValues.Free;
    LSnapshot.Free;
  end;
end;

procedure TVclSkillTests.Fill_ReportsWhatItCouldNotDo;
var
  LValues: TJSONObject;
  LResult: string;
begin
  BuildPlainForm;
  LValues := TJSONObject.ParseJSONValue('{"cbCity": "Napoli", "edNothing": "x", ' +
    '"edFirst": "A name much longer than twenty"}') as TJSONObject;
  try
    LResult := HelpChatVclFillForm(FForm, LValues, hfmCurrent, False);
    Assert.Contains(LResult, '0 field(s) set, 3 not set');
    Assert.Contains(LResult, '"Napoli" is not allowed');
    Assert.Contains(LResult, 'edNothing: unknown field');
    Assert.Contains(LResult, 'too long');
    Assert.Contains(LResult, 'Required fields still empty: First name (edFirst)');
  finally
    LValues.Free;
  end;
end;

procedure TVclSkillTests.DataAware_APasswordEdit_IsNeverRead;
var
  LEdit: TDBEdit;
  LText: string;
begin
  // The data-aware adapter is asked before the plain edit one, which was
  // the only one to know a password when it saw one.
  BuildDataForm;
  LEdit := FForm.FindComponent('edCompany') as TDBEdit;
  LEdit.PasswordChar := '*';
  FTable.Edit;
  FTable.FieldByName('CompanyName').AsString := 'TopSecret42';
  try
    LText := HelpChatVclDescribeForm(FForm, False);
    Assert.DoesNotContain(LText, 'TopSecret42', 'the value never reaches the model');
  finally
    FTable.Cancel;
  end;
end;

procedure TVclSkillTests.Lookup_BeingEdited_IsNeitherPostedNorCancelled;
begin
  // Describing a form reads its lookup lists, and reading used to walk them
  // with First/Next - which posts the record somebody is editing there.
  BuildDataForm;
  FRegions.Locate('Id', 2, []);
  FRegions.Edit;
  FRegions.FieldByName('Description').AsString := 'Changed';
  HelpChatVclDescribeForm(FForm, False);
  Assert.AreEqual(Ord(dsEdit), Ord(FRegions.State), 'still being edited after describe_form');
  try
    HelpChatVclFindChoice(FForm, 'cbRegion', 'lig');
  except
    // It may refuse - what it must not do is save.
  end;
  Assert.AreEqual(Ord(dsEdit), Ord(FRegions.State), 'and after find_choice');
  FRegions.Cancel;
  Assert.AreEqual('Piemonte', FRegions.FieldByName('Description').AsString, 'nothing was saved');
end;

procedure TVclSkillTests.DataAware_Describe_ReadsTheField;
var
  LText: string;
begin
  BuildDataForm;
  LText := HelpChatVclDescribeForm(FForm, False);
  Assert.Contains(LText, 'State of Customers: browsing the record shown.');
  Assert.Contains(LText, '- edCode | Code | text, max 10 characters | required | "C1"');
  Assert.Contains(LText, '- edCompany | Company |', 'the display label');
  Assert.Contains(LText, 'reference to a record of "Regions"');
  Assert.Contains(LText, '"1 = Lombardia"');
  Assert.Contains(LText, '| "1 (Lombardia)"');
  Assert.Contains(LText, '- chkActive | Active | yes/no');
  Assert.Contains(LText, 'Lists: grdCustomers (Customers: 2 record(s))');
end;

procedure TVclSkillTests.DataAware_FillInsert_NeverPosts_AndCancelDropsIt;
var
  LValues: TJSONObject;
  LResult: string;
begin
  BuildDataForm;
  LValues := TJSONObject.ParseJSONValue('{"edCode": "C3", "Company": "Bianchi", ' +
    '"chkActive": "yes"}') as TJSONObject;
  try
    LResult := HelpChatVclFillForm(FForm, LValues, hfmInsert, False);
    Assert.Contains(LResult, '3 field(s) set, 0 not set');
    Assert.Contains(LResult, 'inserting a new record');
    Assert.AreEqual(dsInsert, FTable.State, 'never posted');
    Assert.AreEqual('C3', FTable.FieldByName('Code').AsString);
    Assert.IsTrue(FTable.FieldByName('Active').AsBoolean);
    // Inserting again while editing an existing record would post it: refused.
    FTable.Cancel;
    FTable.Edit;
    Assert.WillRaise(
      procedure
      begin
        HelpChatVclFillForm(FForm, LValues, hfmInsert, False);
      end, Exception);
    Assert.AreEqual(dsEdit, FTable.State);
    FTable.Cancel;
    HelpChatVclFillForm(FForm, LValues, hfmInsert, False);
    LResult := HelpChatVclCancelEdit(FForm);
    Assert.Contains(LResult, 'the new record of Customers');
    Assert.AreEqual(dsBrowse, FTable.State);
    Assert.AreEqual(2, FTable.RecordCount);
  finally
    LValues.Free;
  end;
end;

procedure TVclSkillTests.DataAware_Lookup_ByDescription_WritesTheCode;
var
  LValues: TJSONObject;
  LResult: string;
begin
  BuildDataForm;
  LValues := TJSONObject.ParseJSONValue('{"cbRegion": "liguria"}') as TJSONObject;
  try
    LResult := HelpChatVclFillForm(FForm, LValues, hfmEdit, False);
    Assert.Contains(LResult, 'set to 3 (Liguria)');
    Assert.AreEqual(3, FTable.FieldByName('Region').AsInteger);
    Assert.AreEqual(dsEdit, FTable.State);
    FTable.Cancel;
  finally
    LValues.Free;
  end;
  LValues := TJSONObject.ParseJSONValue('{"cbRegion": "Toscana"}') as TJSONObject;
  try
    LResult := HelpChatVclFillForm(FForm, LValues, hfmEdit, False);
    Assert.Contains(LResult, 'find_choice');
  finally
    LValues.Free;
    FTable.Cancel;
  end;
  LResult := HelpChatVclFindChoice(FForm, 'cbRegion', 'mont');
  Assert.Contains(LResult, '2 = Piemonte');
  Assert.DoesNotContain(LResult, 'Liguria');
end;

procedure TVclSkillTests.DataAware_NoAutoEdit_CurrentModeRefuses;
var
  LValues: TJSONObject;
begin
  BuildDataForm;
  FSource.AutoEdit := False;
  LValues := TJSONObject.ParseJSONValue('{"edCompany": "X"}') as TJSONObject;
  try
    Assert.WillRaise(
      procedure
      begin
        HelpChatVclFillForm(FForm, LValues, hfmCurrent, False);
      end, Exception);
    Assert.AreEqual(dsBrowse, FTable.State);
  finally
    LValues.Free;
  end;
end;

procedure TVclSkillTests.Records_FindRecord_NeitherSearchesNorReportsAPassword;
var
  LEdit: TDBEdit;
  LResult: string;
begin
  // describe_form said "filled" for a masked edit, and find_record then
  // reported the same field in clear with the record it found.
  BuildDataForm;
  LEdit := FForm.FindComponent('edCompany') as TDBEdit;
  LEdit.PasswordChar := '*';
  LResult := HelpChatVclFindRecord(FForm, 'C2', 'Code', '', False);
  Assert.Contains(LResult, 'on the record found');
  Assert.DoesNotContain(LResult, FTable.FieldByName('CompanyName').AsString, True);
  // Nor is it searched: a search that finds tells what the field holds.
  Assert.Contains(HelpChatVclFindRecord(FForm, 'rossi', '', '', False), 'was not found');
end;

procedure TVclSkillTests.Records_CountAndFind_RefusingWhileEditing;
var
  LResult: string;
begin
  BuildDataForm;
  Assert.Contains(HelpChatVclCountRecords(FForm, ''), '2 record(s)');
  LResult := HelpChatVclFindRecord(FForm, 'rossi', '', '', False);
  Assert.Contains(LResult, 'on the record found');
  Assert.AreEqual('C2', FTable.FieldByName('Code').AsString, 'starting with');
  HelpChatVclFindRecord(FForm, 'C1', 'Code', 'grdCustomers', False);
  Assert.AreEqual('C1', FTable.FieldByName('Code').AsString);
  Assert.Contains(HelpChatVclFindRecord(FForm, 'nobody', '', '', False), 'was not found');
  FTable.Edit;
  Assert.WillRaise(
    procedure
    begin
      HelpChatVclFindRecord(FForm, 'C2', '', '', False);
    end, Exception);
  Assert.AreEqual(dsEdit, FTable.State, 'moving would have posted');
  FTable.Cancel;
end;

procedure TVclSkillTests.Commands_WhileEditing_LeaveOutWhatMovesTheRecord;
var
  LActions: TActionList;
  LNext: TDataSetNext;
  LButton: TButton;
begin
  // A button with one of the standard data set actions: Next posts the
  // record being edited, which is saving - the one thing the skills never do.
  BuildDataForm;
  LActions := TActionList.Create(FForm);
  LNext := TDataSetNext.Create(FForm);
  LNext.ActionList := LActions;
  LNext.DataSource := FSource;
  LNext.Caption := 'Following record';
  LButton := TButton.Create(FForm);
  LButton.Name := 'btnFollowing';
  LButton.Parent := FForm;
  LButton.SetBounds(10, 400, 120, 25);
  LButton.Action := LNext;
  FTable.First;
  Assert.Contains(HelpChatVclListCommands(FForm), 'btnFollowing', 'offered while browsing');
  FTable.Edit;
  try
    Assert.DoesNotContain(HelpChatVclListCommands(FForm), 'btnFollowing',
      'not while a record is being edited');
  finally
    FTable.Cancel;
  end;
end;

procedure TVclSkillTests.Commands_LeaveOutTheSaves_AndPress;
var
  LText: string;
begin
  BuildPlainForm;
  LText := HelpChatVclListCommands(FForm);
  Assert.Contains(LText, '- btnCalc | Calculate | -');
  Assert.Contains(LText, 'Computes the discount');
  Assert.DoesNotContain(LText, 'btnStore', 'a caption that saves');
  Assert.DoesNotContain(LText, 'btnClose', 'ModalResult OK');
  HelpChatVclPressCommand(FForm, 'calculate', False);
  Assert.AreEqual(1, FCalcClicked);
  Assert.WillRaise(
    procedure
    begin
      HelpChatVclPressCommand(FForm, 'btnStore', False);
    end, Exception);
end;

procedure TVclSkillTests.Pages_ShowANestedPage;
var
  LResult: string;
  LFields: TObjectList<THelpChatVclField>;
begin
  BuildPlainForm;
  LResult := HelpChatVclShowPage(FForm, 'Private');
  Assert.Contains(LResult, '"Notes > Private" is shown');
  Assert.IsTrue(FTabPrivate.Showing);
  Assert.AreEqual(FTabNotes, FPages.ActivePage);
  Assert.IsFalse(FTabGeneral.Visible);
  LFields := HelpChatVclCollectFields(FForm);
  try
    Assert.AreEqual(1, LFields.Count, DumpFields(LFields));
    Assert.AreEqual('memPrivate', LFields[0].Id);
    Assert.AreEqual(hfkMemo, LFields[0].Kind);
  finally
    LFields.Free;
  end;
  Assert.Contains(HelpChatVclShowPage(FForm, 'Private'), 'already shown');
  Assert.WillRaise(
    procedure
    begin
      HelpChatVclShowPage(FForm, 'Accounting');
    end, Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TSkillRegistryTests);
  TDUnitX.RegisterTestFixture(TVclSkillTests);

end.
